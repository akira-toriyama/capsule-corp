#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# ---- ZMKで定義したベースキー ----
export X_Q=0x0C
export X_W=0x0D
export X_E=0x0E
export X_R=0x0F
export X_T=0x11
export X_A=0x00
export X_S=0x01
export X_D=0x02
export X_F=0x03
export X_G=0x05
export X_Z=0x06
export X_X=0x07
export X_C=0x08
export X_V=0x09
export X_B=0x0B
export X_Y=0x10
export X_U=0x20
export X_I=0x22
export X_O=0x1F
export X_P=0x23
export X_H=0x04
export X_J=0x26
export X_K=0x28
export X_L=0x25
export X_N=0x2D
export X_M=0x2E
export X_1=0x53
export X_2=0x54
export X_3=0x55
export X_4=0x56

# ---- ZMKで定義したmodifier セット ----
export MODS_LL="rctrl + ralt + rshift"      # LL: RALT+RSHIFT+RCTRL (RGUI なし)
export MODS_LM="rctrl + rcmd + rshift"      # LM: RGUI+RSHIFT+RCTRL (RALT なし)
export MODS_RM="rctrl + rcmd + ralt"        # RM: RGUI+RALT+RCTRL  (RSHIFT なし)
export MODS_RR="rcmd + ralt + rshift"       # RR: RGUI+RALT+RSHIFT (RCTRL なし)


# ---- macOS 側の出力で使うキーコード ----
export BRACKET_OPEN=0x21   # [
export BRACKET_CLOSE=0x1E  # ]


# ---- skhdrc 生成 → 検証 → デプロイ ----
# source (skhdrc.tmpl) は repo 内、生成物は ~/.config/skhd/skhdrc へ配置。
# 一旦 temp に生成して検証し、OK の時だけデプロイ先へ移動する
# (壊れた設定が稼働中の skhdrc を上書きしない)。
OUT="$HOME/.config/skhd/skhdrc"

# envsubst は指定変数のみ置換 (jq フィルタの $array 等を守るため)
VARS='${X_Q} ${X_W} ${X_E} ${X_R} ${X_T} ${X_A} ${X_S} ${X_D} ${X_F} ${X_G} ${X_Z} ${X_X} ${X_C} ${X_V} ${X_B}'
VARS="$VARS "'${X_Y} ${X_U} ${X_I} ${X_O} ${X_P} ${X_H} ${X_J} ${X_K} ${X_L} ${X_N} ${X_M} ${X_1} ${X_2} ${X_3} ${X_4}'
VARS="$VARS "'${BRACKET_OPEN} ${BRACKET_CLOSE} ${MODS_LL} ${MODS_LM} ${MODS_RM} ${MODS_RR}'

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
envsubst "$VARS" < skhdrc.tmpl > "$tmp"

errors=$(timeout 1 skhd -V -c "$tmp" 2>&1 | grep "error" || true)
if [ -n "$errors" ]; then
    echo "skhdrc has parse errors, NOT deploying:"
    echo "$errors"
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
mv "$tmp" "$OUT"
trap - EXIT
skhd --reload 2>/dev/null || skhd --restart-service
echo "skhdrc deployed to $OUT and reloaded"
