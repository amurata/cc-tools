# Emotion Practical Guide v11

## Setup and Optimized Configuration

### Next.js 14+ App Router Complete Support

```typescript
// next.config.js
module.exports = {
  compiler: {
    emotion: {
      sourceMap: process.env.NODE_ENV !== 'production',
      autoLabel: 'dev-only',
      labelFormat: '[local]',
      importMap: {
        '@emotion/react': {
          styled: {
            canonicalImport: ['@emotion/styled', 'default'],
          },
          Global: {
            canonicalImport: ['@emotion/react', 'Global'],
          },
        },
      },
    },
  },
  experimental: {
    emotion: {
      extractStatic: true,
      ssr: true,
    },
  },
};

// app/emotion-registry.tsx
'use client';

import { CacheProvider } from '@emotion/react';
import createCache from '@emotion/cache';
import { useServerInsertedHTML } from 'next/navigation';
import { useState } from 'react';

export default function EmotionRegistry({
  children,
}: {
  children: React.ReactNode;
}) {
  const [cache] = useState(() =>
    createCache({
      key: 'emotion',
      prepend: true,
      speedy: process.env.NODE_ENV === 'production',
    })
  );

  useServerInsertedHTML(() => {
    const dataEmotionAttribute = cache.key;
    const dataEmotionValues = Object.keys(cache.inserted)
      .filter((key) => typeof cache.inserted[key] !== 'boolean')
      .map((key) => cache.inserted[key]);

    if (dataEmotionValues.length === 0) {
      return null;
    }

    return (
      <style
        data-emotion={`${dataEmotionAttribute} ${Object.keys(cache.inserted).join(' ')}`}
        dangerouslySetInnerHTML={{
          __html: dataEmotionValues.join(''),
        }}
      />
    );
  });

  return <CacheProvider value={cache}>{children}</CacheProvider>;
}

// app/layout.tsx
import EmotionRegistry from './emotion-registry';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <EmotionRegistry>{children}</EmotionRegistry>
      </body>
    </html>
  );
}
```

### Complete TypeScript Integration

```typescript
// emotion.d.ts
import '@emotion/react';

declare module '@emotion/react' {
  export interface Theme {
    colors: {
      primary: string;
      primaryLight: string;
      primaryDark: string;
      secondary: string;
      secondaryLight: string;
      secondaryDark: string;
      error: string;
      warning: string;
      info: string;
      success: string;
      text: {
        primary: string;
        secondary: string;
        disabled: string;
        hint: string;
      };
      background: {
        default: string;
        paper: string;
        elevated: string;
      };
      divider: string;
    };
    typography: {
      fontFamily: {
        sans: string;
        serif: string;
        mono: string;
      };
      fontSize: {
        xs: string;
        sm: string;
        base: string;
        lg: string;
        xl: string;
        '2xl': string;
        '3xl': string;
        '4xl': string;
      };
      fontWeight: {
        thin: number;
        light: number;
        normal: number;
        medium: number;
        semibold: number;
        bold: number;
      };
      lineHeight: {
        none: number;
        tight: number;
        snug: number;
        normal: number;
        relaxed: number;
        loose: number;
      };
    };
    spacing: {
      0: string;
      1: string;
      2: string;
      3: string;
      4: string;
      5: string;
      6: string;
      8: string;
      10: string;
      12: string;
      16: string;
      20: string;
      24: string;
      32: string;
    };
    breakpoints: {
      sm: string;
      md: string;
      lg: string;
      xl: string;
      '2xl': string;
    };
    radii: {
      none: string;
      sm: string;
      default: string;
      md: string;
      lg: string;
      xl: string;
      full: string;
    };
    shadows: {
      sm: string;
      default: string;
      md: string;
      lg: string;
      xl: string;
      '2xl': string;
      inner: string;
      none: string;
    };
    transitions: {
      fast: string;
      normal: string;
      slow: string;
      easing: {
        easeInOut: string;
        easeOut: string;
        easeIn: string;
        sharp: string;
      };
    };
    zIndices: {
      hide: number;
      auto: string;
      base: number;
      docked: number;
      dropdown: number;
      sticky: number;
      banner: number;
      overlay: number;
      modal: number;
      popover: number;
      skipLink: number;
      toast: number;
      tooltip: number;
    };
  }
}
```

