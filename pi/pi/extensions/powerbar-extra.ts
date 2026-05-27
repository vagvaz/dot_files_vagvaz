/**
 * powerbar-extra.ts — Extra status segments for pi-powerbar.
 *
 * Adds:
 *   - Current time (segment: "time")
 *   - OS CPU usage  (segment: "cpu")
 *   - OS memory usage (segment: "memory")
 *   - MCP server status (segment: "mcp-status")
 *
 * Usage: Add these segment IDs to powerbar settings left/right:
 *   /settings powerbar left git-branch,tokens,context-usage,cpu,memory
 *   /settings powerbar right provider,model,time,mcp-status,sub-hourly,sub-weekly
 *
 * Dependencies:
 *   - @juanibiapina/pi-powerbar (for the powerbar event protocol)
 *   - Requires no additional npm packages (uses Node.js built-in `os` and `fetch`)
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import * as os from "node:os";
import * as fs from "node:fs";
import * as path from "node:path";

// ─── Time Segment ───────────────────────────────────────────────────────────

function getTimeString(): string {
  const now = new Date();
  return now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

function emitTime(pi: ExtensionAPI): void {
  pi.events.emit("powerbar:update", {
    id: "time",
    text: getTimeString(),
    color: "dim",
  });
}

// ─── CPU Segment ────────────────────────────────────────────────────────────

/** Read a line from /proc/stat (Linux) or fall back to os.loadavg() */
function getCpuPercent(): number | undefined {
  try {
    // Linux: read /proc/stat for delta-based CPU usage
    const stat = fs.readFileSync("/proc/stat", "utf-8");
    const cpuLine = stat.split("\n").find((l) => l.startsWith("cpu "));
    if (!cpuLine) return undefined;
    const parts = cpuLine.trim().split(/\s+/).slice(1).map(Number);
    const total = parts.reduce((a, b) => a + b, 0);
    const idle = parts[3] || 0;
    return total > 0 ? Math.round((1 - idle / total) * 100) : 0;
  } catch {
    // Fallback: os.loadavg() gives 1/5/15 min load averages
    const load = os.loadavg()[0];
    const cpus = os.cpus().length;
    return cpus > 0 ? Math.round((load / cpus) * 100) : undefined;
  }
}

/** Cached CPU ticks from previous measurement for delta calculation */
let prevCpuTicks: { total: number; idle: number } | undefined;

function measureCpuDelta(): number | undefined {
  try {
    const stat = fs.readFileSync("/proc/stat", "utf-8");
    const cpuLine = stat.split("\n").find((l) => l.startsWith("cpu "));
    if (!cpuLine) return undefined;
    const parts = cpuLine.trim().split(/\s+/).slice(1).map(Number);
    const total = parts.reduce((a, b) => a + b, 0);
    const idle = parts[3] || 0;

    if (prevCpuTicks) {
      const deltaTotal = total - prevCpuTicks.total;
      const deltaIdle = idle - prevCpuTicks.idle;
      if (deltaTotal > 0) {
        return Math.round((1 - deltaIdle / deltaTotal) * 100);
      }
    }

    prevCpuTicks = { total, idle };
    // First measurement: use current snapshot
    return total > 0 ? Math.round((1 - idle / total) * 100) : 0;
  } catch {
    const load = os.loadavg()[0];
    const cpus = os.cpus().length;
    return cpus > 0 ? Math.round((load / cpus) * 100) : undefined;
  }
}

function getCpuColor(pct: number): string {
  if (pct > 80) return "error";
  if (pct > 60) return "warning";
  return "muted";
}

function emitCpu(pi: ExtensionAPI): void {
  const pct = measureCpuDelta();
  if (pct !== undefined) {
    pi.events.emit("powerbar:update", {
      id: "cpu",
      icon: "▂",
      text: `${pct}%`,
      color: getCpuColor(pct),
    });
  }
}

// ─── Memory Segment ─────────────────────────────────────────────────────────

function getMemPercent(): number | undefined {
  try {
    // Linux: read /proc/meminfo for accurate measurement
    const meminfo = fs.readFileSync("/proc/meminfo", "utf-8");
    const memTotal = parseMemInfoLine(meminfo, "MemTotal");
    const memAvailable = parseMemInfoLine(meminfo, "MemAvailable");
    if (memTotal > 0 && memAvailable !== undefined) {
      return Math.round(((memTotal - memAvailable) / memTotal) * 100);
    }
    // Fallback
    return undefined;
  } catch {
    const total = os.totalmem();
    const free = os.freemem();
    return total > 0 ? Math.round(((total - free) / total) * 100) : undefined;
  }
}

function parseMemInfoLine(meminfo: string, key: string): number | undefined {
  const line = meminfo.split("\n").find((l) => l.startsWith(key + ":"));
  if (!line) return undefined;
  const match = line.match(/(\d+)/);
  return match ? Number.parseInt(match[1], 10) : undefined;
}

function getMemColor(pct: number): string {
  if (pct > 80) return "error";
  if (pct > 60) return "warning";
  return "muted";
}

function emitMemory(pi: ExtensionAPI): void {
  const pct = getMemPercent();
  if (pct !== undefined) {
    pi.events.emit("powerbar:update", {
      id: "memory",
      icon: "⬇",
      text: `${pct}%`,
      color: getMemColor(pct),
    });
  }
}

