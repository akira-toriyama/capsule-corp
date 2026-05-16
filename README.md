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

### Docker ローカルビルド（ツールチェーン不要）

Zephyr toolchain を入れずに Docker でビルドする。`scripts/build-local.sh` が
ZMK 公式イメージ内で west ワークスペースを構築する。

```sh
./scripts/build-local.sh              # build.yaml の全ターゲット
./scripts/build-local.sh imprint_left # 指定シールドのみ
./scripts/build-local.sh --update     # 依存を最新化（west update 強制）
./scripts/build-local.sh --clean      # ワークスペース破棄
# → firmware/{imprint_left,imprint_right}.uf2
```

- 依存（`zmk/` `zephyr/` `modules/`）は `~/.cache/zmk-capsule-corp` に永続化。
  2 回目以降は `west update` を自動スキップしビルドのみ（数分）。
- 実リポジトリを汚さないようキャッシュ領域へ複製してビルド。生成物は
  `firmware/`（gitignore 済）。
- 要 Docker（未起動なら `open -a Docker`）。`ZMK_WS` / `ZMK_IMAGE` で上書き可。

## skhd セットアップ

このリポジトリを clone した任意の場所から:

```sh
host/skhd/render.sh   # ~/.config/skhd/skhdrc を生成・検証・reload
```

clone 位置に依存しない。生成物（skhdrc）はリポジトリに残らず
`~/.config/skhd/` へデプロイされる。壊れた設定は稼働中の skhdrc を上書きしない。

## Keymap

![keymap](keymap-drawer/imprint.svg)
