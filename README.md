# capsule-corp

入力デバイス設定の monorepo。

- [Cyboard Imprint](https://cyboard.digital/products/imprint) の ZMK 設定（ルート = ZMK user-config）
- [skhd.zig](https://github.com/jackielii/skhd.zig) の設定（`host/skhd/`）

ZMK が送る chord（親指ホールドで「右 4 修飾子のうち 3 つ」+ base key）を
skhd 側で受けて処理する。両者の対応は `host/skhd/render.sh` がブリッジする。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `config/imprint.keymap` | レイヤー定義（`#include` で各 dtsi を合成） |
| `config/keymap_defines.h` | 集約ヘッダ → `layers.h` / `keypos.h` / `behaviors_gen.h` |
| `config/{imprint_behaviors,letter_morphs,arrow_behaviors,macros,eiji_macros,combos}.dtsi` | behavior / macro / combo |
| `keymap_drawer.config.yaml` | keymap-drawer 表示設定 |
| `host/skhd/render.sh` | ZMK 論理定義 → skhd kVK へ変換し `~/.config/skhd/skhdrc` を生成 |
| `host/skhd/skhdrc.tmpl` | skhd 設定テンプレート（`${VAR}` を render.sh が置換） |

## firmware ビルド

### GitHub Actions（推奨）

push すると `.github/workflows/build.yml` が `.uf2` を生成。
Actions の artifact からダウンロードして書き込む。ローカル環境構築不要。

### ローカルビルド（vanilla west）

前提: Zephyr toolchain（[zmk.dev / Toolchain Setup](https://zmk.dev/docs/development/setup) 参照）。
このリポジトリの `config/west.yml` を manifest にする。**clone 内で完結**し、
west 生成物（`zmk/` `zephyr/` `modules/` `.west/` `build/`）は gitignore 済で
いつ消しても `west update` で再生成できる（canonical は追跡ファイルのみ）。

```sh
# このリポジトリの clone 直下で
west init -l config
west update
west zephyr-export

# build.yaml: board=assimilator-bt, shield=imprint_left / imprint_right
west build -s zmk/app -d build/left  -b assimilator-bt -- -DSHIELD=imprint_left  -DZMK_CONFIG="$PWD/config"
west build -s zmk/app -d build/right -b assimilator-bt -- -DSHIELD=imprint_right -DZMK_CONFIG="$PWD/config"
# → build/{left,right}/zephyr/zmk.uf2
```

ビルド環境をリセットしたい場合は `rm -rf .west zmk zephyr modules build` 後に
`west init -l config && west update` で再構築。

## skhd セットアップ

このリポジトリを clone した任意の場所から:

```sh
host/skhd/render.sh   # ~/.config/skhd/skhdrc を生成・検証・reload
```

clone 位置に依存しない。生成物（skhdrc）はリポジトリに残らず
`~/.config/skhd/` へデプロイされる。壊れた設定は稼働中の skhdrc を上書きしない。

## Keymap

![keymap](keymap-drawer/imprint.svg)
