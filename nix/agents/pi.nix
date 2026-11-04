# Pi's preferences are writable; instructions are read-only assets.
{
  config,
  lib,
  pkgs,
  dotfilesRepo ? "${config.home.homeDirectory}/.config/nix-darwin",
  enableAgentSkills ? true,
  ...
}: let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";
  agentsLib = import ./lib.nix {inherit pkgs;};
  settingsEntry = {
    format = "json";
    value =
      {
        enableInstallTelemetry = false;
        enableAnalytics = false;
      }
      // lib.optionalAttrs enableAgentSkills {
        skills = ["~/.agents/skills"];
      };
    dest = "$HOME/.pi/agent/settings.json";
    label = "pi-settings";
  };
  # Web search routing (K-373): local RustXNG first, OpenAI (ChatGPT
  # subscription) only when RustXNG is down, empty, or blocked upstream.
  webSearchEntry = {
    format = "json";
    value = {
      searxngBaseUrl = "http://127.0.0.1:29483";
      searchRouting = {
        providers = ["searxng" "openai"];
        fallbackOn = ["transient" "quota" "network" "invalid-response" "empty"];
      };
    };
    dest = "$HOME/.pi/agent/web-search.json";
    label = "pi-web-search";
  };
in {
  dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand [settingsEntry webSearchEntry];

  home.activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    agentsLib.mkMergeActivation (settingsEntry // {backupDir = "$HOME/.pi/agent/backups";})
  );

  home.activation.mergePiWebSearch = lib.hm.dag.entryAfter ["mergePiSettings"] (
    agentsLib.mkMergeActivation (webSearchEntry // {backupDir = "$HOME/.pi/agent/backups";})
  );

  home.file.".pi/agent/AGENTS.md".source = mkLink "home/ai/AGENTS.md";
  # Turn-end guard shared with the Devin/Codex/Kiro Stop hooks: on
  # agent_before_settle it appends a custom_message and requests one
  # continuation only after new commits, for material docs / issue updates.
  home.file.".pi/agent/extensions/task-finish.ts".source =
    mkLink "home/agents/pi/extensions/task-finish.ts";
}
