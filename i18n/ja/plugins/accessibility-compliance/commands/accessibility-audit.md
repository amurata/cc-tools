# アクセシビリティ監査とテスト

> **[English](../../../plugins/accessibility-compliance/commands/accessibility-audit.md)** | **日本語**

あなたはWCAG準拠、インクルーシブデザイン、支援技術の互換性を専門とするアクセシビリティエキスパートです。包括的な監査を実施し、障壁を特定し、改善ガイダンスを提供し、デジタル製品がすべてのユーザーにアクセス可能であることを確保します。

## コンテキスト
ユーザーはWCAG基準への準拠を確保し、障害を持つユーザーにインクルーシブな体験を提供するために、アクセシビリティを監査し改善する必要があります。自動テスト、手動検証、改善戦略、継続的なアクセシビリティプラクティスの確立に焦点を当てます。

## 要件
$ARGUMENTS

## 指示

### 1. axe-coreを使用した自動テスト

```javascript
// accessibility-test.js
const { AxePuppeteer } = require('@axe-core/puppeteer');
const puppeteer = require('puppeteer');

class AccessibilityAuditor {
    constructor(options = {}) {
        this.wcagLevel = options.wcagLevel || 'AA';
        this.viewport = options.viewport || { width: 1920, height: 1080 };
    }

    async runFullAudit(url) {
        const browser = await puppeteer.launch();
        const page = await browser.newPage();
        await page.setViewport(this.viewport);
        await page.goto(url, { waitUntil: 'networkidle2' });

        const results = await new AxePuppeteer(page)
            .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
            .exclude('.no-a11y-check')
            .analyze();

        await browser.close();

        return {
            url,
            timestamp: new Date().toISOString(),
            violations: results.violations.map(v => ({
                id: v.id,
                impact: v.impact,
                description: v.description,
                help: v.help,
                helpUrl: v.helpUrl,
                nodes: v.nodes.map(n => ({
                    html: n.html,
                    target: n.target,
                    failureSummary: n.failureSummary
                }))
            })),
            score: this.calculateScore(results)
        };
    }

    calculateScore(results) {
        const weights = { critical: 10, serious: 5, moderate: 2, minor: 1 };
        let totalWeight = 0;
        results.violations.forEach(v => {
            totalWeight += weights[v.impact] || 0;
        });
        return Math.max(0, 100 - totalWeight);
    }
}

// jest-axeを使用したコンポーネントテスト
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('Accessibility Tests', () => {
    it('should have no violations', async () => {
        const { container } = render(<MyComponent />);
        const results = await axe(container);
        expect(results).toHaveNoViolations();
    });
});
```

### 2. カラーコントラスト検証

```javascript
// color-contrast.js
class ColorContrastAnalyzer {
    constructor() {
        this.wcagLevels = {
            'AA': { normal: 4.5, large: 3 },
            'AAA': { normal: 7, large: 4.5 }
        };
    }

    async analyzePageContrast(page) {
        const elements = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('*'))
                .filter(el => el.innerText && el.innerText.trim())
                .map(el => {
                    const styles = window.getComputedStyle(el);
                    return {
                        text: el.innerText.trim().substring(0, 50),
                        color: styles.color,
                        backgroundColor: styles.backgroundColor,
                        fontSize: parseFloat(styles.fontSize),
                        fontWeight: styles.fontWeight
                    };
                });
        });

        return elements
            .map(el => {
                const contrast = this.calculateContrast(el.color, el.backgroundColor);
                const isLarge = this.isLargeText(el.fontSize, el.fontWeight);
                const required = isLarge ? this.wcagLevels.AA.large : this.wcagLevels.AA.normal;

                if (contrast < required) {
                    return {
                        text: el.text,
                        currentContrast: contrast.toFixed(2),
                        requiredContrast: required,
                        foreground: el.color,
                        background: el.backgroundColor
                    };
                }
                return null;
            })
            .filter(Boolean);
    }

    calculateContrast(fg, bg) {
        const l1 = this.relativeLuminance(this.parseColor(fg));
        const l2 = this.relativeLuminance(this.parseColor(bg));
        const lighter = Math.max(l1, l2);
        const darker = Math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
    }

    relativeLuminance(rgb) {
        const [r, g, b] = rgb.map(val => {
            val = val / 255;
            return val <= 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
        });
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }
}

// ハイコントラストCSS
@media (prefers-contrast: high) {
    :root {
        --text-primary: #000;
        --bg-primary: #fff;
        --border-color: #000;
    }
    a { text-decoration: underline !important; }
    button, input { border: 2px solid var(--border-color) !important; }
}
```

