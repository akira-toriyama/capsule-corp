# skhd ブリッジ

ZMK が送る「修飾キーの組み合わせ（chord）＋ base key」を macOS 側で
[skhd.zig](https://github.com/jackielii/skhd.zig) が受けて操作に変換する。

- 単一ソース: [`skhdrc.tmpl`](skhdrc.tmpl)（`.define` で共通コマンド、`@ref`
  で参照、`["App" : cmd]` でアプリ別）
- [`render.sh`](render.sh) が変数を `envsubst` で置換 → 検証 →
  `~/.config/skhd/skhdrc` へ反映・reload（検証 NG なら反映しない）
- 更新手順: `skhdrc.tmpl` を編集 → `./render.sh`

## 修飾セット（[`render.sh`](render.sh) で定義）

| 名前 | 構成 | 備考 |
|---|---|---|
| `MODS_LL` | 右 Ctrl + 右 Alt + 右 Shift | RGUI なし（現状の有効バインドはこれ） |
| `MODS_LM` | 右 Ctrl + 右 Cmd + 右 Shift | RAlt なし（予約） |
| `MODS_RM` | 右 Ctrl + 右 Cmd + 右 Alt | RShift なし（予約） |
| `MODS_RR` | 右 Cmd + 右 Alt + 右 Shift | RCtrl なし（予約） |

物理キー（`X_C` 等）は ZMK 側で定義した base key。チョード＝修飾セットを
ホールドしながら base key を打つ。

## ショートカット一覧

`skhdrc.tmpl` の現行バインド（`MODS_LL` ＝ 右 Ctrl+Alt+Shift を併用）:

| チョード | 操作 | Google Chrome | VS Code | 既定 |
|---|---|---|---|---|
| `LL + C` | タブを左へ | `Ctrl+Shift+Tab` | `Cmd+Shift+[` | — |
| `LL + V` | タブを右へ | `Ctrl+Tab` | `Cmd+Shift+]` | — |
| `LL + D` | 前のウィンドウへ | — | — | yabai: 前のウィンドウへフォーカス |
| `LL + F` | 次のウィンドウへ | — | — | yabai: 次のウィンドウへフォーカス |

- タブ操作（C / V）はアプリ判定。未定義アプリでは無反応。
- ウィンドウ移動（D / F）は yabai 連携（同一スペースの非最小化ウィンドウを
  表示順で巡回。`skhdrc.tmpl` の `.define yabai_focus_prev/next`）。

> 一覧は [`skhdrc.tmpl`](skhdrc.tmpl) を正とする手動ドキュメント。バインドを
> 増減したらこの表も更新する。
