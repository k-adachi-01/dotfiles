# VS Code family GUI settings. `settings.json` is class A (declare + merge,
# see docs/management-policy.md): the GUI Settings UI writes to this same
# file (theme picks, per-language overrides added via the UI, etc.), so a
# plain home.file symlink made it read-only and broke "change a setting in
# the GUI" for these apps. `keybindings.json` stays a plain generated file
# (Nix store symlink) for now: unlike settings.json its top level is a bare
# JSON array, so the class A merge (dict-only, see nix/agents/lib.nix) can't
# preserve GUI-added shortcuts anyway — declaring it there would just
# silently discard any keybinding a user adds via the GUI on every switch.
{
  lib,
  pkgs,
  ...
}: let
  agentsLib = import ./agents/lib.nix {inherit pkgs;};
  json = pkgs.formats.json {};
  vimSettings = {
    "vim.easymotion" = true;
    "vim.incsearch" = true;
    "vim.useSystemClipboard" = true;
    "vim.useCtrlKeys" = true;
    "vim.hlsearch" = true;
    "vim.insertModeKeyBindings" = [
      {
        before = [
          "j"
          "j"
        ];
        after = ["<Esc>"];
      }
    ];
    "vim.normalModeKeyBindingsNonRecursive" = [
      {
        before = [
          "<leader>"
          "d"
        ];
        after = [
          "d"
          "d"
        ];
      }
      {
        before = ["<C-n>"];
        commands = [":nohl"];
      }
      {
        before = ["K"];
        commands = ["lineBreakInsert"];
        silent = true;
      }
    ];
    "vim.leader" = "<space>";
    "vim.handleKeys" = {
      "<C-a>" = false;
      "<C-f>" = false;
    };
  };
  commonSettings =
    vimSettings
    // {
      "window.commandCenter" = true;
      "git.autofetch" = true;
      "redhat.telemetry.enabled" = false;
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "plantuml.render" = "PlantUMLServer";
      "plantuml.server" = "https://www.plantuml.com/plantuml";
      "github.copilot.chat.localeOverride" = "ja";
      "github.copilot.nextEditSuggestions.enabled" = true;
      "amazonQ.suppressPrompts" = {
        amazonQChatPairProgramming = true;
        amazonQChatDisclaimer = true;
        amazonQSessionConfigurationMessage = true;
      };
      "extensions.experimental.affinity"."vscodevim.vim" = 1;
    };
  cursorSettings =
    commonSettings
    // {
      "hediet.vscode-drawio.resizeImages" = null;
      "[markdown]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 4;
      };
      "markdownlint.config".MD007.indent = 4;
      "[dockercompose]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
        "editor.autoIndent" = "advanced";
        "editor.quickSuggestions" = {
          other = true;
          comments = false;
          strings = true;
        };
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
      "githubPullRequests.createOnPublishBranch" = "never";
      "git.enableSmartCommit" = true;
      "typescript.experimental.useTsgo" = true;
      "window.autoDetectColorScheme" = false;
    };
  cursorKeybindings = [
    {
      key = "ctrl+i";
      command = "composerMode.agent";
    }
    {
      key = "shift+enter";
      command = "workbench.action.terminal.sendSequence";
      args.text = "\\\r\n";
      when = "terminalFocus";
    }
  ];

  mkSettingsEntry = {
    appDir,
    value,
    label,
  }: {
    format = "json";
    inherit value label;
    dest = "$HOME/Library/Application Support/${appDir}/User/settings.json";
  };

  vscodeSettingsEntry = mkSettingsEntry {
    appDir = "Code";
    value = commonSettings;
    label = "vscode-settings";
  };
  cursorSettingsEntry = mkSettingsEntry {
    appDir = "Cursor";
    value = cursorSettings;
    label = "cursor-editor-settings";
  };
  antigravitySettingsEntry = mkSettingsEntry {
    appDir = "Antigravity";
    value = cursorSettings;
    label = "antigravity-settings";
  };
  antigravityIdeSettingsEntry = mkSettingsEntry {
    appDir = "Antigravity IDE";
    value = cursorSettings;
    label = "antigravity-ide-settings";
  };
  settingsEntries = [
    vscodeSettingsEntry
    cursorSettingsEntry
    antigravitySettingsEntry
    antigravityIdeSettingsEntry
  ];

  backupDirFor = entry: "${builtins.dirOf entry.dest}/backups";
  mkActivation = entry:
    lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (entry // {backupDir = backupDirFor entry;})
    );
in
  lib.mkIf pkgs.stdenv.isDarwin {
    dotfilesAgents.classAMerges = map agentsLib.mkDiffCommand settingsEntries;

    home = {
      activation = {
        mergeVscodeSettings = mkActivation vscodeSettingsEntry;
        mergeCursorEditorSettings = mkActivation cursorSettingsEntry;
        mergeAntigravitySettings = mkActivation antigravitySettingsEntry;
        mergeAntigravityIdeSettings = mkActivation antigravityIdeSettingsEntry;
      };

      file = {
        "Library/Application Support/Cursor/User/keybindings.json".source =
          json.generate "cursor-keybindings.json" cursorKeybindings;

        "Library/Application Support/Antigravity/User/keybindings.json".source =
          json.generate "antigravity-keybindings.json" cursorKeybindings;

        "Library/Application Support/Antigravity IDE/User/keybindings.json".source =
          json.generate "antigravity-ide-keybindings.json" cursorKeybindings;
      };
    };
  }
