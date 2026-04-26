---
name: report-flaky-pattern
description: Playwrightテストの失敗（flaky / locator / env / プロダクトバグ疑い）を構造化して GitHub Issue として起票する。ローカルやCIで失敗を踏んだとき、ユーザーが「このflakyを起票しておいて」「いまの失敗をナレッジ化したい」と依頼したら起動する。
---

# report-flaky-pattern

このSkillは Playwright のテスト失敗を **構造化された GitHub Issue** として起票する。
QAナレッジ蓄積プラットフォームの "起点" となるSkill。

## いつ起動するか

ユーザーが以下のような依頼をしたとき:

- 「このflakyを起票しておいて」
- 「いまの失敗を gh issue にしておいて」
- 「ナレッジ化しておいて」
- CIログを貼り付けて「これパターン化して」

## どう動くか

### Step 1: 失敗の分類を決める

エラーログを読んで、以下4種のどれかに分類する:

| 失敗の種類 | 使うテンプレ | 主なシグナル |
|---|---|---|
| 間欠的に落ちる | `flaky-pattern.yml` | 「ときどき落ちる」「retryで通る」「CIだけ落ちる」 |
| 常にlocatorで失敗 | `locator-issue.yml` | strict mode violation / timeout で要素見つからず |
| CI/Docker/設定起因 | `env-config-issue.yml` | webServer起動失敗、Docker内だけ失敗、playwright.config由来 |
| プロダクトバグ疑い | `product-bug-suspect.yml` | 期待値と実装挙動が乖離している |

判別がつかないときは **`flaky-pattern.yml` をデフォルト** にして、本文に「分類自信なし」と書く。

### Step 2: 必須フィールドを集める

エラーログ・スタックトレース・テスト名・playwright-report の `results.json` から、テンプレートの必須フィールドを埋める:

- 失敗したテスト名（`tests/<file>.spec.ts > <describe> > <test>`）
- エラーログ抜粋（10〜30行、長すぎる場合は collapsible）
- 再現性（CI runs / local runs で踏んだ回数から推定）
- 疑っているパターン（`P-locator-timeout` 等のラベル候補）

不足情報があれば **ユーザーに質問する**。憶測で埋めない。

### Step 3: Hard bans に該当する応急処置がないか確認

ユーザーが既に試した workaround で以下が含まれていたら、起票本文に **明示的に書く**（隠さない）:

- `page.waitForTimeout(N)` を入れた
- `.nth(N)` で strict mode を回避した
- `getByRole` / `getByTestId` を CSS / XPath に置き換えた
- `try/catch` で assertion を握りつぶした

これらは Hard bans 違反だが、**事実を起票することは正義**。triage 時に正しい修正へ誘導する材料になる。

### Step 4: gh issue create を実行

```bash
gh issue create \
  --title "[flaky] <テスト名> が <症状>" \
  --label "status-triage,confidence-low,P-<候補>,scope-<候補>,severity-<候補>" \
  --body "$(構造化した本文)"
```

ラベルは確度が低い場合は **`P-*` を1つだけ** 付ける（複数候補は本文に書く）。`status-triage` と `confidence-low` は固定で付ける。

### Step 5: 起票後の案内

ユーザーに以下を伝える:

- 起票した issue 番号と URL
- triage 担当（または triage-issue.yml）が Pattern label を確定する旨
- 同症状を再発したら **コメントを足す** よう案内（confidence-high への昇格判断材料）

## 守ってほしいこと

- 同じ症状の open issue が既にないか必ず `lookup-pattern` Skill で先に検索する。あれば **新規起票せずコメント追加** に切り替える
- ラベルを過剰に付けない。triage が判断する余地を残す
- プロダクト機密（顧客情報、内部URL、社内環境名）が error log に含まれていたら **マスクしてから起票**

## 関連

- `lookup-pattern` Skill: 起票前の重複チェック
- `.github/ISSUE_TEMPLATE/*.yml`: 構造化フォームの定義
- `.github/instructions/qa-knowledge-base.instructions.md`: Hard bans の正典
