# styled-components Practical Guide v6

## Setup and TypeScript Integration

### Next.js 14+ App Router Support

```typescript
// next.config.js
module.exports = {
  compiler: {
    styledComponents: {
      displayName: process.env.NODE_ENV !== 'production',
      ssr: true,
      fileName: true,
      topLevelImportPaths: [],
      meaninglessFileNames: ['index'],
      cssProp: true,
      namespace: '',
      minify: true,
      transpileTemplateLiterals: true,
      pure: true,
    },
  },
};

// app/layout.tsx
import StyledComponentsRegistry from './lib/styled-registry';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html>
      <body>
        <StyledComponentsRegistry>{children}</StyledComponentsRegistry>
      </body>
    </html>
  );
}

// app/lib/styled-registry.tsx
'use client';

import React, { useState } from 'react';
import { useServerInsertedHTML } from 'next/navigation';
import { ServerStyleSheet, StyleSheetManager } from 'styled-components';

export default function StyledComponentsRegistry({
  children,
}: {
  children: React.ReactNode;
}) {
  const [styledComponentsStyleSheet] = useState(() => new ServerStyleSheet());

  useServerInsertedHTML(() => {
    const styles = styledComponentsStyleSheet.getStyleElement();
    styledComponentsStyleSheet.instance.clearTag();
    return styles;
  });

  if (typeof window !== 'undefined') return <>{children}</>;

  return (
    <StyleSheetManager sheet={styledComponentsStyleSheet.instance}>
      {children}
    </StyleSheetManager>
  );
}
```

### Complete TypeScript Integration

```typescript
// styled.d.ts
import 'styled-components';

interface IPalette {
  main: string;
  contrastText: string;
  dark: string;
  light: string;
}

declare module 'styled-components' {
  export interface DefaultTheme {
    borderRadius: {
      small: string;
      medium: string;
      large: string;
    };
    colors: {
      primary: IPalette;
      secondary: IPalette;
      error: IPalette;
      warning: IPalette;
      info: IPalette;
      success: IPalette;
      grey: {
        50: string;
        100: string;
        200: string;
        300: string;
        400: string;
        500: string;
        600: string;
        700: string;
        800: string;
        900: string;
      };
    };
    typography: {
      fontFamily: string;
      fontSize: {
        xs: string;
        sm: string;
        md: string;
        lg: string;
        xl: string;
        '2xl': string;
        '3xl': string;
      };
      fontWeight: {
        light: number;
        regular: number;
        medium: number;
        semibold: number;
        bold: number;
      };
      lineHeight: {
        tight: number;
        normal: number;
        relaxed: number;
      };
    };
    spacing: (factor: number) => string;
    transitions: {
      fast: string;
      normal: string;
      slow: string;
    };
    breakpoints: {
      xs: string;
      sm: string;
      md: string;
      lg: string;
      xl: string;
      '2xl': string;
    };
    zIndex: {
      appBar: number;
      drawer: number;
      modal: number;
      snackbar: number;
      tooltip: number;
    };
  }
}
```

## Advanced Styling Patterns

### 1. Dynamic Styles and Variant Management

