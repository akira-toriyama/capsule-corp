# skhd ブリッジ

ZMK が送る「修飾キーの組み合わせ（chord）＋ base key」を macOS 側で
[skhd.zig](https://github.com/jackielii/skhd.zig) が受けて操作に変換する。

- 単一ソース: [`skhdrc.tmpl`](skhdrc.tmpl)（`.define` で共通コマンド、`@ref`
  で参照、`["App" : cmd]` でアプリ別）
- [`render.sh`](render.sh) が変数を `envsubst` で置換 → 検証 →
  `~/.config/skhd/skhdrc` へ反映・reload（検証 NG なら反映しない）
- 更新手順: `skhdrc.tmpl` を編集 → `./render.sh`

## 修飾セット（[`render.sh`](render.sh) で定義）

| 名前      | 構成                        | 備考 |
| --------- | --------------------------- | ---- |
| `ULTRA_LL` | 右 Ctrl + 右 Alt + 右 Shift |
| `MIRACLE_LM` | 右 Ctrl + 右 Cmd + 右 Shift |
| `MEGA_RM` | 右 Ctrl + 右 Cmd + 右 Alt   |
| `WONDER_RR` | 右 Cmd + 右 Alt + 右 Shift  |

## ショートカット一覧

`skhdrc.tmpl` の現行バインド（`ULTRA_LL` ＝ 右 Ctrl+Alt+Shift を併用）:

| ショートカット | 操作             | Google Chrome    | VS Code       | 既定                              |
| -------------- | ---------------- | ---------------- | ------------- | --------------------------------- |
| `ULTRA_LL + C`       | タブを左へ       | `Ctrl+Shift+Tab` | `Cmd+Shift+[` | —                                 |
| `ULTRA_LL + V`       | タブを右へ       | `Ctrl+Tab`       | `Cmd+Shift+]` | —                                 |
| `ULTRA_LL + D`       | 前のウィンドウへ | —                | —             | yabai: 前のウィンドウへフォーカス |
| `ULTRA_LL + F`       | 次のウィンドウへ | —                | —             | yabai: 次のウィンドウへフォーカス |

## emacs/readline 風 Ctrl+key remap

| キー     | 動作                       |
| -------- | -------------------------- |
| `Ctrl+B` | ← Left                     |
| `Ctrl+F` | → Right                    |
| `Ctrl+P` | ↑ Up                       |
| `Ctrl+N` | ↓ Down                     |
| `Ctrl+H` | Backspace                  |
| `Ctrl+D` | 前方削除（Forward Delete） |
| `Ctrl+J` | Return                     |

> 一覧は [`skhdrc.tmpl`](skhdrc.tmpl) を正とする手動ドキュメント。バインドを
> 増減したらこの表も更新する。