## Advanced Styling Patterns

### 1. css prop vs styled API Usage

```typescript
/** @jsxImportSource @emotion/react */
import { css, Theme } from '@emotion/react';
import styled from '@emotion/styled';

// 1. css prop pattern (for dynamic styles)
interface DynamicBoxProps {
  color?: string;
  size?: 'small' | 'medium' | 'large';
  isActive?: boolean;
}

const dynamicBoxStyles = (theme: Theme, props: DynamicBoxProps) => css`
  padding: ${theme.spacing[props.size === 'small' ? 2 : props.size === 'large' ? 6 : 4]};
  background-color: ${props.isActive ? theme.colors.primary : theme.colors.background.paper};
  color: ${props.color || theme.colors.text.primary};
  border-radius: ${theme.radii.md};
  transition: ${theme.transitions.normal};
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: ${theme.shadows.lg};
  }
  
  /* Media query mixin */
  ${theme.breakpoints.md} {
    padding: ${theme.spacing[8]};
  }
`;

export function DynamicBox({ color, size = 'medium', isActive, children }: DynamicBoxProps & { children: React.ReactNode }) {
  return (
    <div css={(theme) => dynamicBoxStyles(theme, { color, size, isActive })}>
      {children}
    </div>
  );
}

// 2. styled API pattern (for static components)
const StyledCard = styled.div<{ $elevated?: boolean }>`
  background: ${({ theme }) => theme.colors.background.paper};
  border-radius: ${({ theme }) => theme.radii.lg};
  padding: ${({ theme }) => theme.spacing[4]};
  box-shadow: ${({ theme, $elevated }) => 
    $elevated ? theme.shadows.xl : theme.shadows.md};
  transition: ${({ theme }) => theme.transitions.normal};
  
  &:hover {
    box-shadow: ${({ theme }) => theme.shadows['2xl']};
  }
`;

// 3. Composite pattern (maximum flexibility)
const BaseButton = styled.button<{ $variant?: 'primary' | 'secondary' }>`
  /* Base styles */
  font-family: ${({ theme }) => theme.typography.fontFamily.sans};
  font-weight: ${({ theme }) => theme.typography.fontWeight.medium};
  border-radius: ${({ theme }) => theme.radii.default};
  transition: ${({ theme }) => theme.transitions.fast};
  cursor: pointer;
  border: none;
  outline: none;
  
  /* Variant styles */
  ${({ theme, $variant }) => {
    const styles = {
      primary: css`
        background: ${theme.colors.primary};
        color: white;
        &:hover {
          background: ${theme.colors.primaryDark};
        }
      `,
      secondary: css`
        background: transparent;
        color: ${theme.colors.primary};
        border: 2px solid ${theme.colors.primary};
        &:hover {
          background: ${theme.colors.primary};
          color: white;
        }
      `,
    };
    return styles[$variant || 'primary'];
  }}
`;

// Dynamic extension
export function Button({ loading, ...props }: any) {
  return (
    <BaseButton
      {...props}
      css={loading && css`
        opacity: 0.7;
        pointer-events: none;
        position: relative;
        
        &::after {
          content: '';
          position: absolute;
          width: 16px;
          height: 16px;
          top: 50%;
          left: 50%;
          margin: -8px 0 0 -8px;
          border: 2px solid currentColor;
          border-radius: 50%;
          border-top-color: transparent;
          animation: spin 0.6s linear infinite;
        }
        
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}
    />
  );
}
```

### 2. High-Performance Selectors and Caching

```typescript
// utils/emotion-utils.ts
import { css, SerializedStyles, Theme } from '@emotion/react';
import createCache from '@emotion/cache';
import weakMemoize from '@emotion/weak-memoize';

// Selector caching
const selectorCache = new Map<string, SerializedStyles>();

