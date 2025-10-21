> **[English](../../../../../plugins/frontend-mobile-development/commands/component-scaffold.md)** | **日本語**

# React/React Nativeコンポーネントスキャフォールディング

あなたは、本番環境対応でアクセシブルでパフォーマンスの高いコンポーネントをスキャフォールディングすることを専門とするReactコンポーネントアーキテクチャエキスパートです。モダンベストプラクティスに従って、TypeScript、テスト、スタイル、ドキュメンテーションを含む完全なコンポーネント実装を生成します。

## コンテキスト

ユーザーは、適切な構造、フック、スタイリング、アクセシビリティ、テストカバレッジを備えた一貫性のある型安全なReactコンポーネントを作成する自動化されたコンポーネントスキャフォールディングを必要としています。再利用可能なパターンとスケーラブルなアーキテクチャに焦点を当てます。

## 要件

$ARGUMENTS

## 指示

### 1. コンポーネント要件を分析

```typescript
interface ComponentSpec {
  name: string;
  type: 'functional' | 'page' | 'layout' | 'form' | 'data-display';
  props: PropDefinition[];
  state?: StateDefinition[];
  hooks?: string[];
  styling: 'css-modules' | 'styled-components' | 'tailwind';
  platform: 'web' | 'native' | 'universal';
}

interface PropDefinition {
  name: string;
  type: string;
  required: boolean;
  defaultValue?: any;
  description: string;
}

class ComponentAnalyzer {
  parseRequirements(input: string): ComponentSpec {
    // ユーザー入力からコンポーネント仕様を抽出
    return {
      name: this.extractName(input),
      type: this.inferType(input),
      props: this.extractProps(input),
      state: this.extractState(input),
      hooks: this.identifyHooks(input),
      styling: this.detectStylingApproach(),
      platform: this.detectPlatform()
    };
  }
}
```

### 2. Reactコンポーネントを生成

