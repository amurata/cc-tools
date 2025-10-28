---
name: angular-migration
description: ハイブリッドモード、段階的コンポーネント書き換え、依存性注入更新を使用してAngularJSからAngularへ移行します。AngularJSアプリケーションのアップグレード、フレームワーク移行の計画、またはレガシーAngularコードのモダナイゼーション時に使用します。
---

> **[English](../../../../../plugins/framework-migration/skills/angular-migration/SKILL.md)** | **日本語**

# Angular移行

ハイブリッドアプリ、コンポーネント変換、依存性注入の変更、ルーティング移行を含む、AngularJSからAngularへの移行をマスターします。

## このスキルを使用するタイミング

- AngularJS（1.x）アプリケーションをAngular（2+）へ移行
- ハイブリッドAngularJS/Angularアプリケーションの実行
- ディレクティブをコンポーネントに変換
- 依存性注入のモダナイゼーション
- ルーティングシステムの移行
- 最新Angularバージョンへの更新
- Angularベストプラクティスの実装

## 移行戦略

### 1. ビッグバン（完全な書き換え）
- Angularでアプリ全体を書き直す
- 並行開発
- 一度に切り替える
- **最適**: 小規模アプリ、グリーンフィールドプロジェクト

### 2. 段階的（ハイブリッドアプローチ）
- AngularJSとAngularを並行実行
- 機能ごとに移行
- 相互運用のためのngUpgrade
- **最適**: 大規模アプリ、継続的デリバリー

### 3. バーティカルスライス
- 1つの機能を完全に移行
- Angularで新機能、AngularJSで既存を維持
- 段階的に置き換え
- **最適**: 中規模アプリ、明確な機能

## ハイブリッドアプリのセットアップ

```typescript
// main.ts - ハイブリッドアプリをブートストラップ
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { UpgradeModule } from '@angular/upgrade/static';
import { AppModule } from './app/app.module';

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .then(platformRef => {
    const upgrade = platformRef.injector.get(UpgradeModule);
    // AngularJSをブートストラップ
    upgrade.bootstrap(document.body, ['myAngularJSApp'], { strictDi: true });
  });
```

```typescript
// app.module.ts
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { UpgradeModule } from '@angular/upgrade/static';

@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule
  ]
})
export class AppModule {
  constructor(private upgrade: UpgradeModule) {}

  ngDoBootstrap() {
    // main.tsで手動でブートストラップ
  }
}
```

## コンポーネント移行

### AngularJSコントローラー → Angularコンポーネント
```javascript
// Before: AngularJSコントローラー
angular.module('myApp').controller('UserController', function($scope, UserService) {
  $scope.user = {};

  $scope.loadUser = function(id) {
    UserService.getUser(id).then(function(user) {
      $scope.user = user;
    });
  };

  $scope.saveUser = function() {
    UserService.saveUser($scope.user);
  };
});
```

```typescript
// After: Angularコンポーネント
import { Component, OnInit } from '@angular/core';
import { UserService } from './user.service';

@Component({
  selector: 'app-user',
  template: `
    <div>
      <h2>{{ user.name }}</h2>
      <button (click)="saveUser()">Save</button>
    </div>
  `
})
export class UserComponent implements OnInit {
  user: any = {};

  constructor(private userService: UserService) {}

  ngOnInit() {
    this.loadUser(1);
  }

  loadUser(id: number) {
    this.userService.getUser(id).subscribe(user => {
      this.user = user;
    });
  }

  saveUser() {
    this.userService.saveUser(this.user);
  }
}
```

### AngularJSディレクティブ → Angularコンポーネント
```javascript
// Before: AngularJSディレクティブ
angular.module('myApp').directive('userCard', function() {
  return {
    restrict: 'E',
    scope: {
      user: '=',
      onDelete: '&'
    },
    template: `
      <div class="card">
        <h3>{{ user.name }}</h3>
        <button ng-click="onDelete()">Delete</button>
      </div>
    `
  };
});
```

```typescript
// After: Angularコンポーネント
import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-user-card',
  template: `
    <div class="card">
      <h3>{{ user.name }}</h3>
      <button (click)="delete.emit()">Delete</button>
    </div>
  `
})
export class UserCardComponent {
  @Input() user: any;
  @Output() delete = new EventEmitter<void>();
}

// 使用法: <app-user-card [user]="user" (delete)="handleDelete()"></app-user-card>
```

## サービス移行

```javascript
// Before: AngularJSサービス
angular.module('myApp').factory('UserService', function($http) {
  return {
    getUser: function(id) {
      return $http.get('/api/users/' + id);
    },
    saveUser: function(user) {
      return $http.post('/api/users', user);
    }
  };
});
```

```typescript
// After: Angularサービス
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private http: HttpClient) {}

  getUser(id: number): Observable<any> {
    return this.http.get(`/api/users/${id}`);
  }

  saveUser(user: any): Observable<any> {
    return this.http.post('/api/users', user);
  }
}
```

