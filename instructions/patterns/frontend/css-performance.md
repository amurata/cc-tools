# CSS Performance Optimization Complete Guide

## Critical CSS Extraction and Inlining

### Automated Critical CSS Generation
```javascript
// Critical CSS extraction with Critters
const Critters = require('critters');

const critters = new Critters({
  path: 'dist',
  publicPath: '/',
  inlineThreshold: 2048, // Inline if under 2KB
  minimumExternalSize: 10000, // Don't inline large sheets
  pruneSource: true, // Remove inlined rules from external CSS
  logLevel: 'info',
  fonts: true, // Inline critical font-face rules
  preload: 'swap', // Preload strategy
  noscriptFallback: true, // Add noscript fallback
  mergeStylesheets: true, // Merge multiple stylesheets
  additionalStylesheets: ['critical-overrides.css']
});

// Webpack plugin configuration
module.exports = {
  plugins: [
    new HtmlWebpackPlugin(),
    new Critters({
      preload: 'swap',
      includeSelectors: [
        // Force include specific selectors
        '.critical-class',
        '#important-id'
      ],
      excludeSelectors: [
        // Never inline these
        '.lazy-load',
        '[data-deferred]'
      ]
    })
  ]
};
```

### Manual Critical CSS Implementation
```html
<!DOCTYPE html>
<html>
<head>
  <!-- Inline critical CSS -->
  <style>
    /* Critical above-the-fold styles */
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
    }
    
    .header {
      position: fixed;
      top: 0;
      width: 100%;
      height: 60px;
      background: #fff;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      z-index: 1000;
    }
    
    .hero {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 20px;
    }
    
    /* Critical animations */
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    .fade-in {
      animation: fadeIn 0.6s ease-out;
    }
  </style>
  
  <!-- Preload non-critical CSS -->
  <link rel="preload" href="/css/main.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
  <noscript><link rel="stylesheet" href="/css/main.css"></noscript>
  
  <!-- Preload fonts -->
  <link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>
  
  <!-- Preconnect to external domains -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="dns-prefetch" href="https://cdn.example.com">
</head>
</html>
```

## Advanced CSS Optimization Techniques

