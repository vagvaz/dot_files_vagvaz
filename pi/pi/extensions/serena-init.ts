/**
 * Serena auto-init extension
 *
 * On startup, checks if the current working directory is inside a Serena
 * project. If so, performs the MCP initialize handshake and calls the
 * `session_init` tool to bind the session and activate the project.
 *
 * If Serena isn't running or the cwd isn't a Serena project, this is a
 * silent no-op.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as crypto from "node:crypto";

const SERENA_HOST = "http://127.0.0.1:8765";

/**
 * Walk up from `dir` looking for `.serena/project.yml`.
 * Returns the project root path if found, or null.
 */
function findSerenaProjectRoot(dir: string): string | null {
  let current = path.resolve(dir);
  for (let i = 0; i < 20; i++) {
    const candidate = path.join(current, ".serena", "project.yml");
    try {
      if (fs.statSync(candidate).isFile()) {
        return current;
      }
    } catch {
      // not found, keep walking up
    }
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  return null;
}

/**
 * Minimal MCP-over-SSE client that performs the initialize handshake
 * and calls a tool. Uses a single SSE connection for the full lifecycle.
 */
async function callSessionInit(
  projectRoot: string,
  signal?: AbortSignal,
): Promise<void> {
  // 1. Open SSE connection (pass cwd for auto-init as fallback)
  const sseUrl = `${SERENA_HOST}/sse?cwd=${encodeURIComponent(projectRoot)}`;
  const response = await fetch(sseUrl, { signal });
  if (!response.ok || !response.body) {
    throw new Error(`SSE connection failed: ${response.status}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let endpointPath: string | undefined;
  let buffer = "";

  // 2. Read SSE until we get the endpoint event
  while (!endpointPath) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    for (const line of buffer.split("\n")) {
      if (line.startsWith("data: ") && line.includes("/messages/")) {
        endpointPath = line.slice(6).trim();
        break;
      }
    }
  }
  if (!endpointPath) {
    reader.cancel().catch(() => {});
    throw new Error("No endpoint received from SSE stream");
  }

  const postUrl = endpointPath.startsWith("http")
    ? endpointPath
    : `${SERENA_HOST}${endpointPath}`;

  // Helper: POST a JSON-RPC message and wait for the response on SSE
  async function sendRequest(
    method: string,
    params: unknown,
    requestId: string,
  ): Promise<unknown> {
    const body = JSON.stringify({
      jsonrpc: "2.0",
      id: requestId,
      method,
      params,
    });

    const postRes = await fetch(postUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      signal,
    });
    if (!postRes.ok) {
      const text = await postRes.text().catch(() => "");
      throw new Error(`POST failed (${postRes.status}): ${text}`);
    }

    // Read SSE until we get a matching response
    while (true) {
      const { done, value } = await reader.read();
      if (done) throw new Error("SSE stream ended before response");
      buffer += decoder.decode(value, { stream: true });

      const lines = buffer.split("\n");
      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const dataStr = line.slice(6);
          try {
            const msg = JSON.parse(dataStr);
            if (msg.id === requestId) {
              if (msg.error) {
                throw new Error(
                  `MCP error [${msg.error.code}]: ${msg.error.message}`,
                );
              }
              return msg.result;
            }
          } catch (e) {
            if (e instanceof SyntaxError) continue;
            throw e;
          }
        }
      }
      // Keep only last partial line
      buffer = lines[lines.length - 1] ?? "";
    }
  }

  try {
    // 3. MCP initialize handshake
    const initResult = await sendRequest(
      "initialize",
      {
        protocolVersion: "2025-11-25",
        capabilities: {},
        clientInfo: { name: "pi", version: "1.0" },
      },
      crypto.randomUUID(),
    );
    console.debug("[serena-init] Initialize result:", JSON.stringify(initResult).slice(0, 200));

    // 4. Send initialized notification
    const notifBody = JSON.stringify({
      jsonrpc: "2.0",
      method: "notifications/initialized",
    });
    await fetch(postUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: notifBody,
      signal,
    }).catch(() => {}); // fire-and-forget

    // 5. Call session_init tool
    const toolResult = await sendRequest(
      "tools/call",
      {
        name: "session_init",
        arguments: { project: projectRoot },
      },
      crypto.randomUUID(),
    );
    console.debug(
      "[serena-init] session_init result:",
      JSON.stringify(toolResult).slice(0, 300),
    );
  } finally {
    reader.cancel().catch(() => {});
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    // 1. Check if we're in a Serena project
    const projectRoot = findSerenaProjectRoot(ctx.cwd);
    if (!projectRoot) {
      console.debug("[serena-init] cwd is not inside a Serena project — skipping");
      return;
    }

    console.debug(`[serena-init] Found Serena project at ${projectRoot}`);

    // 2. Perform MCP handshake and call session_init
    try {
      await callSessionInit(projectRoot, ctx.signal);
      console.debug("[serena-init] Session initialized successfully");
    } catch (err: any) {
      console.debug("[serena-init] Could not initialize Serena session:", err.message);
    }
  });
}