## 依存性注入の変更

### ダウングレード Angular → AngularJS
```typescript
// Angularサービス
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class NewService {
  getData() {
    return 'data from Angular';
  }
}

// AngularJSで利用可能にする
import { downgradeInjectable } from '@angular/upgrade/static';

angular.module('myApp')
  .factory('newService', downgradeInjectable(NewService));

// AngularJSで使用
angular.module('myApp').controller('OldController', function(newService) {
  console.log(newService.getData());
});
```

### アップグレード AngularJS → Angular
```typescript
// AngularJSサービス
angular.module('myApp').factory('oldService', function() {
  return {
    getData: function() {
      return 'data from AngularJS';
    }
  };
});

// Angularで利用可能にする
import { InjectionToken } from '@angular/core';

export const OLD_SERVICE = new InjectionToken<any>('oldService');

@NgModule({
  providers: [
    {
      provide: OLD_SERVICE,
      useFactory: (i: any) => i.get('oldService'),
      deps: ['$injector']
    }
  ]
})

// Angularで使用
@Component({...})
export class NewComponent {
  constructor(@Inject(OLD_SERVICE) private oldService: any) {
    console.log(this.oldService.getData());
  }
}
```

## ルーティング移行

```javascript
// Before: AngularJSルーティング
angular.module('myApp').config(function($routeProvider) {
  $routeProvider
    .when('/users', {
      template: '<user-list></user-list>'
    })
    .when('/users/:id', {
      template: '<user-detail></user-detail>'
    });
});
```

```typescript
// After: Angularルーティング
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  { path: 'users', component: UserListComponent },
  { path: 'users/:id', component: UserDetailComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
```

## フォーム移行

```html
<!-- Before: AngularJS -->
<form name="userForm" ng-submit="saveUser()">
  <input type="text" ng-model="user.name" required>
  <input type="email" ng-model="user.email" required>
  <button ng-disabled="userForm.$invalid">Save</button>
</form>
```

```typescript
// After: Angular (テンプレート駆動)
@Component({
  template: `
    <form #userForm="ngForm" (ngSubmit)="saveUser()">
      <input type="text" [(ngModel)]="user.name" name="name" required>
      <input type="email" [(ngModel)]="user.email" name="email" required>
      <button [disabled]="userForm.invalid">Save</button>
    </form>
  `
})

// またはリアクティブフォーム（推奨）
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

@Component({
  template: `
    <form [formGroup]="userForm" (ngSubmit)="saveUser()">
      <input formControlName="name">
      <input formControlName="email">
      <button [disabled]="userForm.invalid">Save</button>
    </form>
  `
})
export class UserFormComponent {
  userForm: FormGroup;

  constructor(private fb: FormBuilder) {
    this.userForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]]
    });
  }

  saveUser() {
    console.log(this.userForm.value);
  }
}
```

## 移行タイムライン

```
フェーズ1: セットアップ（1-2週間）
- Angular CLIをインストール
- ハイブリッドアプリをセットアップ
- ビルドツールを設定
- テストをセットアップ

フェーズ2: インフラストラクチャ（2-4週間）
- サービスを移行
- ユーティリティを移行
- ルーティングをセットアップ
- 共有コンポーネントを移行

フェーズ3: 機能移行（様々）
- 機能ごとに移行
- 徹底的にテスト
- 段階的にデプロイ

フェーズ4: クリーンアップ（1-2週間）
- AngularJSコードを削除
- ngUpgradeを削除
- バンドルを最適化
- 最終テスト
```

## リソース

- **references/hybrid-mode.md**: ハイブリッドアプリパターン
- **references/component-migration.md**: コンポーネント変換ガイド
- **references/dependency-injection.md**: DI移行戦略
- **references/routing.md**: ルーティング移行
- **assets/hybrid-bootstrap.ts**: ハイブリッドアプリテンプレート
- **assets/migration-timeline.md**: プロジェクト計画
- **scripts/analyze-angular-app.sh**: アプリ分析スクリプト

## ベストプラクティス

1. **サービスから開始**: サービスを最初に移行（より簡単）
2. **段階的アプローチ**: 機能ごとの移行
3. **継続的にテスト**: 各ステップでテスト
4. **TypeScriptを使用**: 早期にTypeScriptに移行
5. **スタイルガイドに従う**: 初日からAngularスタイルガイド
6. **後で最適化**: まず動作させ、次に最適化
7. **文書化**: 移行ノートを保持

## 一般的な落とし穴

- ハイブリッドアプリを正しくセットアップしない
- ロジックの前にUIを移行
- 変更検出の違いを無視
- スコープを適切に処理しない
- パターンの混在（AngularJS + Angular）
- 不十分なテスト