```typescript
// components/Button/Button.styles.ts
import styled, { css, DefaultTheme } from 'styled-components';
import { motion } from 'framer-motion';

type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost';
type ButtonSize = 'small' | 'medium' | 'large';

interface ButtonStyleProps {
  $variant: ButtonVariant;
  $size: ButtonSize;
  $fullWidth?: boolean;
  $loading?: boolean;
}

// Variant style map
const variantStyles = {
  primary: css`
    background: ${({ theme }) => theme.colors.primary.main};
    color: ${({ theme }) => theme.colors.primary.contrastText};
    border: 2px solid transparent;
    
    &:hover:not(:disabled) {
      background: ${({ theme }) => theme.colors.primary.dark};
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
    }
    
    &:active:not(:disabled) {
      transform: translateY(0);
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
  `,
  secondary: css`
    background: ${({ theme }) => theme.colors.grey[100]};
    color: ${({ theme }) => theme.colors.grey[800]};
    border: 2px solid ${({ theme }) => theme.colors.grey[300]};
    
    &:hover:not(:disabled) {
      background: ${({ theme }) => theme.colors.grey[200]};
      border-color: ${({ theme }) => theme.colors.grey[400]};
    }
  `,
  danger: css`
    background: ${({ theme }) => theme.colors.error.main};
    color: ${({ theme }) => theme.colors.error.contrastText};
    border: 2px solid transparent;
    
    &:hover:not(:disabled) {
      background: ${({ theme }) => theme.colors.error.dark};
    }
  `,
  ghost: css`
    background: transparent;
    color: ${({ theme }) => theme.colors.primary.main};
    border: 2px solid transparent;
    
    &:hover:not(:disabled) {
      background: ${({ theme }) => theme.colors.primary.main}10;
    }
  `,
};

// Size style map
const sizeStyles = {
  small: css`
    padding: ${({ theme }) => `${theme.spacing(1)} ${theme.spacing(2)}`};
    font-size: ${({ theme }) => theme.typography.fontSize.sm};
    min-height: 32px;
  `,
  medium: css`
    padding: ${({ theme }) => `${theme.spacing(1.5)} ${theme.spacing(3)}`};
    font-size: ${({ theme }) => theme.typography.fontSize.md};
    min-height: 40px;
  `,
  large: css`
    padding: ${({ theme }) => `${theme.spacing(2)} ${theme.spacing(4)}`};
    font-size: ${({ theme }) => theme.typography.fontSize.lg};
    min-height: 48px;
  `,
};

// Styled component
export const StyledButton = styled(motion.button)<ButtonStyleProps>`
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: ${({ theme }) => theme.spacing(1)};
  border-radius: ${({ theme }) => theme.borderRadius.medium};
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-weight: ${({ theme }) => theme.typography.fontWeight.medium};
  line-height: ${({ theme }) => theme.typography.lineHeight.tight};
  transition: ${({ theme }) => theme.transitions.fast};
  cursor: pointer;
  user-select: none;
  outline: none;
  
  /* Apply variant styles */
  ${({ $variant }) => variantStyles[$variant]}
  
  /* Apply size styles */
  ${({ $size }) => sizeStyles[$size]}
  
  /* Conditional styles */
  ${({ $fullWidth }) => $fullWidth && css`
    width: 100%;
  `}
  
  ${({ $loading }) => $loading && css`
    pointer-events: none;
    opacity: 0.7;
    
    &::before {
      content: '';
      position: absolute;
      top: 50%;
      left: 50%;
      width: 16px;
      height: 16px;
      margin: -8px 0 0 -8px;
      border: 2px solid currentColor;
      border-radius: 50%;
      border-top-color: transparent;
      animation: spin 0.6s linear infinite;
    }
  `}
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  &:focus-visible {
    box-shadow: 0 0 0 3px ${({ theme }) => theme.colors.primary.main}40;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
`;

// Icon wrapper
export const IconWrapper = styled.span<{ $position?: 'left' | 'right' }>`
  display: inline-flex;
  align-items: center;
  order: ${({ $position }) => $position === 'right' ? 1 : -1};
`;
```

### 2. Advanced Theme System

```typescript
// styles/theme.ts
import { DefaultTheme } from 'styled-components';

// Theme factory function
export const createTheme = (mode: 'light' | 'dark'): DefaultTheme => {
  const baseColors = {
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#dc004e',
      light: '#e33371',
      dark: '#9a0036',
      contrastText: '#ffffff',
    },
    error: {
      main: '#f44336',
      light: '#e57373',
      dark: '#d32f2f',
      contrastText: '#ffffff',
    },
    warning: {
      main: '#ff9800',
      light: '#ffb74d',
      dark: '#f57c00',
      contrastText: 'rgba(0, 0, 0, 0.87)',
    },
    info: {
      main: '#2196f3',
      light: '#64b5f6',
      dark: '#1976d2',
      contrastText: '#ffffff',
    },
    success: {
      main: '#4caf50',
      light: '#81c784',
      dark: '#388e3c',
      contrastText: 'rgba(0, 0, 0, 0.87)',
    },
  };

  const palette = mode === 'dark' ? {
    ...baseColors,
    grey: {
      50: '#fafafa',
      100: '#f5f5f5',
      200: '#eeeeee',
      300: '#e0e0e0',
      400: '#bdbdbd',
      500: '#9e9e9e',
      600: '#757575',
      700: '#616161',
      800: '#424242',
      900: '#212121',
    },
  } : {
    ...baseColors,
    grey: {
      50: '#212121',
      100: '#424242',
      200: '#616161',
      300: '#757575',
      400: '#9e9e9e',
      500: '#bdbdbd',
      600: '#e0e0e0',
      700: '#eeeeee',
      800: '#f5f5f5',
      900: '#fafafa',
    },
  };

  return {
    colors: palette,
    borderRadius: {
      small: '4px',
      medium: '8px',
      large: '12px',
    },
    typography: {
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      fontSize: {
        xs: '0.75rem',
        sm: '0.875rem',
        md: '1rem',
        lg: '1.125rem',
        xl: '1.25rem',
        '2xl': '1.5rem',
        '3xl': '2rem',
      },
      fontWeight: {
        light: 300,
        regular: 400,
        medium: 500,
        semibold: 600,
        bold: 700,
      },
      lineHeight: {
        tight: 1.25,
        normal: 1.5,
        relaxed: 1.75,
      },
    },
    spacing: (factor: number) => `${factor * 8}px`,
    transitions: {
      fast: 'all 0.15s cubic-bezier(0.4, 0, 0.2, 1)',
      normal: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      slow: 'all 0.45s cubic-bezier(0.4, 0, 0.2, 1)',
    },
    breakpoints: {
      xs: '0px',
      sm: '600px',
      md: '900px',
      lg: '1200px',
      xl: '1536px',
      '2xl': '1920px',
    },
    zIndex: {
      appBar: 1100,
      drawer: 1200,
      modal: 1300,
      snackbar: 1400,
      tooltip: 1500,
    },
  };
};

// Theme Provider
// components/ThemeProvider.tsx
import { ThemeProvider as StyledThemeProvider } from 'styled-components';
import { createContext, useContext, useState, useEffect } from 'react';

interface ThemeContextType {
  mode: 'light' | 'dark';
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<'light' | 'dark'>('light');
  
  useEffect(() => {
    const stored = localStorage.getItem('theme-mode') as 'light' | 'dark';
    if (stored) setMode(stored);
    
    // System theme detection
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    if (!stored) setMode(mediaQuery.matches ? 'dark' : 'light');
    
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
  };
  
  const theme = createTheme(mode);
  
  return (
    <ThemeContext.Provider value={{ mode, toggleTheme }}>
      <StyledThemeProvider theme={theme}>
        {children}
      </StyledThemeProvider>
    </ThemeContext.Provider>
  );
}
```

### 3. Performance Optimization Techniques

```typescript
// utils/styled-utils.ts
import { css } from 'styled-components';

// Media query helpers (memoized)
const breakpoints = {
  xs: '0px',
  sm: '600px',
  md: '900px',
  lg: '1200px',
  xl: '1536px',
} as const;

type Breakpoint = keyof typeof breakpoints;

const mediaCache = new Map<string, ReturnType<typeof css>>();

export const media = {
  up: (breakpoint: Breakpoint) => {
    const key = `up-${breakpoint}`;
    if (!mediaCache.has(key)) {
      mediaCache.set(key, css`@media (min-width: ${breakpoints[breakpoint]})`);
    }
    return mediaCache.get(key)!;
  },
  down: (breakpoint: Breakpoint) => {
    const key = `down-${breakpoint}`;
    if (!mediaCache.has(key)) {
      const maxWidth = `${parseInt(breakpoints[breakpoint]) - 0.02}px`;
      mediaCache.set(key, css`@media (max-width: ${maxWidth})`);
    }
    return mediaCache.get(key)!;
  },
  between: (start: Breakpoint, end: Breakpoint) => {
    const key = `between-${start}-${end}`;
    if (!mediaCache.has(key)) {
      mediaCache.set(
        key,
        css`@media (min-width: ${breakpoints[start]}) and (max-width: ${parseInt(breakpoints[end]) - 0.02}px)`
      );
    }
    return mediaCache.get(key)!;
  },
};

// Dynamic style generation optimization
export const memoizedStyle = <P extends object>(
  styleFunction: (props: P) => ReturnType<typeof css>
) => {
  const cache = new WeakMap<P, ReturnType<typeof css>>();
  
  return (props: P) => {
    if (!cache.has(props)) {
      cache.set(props, styleFunction(props));
    }
    return cache.get(props)!;
  };
};

// Batch style updates
export const batchedStyles = styled.div.attrs<{ $updates: string[] }>(
  ({ $updates = [] }) => ({
    style: {
      '--batch-update': $updates.join(' '),
    },
  })
)<{ $updates: string[] }>`
  /* Efficient updates using CSS variables */
  transition: var(--batch-update);
`;
```

## SSR/SSG Optimization

### Critical CSS Extraction

```typescript
// utils/critical-styles.ts
import { ServerStyleSheet } from 'styled-components';
import { renderToString } from 'react-dom/server';

export async function extractCriticalStyles(
  Component: React.ComponentType,
  props: any
) {
  const sheet = new ServerStyleSheet();
  
  try {
    const html = renderToString(
      sheet.collectStyles(<Component {...props} />)
    );
    
    const styleTags = sheet.getStyleTags();
    const criticalStyles = styleTags.replace(/<style[^>]*>/g, '')
      .replace(/<\/style>/g, '');
    
    return {
      html,
      styles: criticalStyles,
    };
  } finally {
    sheet.seal();
  }
}

// pages/_document.tsx implementation
import Document, { DocumentContext } from 'next/document';
import { ServerStyleSheet } from 'styled-components';

export default class MyDocument extends Document {
  static async getInitialProps(ctx: DocumentContext) {
    const sheet = new ServerStyleSheet();
    const originalRenderPage = ctx.renderPage;
    
    try {
      ctx.renderPage = () =>
        originalRenderPage({
          enhanceApp: (App) => (props) =>
            sheet.collectStyles(<App {...props} />),
        });
      
      const initialProps = await Document.getInitialProps(ctx);
      return {
        ...initialProps,
        styles: [
          initialProps.styles,
          sheet.getStyleElement(),
        ],
      };
    } finally {
      sheet.seal();
    }
  }
}
```

## Troubleshooting

### 1. Flash of Unstyled Content (FOUC)

```typescript
// Solution: Babel configuration and SSR optimization
// .babelrc
{
  "presets": ["next/babel"],
  "plugins": [
    ["styled-components", {
      "ssr": true,
      "displayName": true,
      "preprocess": false
    }]
  ]
}
```

### 2. TypeScript Type Errors

```typescript
// Solution: Transient props pattern
// Use $ prefix to prevent props from leaking to DOM
interface StyledProps {
  $isActive?: boolean;  // $ prefix for transient prop
  $color?: string;
}

const StyledDiv = styled.div<StyledProps>`
  background: ${({ $color }) => $color || 'transparent'};
  opacity: ${({ $isActive }) => $isActive ? 1 : 0.5};
`;
```

## Best Practices

1. **Transient Props**: Use `$` prefix to prevent DOM pollution
2. **Theme Integration**: Complete type safety with TypeScript type definitions
3. **Performance**: Memoization, batch updates, Critical CSS extraction
4. **SSR Support**: ServerStyleSheet, optimized Babel configuration
5. **Code Splitting**: Dynamic imports to reduce bundle size
6. **Developer Experience**: displayName, dev tools integration for efficient debugging
7. **Maintainability**: Clear separation of styles and logic