### PostCSS Optimization Pipeline
```javascript
// postcss.config.js
module.exports = {
  plugins: [
    // Autoprefixer for vendor prefixes
    require('autoprefixer')({
      overrideBrowserslist: ['last 2 versions', '> 1%'],
      grid: 'autoplace'
    }),
    
    // CSS Nano for minification
    require('cssnano')({
      preset: ['advanced', {
        discardComments: { removeAll: true },
        reduceIdents: true,
        mergeIdents: true,
        reduceInitial: true,
        minifySelectors: true,
        minifyParams: true,
        minifyFontValues: true,
        normalizeWhitespace: true,
        normalizeUrl: true,
        colormin: true,
        calc: true,
        convertValues: {
          length: true,
          time: true,
          angle: true
        },
        orderedValues: true,
        mergeLonghand: true,
        discardDuplicates: true,
        discardEmpty: true,
        uniqueSelectors: true,
        mergeRules: true,
        zindex: false // Preserve z-index values
      }]
    }),
    
    // PurgeCSS for removing unused CSS
    require('@fullhuman/postcss-purgecss')({
      content: [
        './src/**/*.html',
        './src/**/*.jsx',
        './src/**/*.tsx',
        './src/**/*.vue'
      ],
      defaultExtractor: content => {
        // Custom extractor for complex class names
        const broadMatches = content.match(/[^<>"'`\s]*[^<>"'`\s:]/g) || [];
        const innerMatches = content.match(/[^<>"'`\s.()]*[^<>"'`\s.():]/g) || [];
        return broadMatches.concat(innerMatches);
      },
      safelist: {
        standard: [/^(hover|focus|active|disabled):/, /^data-/],
        deep: [/^modal/, /^tooltip/],
        greedy: [/^animate-/]
      },
      blocklist: ['unused-*', 'obsolete-*'],
      keyframes: true,
      fontFace: true,
      variables: true
    }),
    
    // CSS Variables optimization
    require('postcss-custom-properties')({
      preserve: false, // Remove fallbacks in production
      importFrom: './src/css/variables.css'
    }),
    
    // Media query packing
    require('css-mqpacker')({
      sort: true // Sort media queries by min-width
    }),
    
    // Optimize CSS calc()
    require('postcss-calc')({
      precision: 5,
      preserve: false
    })
  ]
};
```

### Tailwind CSS Production Optimization
```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx,html}',
    './public/index.html',
    // Include dynamic class generation patterns
    './src/utils/classNames.js'
  ],
  
  // Safelist critical classes
  safelist: [
    'animate-spin',
    'animate-pulse',
    {
      pattern: /^(bg|text|border)-(red|green|blue)-(100|500|900)/,
      variants: ['hover', 'focus', 'lg:hover']
    }
  ],
  
  theme: {
    extend: {
      // Custom optimized animations
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out'
      },
      
      // Optimized transitions
      transitionTimingFunction: {
        'bounce-in': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
      }
    }
  },
  
  plugins: [
    // Custom plugin for performance utilities
    function({ addUtilities, addComponents, e, config }) {
      addUtilities({
        '.gpu-accelerated': {
          'transform': 'translateZ(0)',
          'will-change': 'transform',
          'backface-visibility': 'hidden',
          'perspective': '1000px'
        },
        '.contain-layout': {
          'contain': 'layout style paint'
        },
        '.contain-strict': {
          'contain': 'strict'
        }
      });
    }
  ],
  
  // Production optimizations
  future: {
    hoverOnlyWhenSupported: true,
    respectDefaultRingColorOpacity: true
  },
  
  experimental: {
    optimizeUniversalDefaults: true,
    matchVariant: true
  }
};
```

## CSS-in-JS Performance Optimization

### Emotion with Static Extraction
```typescript
// Emotion babel configuration for static extraction
// babel.config.js
module.exports = {
  plugins: [
    [
      '@emotion/babel-plugin',
      {
        sourceMap: false,
        autoLabel: 'never', // Disable in production
        labelFormat: '[local]',
        cssPropOptimization: true,
        
        // Extract static styles
        extractStatic: {
          rules: [
            {
              test: /\.css$/,
              loader: 'css-loader'
            }
          ]
        }
      }
    ]
  ]
};

// Component with optimized Emotion
import { css, keyframes } from '@emotion/react';
import styled from '@emotion/styled';

// Static styles extracted at build time
const staticStyles = css`
  display: flex;
  align-items: center;
  padding: 1rem;
  border-radius: 8px;
`;

// Dynamic styles with memoization
const dynamicStyles = (theme: Theme, isActive: boolean) => css`
  ${staticStyles};
  background: ${isActive ? theme.colors.primary : theme.colors.secondary};
  transition: background 0.3s ease;
  
  /* Use CSS containment */
  contain: layout style paint;
  
  /* Hardware acceleration */
  will-change: ${isActive ? 'transform' : 'auto'};
`;

// Memoized styled component
const OptimizedButton = styled.button<{ isActive: boolean }>`
  ${({ theme, isActive }) => dynamicStyles(theme, isActive)};
  
  /* Critical rendering path optimization */
  content-visibility: auto;
  contain-intrinsic-size: 100px 40px;
`;

// Lazy-loaded animation
const slideIn = keyframes`
  from {
    transform: translateX(-100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
`;
```

### styled-components v6 Optimization
```typescript
// styled-components optimization
import styled, { createGlobalStyle, css } from 'styled-components';
import { shouldForwardProp } from '@styled-system/should-forward-prop';

// Configure babel plugin for better performance
// babel.config.js
{
  plugins: [
    [
      'babel-plugin-styled-components',
      {
        ssr: true,
        displayName: false, // Disable in production
        fileName: false,
        minify: true,
        transpileTemplateLiterals: true,
        pure: true
      }
    ]
  ]
}

