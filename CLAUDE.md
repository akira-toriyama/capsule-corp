# CLAUDE.md

Claude Code 向けのプロジェクト運用メモ。人間向けの概要は（整備後の）
[README.md](README.md) を参照。本ファイルは「壊しやすい点」と「正しい手順」に絞る。

## このリポジトリ

入力デバイス設定の monorepo。

- **ZMK ファーム**: ルートが ZMK user-config（[Cyboard Imprint](https://cyboard.digital/products/imprint)）
- **skhd ホストブリッジ**: [host/skhd/](host/skhd/) — ZMK の chord を macOS 側で受ける

設計思想は **低依存**（Python は stdlib のみ、他は shell）。重量級ツールチェーン
（Node ランタイム依存の常駐ツール等）をリポジトリに持ち込まない。git-cliff は
Actions / `npx` 経由で使い、リポジトリに Node 依存を追加しない。

## 壊しやすい点（最優先で意識する）

- **west マニフェストは [config/west.yml](config/west.yml)**（リポジトリ直下では
  ない）。topdir はリポジトリルート、`board=assimilator-bt`、
  `shield=imprint_left|imprint_right`。ボード/シールドは外部モジュール
  Cyboard `zmk-keyboards` 由来で、[boards/shields/](boards/shields/) が空なのは
  正常。
- **単一ソース規約**: [config/eiji_macros.dtsi](config/eiji_macros.dtsi) が唯一の
  ソース。`keymap_drawer.config.yaml` の AUTO-GENERATED ブロックは
  [scripts/gen_eiji_drawer_map.py](scripts/gen_eiji_drawer_map.py) が生成し、
  [verify-eiji-sync.yml](.github/workflows/verify-eiji-sync.yml) が CI で厳密一致を
  検証する。マーカー間を手編集しない。変更は dtsi を直し
  `python3 scripts/gen_eiji_drawer_map.py` を再実行（stdlib のみ）。
- **生成/ツール管理ファイルを手で整形・コミットしない**（[.prettierignore](.prettierignore) で除外済）:
  `keymap_drawer.config.yaml`（gen スクリプト）、`keymap-drawer/imprint.{yaml,svg}`
  （draw-keymap の bot が生成・コミット）、`config/imprint.json`（ツールデータ）。
- **ネットワークボリューム**: 作業ツリーは `/Volumes/...`。リポジトリ直下で
  `west update` しない（重い・汚す）。後述のスクリプトはキャッシュへ複製して
  ビルドする。
- **README は本ブランチでユーザーが執筆予定**。指示なく README を上書きしない。

## ディレクトリ構成（再構築しない）

現構成は健全。以下は ZMK / 上流ツールの制約で**移動不可**：

- `config/` `boards/` `zephyr/module.yml` `build.yaml` はリポジトリ**ルート**必須
  （ZMK reusable build と west の前提）。
- `keymap_drawer.config.yaml`（ルート）と `keymap-drawer/`（出力）の分離は
  caksoylar/keymap-drawer の既定どおりで**意図的**。"整理"して移動しない。
- `host/<tool>/` はツール単位の階層（現状 skhd のみ。将来別ツールも同形で追加）。
  `host/` 直下に平坦化しない。
- `scripts/`（+`scripts/hooks/`）は現規模に適切。これ以上分割しない。

## ビルド

- ローカル: `./scripts/build-local.sh`（Docker。依存は `~/.cache/zmk-capsule-corp`
  に永続化、冪等。`--update` / `--clean`、シールド指定可。出力 `firmware/`＝
  gitignore 済）。詳細は [scripts/build-local.sh](scripts/build-local.sh) 冒頭。
- CI: push で [build.yml](.github/workflows/build.yml)（ZMK 公式 reusable）。
- リリース: [release.yml](.github/workflows/release.yml) を **手動起動**
  （workflow_dispatch）。コミットから次版算出 → tag → `CHANGELOG.md` →
  GitHub Release に `imprint_*.uf2` 添付。

## コミット規約（必須）

**gitmoji + Conventional Commits**: `<:gitmoji:> <type>(<scope>)<!>: <subject>`
semver は `type` で決まる（`feat`→minor / `fix`・`perf`→patch / `!`・
`BREAKING CHANGE:`→major / その他は bump しない）。完全な規約・semver 表・
bot 除外は **[docs/commit-convention.md](docs/commit-convention.md)** を参照
（設定 [cliff.toml](cliff.toml)）。

- ローカル検証フック: `git config core.hooksPath scripts/hooks`
- PR では [commit-lint.yml](.github/workflows/commit-lint.yml) が同規則で検証
- bot（`github-actions` 等）コミットは版算出・CHANGELOG から除外
- 例: `:sparkles: feat(keymap): 矢印レイヤーを追加` /
  `:bug: fix(combos): 誤爆を修正` / `:memo: docs: 手順を追記`

## エディタ

[.vscode/settings.json](.vscode/settings.json) で保存時 prettier（md/json/yaml
のみ。`.dtsi`/`.keymap`/`.conf`/`.sh`/`.py` は対象外）。
