#!/usr/bin/env bash
#
# skhd 設定の生成・反映エントリポイント。
#
#   ./scripts/render-skhd.sh
#
# 実装は持たない。skhd アセット（skhdrc.tmpl 等）と同居させるため、本体は
# host/skhd/render.sh に置き、ここはそれを実行するだけの薄いラッパ
# （scripts/ にエントリポイントを統一する目的）。
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$REPO/host/skhd/render.sh" "$@"
