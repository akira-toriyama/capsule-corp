# cyboard-imprint-zmk

[Cyboard Imprint](https://docs.cyboard.digital/)（左手トラックボール付きスプリット, board: `assimilator-bt`）の
ZMK 設定。日本語入力（macOS の かな / 英数）と記号入力を主眼に組んだ独自キーマップ。

## Keymap

![keymap](keymap-drawer/imprint.svg)

SVG は push 時に [`.github/workflows/draw-keymap.yml`](.github/workflows/draw-keymap.yml) が
[keymap-drawer](https://github.com/caksoylar/keymap-drawer) で自動生成・コミットします。

## レイヤー構成

| layer | display | 役割 |
|---|---|---|
| `DEFAULT` | Base | アルファベット + 親指クラスタ |
| `NUMBER` / `SYMBOL1` / `SYMBOL2` / `FUNCTION` | Num / Sym1 / Sym2 / Fn | 左親指 `MO_LAYER` で momentary |
| `LEFT/RIGHT/UP/DOWN_ARROW` | ← → ↑ ↓ | `ar_*` の hold-tap が一時的に潜るナビ層 (HOME/END/PgUp/PgDn) |
| `T_LL` / `T_LM` / `T_RM` / `T_RR` | LL/LM/RM/RR | 右上親指 chord 層（後述） |

## 主な仕組み

- **IME 連動 letter morph (`al_a`〜`al_z`)** — tap=素のアルファベット / Shift=英数へ切替えてから大文字。
  日本語入力中でも Shift 始動の語が正しく英字になる。
- **`en_*` マクロ** — 「英数へ切替 → 数字/記号」を 1 アクションで送出。IME 状態に依らず記号を確定入力。
  表示文字は `config/eiji_macros.dtsi` の `disp:[X]` が唯一のソースで、keymap-drawer 用の
  `raw_binding_map` は [`scripts/gen_eiji_drawer_map.py`](scripts/gen_eiji_drawer_map.py) が生成
  （[`verify-eiji-sync.yml`](.github/workflows/verify-eiji-sync.yml) が同期を検証）。
- **combo** — 左親指 2 キー＝かな / 右親指 2 キー＝英数（hold-tap で hold=修飾子）。
- **親指上段 (TU) chord** — `T_*_LAYER` を起動しつつ、各層が「右 4 修飾子のうち 3 つ」を
  base key に付けて送出（欠ける 1 つが層ごとに異なり OS 側で識別可能）。
- **親指下段 (TD)** — mod-tap：Shift/⏎・Cmd/⌫・Alt/⎋・Ctrl/␣。
- **左トラックボール** — `input-processors` で常時スクロール化。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `config/imprint.keymap` | レイヤー定義（`#include` で各 dtsi を合成） |
| `config/keymap_defines.h` | 集約ヘッダ → `layers.h` / `keypos.h` / `behaviors_gen.h` |
| `config/{imprint_behaviors,letter_morphs,arrow_behaviors,macros,eiji_macros,combos}.dtsi` | behavior / macro / combo |
| `keymap_drawer.config.yaml` | keymap-drawer 表示設定 |

## Build / Flash

```bash
# zmk-workspace/ で（nix devshell が just / west を提供）
just build imprint_left      # imprint_right も同様

# 対象の半身をブートローダーモードにして UF2 をコピー
cp ~/Documents/zmk/zmk-workspace/firmware/imprint_left-assimilator-bt.uf2 '/Volumes/NO NAME/'
```

> ZMK は upstream（`zmkfirmware/zmk@main`）を参照。以前は macOS Mission Control
> 誤発火回避の mod-morph patch を fork で当てていたが、emacs 風ショートカット廃止に
> 伴い不要となり撤去した（実機検証済み）。
