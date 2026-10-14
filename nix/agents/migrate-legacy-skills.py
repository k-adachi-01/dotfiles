"""Preserve legacy Nix skill trees before the marker-based installer runs."""

import os
from pathlib import Path
import re
import sys
import tempfile


LEGACY_SOURCE = re.compile(
    r"/nix/store/[a-z0-9]{32}-agent-skills-source-[a-f0-9]+-safe"
)


def is_legacy_tree(path):
    if path.is_symlink() or not path.is_dir():
        return False
    if os.path.lexists(path / ".agent-skills-managed.json"):
        return False
    entries = list(path.iterdir())
    return bool(entries) and all(
        entry.is_symlink()
        and LEGACY_SOURCE.fullmatch(str(entry.readlink().parent))
        and entry.readlink().name == entry.name
        for entry in entries
    )


def migrate(paths):
    # Identify all candidates before changing any of the live directories.
    candidates = [path for path in paths if is_legacy_tree(path)]
    for path in candidates:
        backup = Path(tempfile.mkdtemp(prefix="skills.legacy-", dir=path.parent))
        path.rename(backup / "skills")
        print(f"agent-skills: preserved legacy tree {path} in {backup / 'skills'}")


if __name__ == "__main__":
    migrate([Path(arg) for arg in sys.argv[1:]])
