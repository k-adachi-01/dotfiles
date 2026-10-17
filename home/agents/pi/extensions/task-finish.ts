// Turn-end guard: when an agent run is about to settle after a user prompt,
// request one continuation carrying a custom_message that tells the agent to
// update related docs / Linear issues first. Fires at most once per run:
// before_agent_start resets the flag, and the continuation itself does not
// start a new run, so the flag stays set when the follow-up settles.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MESSAGE =
  "終了する前に確認してください: このタスクの作業内容に関連するドキュメント(repo 内の docs/, README, AGENTS.md など)があれば最新の状態に更新してください。また、ブランチ名や会話中に登場した issue ID(K-123 など)に対応する Linear issue があれば、Linear MCP ツールでステータスやコメントを更新してください。どちらも該当しない場合は、そのまま終了して構いません。";

export default function (pi: ExtensionAPI) {
  let fired = false;

  pi.on("before_agent_start", (event) => {
    if (event.messageType === "user") fired = false;
  });

  pi.on("agent_before_settle", (event) => {
    if (fired || event.outcome !== "completed") return;
    fired = true;
    return {
      continue: true,
      entries: [
        ...event.entries,
        {
          type: "custom_message" as const,
          customType: "task-finish-guard",
          content: MESSAGE,
          display: false,
        },
      ],
    };
  });
}
