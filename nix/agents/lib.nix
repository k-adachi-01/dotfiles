# Class A ("declare + merge") helper.
#
# Some AI agent config files are written to by both this repo (declared,
# durable settings) and by the app itself at runtime (trust decisions,
# UI state, telemetry). Treating them as plain home.file symlinks makes the
# app unable to write to its own config; treating them as fully app-owned
# makes the repo drift silently. This module implements the middle ground
# documented in docs/management-policy.md: on every `switch`, the keys we
# declare in Nix are deep-merged into the live file, while any key the app
# added on its own is left untouched.
#
# See docs/management-policy.md section 2 for the full class A/B/C model.
{pkgs}: let
  # Single script, format selected by --format, so every tool's merge
  # activation snippet shares the exact same parse/merge/dump/validate logic.
  # NOTE: TOML/YAML round-trips are not comment-preserving (tomllib/pyyaml
  # don't retain comments). Declared files should not rely on comments
  # surviving a merge.
  mergeConfigScript =
    pkgs.writers.writePython3 "merge-agent-config" {
      libraries = [
        pkgs.python3Packages.tomli-w
        pkgs.python3Packages.pyyaml
        pkgs.python3Packages.pyjson5
      ];
      flakeIgnore = ["E501"];
    } ''
      import argparse
      import difflib
      import json
      import os
      import sys
      import tempfile
      import tomllib

      import tomli_w
      import yaml
      import json5


      def load_toml(path):
          with open(path, "rb") as f:
              return tomllib.load(f)


      def dump_toml(data, path):
          with open(path, "wb") as f:
              tomli_w.dump(data, f)


      def load_json(path):
          with open(path, encoding="utf-8") as f:
              return json.load(f)


      def load_jsonc(path):
          with open(path, encoding="utf-8") as f:
              return json5.load(f)


      def dump_json(data, path):
          with open(path, "w", encoding="utf-8") as f:
              json.dump(data, f, indent=2, sort_keys=False)
              f.write("\n")


      def load_yaml(path):
          with open(path, encoding="utf-8") as f:
              return yaml.safe_load(f) or {}


      def dump_yaml(data, path):
          with open(path, "w", encoding="utf-8") as f:
              yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)


      LOADERS = {
          "toml": load_toml,
          "json": load_json,
          "jsonc": load_jsonc,
          "yaml": load_yaml,
      }
      DUMPERS = {
          "toml": dump_toml,
          "json": dump_json,
          "jsonc": dump_json,
          "yaml": dump_yaml,
      }


      def deep_merge(base, overlay):
          """Merge `overlay` (Nix-declared, SSOT) into `base` (live, app-owned).

          Declared keys always win. Keys the base has but overlay does not are
          preserved untouched, at any depth, so app-written state (trust
          tables, UI toggles, etc.) survives a switch.
          """
          if not isinstance(base, dict) or not isinstance(overlay, dict):
              return overlay
          result = dict(base)
          for key, value in overlay.items():
              if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                  result[key] = deep_merge(result[key], value)
              else:
                  result[key] = value
          return result


      def find_app_owned_paths(live, declared, prefix=""):
          """Yield dotted key paths present in `live` but absent from `declared`.

          These are exactly the keys agents-diff should surface as "this repo
          doesn't own this yet" promotion candidates: nothing under a path
          this function yields will be touched by deep_merge.
          """
          if not isinstance(live, dict):
              return
          if not isinstance(declared, dict):
              declared = {}
          for key, value in live.items():
              path = f"{prefix}{key}"
              if key not in declared:
                  yield path
              elif isinstance(value, dict) and isinstance(declared[key], dict):
                  yield from find_app_owned_paths(value, declared[key], prefix=f"{path}.")


      def check(args):
          """Print what `merge_class_a_file` would do, without touching disk."""
          load = LOADERS[args.format]
          dump = DUMPERS[args.format]
          label = args.label or args.live

          declared = load(args.declared)
          try:
              live = load(args.live)
          except FileNotFoundError:
              live = {}

          merged = deep_merge(live, declared)

          if merged == live:
              print(f"[{label}] no changes on next switch")
          else:
              live_path = merged_path = None
              try:
                  fd, live_path = tempfile.mkstemp(suffix=f".{args.format}")
                  os.close(fd)
                  fd, merged_path = tempfile.mkstemp(suffix=f".{args.format}")
                  os.close(fd)
                  dump(live, live_path)
                  dump(merged, merged_path)
                  with open(live_path, encoding="utf-8") as f:
                      live_lines = f.readlines()
                  with open(merged_path, encoding="utf-8") as f:
                      merged_lines = f.readlines()
              finally:
                  for p in (live_path, merged_path):
                      if p and os.path.exists(p):
                          os.unlink(p)
              print(f"[{label}] will change on next switch:")
              sys.stdout.writelines(
                  difflib.unified_diff(
                      live_lines,
                      merged_lines,
                      fromfile=f"{label} (live now)",
                      tofile=f"{label} (after next switch)",
                  )
              )

          app_owned = sorted(find_app_owned_paths(live, declared))
          if app_owned:
              print(f"[{label}] app-owned keys not declared in Nix (promotion candidates):")
              for path in app_owned:
                  print(f"  {path}")


      def main():
          parser = argparse.ArgumentParser()
          parser.add_argument("--format", required=True, choices=sorted(LOADERS))
          parser.add_argument("--check", action="store_true", help="Print a diff instead of writing OUT")
          parser.add_argument("--label", default="", help="Used in --check output only")
          parser.add_argument("declared")
          parser.add_argument("live")
          parser.add_argument("out", nargs="?")
          args = parser.parse_args()

          if args.check:
              check(args)
              return

          if args.out is None:
              parser.error("OUT is required unless --check is given")

          load = LOADERS[args.format]
          dump = DUMPERS[args.format]

          declared = load(args.declared)

          try:
              live = load(args.live)
          except FileNotFoundError:
              live = {}

          merged = deep_merge(live, declared)
          dump(merged, args.out)

          # Round-trip validation: if this raises, the caller must not swap
          # `out` in over the live file.
          load(args.out)


      if __name__ == "__main__":
          main()
    '';

  formatsFor = format:
    if format == "toml"
    then pkgs.formats.toml {}
    else if format == "json" || format == "jsonc"
    then pkgs.formats.json {}
    else if format == "yaml"
    then pkgs.formats.yaml {}
    else throw "nix/agents/lib.nix: unsupported format '${format}' (expected toml, json, jsonc, or yaml)";

  # Shared by mkMergeActivation and mkDiffCommand so both always agree on
  # what "the declared side" means for a given class A entry.
  #
  # - value: a Nix attrset of *only* the keys this repo wants to own,
  #   serialized to `format` via pkgs.formats.*. Mutually exclusive with
  #   declaredFile.
  # - declaredFile: an already-built file (e.g. a derivation output) to use
  #   as the declared side directly, for cases where the declaration isn't
  #   naturally a Nix attrset (e.g. generated by a non-Nix build step). Must
  #   already be in `format`. Mutually exclusive with value.
  resolveDeclaredFile = {
    format,
    value ? null,
    declaredFile ? null,
    label,
  }:
    if declaredFile != null
    then declaredFile
    else if value != null
    then (formatsFor format).generate "${label}-declared.${format}" value
    else throw "nix/agents/lib.nix: ${label} must set either 'value' or 'declaredFile'";
