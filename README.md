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

### 4. AI 連携を有効化する（任意）

このテンプレは [Claude Code Action](https://github.com/anthropics/claude-code-action) を使う 2 つのワークフローを同梱しています:

- `.github/workflows/triage-issue.yml`: issue 起票時に Claude が triage コメントを自動投稿
- `.github/workflows/promote-to-instructions.yml`: 週次で confidence-high な issue を `instructions/` に昇格する PR を作成

#### セットアップ手順

1. **GitHub App のインストール**: ローカルの Claude Code から
   ```bash
   claude /install-github-app
   ```
   を実行すると、Anthropic 公式の GitHub App インストールと `ANTHROPIC_API_KEY` secret の登録までを対話で完了できます

2. **PR 作成権限の有効化** (`promote-to-instructions.yml` を使う場合のみ):
   Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests" にチェック

3. 動作確認: Issues タブから `flaky-pattern.yml` テンプレで適当に1件起票 → 1〜2分後に Claude の triage 提案コメントが付けば成功

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
