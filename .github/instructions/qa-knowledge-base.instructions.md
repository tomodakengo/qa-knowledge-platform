# QA knowledge base — auto-heal pipeline 用 Pattern Catalogue

このファイルは、Claude Code などの AI コーディングエージェントが Playwright のテスト失敗を fix する前に読む **ナレッジベース** です。

> **Why this file exists.** Without an instructions file, an LLM defaults to its training-era best practices (often 2-3 years old) and tends to "fix" tests by extending timeouts or inserting `nth(0)`. This file injects YOUR project's current rules so the agent stays inside guardrails.

> **How to evolve it.** ここに書かれている Pattern catalogue は **GitHub Issues に蓄積されたナレッジから昇格** されたものです。新パターンを足したい場合は Issue を起票し、`status-confirmed` + `confidence-high` まで育ててから `promote-to-instructions.yml` ワークフローで PR が作られます。直接ここを編集するのは "Hard bans" の更新時のみにしてください。

---

## どう使うか（AI 向け）

1. 失敗したテスト名、エラーメッセージ、スタックトレースを Playwright JSON report から読む
2. 下の **Patterns** セクションでパターン照合する
3. 該当パターンがあれば、その **Fix recipe** を listed scope (`tests/`, `pages/`, `utils/`) 内で適用する
4. **照合できなければ "no matching pattern — possible product bug, please review." とコメントして PR を作る**。憶測で fix しない
5. **Hard bans** は何があっても破らない

---

## Hard bans（絶対禁止）

- ❌ `page.waitForTimeout(N)` を入れて timing 失敗を "直す"
- ❌ `playwright.config.ts` の global `timeout` を膨らませる
- ❌ `.nth(N)` で strict-mode violation を回避する。**unique な locator を見つけ直す**
- ❌ `getByRole` / `getByLabel` / `getByTestId` を CSS / XPath に置き換える（"role-based locator が脆い" は誤解。Role が contract です）
- ❌ `try { ... } catch {}` で assertion 失敗を握りつぶす
- ❌ `tests/`, `pages/`, `utils/` の外を編集する。プロダクトコードは out of scope
- ❌ テストの期待値を観測値に合わせて書き換える（テストが落ちなくなるが、もう何もテストしていない）

---

## Patterns

### P-locator-timeout — locator polling timeout

**Symptom**

```
Error: locator.click: Timeout 5000ms exceeded.
=========================== logs ===========================
waiting for getByRole('button', { name: 'Save' })
```

**Diagnosis**

要素は DOM に存在するが actionable ではない（オーバーレイで覆われている / `disabled` / アニメーション中）。

**Fix recipe**

- そのアクション**だけ**の per-call timeout を伸ばす:
  ```ts
  await app.products().header.cartLink.click({ timeout: 10_000 });
  ```
- **NEVER** global `actionTimeout` / `expect.timeout` を伸ばす
- 要素が一貫してオーバーレイで覆われているなら、オーバーレイが消えるのを待ってから click:
  ```ts
  await expect(page.getByTestId('loading-overlay')).toBeHidden();
  await app.products().header.cartLink.click();
  ```

**Source issues**: #7（checkout 確定ボタンをローディングスピナーが覆い CI で timeout）。その他は `gh issue list --label P-locator-timeout` で原典を辿れる

---

### P-strict-mode-violation — locator が複数要素にマッチ

**Symptom**

```
Error: strict mode violation: getByRole('button', { name: 'Save' }) resolved to 2 elements
```

**Diagnosis**

同じ accessible name のボタンが画面内に複数ある。

**Fix recipe**

- **やってはいけない**: `.nth(0)`, `.first()` で誤魔化す
- **やる**: scope を絞ってから locator を取り直す
  ```ts
  // ✅ 親要素で絞る
  const dialog = page.getByRole('dialog', { name: '注文確認' });
  await dialog.getByRole('button', { name: '保存' }).click();
  ```
- それでも一意にならなければ **テスト対象アプリ側に `data-testid` を提案する** issue を `product-bug-suspect.yml` で起票

---

### P-network-race — API レスポンス待機不足

**Symptom**

UI は要素を表示しているが、まだ表示中のスケルトン / 古いキャッシュ表示で、assert が失敗する。

```
Error: expect(locator).toHaveText('¥3,200')
Expected string: "¥3,200"
Received string: "¥0"
```

**Diagnosis**

API 呼び出しが返ってくる前に assert が走っている。

**Fix recipe**

- **やってはいけない**: `waitForTimeout(2000)`
- **やる**: web-first assertion で Playwright の auto-retry を信頼する
  ```ts
  await expect(app.cart().total).toHaveText('¥3,200');
  ```
- それでも flaky なら、**そのAPIのレスポンスを待つ**:
  ```ts
  const cartResponse = page.waitForResponse(r => r.url().includes('/api/cart'));
  await app.cart().refresh();
  await cartResponse;
  await expect(app.cart().total).toHaveText('¥3,200');
  ```

**Source issues**: #9（cart total assert で expected ¥3,200 / received ¥0。fixture 側で `waitForResponse` の追加が望ましい）

---

## このファイルの育て方

このファイルに **直接** パターンを追加するのは推奨しません。代わりに:

1. 失敗を踏んだら `flaky-pattern.yml` テンプレで Issue を起票
2. triage 担当 / triage-issue.yml が Pattern label と confidence を付与
3. 同症状が3件以上 or 1週間以内に再現すると `confidence-high` に昇格
4. 週次の `promote-to-instructions.yml` がこのファイルへ追記する PR を起こす
5. 人間レビュー後にマージ → AI が次回失敗時から参照する

詳しくは `docs/promotion-workflow.md`。
