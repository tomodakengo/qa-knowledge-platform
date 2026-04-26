## 失敗したテスト名
`tests/cart.spec.ts > Cart > should reflect added item total`

## エラーログ抜粋

```
Error: expect(locator).toHaveText('¥3,200')
Expected string: "¥3,200"
Received string: "¥0"
  Locator: getByTestId('cart-total')

  at Object.<anonymous> (/home/runner/.../cart.spec.ts:24:7)
```

## 再現性
ときどき失敗する (10-50%)

## どこで再現したか
- CI (nightly)
- ローカル (Headless)

## 疑っているパターン
**P-network-race** に該当しそう。
カート追加 API のレスポンスが返る前に total assert が走っている。
fixture 側で `app.cart()` の初期化時にレスポンス待機を入れていない疑い。

## 一時しのぎ
ローカル再現時に `page.waitForTimeout(2000)` を一時的に入れたら通った。
**ただしこれは Hard bans 違反なので外して起票している**。
正しい修正は web-first assertion か `waitForResponse` だと考えている。

## 自己チェック
- [x] `page.waitForTimeout(N)` を入れて誤魔化していない（一時的に試したが外した）
- [x] `.nth(N)` で strict mode を回避していない
- [x] `getByRole/getByLabel/getByTestId` を CSS/XPath に置き換えていない
