#!/usr/bin/env python3
"""Write the Hafþi Cask from the exact release ZIP and its SHA-256."""

import hashlib
from pathlib import Path
import re
import sys


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: update-cask.py VERSION ZIP")

    version, archive_name = sys.argv[1:]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-beta\.[0-9]+)?", version):
        raise SystemExit(f"invalid release version: {version}")

    expected_name = f"Hafthi-{version}-macOS-arm64.zip"
    archive = Path(archive_name)
    if archive.name != expected_name or not archive.is_file():
        raise SystemExit(f"expected release archive: {expected_name}")

    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    checksum = digest.hexdigest()
    cask = f'''cask "hafthi" do
  version "{version}"
  sha256 "{checksum}"

  url "https://github.com/pdahlbeck/hafthi-mac/releases/download/v#{{version}}/Hafthi-#{{version}}-macOS-arm64.zip"
  name "Hafþi"
  desc "Native terminal emulator for macOS"
  homepage "https://github.com/pdahlbeck/hafthi-mac"

  depends_on macos: :ventura
  depends_on arch: :arm64

  app "Hafþi.app"
end
'''
    destination = Path("Casks/hafthi.rb")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(cask, encoding="utf-8")
    print(f"Updated {destination} for {version} ({checksum})")


if __name__ == "__main__":
    main()
