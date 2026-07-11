# Zed editor settings. `settings.json` is class A (merge): Zed's Settings UI
# writes to the same file. `keymap.json` is class B (mkLink): top-level JSON
# array, so the dict-only merge helper cannot preserve GUI-added bindings.
{
  config,
  lib,
  pkgs,
  dotfilesRepo ? "${config.home.homeDirectory}/.config/nix-darwin",
  ...
}: let
  agentsLib = import ./agents/lib.nix {inherit pkgs;};
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${path}";

  zedSettings = builtins.fromJSON (builtins.readFile ../home/editors/zed/settings.json);

  zedSettingsEntry = {
    format = "jsonc";
    value = zedSettings;
    label = "zed-settings";
    dest = "$HOME/.config/zed/settings.json";
  };

  backupDir = "$HOME/.config/zed/backups";
in {
  dotfilesAgents.classAMerges = [
    (agentsLib.mkDiffCommand zedSettingsEntry)
  ];

  home = {
    activation.mergeZedSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
      agentsLib.mkMergeActivation (zedSettingsEntry // {inherit backupDir;})
    );

    file = {
      ".config/zed/keymap.json".source = mkLink "home/editors/zed/keymap.json";
    };
  };
}