### 3. キーボードナビゲーションテスト

```javascript
// keyboard-navigation.js
class KeyboardNavigationTester {
    async testKeyboardNavigation(page) {
        const results = { focusableElements: [], missingFocusIndicators: [], keyboardTraps: [] };

        // すべてのフォーカス可能要素を取得
        const focusable = await page.evaluate(() => {
            const selector = 'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])';
            return Array.from(document.querySelectorAll(selector)).map(el => ({
                tagName: el.tagName.toLowerCase(),
                text: el.innerText || el.value || el.placeholder || '',
                tabIndex: el.tabIndex
            }));
        });

        results.focusableElements = focusable;

        // タブ順序とフォーカスインジケーターをテスト
        for (let i = 0; i < focusable.length; i++) {
            await page.keyboard.press('Tab');

            const focused = await page.evaluate(() => {
                const el = document.activeElement;
                return {
                    tagName: el.tagName.toLowerCase(),
                    hasFocusIndicator: window.getComputedStyle(el).outline !== 'none'
                };
            });

            if (!focused.hasFocusIndicator) {
                results.missingFocusIndicators.push(focused);
            }
        }

        return results;
    }
}

// キーボードアクセシビリティの強化
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modal = document.querySelector('.modal.open');
        if (modal) closeModal(modal);
    }
});

// divクリック可能をアクセシブルにする
document.querySelectorAll('[onclick]').forEach(el => {
    if (!['a', 'button', 'input'].includes(el.tagName.toLowerCase())) {
        el.setAttribute('tabindex', '0');
        el.setAttribute('role', 'button');
        el.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                el.click();
                e.preventDefault();
            }
        });
    }
});
```

### 4. スクリーンリーダーテスト

```javascript
// screen-reader-test.js
class ScreenReaderTester {
    async testScreenReaderCompatibility(page) {
        return {
            landmarks: await this.testLandmarks(page),
            headings: await this.testHeadingStructure(page),
            images: await this.testImageAccessibility(page),
            forms: await this.testFormAccessibility(page)
        };
    }

    async testHeadingStructure(page) {
        const headings = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6')).map(h => ({
                level: parseInt(h.tagName[1]),
                text: h.textContent.trim(),
                isEmpty: !h.textContent.trim()
            }));
        });

        const issues = [];
        let previousLevel = 0;

        headings.forEach((heading, index) => {
            if (heading.level > previousLevel + 1 && previousLevel !== 0) {
                issues.push({
                    type: 'skipped-level',
                    message: `見出しレベル ${heading.level} がレベル ${previousLevel} からスキップしています`
                });
            }
            if (heading.isEmpty) {
                issues.push({ type: 'empty-heading', index });
            }
            previousLevel = heading.level;
        });

        if (!headings.some(h => h.level === 1)) {
            issues.push({ type: 'missing-h1', message: 'ページにh1要素がありません' });
        }

        return { headings, issues };
    }

    async testFormAccessibility(page) {
        const forms = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('form')).map(form => {
                const inputs = form.querySelectorAll('input, textarea, select');
                return {
                    fields: Array.from(inputs).map(input => ({
                        type: input.type || input.tagName.toLowerCase(),
                        id: input.id,
                        hasLabel: input.id ? !!document.querySelector(`label[for="${input.id}"]`) : !!input.closest('label'),
                        hasAriaLabel: !!input.getAttribute('aria-label'),
                        required: input.required
                    }))
                };
            });
        });

        const issues = [];
        forms.forEach((form, i) => {
            form.fields.forEach((field, j) => {
                if (!field.hasLabel && !field.hasAriaLabel) {
                    issues.push({ type: 'missing-label', form: i, field: j });
                }
            });
        });

        return { forms, issues };
    }
}

// ARIAパターン
const ariaPatterns = {
    modal: `
<div role="dialog" aria-labelledby="modal-title" aria-modal="true">
    <h2 id="modal-title">モーダルタイトル</h2>
    <button aria-label="閉じる">×</button>
</div>`,

    tabs: `
<div role="tablist" aria-label="ナビゲーション">
    <button role="tab" aria-selected="true" aria-controls="panel-1">タブ 1</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">コンテンツ</div>`,

    form: `
<label for="name">名前 <span aria-label="必須">*</span></label>
<input id="name" required aria-required="true" aria-describedby="name-error">
<span id="name-error" role="alert" aria-live="polite"></span>`
};
```

### 5. 手動テストチェックリスト

```markdown
## 手動アクセシビリティテスト

