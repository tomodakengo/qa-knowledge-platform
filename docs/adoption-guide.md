# adoption-guide — 既存リポジトリへの移植手順

このテンプレートを **既存の Playwright プロジェクト** に取り込む手順です。`tomodakengo/playwright-fixture` を例に説明しますが、Cypress / Puppeteer / pytest など他フレームワーク採用プロジェクトでも考え方は同じです。

## 前提

- リポジトリで既に GitHub Issues を有効にしている
- `gh` CLI がインストール済み（`brew install gh` / `winget install gh` 等）
- リポジトリへの write 権限がある

## ステップ

### 1. ラベル定義をコピーする

```bash
mkdir -p .github
curl -L -o .github/labels.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/labels.yml
```

すでに `.github/labels.yml` がある場合は、`P-*`, `scope-*`, `severity-*`, `status-*`, `confidence-*` のセクションだけ追記してください。

### 2. ラベルを反映する

`.github/workflows/sync-labels.yml` を本テンプレからコピー:

```bash
mkdir -p .github/workflows
curl -L -o .github/workflows/sync-labels.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/workflows/sync-labels.yml
```

PR を作って main にマージ → ラベルがリポジトリに生えます。

または手動で:

```bash
gh label create "P-locator-timeout" --color "d73a4a" --description "..."
# (繰り返し)
```

### 3. Issue Template を取り込む

```bash
mkdir -p .github/ISSUE_TEMPLATE
curl -L -o .github/ISSUE_TEMPLATE/flaky-pattern.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/ISSUE_TEMPLATE/flaky-pattern.yml
# (locator-issue.yml, env-config-issue.yml, product-bug-suspect.yml も同様)
curl -L -o .github/ISSUE_TEMPLATE/config.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/ISSUE_TEMPLATE/config.yml
```

`config.yml` の `contact_links` の URL は自分のリポジトリに書き換えてください。

### 4. instructions ファイルを置く

```bash
mkdir -p .github/instructions
curl -L -o .github/instructions/qa-knowledge-base.instructions.md \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/instructions/qa-knowledge-base.instructions.md
```

**重要**: テスト対象プロジェクトに合わせて以下をカスタマイズ:

- **Hard bans** セクション: プロジェクト固有の禁則を追加（例: 「`evaluate()` で DOM を直接操作しない」など）
- **Patterns**: 既に踏んだことのある失敗パターンがあれば追記。**空からスタートしても問題ありません**。Issue を起票しながら週次で育てていきます

### 5. 既存の auto-heal pipeline と統合する

すでに [playwright-auto-heal-claude-code](https://zenn.dev/yuden/articles/playwright-auto-heal-claude-code) のような auto-heal ワークフローがある場合:

- Claude Code に渡すプロンプトに `qa-knowledge-base.instructions.md` を追加
- 失敗したテストの error log と一緒に instructions を context として load
- Pattern catalogue 内のパターン照合を最初に行わせる

例（GitHub Actions step）:

```yaml
- name: Run Claude with QA knowledge
  uses: anthropics/claude-code-action@v1
  with:
    prompt: |
      You are an auto-heal agent for Playwright tests.
      Read the failure log below and the QA knowledge base, then propose a fix.
      
      ## QA Knowledge Base
      $(cat .github/instructions/qa-knowledge-base.instructions.md)
      
      ## Failure log
      $(cat playwright-report/results.json)
```

### 6. 最初のサンプル起票で動作確認

```bash
# 本リポジトリの examples/seed-issues.sh を流用すると 3 件サンプルが入ります
curl -L https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/examples/seed-issues.sh | bash
```

GitHub の Issues タブで Pattern label が付いた Issue が 3 件作られていれば成功です。

### 7. 運用に乗せる

- **週次の triage 時間** をチームカレンダーに 30 分確保
- **昇格 PR レビュー** を QA リードのタスクに組み込む
- 1ヶ月後にラベル taxonomy の振り返り

詳しくは `docs/promotion-workflow.md` を参照。

## トラブルシュート

| 症状 | 対処 |
|---|---|
| Issue Template が GitHub UI で出てこない | `.github/ISSUE_TEMPLATE/` 配下にあるか、ファイル名が `.yml`（`.yaml` ではなく）か確認 |
| `sync-labels.yml` が動かない | リポジトリ Settings → Actions → permissions が Read and Write になっているか確認 |
| ラベルが日本語にならない | 本テンプレは英語ラベル前提。ローカライズしたい場合は `name` を変更（`P-*` 等のプレフィックスは保つ） |
