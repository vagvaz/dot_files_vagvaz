/**
 * profile-switcher.ts — Switch between agent model profiles (local vs online).
 * Usage: /profile local  or  /profile online  or  /profile list
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

const PI_AGENT_DIR = path.join(os.homedir(), ".pi", "agent");
const PROFILES_INDEX = path.join(PI_AGENT_DIR, "profiles", "profiles.json");
const SETTINGS_FILE = path.join(PI_AGENT_DIR, "settings.json");

interface ProfileConfig {
  name: string;
  description: string;
  agentOverrides: Record<string, { model?: string; thinking?: string }>;
}

interface ProfilesIndex {
  [key: string]: string;
}

interface Settings {
  [key: string]: unknown;
  activeProfile?: string;
  subagents?: {
    agentOverrides?: Record<string, unknown>;
  };
}

function getCurrentProfile(): string | null {
  try {
    const settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
    return settings.activeProfile || null;
  } catch {
    return null;
  }
}

function loadProfilesIndex(): ProfilesIndex {
  try {
    return JSON.parse(fs.readFileSync(PROFILES_INDEX, "utf-8"));
  } catch {
    return {};
  }
}

function loadProfile(filePath: string): ProfileConfig {
  const content = fs.readFileSync(filePath, "utf-8");
  return JSON.parse(content);
}

function activateProfile(profileName: string): string {
  const index = loadProfilesIndex();
  const profilePath = index[profileName];

  if (!profilePath) {
    const available = Object.keys(index).join(", ") || "none";
    return `Profile "${profileName}" not found. Available: ${available}`;
  }

  const resolvedPath = profilePath.replace("~", os.homedir());
  const profile = loadProfile(resolvedPath);

  let settings: Settings = {};
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
  } catch {
    // start fresh
  }

  settings.activeProfile = profileName;
  settings.subagents = settings.subagents || {};
  settings.subagents.agentOverrides = profile.agentOverrides as Record<string, unknown>;

  fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2));

  const mappings = Object.entries(profile.agentOverrides)
    .map(([agent, cfg]) => `  ${agent}: ${cfg.model || "default"} (${cfg.thinking || "default"})`)
    .join("\n");

  return `Switched to profile "${profileName}" (${profile.description}).\n\nAgent model mappings:\n${mappings}\n\nRestart Pi or run /reload to apply changes.`;
}

function listProfiles(): string {
  const index = loadProfilesIndex();
  const current = getCurrentProfile();
  const lines: string[] = ["Available profiles:"];

  for (const [name, filePath] of Object.entries(index)) {
    try {
      const resolvedPath = filePath.replace("~", os.homedir());
      const profile = loadProfile(resolvedPath);
      const marker = name === current ? " ← active" : "";
      lines.push(`  ${name}: ${profile.description}${marker}`);
    } catch {
      lines.push(`  ${name}: (could not load)`);
    }
  }

  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("profile", {
    description: "Switch between agent model profiles (e.g., local, online)",
    handler: async (args, ctx) => {
      const action = args?.trim();

      if (!action || action === "list" || action === "ls") {
        ctx.ui.notify(listProfiles(), "info");
        return;
      }

      const result = activateProfile(action);
      ctx.ui.notify(result, "info");
    },
  });
}