// Optimized global styles
const GlobalStyles = createGlobalStyle`
  /* Use CSS custom properties for theming */
  :root {
    --color-primary: ${props => props.theme.colors.primary};
    --color-secondary: ${props => props.theme.colors.secondary};
    --spacing-unit: ${props => props.theme.spacing.unit}px;
  }
  
  /* Performance optimizations */
  * {
    box-sizing: border-box;
  }
  
  body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    
    /* Optimize text rendering */
    text-rendering: optimizeLegibility;
    
    /* Prevent layout shift */
    overflow-y: scroll;
    overflow-x: hidden;
  }
  
  /* Optimize images */
  img {
    max-width: 100%;
    height: auto;
    content-visibility: auto;
  }
  
  /* Reduce paint areas */
  button, input, select, textarea {
    font: inherit;
    contain: layout style;
  }
`;

// Memoized style utilities
const buttonStyles = css<{ variant: 'primary' | 'secondary' }>`
  /* Static styles */
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s ease;
  
  /* Dynamic styles with CSS variables */
  background: ${({ variant }) => 
    variant === 'primary' ? 'var(--color-primary)' : 'var(--color-secondary)'};
  
  /* Performance hints */
  will-change: transform;
  contain: layout style paint;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
  }
  
  &:active {
    transform: translateY(0);
  }
`;

// Optimized component with prop filtering
const Button = styled.button.withConfig({
  shouldForwardProp: (prop) => shouldForwardProp(prop) && prop !== 'variant'
})<{ variant: 'primary' | 'secondary' }>`
  ${buttonStyles}
`;
```

## Render Performance Optimization

### CSS Containment and Content Visibility
```css
/* Layout containment for components */
.card {
  contain: layout style paint;
  /* Component won't affect outside layout */
}

.sidebar {
  contain: strict;
  /* Full containment - size, layout, style, paint */
  width: 250px;
  height: 100vh;
}

/* Content visibility for lazy rendering */
.comment {
  content-visibility: auto;
  contain-intrinsic-size: 0 500px;
  /* Browser can skip rendering off-screen comments */
}

.lazy-section {
  content-visibility: auto;
  contain-intrinsic-size: 1000px;
  /* Improves initial page load */
}

/* Size containment for predictable layout */
.ad-container {
  contain: size layout;
  width: 300px;
  height: 250px;
  /* Prevents layout shift from dynamic ads */
}

/* Paint containment for animations */
.animated-element {
  contain: paint;
  will-change: transform;
  /* Limits paint operations to element bounds */
}
```

### Animation Performance
```css
/* GPU-accelerated animations */
@keyframes slideIn {
  from {
    transform: translateX(-100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.slide-animation {
  animation: slideIn 0.3s ease-out;
  
  /* GPU acceleration hints */
  will-change: transform, opacity;
  transform: translateZ(0);
  backface-visibility: hidden;
  perspective: 1000px;
}

/* Avoid expensive properties */
.bad-animation {
  /* DON'T animate these */
  animation: badAnimation 1s;
}

@keyframes badAnimation {
  from {
    width: 100px; /* Triggers layout */
    height: 100px; /* Triggers layout */
    top: 0; /* Triggers layout */
    left: 0; /* Triggers layout */
  }
}

/* Use transforms instead */
.good-animation {
  animation: goodAnimation 1s;
}

@keyframes goodAnimation {
  from {
    transform: scale(0.5) translate(-50px, -50px);
    opacity: 0;
  }
}

/* Reduce paint complexity */
.optimized-shadow {
  /* Use box-shadow sparingly */
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  
  /* Or use pseudo-element for better performance */
  position: relative;
}

.optimized-shadow::after {
  content: '';
  position: absolute;
  inset: 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  pointer-events: none;
  z-index: -1;
}
```

## Bundle Size Optimization

### CSS Splitting and Code Splitting
```javascript
// Webpack configuration for CSS splitting
module.exports = {
  optimization: {
    splitChunks: {
      cacheGroups: {
        // Extract vendor CSS
        vendorStyles: {
          name: 'vendor',
          test: /[\\/]node_modules[\\/].*\.css$/,
          chunks: 'all',
          enforce: true
        },
        
        // Extract common CSS
        commonStyles: {
          name: 'common',
          test: /[\\/]src[\\/]styles[\\/]common[\\/].*\.css$/,
          chunks: 'all',
          minChunks: 2
        },
        
        // Route-based CSS splitting
        pageStyles: {
          test: /[\\/]src[\\/]pages[\\/].*\.css$/,
          chunks: 'async',
          minChunks: 1,
          priority: 10,
          reuseExistingChunk: true
        }
      }
    }
  },
  
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              // Enable HMR in development
              hmr: process.env.NODE_ENV === 'development',
              // Reduce runtime size
              esModule: false
            }
          },
          {
            loader: 'css-loader',
            options: {
              importLoaders: 1,
              modules: {
                auto: true,
                localIdentName: '[hash:base64:5]'
              }
            }
          },
          'postcss-loader'
        ]
      }
    ]
  },
  
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].[contenthash:8].css',
      chunkFilename: '[name].[contenthash:8].chunk.css',
      ignoreOrder: true // Prevent order warnings
    }),
    
    // Compress CSS
    new CompressionPlugin({
      test: /\.css$/,
      algorithm: 'brotli',
      compressionOptions: { level: 11 }
    })
  ]
};
```

## Measurement and Monitoring

```javascript
// Performance monitoring utilities
class CSSPerformanceMonitor {
  constructor() {
    this.metrics = {
      stylesheets: [],
      cssRules: 0,
      unusedRules: 0,
      renderTime: 0
    };
  }