export const cachedSelector = (key: string, styles: SerializedStyles) => {
  if (!selectorCache.has(key)) {
    selectorCache.set(key, styles);
  }
  return selectorCache.get(key)!;
};

// Media query helpers
export const mq = weakMemoize((breakpoints: Theme['breakpoints']) => ({
  sm: `@media (min-width: ${breakpoints.sm})`,
  md: `@media (min-width: ${breakpoints.md})`,
  lg: `@media (min-width: ${breakpoints.lg})`,
  xl: `@media (min-width: ${breakpoints.xl})`,
  '2xl': `@media (min-width: ${breakpoints['2xl']})`,
  
  // Custom queries
  hover: '@media (hover: hover)',
  touch: '@media (hover: none)',
  motion: '@media (prefers-reduced-motion: no-preference)',
  dark: '@media (prefers-color-scheme: dark)',
  print: '@media print',
}));

// Conditional style helper
export const conditionalStyles = <P extends object>(
  conditions: Array<[boolean | ((props: P) => boolean), SerializedStyles | string]>
) => (props: P) => css`
  ${conditions
    .filter(([condition]) => 
      typeof condition === 'function' ? condition(props) : condition
    )
    .map(([, styles]) => styles)}
`;

// Variant mapping
export const createVariants = <V extends string>(
  variants: Record<V, SerializedStyles | ((theme: Theme) => SerializedStyles)>
) => variants;

// Usage example
const buttonVariants = createVariants({
  primary: (theme: Theme) => css`
    background: ${theme.colors.primary};
    color: white;
    
    &:hover {
      background: ${theme.colors.primaryDark};
    }
  `,
  secondary: (theme: Theme) => css`
    background: transparent;
    color: ${theme.colors.primary};
    border: 2px solid ${theme.colors.primary};
    
    &:hover {
      background: ${theme.colors.primary}10;
    }
  `,
  danger: (theme: Theme) => css`
    background: ${theme.colors.error};
    color: white;
    
    &:hover {
      filter: brightness(0.9);
    }
  `,
});
```

### 3. Advanced Theme and Context Management

```typescript
// contexts/ThemeContext.tsx
import { ThemeProvider as EmotionThemeProvider, Global, css, Theme } from '@emotion/react';
import { createContext, useContext, useState, useEffect, useMemo } from 'react';

const lightTheme: Theme = {
  // ... theme definition
};

const darkTheme: Theme = {
  // ... theme definition
};

