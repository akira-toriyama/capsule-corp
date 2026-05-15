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

push 時に GitHub Actions（`.github/workflows/build.yml`）が `.uf2` を生成する。

### ローカルビルド

ビルドハーネスに [`kot149/zmk-workspace`](https://github.com/kot149/zmk-workspace)
（nix + just + flash）を使う。**workspace は使い捨て可能**で、canonical は
このリポジトリのみ。消しても以下で完全再構築できる:

```sh
git clone https://github.com/kot149/zmk-workspace
cd zmk-workspace
# nix + direnv セットアップは kot149/zmk-workspace README 参照

cd config
git clone https://github.com/akira-toriyama/capsule-corp
cd ..

just init config/capsule-corp   # .west/config に config パスを記録
just build                      # firmware ビルド
just flash -r                   # ビルド + フラッシュ
```

## skhd セットアップ

このリポジトリを clone した任意の場所から:

```sh
host/skhd/render.sh   # ~/.config/skhd/skhdrc を生成・検証・reload
```

clone 位置に依存しない。生成物（skhdrc）はリポジトリに残らず
`~/.config/skhd/` へデプロイされる。壊れた設定は稼働中の skhdrc を上書きしない。

## Keymap

![keymap](keymap-drawer/imprint.svg)