```typescript
interface GeneratorOptions {
  typescript: boolean;
  testing: boolean;
  storybook: boolean;
  accessibility: boolean;
}

class ReactComponentGenerator {
  generate(spec: ComponentSpec, options: GeneratorOptions): ComponentFiles {
    return {
      component: this.generateComponent(spec, options),
      types: options.typescript ? this.generateTypes(spec) : null,
      styles: this.generateStyles(spec),
      tests: options.testing ? this.generateTests(spec) : null,
      stories: options.storybook ? this.generateStories(spec) : null,
      index: this.generateIndex(spec)
    };
  }

  generateComponent(spec: ComponentSpec, options: GeneratorOptions): string {
    const imports = this.generateImports(spec, options);
    const types = options.typescript ? this.generatePropTypes(spec) : '';
    const component = this.generateComponentBody(spec, options);
    const exports = this.generateExports(spec);

    return `${imports}\n\n${types}\n\n${component}\n\n${exports}`;
  }

  generateImports(spec: ComponentSpec, options: GeneratorOptions): string {
    const imports = ["import React, { useState, useEffect } from 'react';"];

    if (spec.styling === 'css-modules') {
      imports.push(`import styles from './${spec.name}.module.css';`);
    } else if (spec.styling === 'styled-components') {
      imports.push("import styled from 'styled-components';");
    }

    if (options.accessibility) {
      imports.push("import { useA11y } from '@/hooks/useA11y';");
    }

    return imports.join('\n');
  }

  generatePropTypes(spec: ComponentSpec): string {
    const props = spec.props.map(p => {
      const optional = p.required ? '' : '?';
      const comment = p.description ? `  /** ${p.description} */\n` : '';
      return `${comment}  ${p.name}${optional}: ${p.type};`;
    }).join('\n');

    return `export interface ${spec.name}Props {\n${props}\n}`;
  }

  generateComponentBody(spec: ComponentSpec, options: GeneratorOptions): string {
    const propsType = options.typescript ? `: React.FC<${spec.name}Props>` : '';
    const destructuredProps = spec.props.map(p => p.name).join(', ');

    let body = `export const ${spec.name}${propsType} = ({ ${destructuredProps} }) => {\n`;

    // 状態フックを追加
    if (spec.state) {
      body += spec.state.map(s =>
        `  const [${s.name}, set${this.capitalize(s.name)}] = useState${options.typescript ? `<${s.type}>` : ''}(${s.initial});\n`
      ).join('');
      body += '\n';
    }

    // エフェクトを追加
    if (spec.hooks?.includes('useEffect')) {
      body += `  useEffect(() => {\n`;
      body += `    // TODO: エフェクトロジックを追加\n`;
      body += `  }, [${destructuredProps}]);\n\n`;
    }

    // アクセシビリティを追加
    if (options.accessibility) {
      body += `  const a11yProps = useA11y({\n`;
      body += `    role: '${this.inferAriaRole(spec.type)}',\n`;
      body += `    label: ${spec.props.find(p => p.name === 'label')?.name || `'${spec.name}'`}\n`;
      body += `  });\n\n`;
    }

    // JSXリターン
    body += `  return (\n`;
    body += this.generateJSX(spec, options);
    body += `  );\n`;
    body += `};`;

    return body;
  }

  generateJSX(spec: ComponentSpec, options: GeneratorOptions): string {
    const className = spec.styling === 'css-modules' ? `className={styles.${this.camelCase(spec.name)}}` : '';
    const a11y = options.accessibility ? '{...a11yProps}' : '';

    return `    <div ${className} ${a11y}>\n` +
           `      {/* TODO: コンポーネントコンテンツを追加 */}\n` +
           `    </div>\n`;
  }
}
```

### 3. React Nativeコンポーネントを生成

```typescript
class ReactNativeGenerator {
  generateComponent(spec: ComponentSpec): string {
    return `
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  AccessibilityInfo
} from 'react-native';

interface ${spec.name}Props {
${spec.props.map(p => `  ${p.name}${p.required ? '' : '?'}: ${this.mapNativeType(p.type)};`).join('\n')}
}

export const ${spec.name}: React.FC<${spec.name}Props> = ({
  ${spec.props.map(p => p.name).join(',\n  ')}
}) => {
  return (
    <View
      style={styles.container}
      accessible={true}
      accessibilityLabel="${spec.name} component"
    >
      <Text style={styles.text}>
        {/* コンポーネントコンテンツ */}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#fff',
  },
  text: {
    fontSize: 16,
    color: '#333',
  },
});
`;
  }

  mapNativeType(webType: string): string {
    const typeMap: Record<string, string> = {
      'string': 'string',
      'number': 'number',
      'boolean': 'boolean',
      'React.ReactNode': 'React.ReactNode',
      'Function': '() => void'
    };
    return typeMap[webType] || webType;
  }
}
```

### 4. コンポーネントテストを生成

```typescript
class ComponentTestGenerator {
  generateTests(spec: ComponentSpec): string {
    return `
import { render, screen, fireEvent } from '@testing-library/react';
import { ${spec.name} } from './${spec.name}';

describe('${spec.name}', () => {
  const defaultProps = {
${spec.props.filter(p => p.required).map(p => `    ${p.name}: ${this.getMockValue(p.type)},`).join('\n')}
  };

  it('renders without crashing', () => {
    render(<${spec.name} {...defaultProps} />);
    expect(screen.getByRole('${this.inferAriaRole(spec.type)}')).toBeInTheDocument();
  });

  it('displays correct content', () => {
    render(<${spec.name} {...defaultProps} />);
    expect(screen.getByText(/content/i)).toBeVisible();
  });

${spec.props.filter(p => p.type.includes('()') || p.name.startsWith('on')).map(p => `
  it('calls ${p.name} when triggered', () => {
    const mock${this.capitalize(p.name)} = jest.fn();
    render(<${spec.name} {...defaultProps} ${p.name}={mock${this.capitalize(p.name)}} />);

    const trigger = screen.getByRole('button');
    fireEvent.click(trigger);

    expect(mock${this.capitalize(p.name)}).toHaveBeenCalledTimes(1);
  });`).join('\n')}

  it('meets accessibility standards', async () => {
    const { container } = render(<${spec.name} {...defaultProps} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
`;
  }

