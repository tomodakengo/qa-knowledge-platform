# label-taxonomy — ラベル設計の指針

## 5 軸ラベルだけ使う

ラベルは爆発しがちなので、本テンプレでは **5 軸** に固定します。`labels.yml` 以外のラベルは増やさない運用を推奨します。

| 軸 | プレフィックス | 何を表すか | 個数の目安 |
|---|---|---|---|
| Pattern | `P-*` | 失敗の分類 | **20以下に収める** |
| 影響範囲 | `scope-*` | どこを直す必要があるか | 4 |
| 緊急度 | `severity-*` | リリース判断への影響 | 3 |
| 状態 | `status-*` | issue ライフサイクル | 4 |
| 確度 | `confidence-*` | 昇格判定材料 | 2 |

## 設計ルール

### 1. Pattern (P-*) は 20 を超えたら再分類する

人間が暗記できる数を超えるとラベル選択が雑になります。20 を超えそうになったら:

- **統合できないか**: `P-overlay-blocks-click` と `P-locator-timeout` は「actionable じゃない」で統合できる
- **昇格時に削れないか**: `instructions/` に書いた瞬間に Pattern label の存在意義は薄まる。古いものは削除可能

### 2. status は必ずひとつ付く

`status-*` は **mutually exclusive** です（triage / confirmed / promoted / rejected）。triage-issue ワークフロー / triage 担当が遷移を管理します。

```
opened
  ↓
status-triage （起票時の自動付与）
  ↓
  ├─ status-confirmed → ... → status-promoted → close
  └─ status-rejected → close
```

### 3. confidence は単独では何も決めない

`confidence-high` がついても、`status-confirmed` が無ければ昇格しません。逆に `status-confirmed` でも `confidence-low` なら様子見です。**両方そろった issue だけが instructions/ に昇格** します。

### 4. severity は QA 視点ではなくリリース判断視点

「テストの直しやすさ」ではなく「**ユーザー影響の可能性**」で付ける。同じ flaky テストでも、それが checkout フローを守っているなら `severity-blocker`、設定画面なら `severity-minor`。

### 5. scope はリファクタ判断材料

`scope-fixture` 以上が付いた issue は、fix のレビューに **fixture の知識を持つ人**を巻き込む必要があります。trivial PR と扱わせない目印。

## やってはいけないこと

- ❌ チーム名や個人名のラベル（`triage-by-yuden` など）。**個人依存はナレッジ蓄積の敵**
- ❌ 期間ラベル（`2026Q2` など）。Issue 検索は `created:` フィルタで十分
- ❌ "good first issue" 的な社外向けラベル。本テンプレは内部運用前提

## ラベル追加のフロー

1. labels.yml を編集
2. PR を作成。レビュアーは「20 個の上限を超えていないか」「既存と重複していないか」を確認
3. main にマージされると `sync-labels.yml` が GitHub に反映

詳細: `docs/promotion-workflow.md`