in {
  inherit mergeConfigScript;

  # mkMergeActivation renders a self-contained bash snippet for use inside a
  # `home.activation.<name> = lib.hm.dag.entryAfter [...] (...)` entry.
  #
  # - format: "toml" | "json" | "jsonc" | "yaml"
  # - value / declaredFile: see resolveDeclaredFile above.
  # - dest: absolute live path, e.g. "$HOME/.codex/config.toml"
  # - backupDir: absolute directory to copy the pre-merge file into
  # - label: short identifier used in log lines and backup filenames
  #
  # Caveat: the merge is dict-only. A list-valued key is replaced wholesale
  # by the declared value, it is not concatenated/deduped element-by-element.
  # If an app is observed appending to a class A list field at runtime (e.g.
  # an approvals list), that field is not a good fit for this merge model —
  # leave it out of the declared value (class C) instead.
  mkMergeActivation = {
    format,
    value ? null,
    declaredFile ? null,
    dest,
    backupDir,
    label,
  }: let
    resolvedDeclaredFile = resolveDeclaredFile {inherit format value declaredFile label;};
  in ''
    merge_class_a_file() {
      local label="$1" format="$2" declared="$3" dest="$4" backup_dir="$5"

      mkdir -p "$(dirname "$dest")"
      mkdir -p "$backup_dir"

      local tmp tmp_err
      tmp="$(mktemp "$dest.merge.XXXXXX")"
      tmp_err="$(mktemp)"

      if ! ${mergeConfigScript} --format "$format" "$declared" "$dest" "$tmp" 2>"$tmp_err"; then
        echo "merge_class_a_file: failed to merge $label ($dest), leaving it untouched" >&2
        cat "$tmp_err" >&2
        rm -f "$tmp" "$tmp_err"
        exit 1
      fi
      rm -f "$tmp_err"

      if [ -f "$dest" ] && ${pkgs.diffutils}/bin/cmp -s "$tmp" "$dest"; then
        rm -f "$tmp"
        return 0
      fi

      if [ -f "$dest" ]; then
        cp -a "$dest" "$backup_dir/$(basename "$dest").$(date +%Y%m%d%H%M%S)"
      fi

      mv "$tmp" "$dest"
      chmod 0644 "$dest"
      echo "merge_class_a_file: updated $label ($dest)"
    }

    merge_class_a_file "${label}" "${format}" "${resolvedDeclaredFile}" "${dest}" "${backupDir}"
  '';

  # mkDiffCommand renders a bash snippet that prints, for one class A entry,
  # what the next `switch` would change plus which live keys are app-owned
  # (declared nowhere in Nix, so never touched by the merge). Used to build
  # the shared `agents-diff` script (see nix/agents/default.nix); never
  # writes to `dest`. Takes the same arguments as mkMergeActivation, minus
  # backupDir.
  mkDiffCommand = {
    format,
    value ? null,
    declaredFile ? null,
    dest,
    label,
  }: let
    resolvedDeclaredFile = resolveDeclaredFile {inherit format value declaredFile label;};
  in ''
    ${mergeConfigScript} --check --format "${format}" --label "${label}" "${resolvedDeclaredFile}" "${dest}"
  '';
}
