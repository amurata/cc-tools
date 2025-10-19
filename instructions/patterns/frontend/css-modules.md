# CSS Modules Practical Guide

## Basic Setup and Type Safety

### Next.js 14+ Configuration

```typescript
// next.config.js
const nextConfig = {
  // Enable automatic type generation for CSS Modules
  typescript: {
    ignoreBuildErrors: false,
  },
  webpack: (config) => {
    config.module.rules.push({
      test: /\.module\.(css|scss)$/,
      use: [
        {
          loader: 'css-loader',
          options: {
            modules: {
              localIdentName: process.env.NODE_ENV === 'production'
                ? '[hash:base64:8]' // Production: minified
                : '[path][name]__[local]--[hash:base64:5]', // Development: debuggable
              exportLocalsConvention: 'camelCase',
            },
          },
        },
      ],
    });
    return config;
  },
};
```

### TypeScript Type Definition Auto-generation

```typescript
// typed-css-modules.config.js
module.exports = {
  pattern: 'src/**/*.module.{css,scss}',
  watch: true,
  camelCase: true,
  exportType: 'default',
  nameFormat: '[name]__[local]--[hash:base64:5]',
};

// package.json scripts
{
  "scripts": {
    "css-types": "typed-css-modules -p 'src/**/*.module.{css,scss}' -w",
    "dev": "concurrently \"next dev\" \"npm run css-types\""
  }
}
```

## Advanced Patterns and Implementation

### 1. Dynamic Styling and Theme Integration

```typescript
// styles/Button.module.css
.button {
  /* Theme support with CSS variables */
  background-color: var(--button-bg, #007bff);
  color: var(--button-color, white);
  padding: var(--button-padding, 8px 16px);
  border-radius: var(--button-radius, 4px);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  
  /* Data attribute selectors for state management */
  &[data-variant="primary"] {
    --button-bg: var(--color-primary);
  }
  
  &[data-variant="danger"] {
    --button-bg: var(--color-danger);
  }
  
  &[data-size="small"] {
    --button-padding: 4px 8px;
    font-size: 0.875rem;
  }
  
  &[data-loading="true"] {
    pointer-events: none;
    opacity: 0.7;
    
    &::after {
      content: "";
      position: absolute;
      width: 16px;
      height: 16px;
      border: 2px solid currentColor;
      border-radius: 50%;
      border-top-color: transparent;
      animation: spin 0.6s linear infinite;
    }
  }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Composition API for combining multiple classes */
.button.primary {
  composes: button;
  composes: primary from "./themes.module.css";
}

/* Performance optimization: proper use of will-change */
.button:hover {
  will-change: transform, background-color;
  transform: translateY(-1px);
}

.button:active {
  will-change: auto; /* Reset after animation */
  transform: translateY(0);
}
```

### 2. TypeScript Integration and Utility Functions

```typescript
// utils/cssModules.ts
import { clsx, type ClassValue } from 'clsx';

/**
 * Safely combine CSS Modules class names
 * Handles conditional classes, dynamic classes, and undefined values
 */
export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

/**
 * Type-safe variant generation for CSS Modules
 */
export function createStyleVariants<T extends Record<string, string>>(
  styles: T,
  variants: Record<string, Record<string, string>>
) {
  return (variant: keyof typeof variants, condition = true) => {
    if (!condition) return '';
    return variants[variant as string]
      ?.split(' ')
      .map(className => styles[className] || className)
      .join(' ') || '';
  };
}

// Usage example
// components/Button.tsx
import styles from './Button.module.css';
import { cn, createStyleVariants } from '@/utils/cssModules';

const styleVariants = createStyleVariants(styles, {
  primary: 'button primary',
  secondary: 'button secondary',
  danger: 'button danger',
});

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  className?: string;
}

export function Button({ 
  variant = 'primary', 
  size = 'medium',
  loading = false,
  className,
  ...props 
}: ButtonProps) {
  return (
    <button
      className={cn(
        styles.button,
        styleVariants(variant),
        className
      )}
      data-variant={variant}
      data-size={size}
      data-loading={loading}
      disabled={loading}
      {...props}
    />
  );
}
```

### 3. SSR/SSG Optimization and Critical CSS