interface ThemeContextValue {
  mode: 'light' | 'dark';
  toggleTheme: () => void;
  setTheme: (mode: 'light' | 'dark') => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export const useThemeMode = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useThemeMode must be used within ThemeProvider');
  }
  return context;
};

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<'light' | 'dark'>('light');
  
  useEffect(() => {
    // Sync with localStorage and system preference
    const stored = localStorage.getItem('theme-mode') as 'light' | 'dark' | null;
    const systemPreference = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    setMode(stored || (systemPreference ? 'dark' : 'light'));
    
    // Real-time change monitoring
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = (e: MediaQueryListEvent) => {
      if (!localStorage.getItem('theme-mode')) {
        setMode(e.matches ? 'dark' : 'light');
      }
    };
    
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, []);
  
  const toggleTheme = () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    localStorage.setItem('theme-mode', newMode);
    
    // Fire custom event
    window.dispatchEvent(new CustomEvent('theme-change', { detail: newMode }));
  };
  
  const theme = useMemo(
    () => (mode === 'light' ? lightTheme : darkTheme),
    [mode]
  );
  
  const globalStyles = useMemo(
    () => css`
      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      
      html {
        font-size: 16px;
        font-family: ${theme.typography.fontFamily.sans};
        color: ${theme.colors.text.primary};
        background: ${theme.colors.background.default};
        transition: ${theme.transitions.normal};
        
        /* Smooth scrolling */
        scroll-behavior: smooth;
        
        /* Disable tap highlight */
        -webkit-tap-highlight-color: transparent;
      }
      
      /* Focus styles */
      :focus-visible {
        outline: 2px solid ${theme.colors.primary};
        outline-offset: 2px;
      }
      
      /* Scrollbar styling */
      ::-webkit-scrollbar {
        width: 12px;
        height: 12px;
      }
      
      ::-webkit-scrollbar-track {
        background: ${theme.colors.background.paper};
      }
      
      ::-webkit-scrollbar-thumb {
        background: ${theme.colors.text.disabled};
        border-radius: ${theme.radii.full};
        
        &:hover {
          background: ${theme.colors.text.secondary};
        }
      }
      
      /* Animation settings */
      @media (prefers-reduced-motion: reduce) {
        *,
        *::before,
        *::after {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          transition-duration: 0.01ms !important;
        }
      }
    `,
    [theme]
  );
  
  return (
    <ThemeContext.Provider value={{ mode, toggleTheme, setTheme: setMode }}>
      <EmotionThemeProvider theme={theme}>
        <Global styles={globalStyles} />
        {children}
      </EmotionThemeProvider>
    </ThemeContext.Provider>
  );
}
```

## Performance Optimization

### 1. Runtime Minimization and Bundle Optimization

```javascript
// webpack.config.js
module.exports = {
  resolve: {
    alias: {
      // Use lightweight version in production
      '@emotion/react': process.env.NODE_ENV === 'production' 
        ? '@emotion/react/dist/emotion-react.cjs.prod.js'
        : '@emotion/react',
    },
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx)$/,
        use: [
          {
            loader: '@emotion/babel-plugin',
            options: {
              sourceMap: process.env.NODE_ENV !== 'production',
              autoLabel: 'dev-only',
              labelFormat: '[local]',
              cssPropOptimization: true,
            },
          },
        ],
      },
    ],
  },
  plugins: [
    // Emotion static extraction
    new (require('@emotion/babel-plugin-extract-static'))({
      outputDir: './static-styles',
      filename: '[name].[hash].css',
    }),
  ],
};
```

### 2. Dynamic Style Optimization

```typescript
// hooks/useOptimizedStyles.ts
import { useLayoutEffect, useRef, useState } from 'react';
import { css, SerializedStyles } from '@emotion/react';

export function useOptimizedStyles<T extends object>(
  styleFactory: (props: T) => SerializedStyles,
  deps: T
): SerializedStyles {
  const [styles, setStyles] = useState(() => styleFactory(deps));
  const prevDepsRef = useRef(deps);
  
  useLayoutEffect(() => {
    // Deep comparison to prevent unnecessary recalculation
    if (!deepEqual(prevDepsRef.current, deps)) {
      setStyles(styleFactory(deps));
      prevDepsRef.current = deps;
    }
  }, [deps, styleFactory]);
  
  return styles;
}

// Virtual stylesheet for runtime performance
export function createVirtualStyleSheet() {
  const styleMap = new Map<string, string>();
  let updateScheduled = false;
  const subscribers = new Set<() => void>();
  
  const scheduleUpdate = () => {
    if (!updateScheduled) {
      updateScheduled = true;
      requestAnimationFrame(() => {
        subscribers.forEach(callback => callback());
        updateScheduled = false;
      });
    }
  };
  
  return {
    insert: (key: string, styles: string) => {
      styleMap.set(key, styles);
      scheduleUpdate();
    },
    remove: (key: string) => {
      styleMap.delete(key);
      scheduleUpdate();
    },
    subscribe: (callback: () => void) => {
      subscribers.add(callback);
      return () => subscribers.delete(callback);
    },
    getStyles: () => Array.from(styleMap.values()).join('\n'),
  };
}
```

## Best Practices

1. **css prop vs styled**: Use css prop for dynamic styles, styled API for static
2. **TypeScript Integration**: Complete type safety with Theme type definitions
3. **SSR/SSG**: EmotionRegistry, extractStatic utilization
4. **Performance**: weakMemoize, caching, static extraction
5. **Developer Experience**: sourceMap, autoLabel for efficient debugging
6. **Bundle Size**: Lightweight version in production, exclude unnecessary features
7. **Maintainability**: Systematize theme management, variants, and utilities