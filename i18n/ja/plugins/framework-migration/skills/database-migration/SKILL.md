---
name: database-migration
description: ゼロダウンタイム戦略、データ変換、ロールバック手順を使用して、ORM間およびプラットフォーム間でデータベース移行を実行します。データベースの移行、スキーマの変更、データ変換の実行、またはゼロダウンタイムデプロイメント戦略の実装時に使用します。
---

> **[English](../../../../../plugins/framework-migration/skills/database-migration/SKILL.md)** | **日本語**

# データベース移行

Sequelize、TypeORM、Prismaなどのデータベーススキーマとデータ移行、ロールバック戦略、ゼロダウンタイムデプロイメントをマスターします。

## このスキルを使用するタイミング

- 異なるORM間の移行
- スキーマ変換の実行
- データベース間でのデータ移動
- ロールバック手順の実装
- ゼロダウンタイムデプロイメント
- データベースバージョンアップグレード
- データモデルのリファクタリング

## ORM移行

### Sequelize移行
```javascript
// migrations/20231201-create-users.js
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      email: {
        type: Sequelize.STRING,
        unique: true,
        allowNull: false
      },
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('users');
  }
};

// 実行: npx sequelize-cli db:migrate
// ロールバック: npx sequelize-cli db:migrate:undo
```

### TypeORM移行
```typescript
// migrations/1701234567-CreateUsers.ts
import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateUsers1701234567 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            type: 'int',
            isPrimary: true,
            isGenerated: true,
            generationStrategy: 'increment'
          },
          {
            name: 'email',
            type: 'varchar',
            isUnique: true
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP'
          }
        ]
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('users');
  }
}

// 実行: npm run typeorm migration:run
// ロールバック: npm run typeorm migration:revert
```

### Prisma移行
```prisma
// schema.prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  createdAt DateTime @default(now())
}

// 移行生成: npx prisma migrate dev --name create_users
// 適用: npx prisma migrate deploy
```

## スキーマ変換

### デフォルト値付きカラムの追加
```javascript
// 安全な移行: デフォルト値でカラムを追加
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'status', {
      type: Sequelize.STRING,
      defaultValue: 'active',
      allowNull: false
    });
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'status');
  }
};
```

### カラムのリネーム（ゼロダウンタイム）
```javascript
// ステップ1: 新しいカラムを追加
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'full_name', {
      type: Sequelize.STRING
    });

    // 古いカラムからデータをコピー
    await queryInterface.sequelize.query(
      'UPDATE users SET full_name = name'
    );
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'full_name');
  }
};

// ステップ2: 新しいカラムを使用するようにアプリケーションを更新

// ステップ3: 古いカラムを削除
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'name');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'name', {
      type: Sequelize.STRING
    });
  }
};
```

### カラムタイプの変更
```javascript
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // 大きなテーブルの場合、複数ステップアプローチを使用

    // 1. 新しいカラムを追加
    await queryInterface.addColumn('users', 'age_new', {
      type: Sequelize.INTEGER
    });

    // 2. データをコピーして変換
    await queryInterface.sequelize.query(`
      UPDATE users
      SET age_new = CAST(age AS INTEGER)
      WHERE age IS NOT NULL
    `);

    // 3. 古いカラムを削除
    await queryInterface.removeColumn('users', 'age');

    // 4. 新しいカラムをリネーム
    await queryInterface.renameColumn('users', 'age_new', 'age');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.changeColumn('users', 'age', {
      type: Sequelize.STRING
    });
  }
};
```

## データ変換

### 複雑なデータ移行
```javascript
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // すべてのレコードを取得
    const [users] = await queryInterface.sequelize.query(
      'SELECT id, address_string FROM users'
    );

    // 各レコードを変換
    for (const user of users) {
      const addressParts = user.address_string.split(',');

      await queryInterface.sequelize.query(
        `UPDATE users
         SET street = :street,
             city = :city,
             state = :state
         WHERE id = :id`,
        {
          replacements: {
            id: user.id,
            street: addressParts[0]?.trim(),
            city: addressParts[1]?.trim(),
            state: addressParts[2]?.trim()
          }
        }
      );
    }

    // 古いカラムを削除
    await queryInterface.removeColumn('users', 'address_string');
  },

  down: async (queryInterface, Sequelize) => {
    // 元のカラムを再構築
    await queryInterface.addColumn('users', 'address_string', {
      type: Sequelize.STRING
    });

    await queryInterface.sequelize.query(`
      UPDATE users
      SET address_string = CONCAT(street, ', ', city, ', ', state)
    `);

    await queryInterface.removeColumn('users', 'street');
    await queryInterface.removeColumn('users', 'city');
    await queryInterface.removeColumn('users', 'state');
  }
};
```

