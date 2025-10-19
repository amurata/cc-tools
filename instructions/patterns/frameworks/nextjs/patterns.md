# Next.js パターン

App Router (Next.js 13+) を活用したフルスタックReactパターン。

## App Router 構造

### ディレクトリ構成
```
app/
├── layout.tsx          # ルートレイアウト
├── page.tsx           # ホームページ
├── api/               # APIルート
│   └── users/
│       └── route.ts
├── (auth)/            # ルートグループ
│   ├── login/
│   └── register/
└── dashboard/
    ├── layout.tsx     # ネストレイアウト
    └── page.tsx
```

## サーバーコンポーネント

### データフェッチング
```tsx
// app/products/page.tsx - デフォルトでサーバーコンポーネント
async function ProductsPage() {
  // サーバーサイドで直接データ取得
  const products = await prisma.product.findMany();
  
  return (
    <div>
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

### Streaming SSR
```tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <>
      <Header />
      <Suspense fallback={<ProductsSkeleton />}>
        <Products />
      </Suspense>
    </>
  );
}

async function Products() {
  const products = await fetchProducts(); // 遅い処理
  return <ProductList products={products} />;
}
```

## クライアントコンポーネント

### インタラクティブ機能
```tsx
'use client';

import { useState } from 'react';

export function SearchBar() {
  const [query, setQuery] = useState('');
  
  return (
    <input
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

## Route Handlers

### API Routes
```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const users = await getUsers();
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await createUser(body);
  return NextResponse.json(user, { status: 201 });
}
```

### Dynamic Routes
```typescript
// app/api/users/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const user = await getUser(params.id);
  if (!user) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
  return NextResponse.json(user);
}
```

## メタデータ

### 静的メタデータ
```tsx
// app/about/page.tsx
export const metadata = {
  title: 'About Us',
  description: 'Learn more about our company',
  openGraph: {
    title: 'About Us',
    description: 'Learn more about our company',
    images: ['/og-image.jpg'],
  },
};
```

### 動的メタデータ
```tsx
export async function generateMetadata({ params }) {
  const product = await getProduct(params.id);
  
  return {
    title: product.name,
    description: product.description,
    openGraph: {
      images: [product.image],
    },
  };
}
```

## パフォーマンス最適化

### 画像最適化
```tsx
import Image from 'next/image';

export function ProductImage({ src, alt }) {
  return (
    <Image
      src={src}
      alt={alt}
      width={500}
      height={300}
      loading="lazy"
      placeholder="blur"
      blurDataURL={shimmer}
    />
  );
}
```

### フォント最適化
```tsx
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
});

export default function Layout({ children }) {
  return (
    <html className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

## データ管理

### Server Actions
```tsx
// app/actions.ts
'use server';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  const content = formData.get('content');
  
  await prisma.post.create({
    data: { title, content }
  });
  
  revalidatePath('/posts');
}

// app/posts/new/page.tsx
import { createPost } from '@/app/actions';

export default function NewPost() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

## キャッシング

### データキャッシュ
```typescript
// 自動キャッシュ（fetch）
const data = await fetch('https://api.example.com/data', {
  cache: 'force-cache', // デフォルト
  // cache: 'no-store',  // キャッシュ無効
  // next: { revalidate: 60 } // 60秒後に再検証
});

// unstable_cache（関数キャッシュ）
import { unstable_cache } from 'next/cache';

const getCachedUser = unstable_cache(
  async (id) => getUser(id),
  ['user'],
  { revalidate: 3600 }
);
```

## チェックリスト
- [ ] App Router使用
- [ ] サーバー/クライアント適切分離
- [ ] Server Actions活用
- [ ] 画像・フォント最適化
- [ ] メタデータ設定
- [ ] キャッシュ戦略
- [ ] Streaming SSR実装