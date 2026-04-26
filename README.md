# qa-knowledge-platform

> **失敗起票 → ラベル分類 → ナレッジ昇格** のループを GitHub Issues 上で回すための QA ナレッジ蓄積テンプレートです。
>
> Claude Code などの AI コーディングエージェントが過去のテスト失敗ナレッジを参照して "暴走しない fix" を提案できるよう、Issues を構造化された Pattern Catalogue として育てる仕組みを提供します。

## なぜこのテンプレートが必要か

E2E テストの auto-heal パイプライン（[参考: 人間が寝ている間にClaude CodeがPlaywrightのE2Eテストを直してPRを出す](https://zenn.dev/yuden/articles/playwright-auto-heal-claude-code)）を運用していると、AI が参照する **ナレッジ側の腐敗** が事故の原因になります。

- `.github/instructions/*.md` だけでナレッジを管理すると、更新権限が開発者寄りになり、QA 非エンジニアの知見が反映されにくい
- 古い情報のまま fix させた結果、`waitForTimeout` 連発 / `nth(0)` 連発 を踏む事故が発生する
- 「Hard bans（絶対禁止）」と「Pattern catalogue（こうやって直す）」が分離されていないと、AI は誤った fix を量産する

このテンプレートは、これらの痛点を **GitHub Issues + ラベル + 週次の昇格ワークフロー** で解決します。

## 全体像

```
   失敗発生
      ↓
  gh issue create  ←── ISSUE_TEMPLATE で構造化
      ↓
  triage-issue.yml  ←── Claude が自動ラベル付け（任意）
      ↓
  status: triage → confirmed
      ↓
  promote-to-instructions.yml （週次cron）
      ↓
  .github/instructions/qa-knowledge-base.instructions.md に追記する PR
      ↓
  AI fix エージェントは instructions を読んで暴走しない
```

## クイックスタート

### 1. テンプレート使用 or 既存リポジトリへ取り込む

GitHub の "Use this template" から新規リポジトリを作るか、`docs/adoption-guide.md` を読んで既存リポジトリに移植します。

### 2. ラベルを反映する

`labels.yml` を編集してリポジトリにラベルを生やします。`sync-labels.yml` ワークフローが `labels.yml` の変更を検知して、リポジトリにラベルを同期します。

```bash
gh workflow run sync-labels.yml
```

### 3. Issue Template で起票する練習

サンプル issue を起票するスクリプトが `examples/seed-issues.sh` にあります。実行すると、Pattern catalogue の起点になる issue が3件作成されます。

```bash
bash examples/seed-issues.sh
```

### 4. AI 連携を有効化する

このテンプレは triage を 2 系統で提供します。**自分のチームに合うほうを選んでください**。

| ワークフロー | エンジン | trigger | セットアップ | コスト |
|---|---|---|---|---|
| `triage-issue-copilot.yml` | GitHub Models (`gpt-4o-mini`) | 自動 (`issues: opened`) | **不要**（権限ブロックだけ） | 無料 quota |
| `triage-issue.yml` | Claude Code Action | 手動 (`workflow_dispatch`) | GitHub App + `ANTHROPIC_API_KEY` | Claude API 課金 |
| `promote-to-instructions.yml` | Claude Code Action | 週次cron | GitHub App + `ANTHROPIC_API_KEY` | Claude API 課金 |

#### A. GitHub完結ルート（デフォルト推奨）

`triage-issue-copilot.yml` は `actions/ai-inference@v1` を使い、**外部API key なし** で動きます。秘密情報の登録不要、Free アカウントでも動作します。

セットアップは：

- **何もしなくてOK**。リポジトリを clone した時点で `permissions: { models: read }` 付きで起動可能になっています

#### B. Claude Code Action ルート（より深い分析が欲しい時）

`triage-issue.yml`（手動 trigger）と `promote-to-instructions.yml`（週次cron）は Claude Code Action を使います。GitHub Models より長文・複雑な分析に向きます。

##### B-1. CLI で一括セットアップ

```bash
claude /install-github-app
```

GitHub App インストールと `ANTHROPIC_API_KEY` 登録までを対話で完了します。OAuth ブラウザが開けない環境（remote control / CI / SSH 等）では B-2 を使ってください。

##### B-2. 手動セットアップ

1. **GitHub App をインストール**
   - [https://github.com/apps/claude](https://github.com/apps/claude) にアクセス
   - "Install" → 対象リポジトリを選択
   - 権限（Contents R/W、Issues R/W、Pull Requests R/W）を許可

2. **API Key を secret として登録**
   - Settings → Secrets and variables → Actions → "New repository secret"
   - Name: `ANTHROPIC_API_KEY`
   - Value: [console.anthropic.com](https://console.anthropic.com) で発行した API key

3. **PR 作成権限の有効化** (`promote-to-instructions.yml` を使う場合のみ)
   - Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests" にチェック

##### B-3. 手動 triage の実行

```bash
gh workflow run triage-issue.yml -f issue_number=42
```

または GitHub UI: Actions タブ → "Triage issue with Claude (manual)" → "Run workflow" → issue 番号を入力。

#### 動作確認

Issues タブから `🌀 Flaky pattern report` テンプレで適当に1件起票 → 1〜2分後に triage 提案コメントが付けば成功（A ルートのみで起動します）。

詳細は `docs/promotion-workflow.md` を参照。

## ディレクトリ構成

```
.
├── .github/
│   ├── ISSUE_TEMPLATE/       # 4種類の構造化テンプレ
│   ├── labels.yml            # ラベル定義（Pattern, scope, severity, status, confidence）
│   ├── workflows/            # sync / triage / promote
│   └── instructions/         # AI が読む昇格済みナレッジ
├── .claude/skills/           # Claude Code Skill（report / lookup）
├── docs/                     # 設計思想・運用ガイド
└── examples/                 # サンプル起票スクリプトと失敗ログ
```

## ドキュメント

- [docs/philosophy.md](docs/philosophy.md) — なぜ issue ベースか
- [docs/label-taxonomy.md](docs/label-taxonomy.md) — ラベル設計の指針
- [docs/promotion-workflow.md](docs/promotion-workflow.md) — issue → instructions の昇格ルール
- [docs/adoption-guide.md](docs/adoption-guide.md) — 既存リポジトリへの移植手順
- [docs/ai4qa-rationale.md](docs/ai4qa-rationale.md) — AI4QA でこの仕組みが効く理由

## 関連プロジェクト

- [`tomodakengo/playwright-fixture`](https://github.com/tomodakengo/playwright-fixture) — Playwright POM + Fixtures + Claude Skills のスターターテンプレ。本リポジトリの Pattern catalogue は `playwright-fixture` の `.github/instructions/ci-failure-analysis.instructions.md` の拡張版です。

## License

MIT
