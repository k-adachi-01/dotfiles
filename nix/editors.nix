{ pkgs, ... }:

let
  json = pkgs.formats.json { };
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
        after = [ "<Esc>" ];
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
        before = [ "<C-n>" ];
        commands = [ ":nohl" ];
      }
      {
        before = [ "K" ];
        commands = [ "lineBreakInsert" ];
        silent = true;
      }
    ];
    "vim.leader" = "<space>";
    "vim.handleKeys" = {
      "<C-a>" = false;
      "<C-f>" = false;
    };
  };
  commonSettings = vimSettings // {
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
  cursorSettings = commonSettings // {
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
in
{
  home.file = {
    "Library/Application Support/Code/User/settings.json".source =
      json.generate "vscode-settings.json" commonSettings;

    "Library/Application Support/Cursor/User/settings.json".source =
      json.generate "cursor-settings.json" cursorSettings;
    "Library/Application Support/Cursor/User/keybindings.json".source =
      json.generate "cursor-keybindings.json" cursorKeybindings;

    "Library/Application Support/Antigravity/User/settings.json".source =
      json.generate "antigravity-settings.json" cursorSettings;
    "Library/Application Support/Antigravity/User/keybindings.json".source =
      json.generate "antigravity-keybindings.json" cursorKeybindings;

    "Library/Application Support/Antigravity IDE/User/settings.json".source =
      json.generate "antigravity-ide-settings.json" cursorSettings;
    "Library/Application Support/Antigravity IDE/User/keybindings.json".source =
      json.generate "antigravity-ide-keybindings.json" cursorKeybindings;
  };
}
