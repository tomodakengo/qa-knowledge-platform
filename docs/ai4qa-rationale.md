# ai4qa-rationale — なぜ AI4QA でこの仕組みが効くか

## AI4QA の本丸はテスト生成ではない

AI を QA に取り入れる議論は「**AI にテストを書かせる**」に偏りがちです。Playwright Test Agents、Codium、Diffblue Cover など、テスト生成を売るツールも増えています。

ですが、運用している QA エンジニアの実感はこうではないでしょうか:

> テストの **書き始め** は AI に任せて 80 点までは取れる。問題はそのあとの "腐っていく" コードと "腐っていく" 知見をどう運用するかだ。

実際、["AIテストへの期待88%と現実12%のギャップ"](https://zenn.dev/yuden/articles/) という調査結果が話題になりました。期待と現実のギャップは、ツール選定ではなく **運用設計の不在** から生まれます。

## ナレッジが腐ると AI は暴走する

auto-heal pipeline（[人間が寝ている間にClaude CodeがPlaywrightのE2Eテストを直してPRを出す](https://zenn.dev/yuden/articles/playwright-auto-heal-claude-code) のようなもの）を運用していると、AI が踏む典型的な事故があります:

| 症状 | 原因 |
|---|---|
| `waitForTimeout(5000)` を書き加えてくる | LLM が training-era の "best practice" を持ち出している |
| `.nth(0)` で strict-mode を回避 | 最短パスが見えてしまう |
| `getByRole` を `.btn-primary` に書き換え | "role-based locator は brittle" という古い言説に引きずられる |
| プロダクトコードを編集しはじめる | スコープ境界がプロンプトに無い |

これらは **すべて、AI に渡す instructions に書いておけば防げる** ものです。逆に、書かれていなければ AI は default の behavior に戻ります。

## ナレッジ運用 3 つの罠

ナレッジを `.github/instructions/` Markdown だけで運用していると、運用が止まったときに罠にハマります:

### 罠 1: 起票コストが高くて現場の知見が貯まらない

「失敗を見つけたが PR を立てるのは面倒」 → 結果、Markdown は半年で更新が止まる。**Issue Template 1 枚** ならカジュアルに起票できる。

### 罠 2: QA 非エンジニアが書けない

手動テスター、ビジネス側の品質担当者、UX チーム … 彼らも貴重な観察を持っているが、PR を書く文化がない。**Issue は誰でも起票できる**。

### 罠 3: 昇格基準が暗黙

「3 回踏まれたら載せる」のような基準が文書化されないと、レビューが属人化する。**ラベル `confidence-high` の付与基準** をドキュメントに固定すれば、誰が triage しても判断が揃う。

## 二段構えで罠を避ける

このリポジトリの設計は:

```
[Issue 起票] (誰でもカジュアルに、Template 任せ)
     │
     ├── label triage (P-* / scope-* / confidence-*)
     │
     ├── 昇格判定 (confidence-high && status-confirmed)
     │
     └── [.github/instructions/ に追記] (人間レビュー必須、AI が読む)
```

**カジュアルさは Issue で、品質ゲートは昇格ワークフローで** という二段構えにすることで、ナレッジ蓄積の継続コストを劇的に下げます。

## なぜ AI4QA で特にこれが効くか

AI コーディングエージェント（Claude Code、Cursor、GitHub Copilot 等）は、**与えられた context に強く影響されます**。

- context が **薄い** → training-era の default に戻る → 古い fix を提案
- context が **濃すぎる** → token を食う → コストと latency が増える
- context が **腐っている** → 古い知見で古い fix を提案

このバランスを取るには「**今まさに有効な、整理されたナレッジだけを濃く渡す**」必要があります。Issue（カジュアルかつ全件）と instructions（厳選かつAI向け）の二層化は、この要請への解です。

## 持論: AI4QA は "ストレージ選定" ではなく "運用リズム" の話

最後に持論を一つ。

ナレッジ蓄積で勝負を分けるのは、**どのストレージを選ぶか** ではなく **運用が止まらないか** です。Notion で運用しても、Confluence でも、Markdown でも、Issues でも、止まれば腐ります。

このリポジトリが提供するのは「止まりにくい運用」のテンプレートです:

- Issue は **5 分で起票できる**（テンプレ任せ）
- 昇格は **週次の自動 PR**（手作業ゼロ）
- 昇格判定は **ラベルだけで decidable**（属人化排除）

リズムが回り続ける限り、AI は腐ったナレッジで暴走しません。回らなくなったら、その時点で他の仕組みに移行すればよい。**ナレッジの "腐敗速度" を下げる** ことが、AI4QA におけるすべての出発点です。
