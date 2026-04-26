# promotion-workflow — issue から instructions への昇格

## 目的

GitHub Issues に積まれた失敗ナレッジから、**信頼度の高いものだけ** を `.github/instructions/qa-knowledge-base.instructions.md` に昇格させ、AI auto-heal エージェントが読むカタログを育てる。

## 昇格条件（confidence-high の付与基準）

以下のいずれかを満たすときに `confidence-high` を付与します:

- 同じ Pattern label の Issue が **3件以上** 立っている（同症状の再発）
- **1週間以内に再発** した
- 解決済み Issue で fix の効果が **複数のテストで確認** された

`confidence-high` + `status-confirmed` の両方が揃った Issue が **昇格対象** です。

## 週次ワークフロー

`.github/workflows/promote-to-instructions.yml`（雛形は本テンプレ未配置、派生案として実装予定）が **毎週月曜の朝 9:00 JST** に以下を実行します:

```
1. gh issue list --label confidence-high --label status-confirmed --state open
2. 各 Issue の Pattern label / Symptom / Diagnosis / Fix recipe をテンプレに整形
3. .github/instructions/qa-knowledge-base.instructions.md にセクション追加する PR を起こす
4. 該当 Issue にコメント: "promotion PR #N に取り込みました"
5. PR には reviewer として QA リード を assign
```

## 人間レビュー時のチェックリスト

PR レビュアーは以下を確認:

- [ ] **Hard bans** に違反する fix が含まれていないか
- [ ] 既存 Pattern との重複がないか（あれば統合）
- [ ] Symptom / Diagnosis / Fix recipe が **AI が機械的に当てはめられる粒度** で書かれているか
  - "状況に応じて" のような曖昧表現は具体に書き直す
- [ ] テストコード以外（プロダクトコード）の修正が混ざっていないか

## 昇格後の Issue 処理

PR がマージされたら:

```
status-confirmed → status-promoted
```

Issue は **クローズしますが削除はしません**。理由:

- triage 時の重複検索で `state:all` で hit させたい
- 「このパターンはいつから知られていたか」の歴史を保持
- `gh issue view N` で原典の議論を追える

## 昇格しなかった Issue の処理

`status-rejected` を付けてクローズ:

- プロダクトバグ → `P-product-bug-suspect` で開発に引き継ぎ済み
- 重複 → 親 Issue にリンクしてクローズ
- 再現せず → 1ヶ月放置後にクローズ。再発時に再起票

## ラベル taxonomy の見直し

月次で:

- 使われていない Pattern label を削除
- `P-*` が 20 を超えていれば再分類検討
- 新パターンが台頭してきたら labels.yml に追加

## このワークフローを始めて回すとき

最初は **手動** で構いません:

1. 月曜の朝に `gh issue list --label confidence-high --label status-confirmed` を眺める
2. 目視で該当 Issue から手で `qa-knowledge-base.instructions.md` に追記
3. PR を作成
4. 慣れてきたら自動化

自動化を急がないことが重要です。**昇格判断には QA としての目利きが入る** ので、最初から完全自動化するとノイズが増えます。
