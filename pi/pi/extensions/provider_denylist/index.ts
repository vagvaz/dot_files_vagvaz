/**
 * provider_denylist.ts — Override built-in providers with a no-op stream
 * that prints "disabled provider" instead of sending requests to the LLM.
 *
 * Configuration: ~/.pi/agent/deny_providers.json (JSON array of provider names)
 *
 * Example deny_providers.json:
 *   ["anthropic", "openai", "deepseek", "google", "openrouter"]
 */

import type { ExtensionAPI, ProviderConfig } from "@earendil-works/pi-coding-agent";
import {
  type AssistantMessage,
  createAssistantMessageEventStream,
} from "@earendil-works/pi-ai";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

/**
 * Create an AssistantMessageEventStream that immediately emits
 * a single text block: "disabled provider: <name>"
 */
function createDisabledProviderStream(providerName: string) {
  const stream = createAssistantMessageEventStream();

  (async () => {
    const output: AssistantMessage = {
      role: "assistant",
      content: [{ type: "text", text: `disabled provider: ${providerName}` }],
      api: "openai-completions",
      provider: providerName,
      model: "disabled",
      usage: {
        input: 0,
        output: 0,
        cacheRead: 0,
        cacheWrite: 0,
        totalTokens: 0,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
      },
      stopReason: "stop",
      timestamp: Date.now(),
    };

    stream.push({ type: "start", partial: { ...output } });
    stream.push({
      type: "text_start",
      contentIndex: 0,
      partial: { ...output, content: [] },
    });
    stream.push({
      type: "text_delta",
      contentIndex: 0,
      delta: `disabled provider: ${providerName}`,
      partial: { ...output, content: [] },
    });
    stream.push({
      type: "text_end",
      contentIndex: 0,
      content: `disabled provider: ${providerName}`,
      partial: { ...output },
    });
    stream.push({ type: "done", reason: "stop", message: output });
    stream.end(output);
  })();

  return stream;
}

export default function (pi: ExtensionAPI) {
  // ── Read deny list ──────────────────────────────────────────────
  const configPath = path.join(os.homedir(), ".pi", "agent", "deny_providers.json");
  let deniedProviders: string[] = [];

  try {
    const content = fs.readFileSync(configPath, "utf-8");
    deniedProviders = JSON.parse(content);
    if (!Array.isArray(deniedProviders)) {
      console.error(
        "[provider_denylist] deny_providers.json must be a JSON array of provider name strings",
      );
      return;
    }
  } catch (err: any) {
    if (err.code === "ENOENT") {
      console.error(
        "[provider_denylist] deny_providers.json not found — no providers will be denied",
      );
    } else {
      console.error(
        "[provider_denylist] Failed to read deny_providers.json:",
        err.message,
      );
    }
    return;
  }

  if (deniedProviders.length === 0) {
    console.debug("[provider_denylist] deny list is empty — nothing to do");
    return;
  }

  // ── Override each denied provider with a no-op stream ───────────
  for (const providerName of deniedProviders) {
    try {
      // Register an override that replaces the stream implementation.
      // Existing models are preserved (we don't pass `models`) but any
      // request to this provider returns "disabled provider" immediately.
      pi.registerProvider(providerName, {
        api: "openai-completions",
        streamSimple: () => createDisabledProviderStream(providerName),
      } as ProviderConfig);
      console.debug(`[provider_denylist] Provider "${providerName}" is disabled`);
    } catch (err: any) {
      console.error(
        `[provider_denylist] Failed to disable provider "${providerName}":`,
        err.message,
      );
    }
  }
}
