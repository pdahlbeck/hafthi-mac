cask "hafthi" do
  version "0.1.0-beta.27"
  sha256 "52d9f6f0310f4114ffd3f835592e8d3451a8c07adc99e146b7382ecf3ce66e09"

  url "https://github.com/pdahlbeck/hafthi-mac/releases/download/v#{version}/Hafthi-#{version}-macOS-arm64.zip"
  name "Hafþi"
  desc "Native terminal emulator for macOS"
  homepage "https://github.com/pdahlbeck/hafthi-mac"

  depends_on macos: :ventura
  depends_on arch: :arm64

  app "Hafþi.app"
end
