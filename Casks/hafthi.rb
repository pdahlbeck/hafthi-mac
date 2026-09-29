cask "hafthi" do
  version "0.1.0-beta.28"
  sha256 "5bb8f1fffd3fe2235932296fbba68dc329d8b566a4a684d3919fc80bbeefc9b0"

  url "https://github.com/pdahlbeck/hafthi-mac/releases/download/v#{version}/Hafthi-#{version}-macOS-arm64.zip"
  name "Hafþi"
  desc "Native terminal emulator for macOS"
  homepage "https://github.com/pdahlbeck/hafthi-mac"

  depends_on macos: :ventura
  depends_on arch: :arm64

  app "Hafþi.app"
end