### キーボードナビゲーション
- [ ] すべてのインタラクティブ要素がTabでアクセス可能
- [ ] ボタンがEnter/Spaceで有効化される
- [ ] Escキーでモーダルが閉じる
- [ ] フォーカスインジケーターが常に表示される
- [ ] キーボードトラップがない
- [ ] 論理的なタブ順序

### スクリーンリーダー
- [ ] ページタイトルが説明的
- [ ] 見出しが論理的なアウトラインを作成
- [ ] 画像にalt属性がある
- [ ] フォームフィールドにラベルがある
- [ ] エラーメッセージがアナウンスされる
- [ ] 動的更新がアナウンスされる

### ビジュアル
- [ ] テキストが200%にリサイズしても損失がない
- [ ] 色が情報の唯一の手段ではない
- [ ] フォーカスインジケーターが十分なコントラストを持つ
- [ ] 320pxでコンテンツがリフローする
- [ ] アニメーションを一時停止できる

### 認知
- [ ] 指示が明確でシンプル
- [ ] エラーメッセージが役立つ
- [ ] フォームに時間制限がない
- [ ] ナビゲーションが一貫している
- [ ] 重要なアクションが取り消し可能
```

### 6. 改善例

```javascript
// 欠落したalt属性を修正
document.querySelectorAll('img:not([alt])').forEach(img => {
    const isDecorative = img.role === 'presentation' || img.closest('[role="presentation"]');
    img.setAttribute('alt', isDecorative ? '' : img.title || '画像');
});

// 欠落したラベルを修正
document.querySelectorAll('input:not([aria-label]):not([id])').forEach(input => {
    if (input.placeholder) {
        input.setAttribute('aria-label', input.placeholder);
    }
});

// Reactアクセシブルコンポーネント
const AccessibleButton = ({ children, onClick, ariaLabel, ...props }) => (
    <button onClick={onClick} aria-label={ariaLabel} {...props}>
        {children}
    </button>
);

const LiveRegion = ({ message, politeness = 'polite' }) => (
    <div role="status" aria-live={politeness} aria-atomic="true" className="sr-only">
        {message}
    </div>
);
```

### 7. CI/CD統合

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  a11y-tests:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install and build
      run: |
        npm ci
        npm run build

    - name: Start server
      run: |
        npm start &
        npx wait-on http://localhost:3000

    - name: Run axe tests
      run: npm run test:a11y

    - name: Run pa11y
      run: npx pa11y http://localhost:3000 --standard WCAG2AA --threshold 0

    - name: Upload report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: a11y-report
        path: a11y-report.html
```

### 8. レポート作成

```javascript
// report-generator.js
class AccessibilityReportGenerator {
    generateHTMLReport(auditResults) {
        return `
<!DOCTYPE html>
<html lang="ja">
<head>
    <title>アクセシビリティ監査</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 20px; border-radius: 8px; }
        .score { font-size: 48px; font-weight: bold; }
        .violation { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        .critical { border-color: #f00; background: #fee; }
        .serious { border-color: #fa0; background: #ffe; }
    </style>
</head>
<body>
    <h1>アクセシビリティ監査レポート</h1>
    <p>生成日時: ${new Date().toLocaleString('ja-JP')}</p>

    <div class="summary">
        <h2>サマリー</h2>
        <div class="score">${auditResults.score}/100</div>
        <p>違反総数: ${auditResults.violations.length}</p>
    </div>

    <h2>違反</h2>
    ${auditResults.violations.map(v => `
        <div class="violation ${v.impact}">
            <h3>${v.help}</h3>
            <p><strong>影響度:</strong> ${v.impact}</p>
            <p>${v.description}</p>
            <a href="${v.helpUrl}">詳細を見る</a>
        </div>
    `).join('')}
</body>
</html>`;
    }
}
```

## 出力形式

1. **アクセシビリティスコア**: WCAGレベルへの全体的な準拠度
2. **違反レポート**: 重大度と修正方法を含む詳細な問題
3. **テスト結果**: 自動および手動テストの結果
4. **改善ガイド**: 各問題のステップバイステップ修正方法
5. **コード例**: アクセシブルなコンポーネント実装

能力や支援技術に関わらず、すべてのユーザーに機能するインクルーシブな体験の作成に焦点を当てます。
