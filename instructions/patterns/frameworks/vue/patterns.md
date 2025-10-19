# Vue.js パターン

Vue 3 Composition APIを活用したモダンVueパターン。

## Composition API

### setup 関数
```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

// リアクティブな状態
const count = ref(0);
const doubled = computed(() => count.value * 2);

// メソッド
const increment = () => {
  count.value++;
};

// ライフサイクル
onMounted(() => {
  console.log('Component mounted');
});
</script>

<template>
  <button @click="increment">
    Count: {{ count }} (Doubled: {{ doubled }})
  </button>
</template>
```

## コンポーザブル

### カスタムコンポーザブル
```typescript
// composables/useUser.ts
import { ref, computed } from 'vue';

export function useUser() {
  const user = ref(null);
  const isLoggedIn = computed(() => !!user.value);
  
  const login = async (credentials) => {
    const response = await api.login(credentials);
    user.value = response.data;
  };
  
  const logout = () => {
    user.value = null;
  };
  
  return {
    user: readonly(user),
    isLoggedIn,
    login,
    logout
  };
}

// 使用
const { user, isLoggedIn, login } = useUser();
```

### フェッチコンポーザブル
```typescript
// composables/useFetch.ts
export function useFetch<T>(url: string) {
  const data = ref<T | null>(null);
  const error = ref<Error | null>(null);
  const loading = ref(true);
  
  const fetchData = async () => {
    try {
      loading.value = true;
      const response = await fetch(url);
      data.value = await response.json();
    } catch (e) {
      error.value = e as Error;
    } finally {
      loading.value = false;
    }
  };
  
  onMounted(fetchData);
  
  return { data, error, loading, refetch: fetchData };
}
```

## 状態管理 (Pinia)

### ストア定義
```typescript
// stores/counter.ts
import { defineStore } from 'pinia';

export const useCounterStore = defineStore('counter', () => {
  // 状態
  const count = ref(0);
  
  // ゲッター
  const doubled = computed(() => count.value * 2);
  
  // アクション
  function increment() {
    count.value++;
  }
  
  return { count, doubled, increment };
});

// 使用
const store = useCounterStore();
store.increment();
```

## コンポーネントパターン

### Props とEmits
```vue
<script setup lang="ts">
interface Props {
  title: string;
  count?: number;
}

const props = withDefaults(defineProps<Props>(), {
  count: 0
});

const emit = defineEmits<{
  update: [value: number];
  delete: [];
}>();

const handleClick = () => {
  emit('update', props.count + 1);
};
</script>
```

### スロット
```vue
<!-- BaseCard.vue -->
<template>
  <div class="card">
    <div class="card-header">
      <slot name="header" />
    </div>
    <div class="card-body">
      <slot />
    </div>
    <div class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<!-- 使用 -->
<BaseCard>
  <template #header>
    <h2>Title</h2>
  </template>
  
  Main content
  
  <template #footer>
    <button>Action</button>
  </template>
</BaseCard>
```

## リアクティビティ

### watchとwatchEffect
```typescript
// watch: 特定の値を監視
watch(count, (newValue, oldValue) => {
  console.log(`Count changed: ${oldValue} -> ${newValue}`);
});

// watchEffect: 依存関係を自動追跡
watchEffect(() => {
  console.log(`The count is ${count.value}`);
});

// immediate と deep オプション
watch(
  user,
  (newUser) => {
    saveToLocalStorage(newUser);
  },
  { immediate: true, deep: true }
);
```

### toRef と toRefs
```typescript
// プロパティを個別のrefに変換
const state = reactive({ count: 0, name: 'Vue' });
const count = toRef(state, 'count');

// すべてのプロパティをrefに変換
const { count, name } = toRefs(state);
```

## パフォーマンス最適化

### 動的インポート
```typescript
// ルートレベルの遅延読み込み
const UserProfile = () => import('./views/UserProfile.vue');

// コンポーネントレベル
const AsyncComponent = defineAsyncComponent(() =>
  import('./components/AsyncComponent.vue')
);
```

### v-memo ディレクティブ
```vue
<template>
  <!-- 依存値が変わらない限り再レンダリングスキップ -->
  <div v-for="item in list" :key="item.id" v-memo="[item.id, item.name]">
    {{ expensiveOperation(item) }}
  </div>
</template>
```

## TypeScript統合

### 型定義
```typescript
// types/user.ts
export interface User {
  id: number;
  name: string;
  email: string;
}

// コンポーネントで使用
const user = ref<User | null>(null);
const users = ref<User[]>([]);
```

## チェックリスト
- [ ] Composition API使用
- [ ] コンポーザブル活用
- [ ] Pinia状態管理
- [ ] TypeScript統合
- [ ] Props/Emits型定義
- [ ] パフォーマンス最適化
- [ ] 適切なリアクティビティ