## ロールバック戦略

### トランザクションベースの移行
```javascript
module.exports = {
  up: async (queryInterface, Sequelize) => {
    const transaction = await queryInterface.sequelize.transaction();

    try {
      await queryInterface.addColumn(
        'users',
        'verified',
        { type: Sequelize.BOOLEAN, defaultValue: false },
        { transaction }
      );

      await queryInterface.sequelize.query(
        'UPDATE users SET verified = true WHERE email_verified_at IS NOT NULL',
        { transaction }
      );

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'verified');
  }
};
```

### チェックポイントベースのロールバック
```javascript
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // バックアップテーブルを作成
    await queryInterface.sequelize.query(
      'CREATE TABLE users_backup AS SELECT * FROM users'
    );

    try {
      // 移行を実行
      await queryInterface.addColumn('users', 'new_field', {
        type: Sequelize.STRING
      });

      // 移行を検証
      const [result] = await queryInterface.sequelize.query(
        "SELECT COUNT(*) as count FROM users WHERE new_field IS NULL"
      );

      if (result[0].count > 0) {
        throw new Error('Migration verification failed');
      }

      // バックアップを削除
      await queryInterface.dropTable('users_backup');
    } catch (error) {
      // バックアップから復元
      await queryInterface.sequelize.query('DROP TABLE users');
      await queryInterface.sequelize.query(
        'CREATE TABLE users AS SELECT * FROM users_backup'
      );
      await queryInterface.dropTable('users_backup');
      throw error;
    }
  }
};
```

## ゼロダウンタイム移行

### ブルーグリーンデプロイメント戦略
```javascript
// フェーズ1: 変更を後方互換にする
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // 新しいカラムを追加（古いコードと新しいコードの両方が動作可能）
    await queryInterface.addColumn('users', 'email_new', {
      type: Sequelize.STRING
    });
  }
};

// フェーズ2: 両方のカラムに書き込むコードをデプロイ

// フェーズ3: データをバックフィル
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.sequelize.query(`
      UPDATE users
      SET email_new = email
      WHERE email_new IS NULL
    `);
  }
};

// フェーズ4: 新しいカラムから読み取るコードをデプロイ

// フェーズ5: 古いカラムを削除
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.removeColumn('users', 'email');
  }
};
```

## クロスデータベース移行

### PostgreSQLからMySQLへ
```javascript
// 違いを処理
module.exports = {
  up: async (queryInterface, Sequelize) => {
    const dialectName = queryInterface.sequelize.getDialect();

    if (dialectName === 'mysql') {
      await queryInterface.createTable('users', {
        id: {
          type: Sequelize.INTEGER,
          primaryKey: true,
          autoIncrement: true
        },
        data: {
          type: Sequelize.JSON  // MySQL JSONタイプ
        }
      });
    } else if (dialectName === 'postgres') {
      await queryInterface.createTable('users', {
        id: {
          type: Sequelize.INTEGER,
          primaryKey: true,
          autoIncrement: true
        },
        data: {
          type: Sequelize.JSONB  // PostgreSQL JSONBタイプ
        }
      });
    }
  }
};
```

## リソース

- **references/orm-switching.md**: ORM移行ガイド
- **references/schema-migration.md**: スキーマ変換パターン
- **references/data-transformation.md**: データ移行スクリプト
- **references/rollback-strategies.md**: ロールバック手順
- **assets/schema-migration-template.sql**: SQL移行テンプレート
- **assets/data-migration-script.py**: データ移行ユーティリティ
- **scripts/test-migration.sh**: 移行テストスクリプト

## ベストプラクティス

1. **常にロールバックを提供**: すべてのup()にdown()が必要
2. **移行をテスト**: まずステージングでテスト
3. **トランザクションを使用**: 可能な場合はアトミック移行
4. **まずバックアップ**: 移行前に常にバックアップ
5. **小さな変更**: 小さな段階的ステップに分割
6. **監視**: デプロイメント中のエラーを監視
7. **文書化**: なぜ、どのように説明
8. **冪等性**: 移行は再実行可能であるべき

## 一般的な落とし穴

- ロールバック手順をテストしない
- ダウンタイム戦略なしで破壊的変更を行う
- NULL値の処理を忘れる
- インデックスのパフォーマンスを考慮しない
- 外部キー制約を無視
- 一度に大量のデータを移行
