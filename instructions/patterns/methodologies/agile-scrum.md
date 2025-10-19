# Agile/Scrum パターン

アジャイル開発とスクラムフレームワークのパターン。

## スクラムフレームワーク

### スプリント構造
```yaml
sprint:
  duration: 2週間
  ceremonies:
    - sprint_planning: Day 1
    - daily_standup: 毎日15分
    - sprint_review: 最終日
    - retrospective: 最終日
  
  artifacts:
    - product_backlog
    - sprint_backlog
    - increment
```

### ロールと責任
```yaml
roles:
  product_owner:
    - プロダクトバックログ管理
    - 優先順位決定
    - ステークホルダー調整
  
  scrum_master:
    - プロセス促進
    - 障害除去
    - チーム支援
  
  development_team:
    - 自己組織化
    - クロスファンクショナル
    - 実装責任
```

## バックログ管理

### ユーザーストーリー
```markdown
# テンプレート
As a [role]
I want [feature]
So that [benefit]

# 受け入れ条件
Given [前提条件]
When [アクション]
Then [期待結果]

# 例
As a ユーザー
I want ソーシャルログインを使いたい
So that 簡単にアカウント作成できる

Given ログインページにアクセス
When Googleログインボタンをクリック
Then Googleアカウントでログインできる
```

### ストーリーポイント見積もり
```typescript
// フィボナッチ数列
const storyPoints = [1, 2, 3, 5, 8, 13, 21];

// 見積もり基準
interface EstimationCriteria {
  complexity: 'low' | 'medium' | 'high';
  effort: 'small' | 'medium' | 'large';
  risk: 'low' | 'medium' | 'high';
  dependencies: number;
}

// プランニングポーカー
const estimate = (criteria: EstimationCriteria): number => {
  let points = 1;
  
  if (criteria.complexity === 'high') points += 5;
  if (criteria.effort === 'large') points += 5;
  if (criteria.risk === 'high') points += 3;
  if (criteria.dependencies > 2) points += 3;
  
  // 最も近いフィボナッチ数
  return storyPoints.find(p => p >= points) || 21;
};
```

## スプリント実行

### デイリースタンドアップ
```markdown
## 3つの質問
1. 昨日何をしたか？
2. 今日何をするか？
3. 障害はあるか？

## アンチパターン回避
- ❌ ステータス報告会にしない
- ❌ 問題解決の場にしない
- ❌ 15分を超えない
- ✅ 同期と透明性確保
- ✅ 障害の早期発見
```

### バーンダウンチャート
```typescript
interface BurndownData {
  day: number;
  ideal: number;
  actual: number;
}

const calculateBurndown = (
  totalPoints: number,
  sprintDays: number,
  completedPoints: number[]
): BurndownData[] => {
  const idealRate = totalPoints / sprintDays;
  let remaining = totalPoints;
  
  return completedPoints.map((completed, index) => {
    remaining -= completed;
    return {
      day: index + 1,
      ideal: totalPoints - (idealRate * (index + 1)),
      actual: remaining
    };
  });
};
```

## Definition of Done

### DoD チェックリスト
```yaml
definition_of_done:
  code:
    - 機能実装完了
    - コードレビュー済み
    - リファクタリング完了
  
  testing:
    - ユニットテスト作成
    - 統合テスト実行
    - 受け入れテスト合格
  
  documentation:
    - APIドキュメント更新
    - ユーザーマニュアル更新
    - CHANGELOG記載
  
  deployment:
    - ステージング環境デプロイ
    - パフォーマンステスト合格
    - セキュリティチェック完了
```

## ベロシティ追跡

### ベロシティ計算
```typescript
class VelocityTracker {
  private sprintVelocities: number[] = [];
  
  addSprint(completedPoints: number) {
    this.sprintVelocities.push(completedPoints);
  }
  
  getAverageVelocity(lastNSprints = 3): number {
    const recent = this.sprintVelocities.slice(-lastNSprints);
    return recent.reduce((a, b) => a + b, 0) / recent.length;
  }
  
  predictCompletion(remainingPoints: number): number {
    const avgVelocity = this.getAverageVelocity();
    return Math.ceil(remainingPoints / avgVelocity);
  }
}
```

## レトロスペクティブ

### 振り返りフォーマット
```markdown
## Start - Stop - Continue
- Start: 始めるべきこと
- Stop: やめるべきこと
- Continue: 続けるべきこと

## 4Ls
- Liked: 良かったこと
- Learned: 学んだこと
- Lacked: 不足していたこと
- Longed for: 望むこと
```

### アクションアイテム
```typescript
interface ActionItem {
  id: string;
  description: string;
  owner: string;
  dueDate: Date;
  status: 'pending' | 'in-progress' | 'completed';
}

class RetrospectiveActions {
  private actions: ActionItem[] = [];
  
  addAction(action: Omit<ActionItem, 'id' | 'status'>) {
    this.actions.push({
      ...action,
      id: generateId(),
      status: 'pending'
    });
  }
  
  trackProgress(): void {
    const completed = this.actions.filter(a => a.status === 'completed');
    console.log(`Progress: ${completed.length}/${this.actions.length}`);
  }
}
```

## カンバンとの統合

### WIP制限
```typescript
interface KanbanColumn {
  name: string;
  wipLimit: number;
  tasks: Task[];
}

const validateWipLimit = (column: KanbanColumn): boolean => {
  return column.tasks.length < column.wipLimit;
};

const kanbanBoard: KanbanColumn[] = [
  { name: 'Backlog', wipLimit: Infinity, tasks: [] },
  { name: 'In Progress', wipLimit: 3, tasks: [] },
  { name: 'Review', wipLimit: 2, tasks: [] },
  { name: 'Done', wipLimit: Infinity, tasks: [] }
];
```

## チェックリスト
- [ ] スプリント計画実施
- [ ] デイリースタンドアップ
- [ ] バックログ優先順位付け
- [ ] DoD明確化
- [ ] ベロシティ追跡
- [ ] レトロスペクティブ実施
- [ ] 継続的改善