#!/usr/bin/env bash
#
# skhd キー調査（probe）。ZMK が送るチョードを押すと、それが skhdrc.tmpl の
# どの `${MODS} - ${X_KEY}` に対応するかをコンソールへライブ出力する。
#
#   ./scripts/probe-skhd.sh [秒]      # 既定 15 秒 / 上限 60 秒
#
# 安全設計（操作不能を絶対に起こさない）:
#   - 生 CGEventTap は使わない。skhd の hotkey デーモンのみで、捕捉するのは
#     render.sh 定義の 4 修飾セット × X_ キーの「特殊チョードだけ」。通常の
#     タイピング・マウスは一切奪わない。
#   - 待機は必ず時間制限（自前 sleep+kill）。`timeout` の有無に依存しない。
#   - trap EXIT/INT/TERM で「元の skhdrc を無条件復元 → skhd reload」。
#   - 多重の安全網によりロックアウト不能。
#
# 単一ソースは host/skhd/render.sh（修飾セット名/値・X_ キー名/値）。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER="$REPO/host/skhd/render.sh"
OUT="$HOME/.config/skhd/skhdrc"

SEC="${1:-15}"
case "$SEC" in *[!0-9]* | "") SEC=15 ;; esac
[ "$SEC" -lt 1 ] && SEC=1
[ "$SEC" -gt 60 ] && SEC=60

command -v skhd >/dev/null 2>&1 || {
  echo "skhd が見つかりません。中止します。" >&2
  exit 1
}

LOG="$(mktemp)"
PROBE="$(mktemp)"
BAK="$(mktemp)"
TPID=""
_restored=0

_reload() {
  skhd --reload 2>/dev/null ||
    skhd --restart-service 2>/dev/null ||
    skhd --start-service 2>/dev/null || true
}

restore() {
  [ "$_restored" -eq 1 ] && return 0
  _restored=1
  if [ -n "$TPID" ]; then kill "$TPID" 2>/dev/null || true; fi
  if [ -s "$BAK" ]; then
    cp "$BAK" "$OUT"
  else
    rm -f "$OUT"
  fi
  _reload
  rm -f "$LOG" "$PROBE" "$BAK"
  echo
  echo "元の skhdrc に復元し reload しました。"
}
trap restore EXIT INT TERM

# --- render.sh から修飾セットと X_ キーを取得（単一ソース） ---
mods_src="$(grep -E '^export (ULTRA_LL|MIRACLE_LM|MEGA_RM|WONDER_RR)=' "$RENDER" || true)"
keys_src="$(grep -E '^export X_[A-Z0-9]+=' "$RENDER" || true)"
if [ -z "$mods_src" ] || [ -z "$keys_src" ]; then
  echo "render.sh から変数を取得できません。中止します。" >&2
  exit 1
fi

# --- probe skhdrc を生成（特殊チョードのみ。ログへ「変数名表記」を出力） ---
: >"$PROBE"
echo "# AUTO probe (scripts/probe-skhd.sh) — 一時設定。終了時に自動復元。" >>"$PROBE"
while IFS= read -r ml; do
  mn="${ml#export }"
  mn="${mn%%=*}"
  mrest="${ml#*=\"}"
  mv="${mrest%%\"*}"
  while IFS= read -r kl; do
    kn="${kl#export }"
    kn="${kn%%=*}"
    krest="${kl#*=}"
    kv="${krest%%[[:space:]#]*}"
    line="$mv - $kv : printf '%s\\n' '\${$mn} - \${$kn}' >> \"$LOG\""
    printf '%s\n' "$line" >>"$PROBE"
  done <<<"$keys_src"
done <<<"$mods_src"

# --- 反映 → 時間制限つき待機 → 復元（trap） ---
if [ -f "$OUT" ]; then cp "$OUT" "$BAK"; fi
mkdir -p "$(dirname "$OUT")"
cp "$PROBE" "$OUT"
_reload
: >"$LOG"

echo "▶ ${SEC} 秒間、ZMK のチョードを押してください（自動終了・自動復元）。"
echo "  押下が下に \${ULTRA_LL} - \${X_A} 形式で出ます:"
echo "  ----------------------------------------"
tail -n +1 -f "$LOG" &
TPID=$!
sleep "$SEC"
# restore は trap EXIT で実行される
