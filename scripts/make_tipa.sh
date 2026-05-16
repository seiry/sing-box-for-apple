#!/bin/bash
# Build a TrollStore-compatible TIPA from a built SFI.app
# Usage: ./make_tipa.sh <path-to-SFI.app> <output.tipa>

set -euo pipefail

APP_PATH="${1:?Usage: $0 <SFI.app> <output.tipa>}"
OUT_TIPA="${2:?Usage: $0 <SFI.app> <output.tipa>}"

if [[ ! -d "$APP_PATH" ]]; then
    echo "App not found: $APP_PATH" >&2
    exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$WORKDIR/Payload"
cp -R "$APP_PATH" "$WORKDIR/Payload/"
APP_NAME="$(basename "$APP_PATH")"
APP_IN_PAYLOAD="$WORKDIR/Payload/$APP_NAME"

echo "==> Stripping existing signatures and code-signing metadata"
find "$APP_IN_PAYLOAD" -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
find "$APP_IN_PAYLOAD" -name "embedded.mobileprovision" -delete 2>/dev/null || true

echo "==> Fakesigning frameworks with ldid"
if [[ -d "$APP_IN_PAYLOAD/Frameworks" ]]; then
    for fw in "$APP_IN_PAYLOAD"/Frameworks/*.framework "$APP_IN_PAYLOAD"/Frameworks/*.dylib; do
        [[ -e "$fw" ]] || continue
        if [[ -d "$fw" ]]; then
            fwname="$(basename "$fw" .framework)"
            binary="$fw/$fwname"
        else
            binary="$fw"
        fi
        if [[ -f "$binary" ]]; then
            echo "    - $binary"
            ldid -S "$binary"
        fi
    done
fi

echo "==> Fakesigning extensions (PlugIns/ and Extensions/)"
for plugins_dir in "$APP_IN_PAYLOAD/PlugIns" "$APP_IN_PAYLOAD/Extensions"; do
    [[ -d "$plugins_dir" ]] || continue
    for ext in "$plugins_dir"/*.appex; do
        [[ -d "$ext" ]] || continue
        extname="$(basename "$ext" .appex)"
        ent=""
        case "$extname" in
            Extension)
                ent="$REPO_ROOT/Extension/Extension.entitlements"
                ;;
            FileProviderExtension)
                ent="$REPO_ROOT/FileProviderExtension/FileProviderExtension.entitlements"
                ;;
            WidgetExtension)
                ent="$REPO_ROOT/WidgetExtension/WidgetExtension.entitlements"
                ;;
            IntentsExtension)
                ent="$REPO_ROOT/IntentsExtension/IntentsExtension.entitlements"
                ;;
        esac

        # Read CFBundleExecutable from extension's Info.plist
        exec_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$ext/Info.plist" 2>/dev/null || echo "$extname")"
        binary="$ext/$exec_name"

        if [[ -n "$ent" && -f "$ent" ]]; then
            echo "    - $binary (with $(basename "$ent"))"
            ldid -S"$ent" "$binary"
        else
            echo "    - $binary (ad-hoc)"
            ldid -S "$binary"
        fi

        # Sign any frameworks bundled inside the extension
        if [[ -d "$ext/Frameworks" ]]; then
            for sub in "$ext"/Frameworks/*.framework "$ext"/Frameworks/*.dylib; do
                [[ -e "$sub" ]] || continue
                if [[ -d "$sub" ]]; then
                    sname="$(basename "$sub" .framework)"
                    sbin="$sub/$sname"
                else
                    sbin="$sub"
                fi
                [[ -f "$sbin" ]] && ldid -S "$sbin"
            done
        fi
    done
done

echo "==> Fakesigning main app binary"
MAIN_EXEC="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_IN_PAYLOAD/Info.plist")"
ldid -S"$REPO_ROOT/SFI/SFI.entitlements" "$APP_IN_PAYLOAD/$MAIN_EXEC"

echo "==> Creating TIPA archive"
OUT_ABS="$(cd "$(dirname "$OUT_TIPA")" && pwd)/$(basename "$OUT_TIPA")"
rm -f "$OUT_ABS"
(cd "$WORKDIR" && zip -qry "$OUT_ABS" Payload)
OUT_TIPA="$OUT_ABS"

echo "==> Done: $OUT_TIPA"
ls -lh "$OUT_TIPA"
