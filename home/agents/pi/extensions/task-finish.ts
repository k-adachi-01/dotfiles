// Use the shared commit-boundary guard so all agents follow the same policy.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

function guard(mode: string, sessionId: string, cwd: string): string {
  try {
    return execFileSync(
      "bash",
      [join(homedir(), "bin/agent-task-finish-guard"), ...(mode ? [mode] : [])],
      {
        input: JSON.stringify({ session_id: sessionId, cwd }),
        encoding: "utf8",
        timeout: 10_000,
        stdio: ["pipe", "pipe", "pipe"],
      },
    );
  } catch {
    return "";
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (event.messageType === "user") {
      guard("begin", ctx.sessionManager.getSessionId(), ctx.cwd);
    }
  });

  pi.on("agent_before_settle", (event, ctx) => {
    if (event.outcome !== "completed") return;
    const output = guard("", ctx.sessionManager.getSessionId(), ctx.cwd);
    if (!output) return;
    const result = JSON.parse(output);
    if (result.decision !== "block") return;
    return {
      continue: true,
      entries: [
        ...event.entries,
        {
          type: "custom_message" as const,
          customType: "task-finish-guard",
          content: result.reason,
          display: false,
        },
      ],
    };
  });
}