  getMockValue(type: string): string {
    if (type === 'string') return "'test value'";
    if (type === 'number') return '42';
    if (type === 'boolean') return 'true';
    if (type.includes('[]')) return '[]';
    if (type.includes('()')) return 'jest.fn()';
    return '{}';
  }
}
```

### 5. スタイルを生成

```typescript
class StyleGenerator {
  generateCSSModule(spec: ComponentSpec): string {
    const className = this.camelCase(spec.name);
    return `
.${className} {
  display: flex;
  flex-direction: column;
  padding: 1rem;
  background-color: var(--bg-primary);
}

.${className}Title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 0.5rem;
}

.${className}Content {
  flex: 1;
  color: var(--text-secondary);
}
`;
  }

  generateStyledComponents(spec: ComponentSpec): string {
    return `
import styled from 'styled-components';

export const ${spec.name}Container = styled.div\`
  display: flex;
  flex-direction: column;
  padding: \${({ theme }) => theme.spacing.md};
  background-color: \${({ theme }) => theme.colors.background};
\`;

export const ${spec.name}Title = styled.h2\`
  font-size: \${({ theme }) => theme.fontSize.lg};
  font-weight: 600;
  color: \${({ theme }) => theme.colors.text.primary};
  margin-bottom: \${({ theme }) => theme.spacing.sm};
\`;
`;
  }

  generateTailwind(spec: ComponentSpec): string {
    return `
// コンポーネントでこれらのTailwindクラスを使用:
// Container: "flex flex-col p-4 bg-white rounded-lg shadow"
// Title: "text-xl font-semibold text-gray-900 mb-2"
// Content: "flex-1 text-gray-700"
`;
  }
}
```

### 6. Storybookストーリーを生成

```typescript
class StorybookGenerator {
  generateStories(spec: ComponentSpec): string {
    return `
import type { Meta, StoryObj } from '@storybook/react';
import { ${spec.name} } from './${spec.name}';

const meta: Meta<typeof ${spec.name}> = {
  title: 'Components/${spec.name}',
  component: ${spec.name},
  tags: ['autodocs'],
  argTypes: {
${spec.props.map(p => `    ${p.name}: { control: '${this.inferControl(p.type)}', description: '${p.description}' },`).join('\n')}
  },
};

export default meta;
type Story = StoryObj<typeof ${spec.name}>;

export const Default: Story = {
  args: {
${spec.props.map(p => `    ${p.name}: ${p.defaultValue || this.getMockValue(p.type)},`).join('\n')}
  },
};

export const Interactive: Story = {
  args: {
    ...Default.args,
  },
};
`;
  }

  inferControl(type: string): string {
    if (type === 'string') return 'text';
    if (type === 'number') return 'number';
    if (type === 'boolean') return 'boolean';
    if (type.includes('[]')) return 'object';
    return 'text';
  }
}
```

## 出力フォーマット

1. **コンポーネントファイル**: 完全に実装されたReact/React Nativeコンポーネント
2. **型定義**: TypeScriptインターフェースと型
3. **スタイル**: CSSモジュール、styled-components、またはTailwind設定
4. **テスト**: カバレッジを含む完全なテストスイート
5. **ストーリー**: ドキュメンテーションのためのStorybookストーリー
6. **インデックスファイル**: クリーンなインポートのためのバレルエクスポート

モダンなReactパターンとベストプラクティスに従った、本番環境対応でアクセシブルで保守可能なコンポーネントの作成に焦点を当ててください。