  measureStylesheets() {
    const stylesheets = Array.from(document.styleSheets);
    
    stylesheets.forEach(sheet => {
      try {
        const rules = Array.from(sheet.cssRules || []);
        this.metrics.cssRules += rules.length;
        
        // Measure unused CSS
        rules.forEach(rule => {
          if (rule instanceof CSSStyleRule) {
            const selector = rule.selectorText;
            const elements = document.querySelectorAll(selector);
            if (elements.length === 0) {
              this.metrics.unusedRules++;
            }
          }
        });
      } catch (e) {
        console.warn('Cannot access stylesheet:', sheet.href);
      }
    });
    
    this.metrics.stylesheets = stylesheets.map(s => ({
      href: s.href,
      rules: s.cssRules?.length || 0,
      media: s.media.mediaText
    }));
  }

  measureRenderPerformance() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.entryType === 'paint') {
          this.metrics.renderTime = entry.startTime;
        }
      }
    });
    
    observer.observe({ entryTypes: ['paint'] });
  }

  getCSSCoverage() {
    if ('CSS' in window && 'highlights' in CSS) {
      // Use CSS Coverage API if available
      return performance.measure('css-coverage');
    }
    
    return {
      total: this.metrics.cssRules,
      unused: this.metrics.unusedRules,
      percentage: ((this.metrics.unusedRules / this.metrics.cssRules) * 100).toFixed(2)
    };
  }

  report() {
    console.table(this.metrics);
    console.log('CSS Coverage:', this.getCSSCoverage());
    
    // Send to analytics
    if (window.gtag) {
      window.gtag('event', 'css_performance', {
        total_rules: this.metrics.cssRules,
        unused_rules: this.metrics.unusedRules,
        render_time: this.metrics.renderTime
      });
    }
  }
}

// Usage
const monitor = new CSSPerformanceMonitor();
monitor.measureStylesheets();
monitor.measureRenderPerformance();
monitor.report();
```

## Production Checklist
- [ ] Critical CSS extracted and inlined
- [ ] Non-critical CSS loaded asynchronously
- [ ] Unused CSS removed with PurgeCSS
- [ ] CSS minified and compressed
- [ ] CSS bundled and code-split appropriately
- [ ] Container queries used for responsive design
- [ ] CSS containment applied to components
- [ ] Animations use GPU-accelerated properties
- [ ] Font loading optimized with font-display
- [ ] Performance metrics tracked and monitored