```typescript
// utils/criticalCss.ts
import { readFileSync } from 'fs';
import { resolve } from 'path';

/**
 * Extract and optimize critical CSS
 * Run at build time to improve initial render performance
 */
export function extractCriticalCss(moduleFiles: string[]) {
  const critical = new Set<string>();
  
  moduleFiles.forEach(file => {
    const content = readFileSync(resolve(process.cwd(), file), 'utf-8');
    // Extract only selectors needed for first view
    const criticalSelectors = content.match(
      /\.(button|header|nav|hero|container)[^{]*{[^}]*}/g
    );
    
    if (criticalSelectors) {
      criticalSelectors.forEach(selector => critical.add(selector));
    }
  });
  
  return Array.from(critical).join('\n');
}

// pages/_document.tsx usage
import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  const criticalCss = process.env.NODE_ENV === 'production' 
    ? extractCriticalCss(['styles/*.module.css'])
    : '';
    
  return (
    <Html>
      <Head>
        {criticalCss && (
          <style 
            dangerouslySetInnerHTML={{ __html: criticalCss }}
            data-critical="true"
          />
        )}
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

## Performance Optimization

### 1. Bundle Size Reduction

```javascript
// webpack.config.js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');

module.exports = {
  optimization: {
    minimizer: [
      new CssMinimizerPlugin({
        minimizerOptions: {
          preset: [
            'default',
            {
              // Remove unused CSS variables
              discardUnused: { fontFace: false },
              // Merge duplicate rules
              mergeRules: true,
              // Optimize selectors
              normalizeWhitespace: true,
            },
          ],
        },
      }),
    ],
    // Tree shaking for CSS Modules
    sideEffects: false,
  },
  module: {
    rules: [
      {
        test: /\.module\.css$/,
        use: [
          MiniCssExtractPlugin.loader,
          {
            loader: 'css-loader',
            options: {
              modules: {
                // Generate short class names in production
                localIdentName: '[hash:base64:5]',
                // Remove unused exports
                exportOnlyLocals: false,
              },
            },
          },
          {
            loader: 'postcss-loader',
            options: {
              postcssOptions: {
                plugins: [
                  ['postcss-preset-env', { stage: 3 }],
                  ['postcss-sort-media-queries'],
                  ['postcss-combine-duplicated-selectors'],
                ],
              },
            },
          },
        ],
      },
    ],
  },
};
```

### 2. Runtime Performance

```typescript
// hooks/useLazyStyles.ts
import { useEffect, useState } from 'react';

/**
 * Lazy load CSS Modules
 * Load large stylesheets only when needed
 */
export function useLazyStyles(
  importFn: () => Promise<{ default: Record<string, string> }>
) {
  const [styles, setStyles] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    let cancelled = false;
    
    importFn().then(module => {
      if (!cancelled) {
        setStyles(module.default);
        setLoading(false);
      }
    });
    
    return () => { cancelled = true; };
  }, []);
  
  return { styles, loading };
}

// Usage example
function HeavyComponent() {
  const { styles, loading } = useLazyStyles(
    () => import('./HeavyComponent.module.css')
  );
  
  if (loading) return <Skeleton />;
  
  return <div className={styles.container}>...</div>;
}
```

## Troubleshooting

### 1. Class Name Mismatch in Production

```typescript
// Problem: Different class names in development and production
// Solution: Consistent hash generation configuration

// css-loader.config.js
const getLocalIdent = (context, localIdentName, localName) => {
  const hash = crypto
    .createHash('md5')
    .update(context.resourcePath + localName)
    .digest('base64')
    .slice(0, 5);
    
  return `${localName}_${hash}`;
};

module.exports = {
  modules: {
    getLocalIdent, // Custom function for consistency
  },
};
```

### 2. Avoiding Hydration Errors

```typescript
// Problem: SSR/CSR class name mismatch
// Solution: Isomorphic implementation

import { useIsomorphicLayoutEffect } from '@/hooks/useIsomorphic';

function DynamicStyledComponent() {
  const [mounted, setMounted] = useState(false);
  
  useIsomorphicLayoutEffect(() => {
    setMounted(true);
  }, []);
  
  // Client-side only style application
  const dynamicClass = mounted ? styles.clientOnly : '';
  
  return <div className={cn(styles.base, dynamicClass)} />;
}
```

### 3. CSS Modules and Third-party Library Integration

```css
/* Coexisting with global styles */
.container {
  /* Local scope */
  padding: 1rem;
  
  /* Override global classes */
  :global(.third-party-class) {
    margin: 0;
    padding: inherit;
  }
  
  /* Control global styles in children */
  :global {
    .react-select__control {
      border-color: var(--border-color);
    }
    
    .react-select__menu {
      z-index: var(--z-index-dropdown);
    }
  }
}
```

## Best Practices

1. **Naming Convention**: Use BEM-style naming for clear component structure
2. **Composition**: Reuse common styles for better maintainability
3. **CSS Variables**: Unify theme and responsive handling
4. **PostCSS**: Automate prefixing and optimization
5. **Type Safety**: TypeScript integration for better developer experience
6. **Performance**: Utilize Critical CSS and lazy loading
7. **Testing**: Snapshot testing to detect style changes