// ─── MCP Status Segment ─────────────────────────────────────────────────────

interface McpConfig {
  mcpServers?: Record<string, McpServerConfig>;
}

interface McpServerConfig {
  url?: string;
  command?: string;
  args?: string[];
  lifecycle?: string;
}

interface McpCheckResult {
  name: string;
  alive: boolean;
  url?: string;
}

/** Check if a server endpoint is responsive. */
async function checkUrl(url: string): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    const resp = await fetch(url, {
      method: "GET",
      signal: controller.signal,
    });
    clearTimeout(timeout);
    return resp.ok;
  } catch {
    return false;
  }
}

/** Check if an npx-based MCP server process is running */
async function checkNpxProcess(args?: string[]): Promise<boolean> {
  try {
    const { execSync } = await import("node:child_process");
    const cmd = args?.join(" ") || "";
    const ps = execSync("ps aux", { encoding: "utf-8", timeout: 2000 });
    return cmd.length > 0 && ps.includes(cmd.slice(0, 40));
  } catch {
    return false;
  }
}

/**
 * Build an OSC 8 hyperlink ANSI sequence.
 * In modern terminals (kitty, iTerm2, WezTerm, Windows Terminal),
 * hovering over the text shows the URL as a tooltip.
 */
function hyperlink(url: string, text: string): string {
  return `\x1b]8;;${url}\x1b\\${text}\x1b]8;;\x1b\\`;
}

async function emitMcpStatus(pi: ExtensionAPI): Promise<void> {
  try {
    const configPath = path.join(os.homedir(), ".pi", "agent", "mcp.json");
    const raw = fs.readFileSync(configPath, "utf-8");
    const config: McpConfig = JSON.parse(raw);
    if (!config.mcpServers || Object.keys(config.mcpServers).length === 0) {
      pi.events.emit("powerbar:update", { id: "mcp-status", text: undefined });
      return;
    }

    const results: McpCheckResult[] = await Promise.all(
      Object.entries(config.mcpServers).map(async ([name, cfg]) => {
        if (cfg.url) {
          const alive = await checkUrl(cfg.url);
          return { name, alive, url: cfg.url };
        }
        if (cfg.command === "npx") {
          const alive = await checkNpxProcess(cfg.args);
          return { name, alive };
        }
        return { name, alive: false };
      }),
    );

    const connected = results.filter((r) => r.alive);
    const total = results.length;

    if (total === 0) {
      pi.events.emit("powerbar:update", { id: "mcp-status", text: undefined });
      return;
    }

    // Build individual server indicators: 🟢serena ○ctx7
    // SSE servers get clickable hyperlinks showing the URL on hover
    const parts = results.map((r) => {
      const indicator = r.alive ? "🟢" : "○";
      const label = r.name.length > 8 ? r.name.slice(0, 7) + "…" : r.name;
      if (r.url && r.alive) {
        return indicator + hyperlink(r.url, label);
      }
      return indicator + label;
    });

    const text = parts.join(" ");
    const color = connected.length === total ? "muted" : connected.length > 0 ? "warning" : "error";

    pi.events.emit("powerbar:update", {
      id: "mcp-status",
      text,
      color,
    });
  } catch {
    pi.events.emit("powerbar:update", { id: "mcp-status", text: undefined });
  }
}

// ─── Extension entry point ──────────────────────────────────────────────────

export default function (pi: ExtensionAPI): void {
  // ── Segment registration (deferred to session_start) ──
  // Segment registration is deferred because this extension is auto-discovered
  // from ~/.pi/agent/extensions/ which loads BEFORE packages. The powerbar core
  // (loaded as a package) needs to have its listener set up before we can
  // register segments. On session_start, all extensions are loaded.
  function registerSegments(): void {
    pi.events.emit("powerbar:register-segment", { id: "time", label: "Current Time" });
    pi.events.emit("powerbar:register-segment", { id: "cpu", label: "CPU Usage" });
    pi.events.emit("powerbar:register-segment", { id: "memory", label: "Memory Usage" });
    pi.events.emit("powerbar:register-segment", { id: "mcp-status", label: "MCP Servers" });
  }

  // ── Time ticker ──
  let timeInterval: ReturnType<typeof setInterval> | undefined;

  // ── Session lifecycle ──
  pi.on("session_start", async (_event, ctx) => {
    // Register segments now that all extensions (including powerbar) are loaded
    registerSegments();

    // Emit all segments immediately
    emitTime(pi);
    emitCpu(pi);
    emitMemory(pi);
    await emitMcpStatus(pi);

    // Update time every 30s
    if (!timeInterval) {
      timeInterval = setInterval(() => emitTime(pi), 30_000);
    }
  });

  pi.on("session_shutdown", async () => {
    if (timeInterval) {
      clearInterval(timeInterval);
      timeInterval = undefined;
    }
  });

  // ── Refresh on tool results (bash may affect system state, branches change) ──
  pi.on("tool_result", async (event, ctx) => {
    // Refresh CPU, memory, mcp status every few tool results (not every single one)
    if (event.toolName === "bash") {
      emitCpu(pi);
      emitMemory(pi);
    }
  });

  // ── Refresh on turn start (especially for MCP which may connect/disconnect) ──
  pi.on("turn_start", async () => {
    emitTime(pi);
  });
}
