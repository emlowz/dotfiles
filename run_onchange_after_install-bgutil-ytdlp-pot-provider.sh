#!/bin/sh

set -eu

provider_version="1.3.2"
provider_source_sha256="3545ac7ffc0869498755cb3b4760a72fa2f176689d0890a6f5b898d163012ba2"
provider_plugin_sha256="d51cf1c54e487137df749bd8778cceaa62304e6c5054c955b95f028f93ad6d57"

data_root="${XDG_DATA_HOME:-"$HOME/.local/share"}"
config_root="${XDG_CONFIG_HOME:-"$HOME/.config"}"
provider_dir="$data_root/bgutil-ytdlp-pot-provider"
plugin_dir="$config_root/yt-dlp/plugins"
plugin_file="$plugin_dir/bgutil-ytdlp-pot-provider.zip"

for required_command in curl deno install mktemp shasum tar; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "bgutil yt-dlp setup: missing required command: $required_command" >&2
    exit 1
  fi
done

setup_tmp="$(mktemp -d "${TMPDIR:-/tmp}/bgutil-ytdlp.XXXXXX")"
cleanup() {
  rm -rf -- "$setup_tmp"
}
trap cleanup EXIT HUP INT TERM

source_archive="$setup_tmp/provider-source.tar.gz"
plugin_archive="$setup_tmp/bgutil-ytdlp-pot-provider.zip"
source_url="https://github.com/Brainicism/bgutil-ytdlp-pot-provider/archive/refs/tags/$provider_version.tar.gz"
plugin_url="https://github.com/Brainicism/bgutil-ytdlp-pot-provider/releases/download/$provider_version/bgutil-ytdlp-pot-provider.zip"

curl --fail --location --retry 3 --silent --show-error \
  "$source_url" --output "$source_archive"
curl --fail --location --retry 3 --silent --show-error \
  "$plugin_url" --output "$plugin_archive"

printf '%s  %s\n' "$provider_source_sha256" "$source_archive" \
  | shasum -a 256 --check
printf '%s  %s\n' "$provider_plugin_sha256" "$plugin_archive" \
  | shasum -a 256 --check

tar -xzf "$source_archive" -C "$setup_tmp"
staged_provider="$setup_tmp/bgutil-ytdlp-pot-provider-$provider_version"

(
  cd "$staged_provider/server"
  deno install --allow-scripts=npm:canvas --frozen
)

verification_cache="$setup_tmp/cache"
mkdir -p "$verification_cache"
detected_version="$(
  cd "$staged_provider/server/node_modules"
  XDG_CACHE_HOME="$verification_cache" deno run \
    --allow-env \
    --allow-net \
    --allow-ffi=. \
    --allow-read=".,$verification_cache" \
    --allow-write="$verification_cache" \
    ../src/generate_once.ts --version
)"
if [ "$detected_version" != "$provider_version" ]; then
  echo "bgutil yt-dlp setup: expected provider $provider_version, got $detected_version" >&2
  exit 1
fi

mkdir -p "$data_root" "$plugin_dir"

provider_backup=""
if [ -e "$provider_dir" ]; then
  provider_backup="$provider_dir.backup.$$"
  mv "$provider_dir" "$provider_backup"
fi

if ! mv "$staged_provider" "$provider_dir"; then
  if [ -n "$provider_backup" ]; then
    mv "$provider_backup" "$provider_dir"
  fi
  exit 1
fi

install -m 0644 "$plugin_archive" "$plugin_file"

if [ -n "$provider_backup" ]; then
  rm -rf -- "$provider_backup"
fi

echo "Installed bgutil yt-dlp PO-token provider $provider_version"
