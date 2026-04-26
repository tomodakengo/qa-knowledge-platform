## 問題のlocator

```ts
page.getByRole('button', { name: 'Save' })
```

## 失敗モード
strict mode violation (要素が複数ヒット)

## ARIA snapshot

```yaml
- dialog "プロファイル設定変更":
    - button "Save"
    - button "Cancel"
- region "メインフォーム":
    - button "Save"
```

設定画面に **ダイアログの Save** と **メインフォームの Save** の 2 つが共存している。

## 調査メモ
- ダイアログを開いた直後はメインフォームの Save も visible のまま
- どちらをクリックすべきかは文脈依存
- 既存テストは `.nth(0)` で誤魔化している（要修正）

## 影響範囲
Page Object / Component を共有する複数テスト
