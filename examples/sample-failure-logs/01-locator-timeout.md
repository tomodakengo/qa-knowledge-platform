## 失敗したテスト名
`tests/checkout.spec.ts > Checkout > should complete order`

## エラーログ抜粋

```
Error: locator.click: Timeout 5000ms exceeded.
  Call log:
    - waiting for getByRole('button', { name: '注文を確定する' })
    -   element is not visible

  at Object.click (/home/runner/.../checkout-page.ts:42:5)
  at Context.<anonymous> (/home/runner/.../tests/checkout.spec.ts:18:3)
```

## 再現性
ときどき失敗する (10-50%)

## どこで再現したか
- CI (nightly)
- CI (PR)

## 疑っているパターン
注文確定ボタンを覆っている **ローディングスピナー** が消える前に click を試行している疑い。
ローカルでは画面遷移が速いので踏まないが、CI runner だと遅い。

## 一時しのぎ
今のところ無し。リトライ設定で 2 回中 1 回は通るので運用継続中。

## 自己チェック
- [x] `page.waitForTimeout(N)` を入れて誤魔化していない
- [x] `.nth(N)` で strict mode を回避していない
- [x] `getByRole/getByLabel/getByTestId` を CSS/XPath に置き換えていない
