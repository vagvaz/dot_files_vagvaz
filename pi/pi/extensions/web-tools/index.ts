/**
 * web-tools.ts — Local web search and URL fetching for Pi coding agent.
 * Zero external services: DuckDuckGo HTML for search, Readability + Turndown for page extraction.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { JSDOM } from "jsdom";
import { Readability } from "@mozilla/readability";
import TurndownService from "turndown";

// ─── web_search ───────────────────────────────────────────────────────────────

async function duckduckgoSearch(query: string, maxResults: number = 5): Promise<string> {
  const encoded = encodeURIComponent(query);
  const url = `https://html.duckduckgo.com/html/?q=${encoded}`;

  const response = await fetch(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    throw new Error(`DuckDuckGo search failed: ${response.status} ${response.statusText}`);
  }

  const html = await response.text();
  const dom = new JSDOM(html);
  const doc = dom.window.document;

  const results: Array<{ title: string; url: string; snippet: string }> = [];
  const resultDivs = doc.querySelectorAll(".result");

  for (const div of resultDivs) {
    if (results.length >= maxResults) break;
    const link = div.querySelector("a.result__a");
    const snippet = div.querySelector(".result__snippet");
    if (link && snippet) {
      const href = link.getAttribute("href") || "";
      const title = link.textContent?.trim() || "";
      const snippetText = snippet.textContent?.trim() || "";
      if (title && href) {
        results.push({ title, url: href, snippet: snippetText });
      }
    }
  }

  if (results.length === 0) {
    return `No results found for: "${query}"`;
  }

  return results
    .map((r, i) => `${i + 1}. **${r.title}**\n   URL: ${r.url}\n   ${r.snippet}`)
    .join("\n\n");
}

// ─── web_fetch ────────────────────────────────────────────────────────────────

async function fetchUrlAsMarkdown(url: string): Promise<string> {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    signal: AbortSignal.timeout(20000),
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.status} ${response.statusText}`);
  }

  const contentType = response.headers.get("content-type") || "";

  if (
    contentType.includes("text/markdown") ||
    contentType.includes("text/plain") ||
    contentType.includes("application/json") ||
    contentType.includes("text/xml")
  ) {
    const text = await response.text();
    return `Content from ${url}:\n\n${text.slice(0, 50000)}`;
  }

  const html = await response.text();
  const dom = new JSDOM(html, { url });
  const reader = new Readability(dom.window.document);
  const article = reader.parse();

  if (!article) {
    const text = dom.window.document.body?.textContent || "";
    return `Content from ${url} (no article extracted):\n\n${text.slice(0, 30000)}`;
  }

  const turndown = new TurndownService({
    headingStyle: "atx",
    codeBlockStyle: "fenced",
    bulletListMarker: "-",
  });

  turndown.addRule("pre", {
    filter: "pre",
    replacement: (content, node) => {
      const code = (node as HTMLElement).querySelector("code");
      const text = code ? code.textContent : content;
      return `\n\`\`\`\n${text}\n\`\`\`\n`;
    },
  });

  const markdown = turndown.turndown(article.content);
  const title = article.title ? `# ${article.title}\n\n` : "";

  return `${title}Content from ${url}:\n\n${markdown.slice(0, 50000)}`;
}

// ─── Extension entry point ────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using DuckDuckGo. Returns concise results with titles, URLs, and snippets. Use when you need current information, documentation, or answers that may not be in your training data.",
    parameters: Type.Object({
      query: Type.String({ description: "The search query" }),
      maxResults: Type.Optional(Type.Number({ description: "Maximum number of results (default: 5, max: 10)" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const max = Math.min(params.maxResults || 5, 10);
      const results = await duckduckgoSearch(params.query, max);
      return {
        content: [{ type: "text" as const, text: results }],
        details: {},
      };
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a URL and extract its content as readable markdown. Automatically handles HTML pages (using Readability), JSON, plain text, and XML. Use to read documentation, articles, API responses, or any web page content.",
    parameters: Type.Object({
      url: Type.String({ description: "The URL to fetch" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const content = await fetchUrlAsMarkdown(params.url);
      return {
        content: [{ type: "text" as const, text: content }],
        details: {},
      };
    },
  });
}
