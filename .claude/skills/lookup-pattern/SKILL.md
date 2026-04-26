---
name: lookup-pattern
description: AIが Playwright のテスト失敗を fix する前に、過去の同症状 issue / 昇格済みナレッジを検索する。auto-heal pipeline 用や、ユーザーが「同じ失敗したことあるか調べて」と依頼したときに起動する。
---

# lookup-pattern

このSkillは Playwright のテスト失敗に対して fix を提案する **前に**、
過去のナレッジ（GitHub Issues + `.github/instructions/`）を検索して類似事例を取り込む。

## いつ起動するか

- auto-heal pipeline が失敗を fix しようとするとき（fix 提案の **前**）
- ユーザーが「同じ失敗したことあるか調べて」「過去の事例ある？」と依頼したとき
- `report-flaky-pattern` Skill が起票前に重複チェックするとき

## どう動くか

### Step 1: 症状から候補 Pattern label を絞る

エラーログから候補となる `P-*` ラベルを 1〜3 個に絞る:

| シグナル | 候補ラベル |
|---|---|
| `Timeout 5000ms exceeded` で element 待ち | `P-locator-timeout`, `P-overlay-blocks-click` |
| `strict mode violation` | `P-strict-mode-violation` |
| 期待値と受信値の数値ずれ | `P-network-race`, `P-data-mismatch` |
| `webServer` 起動失敗 / Docker内のみ | `P-env-flake` |
| 同じテストが日によって違う結果 | `P-state-leak` |

### Step 2: 昇格済みナレッジを最初に読む

`.github/instructions/qa-knowledge-base.instructions.md` から該当パターンの **Symptom / Diagnosis / Fix recipe** を読む。
ここに書かれている fix は **人間レビューを経たもの**なので、最も信頼度が高い。

該当パターンが catalogue にあれば、そのfixレシピを fix 提案のベースにする。
ない場合に Step 3 へ進む。

### Step 3: open / closed の Issues を検索

```bash
# まず open を見る（同時並行で起きている可能性）
gh issue list --label "P-locator-timeout" --state open --limit 10

# 解決済みもさらう（過去に同症状があったか）
gh issue list --label "P-locator-timeout" --state closed --limit 20

# 詳細を読む
gh issue view <番号>
```

候補ラベルを 2 個以上絞れない場合は、ラベルなしで全文検索:

```bash
gh issue list --search "in:title,body <キーワード>" --state all
```

### Step 4: 結果の取り扱い

| 検索結果 | 行動 |
|---|---|
| 同症状の `status-promoted` issue がある | catalogue に既にある。recipe をそのまま使う |
| 同症状の `status-confirmed` issue がある（未昇格） | コメントで議論されている fix 案を採用候補にする |
| 同症状の `status-triage` issue がある | **新規起票しない**。コメントで「自分も踏んだ」と追記する案内 |
| 該当なし | 新規起票候補。`report-flaky-pattern` Skill を起動 |

### Step 5: AI fix 提案へのフィードバック

検索結果を fix 提案コンテキストに含めて auto-heal エージェントに渡す:

```
## 過去のナレッジ
- catalogue: P-locator-timeout の Fix recipe
- 関連 issue: #42 (closed, status-promoted), #87 (open, status-confirmed)

## 今回の失敗
<error log>

## 提案する fix
<上記を踏まえた提案>
```

## 守ってほしいこと

- **catalogue を読まず憶測で fix を提案しない**。training-era の "best practice" は古い
- `P-product-bug-suspect` がついた issue が見つかったら **fix を提案せず人間レビューに委ねる**
- 検索結果が大量にある場合は、**最新3件 + 最も confidence-high なもの** に絞って context に入れる（token 効率）
- 同じ catalogue を毎回 fetch すると無駄なので、セッション内では **一度読んだら再利用** する

## 関連

- `report-flaky-pattern` Skill: 起票時の重複チェックでこのSkillを呼ぶ
- `.github/instructions/qa-knowledge-base.instructions.md`: 昇格済みナレッジの正典
- `docs/promotion-workflow.md`: 昇格判断の条件
