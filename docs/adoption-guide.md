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

### 5. Claude Code Action を有効化する（triage / promotion ワークフロー用）

`.github/workflows/triage-issue.yml` と `promote-to-instructions.yml` を動かすには、`anthropics/claude-code-action@v1` のセットアップが必要です。2 通りあります。

#### A. CLI で一括セットアップ

ローカルの Claude Code から:

```bash
claude /install-github-app
```

GitHub App インストールと `ANTHROPIC_API_KEY` 登録までを対話で完了します。OAuth 認証ウィンドウが開けない環境（remote control 中 / SSH のみ / CI 環境）では B を使ってください。

#### B. 手動セットアップ（GitHub Web UI のみで完結）

1. **Anthropic 公式 GitHub App をインストール**
   - [https://github.com/apps/claude](https://github.com/apps/claude) を開く
   - "Install" をクリック
   - "Only select repositories" でこのリポジトリを選択
   - 権限（Contents R/W、Issues R/W、Pull Requests R/W）を許可

2. **`ANTHROPIC_API_KEY` を secret として登録**
   - リポジトリの Settings → Secrets and variables → Actions
   - "New repository secret"
   - Name: `ANTHROPIC_API_KEY`
   - Secret: [console.anthropic.com](https://console.anthropic.com) で発行した API key
   - "Add secret"

3. **PR 作成許可の有効化** (`promote-to-instructions.yml` を使う場合のみ)
   - Settings → Actions → General
   - "Workflow permissions" セクション
   - "Allow GitHub Actions to create and approve pull requests" にチェック → Save

#### App なしで運用できる？

このリポジトリ内の issue / PR にだけ反応させる用途なら、原理的には GitHub App をインストールせず `secrets.GITHUB_TOKEN`（GitHub Actions が自動発行）と workflow `permissions:` ブロックだけで動かせる可能性があります。ただし `anthropics/claude-code-action` は **App 前提で設計されている** ため、App をインストールしておく方がトラブル少です。クロスリポジトリで動かす場合は App 必須。

#### 動作確認

Issues タブから `flaky-pattern.yml` テンプレで1件起票 → 1〜2分後に Claude の triage 提案コメントが付けば成功です。動かない場合は:

- Actions タブで該当 workflow run の log を確認
- `ANTHROPIC_API_KEY` secret が正しいスコープ（Actions secrets であって Codespaces secrets ではない）に登録されているか確認
- App の権限が Contents/Issues/PRs すべて R/W になっているか確認

### 6. 既存の auto-heal pipeline と統合する

すでに [playwright-auto-heal-claude-code](https://zenn.dev/yuden/articles/playwright-auto-heal-claude-code) のような auto-heal ワークフローがある場合:

- 失敗解析プロンプトに `qa-knowledge-base.instructions.md` を Read させる
- `lookup-pattern` Skill で過去の同症状 issue を fetch させてから fix 提案
- 例（Action 呼び出し）:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_args: '--allowedTools "Read,Edit,Bash(gh issue list:*),Bash(gh issue view:*)"'
    prompt: |
      You are an auto-heal agent for Playwright tests.
      First Read .github/instructions/qa-knowledge-base.instructions.md.
      Then look up similar past issues with `gh issue list --label P-<candidate> --state all`.
      Only after that, propose a fix that does NOT violate Hard bans.

      Failure log:
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
