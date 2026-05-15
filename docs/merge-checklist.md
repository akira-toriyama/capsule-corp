# `feature/emacs-like` マージ前 確認チェックリスト

`main` への取り込み前に、しばらくの実機運用で潰し込む観点。
PR: [#12](https://github.com/akira-toriyama/cyboard-imprint-zmk/pull/12)

## 自動検証（CI / ローカルで確認済み）

- [x] Lint: `python3 scripts/gen_eiji_drawer_map.py --check` PASS（eiji_* mapping 同期済み）
- [x] ビルド: `nix develop --command just build imprint_left` PASS
      （FLASH 272956 B / RAM 71924 B — PR #12 ベースラインと完全一致）
- [ ] ビルド: `imprint_right` も同様に通すこと

## 実機確認（リスクの高い順 / 数日の通常運用で）

- [ ] **Mission Control 誤発火なし** — fork 撤去後の最大リスク。Ctrl 親指＋矢印などで暴発しないか
- [ ] **日本語入力** — かな/英数切替が正常、Shift 始動の語が英字になる（`al_a`〜`al_z` morph）
- [ ] **記号確定入力** — `en_*` が IME 状態に依らず正しい記号を確定（英数へ切替→記号）
- [ ] **矢印 hold-tap** — `ar_*` 長押し中に別キーで HOME/END/PgUp/PgDn が成立（`hold-while-undecided`+linger）
- [ ] **親指 chord (TU)** — `T_LL/T_LM/T_RM/T_RR` が OS 側で別物として識別される
- [ ] **combo** — 左親指2キー＝かな / 右親指2キー＝英数、hold＝修飾子が誤爆なく出る
- [ ] **親指下段 mod-tap (TD)** — Shift/⏎・Cmd/⌫・Alt/⎋・Ctrl/␣ が tap/hold とも正しい
- [ ] **layer 切替** — NUMBER / SYMBOL1 / SYMBOL2 / FUNCTION の `MO_LAYER` momentary が正常
- [ ] **左トラックボール** — 常時スクロール化が効いている
- [ ] **左右両半身** — `imprint_left` / `imprint_right` 両方フラッシュして動作確認

## マージ

- [ ] 上記すべて確認後、PR #12 を `main` へマージ（履歴の読み物価値があるため squash しない方針を検討）
