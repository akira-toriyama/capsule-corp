#!/usr/bin/env bash
#
# ZMK ファームウェアを Docker でローカルビルドする。
#
#   ./scripts/build-local.sh                 # build.yaml の全ターゲットをビルド
#   ./scripts/build-local.sh imprint_left    # 指定シールドのみビルド
#   ./scripts/build-local.sh --update        # west update を強制（依存を最新化）
#   ./scripts/build-local.sh --clean         # ワークスペースを破棄して終了
#
# 仕組み:
#   - west の clone 先（zmk/zephyr/modules, 約数 GB）がネットワークボリューム上の
#     実リポジトリを汚さないよう、$ZMK_WS（既定 ~/.cache/zmk-capsule-corp）に
#     リポジトリを複製してビルドする。依存はそこに永続化され、2 回目以降は
#     west update を省略するため高速。
#   - マニフェストは config/west.yml にあるため、リポジトリルートを topdir に
#     して `west init -l config` する（ZMK GitHub Actions と同じ前提）。
#   - `west zephyr-export` の登録はコンテナ HOME に書かれ --rm で消えるので、
#     ビルドコンテナ内で毎回実行する。
#
# 生成物: ./firmware/<shield>.uf2（.gitignore 済み）
#
# 環境変数で上書き可:
#   ZMK_WS     ワークスペース置き場       (既定: ~/.cache/zmk-capsule-corp)
#   ZMK_IMAGE  ビルドイメージ             (既定: zmkfirmware/zmk-build-arm:stable)
#
set -euo pipefail

# --- リポジトリルートへ移動（どこから呼んでも動く） -----------------------
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

WS="${ZMK_WS:-$HOME/.cache/zmk-capsule-corp}"
IMAGE="${ZMK_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
CFG="$WS/cfgrepo"          # リポジトリ複製 = west topdir
FORCE_UPDATE=0

# --- 引数処理 -------------------------------------------------------------
SHIELDS=()
for arg in "$@"; do
  case "$arg" in
    --clean)  echo "ワークスペースを削除: $WS"; rm -rf "$WS"; exit 0 ;;
    --update) FORCE_UPDATE=1 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "不明なオプション: $arg" >&2; exit 2 ;;
    *)  SHIELDS+=("$arg") ;;
  esac
done

# 引数指定が無ければ build.yaml の include から board/shield を抽出。
# 形式:  - board: <b>
#          shield: <s>
if [ ${#SHIELDS[@]} -eq 0 ]; then
  while IFS= read -r line; do SHIELDS+=("$line"); done < <(
    awk '
      /^[[:space:]]*-[[:space:]]*board:/ { sub(/.*board:[[:space:]]*/,""); b=$0 }
      /^[[:space:]]*shield:/             { sub(/.*shield:[[:space:]]*/,""); print b "\t" $0 }
    ' build.yaml
  )
else
  # 引数はシールド名のみ。board は build.yaml の最初の board を使う。
  BOARD="$(awk '/board:/{sub(/.*board:[[:space:]]*/,"");print;exit}' build.yaml)"
  _s=("${SHIELDS[@]}"); SHIELDS=()
  for s in "${_s[@]}"; do SHIELDS+=("$BOARD	$s"); done
fi

if [ ${#SHIELDS[@]} -eq 0 ]; then
  echo "ビルド対象が見つかりません（build.yaml を確認）" >&2; exit 1
fi

# --- 前提チェック ---------------------------------------------------------
if ! docker info >/dev/null 2>&1; then
  echo "Docker デーモンが起動していません。Docker Desktop を起動してください:" >&2
  echo "  open -a Docker" >&2
  exit 1
fi

# --- リポジトリをワークスペースへ同期 -------------------------------------
# west が topdir に clone するツリー（zmk/ zephyr/ modules/ ...）は決して
# 触らない（--delete 無し＋トップレベル限定の除外）。特に cfgrepo/zephyr/ は
# Zephyr RTOS のチェックアウトとリポジトリの zephyr/module.yml が同居するため、
# rsync の管理対象から完全に外す。編集対象（config/ boards/ build.yaml 等）
# のみを上書き同期する。
mkdir -p "$CFG"
rsync -a \
  --exclude '/.git/' --exclude '/.west/' --exclude '/output/' \
  --exclude '/zmk/' --exclude '/zmk-keyboards/' --exclude '/zmk-pmw3610-driver/' \
  --exclude '/modules/' --exclude '/optional/' --exclude '/zephyr/' \
  --exclude '/build/' \
  "$REPO"/ "$CFG"/

# zephyr/ は同期対象外なので、board_root モジュール宣言だけ明示的に配置する
# （単一ファイルのコピーは Zephyr RTOS ツリーを壊さない）。
if [ -f "$REPO/zephyr/module.yml" ]; then
  mkdir -p "$CFG/zephyr"
  cp "$REPO/zephyr/module.yml" "$CFG/zephyr/module.yml"
fi

# --- west init/update が必要か判定 ----------------------------------------
NEED_UPDATE=0
[ ! -d "$CFG/.west" ]      && NEED_UPDATE=1   # 未初期化
[ ! -d "$CFG/zmk/app" ]    && NEED_UPDATE=1   # 依存欠落
[ "$FORCE_UPDATE" -eq 1 ]  && NEED_UPDATE=1   # --update 指定

# --- ビルド対象を表示 -----------------------------------------------------
echo "=========================================="
echo " ワークスペース : $CFG"
echo " イメージ       : $IMAGE"
echo " west update    : $([ $NEED_UPDATE -eq 1 ] && echo '実行' || echo 'スキップ（キャッシュ利用）')"
echo " ビルド対象:"
for row in "${SHIELDS[@]}"; do
  printf '   - %s / %s\n' "${row%%	*}" "${row##*	}"
done
echo "=========================================="

# --- コンテナ内で実行するスクリプトを生成 ---------------------------------
# SHIELDS を "board:shield board:shield ..." の 1 行にして渡す
TARGETS=""
for row in "${SHIELDS[@]}"; do
  TARGETS+="${row%%	*}:${row##*	} "
done

docker run --rm \
  -v "$CFG:/workspace" \
  -w /workspace \
  -e ZEPHYR_BASE=/workspace/zephyr \
  -e NEED_UPDATE="$NEED_UPDATE" \
  -e TARGETS="$TARGETS" \
  "$IMAGE" bash -c '
set -e
git config --global --add safe.directory "*"  # bind mount の uid 不一致対策(Linux)
if [ "$NEED_UPDATE" -eq 1 ]; then
  echo "=== west init/update ==="
  [ -d .west ] || west init -l config
  west update
fi
west zephyr-export
mkdir -p /workspace/output
for t in $TARGETS; do
  BOARD="${t%%:*}"; SH="${t##*:}"
  echo "=== BUILD $BOARD / $SH ==="
  west build -p -s zmk/app -d "build/$SH" -b "$BOARD" -- \
    -DSHIELD="$SH" -DZMK_CONFIG=/workspace/config
  cp "build/$SH/zephyr/zmk.uf2" "/workspace/output/$SH.uf2"
  echo "=== DONE $SH ==="
done
'

# --- 生成物をリポジトリの firmware/ へ取り出す ----------------------------
mkdir -p "$REPO/firmware"
cp "$CFG"/output/*.uf2 "$REPO/firmware/"

echo
echo "✅ 完了。生成物:"
ls -lh "$REPO/firmware/"*.uf2
