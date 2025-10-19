# Web Accessibility (A11y) Complete Implementation Guide

## WCAG 2.1 AAA Level Implementation

### Semantic HTML Foundation
```html
<!-- Proper heading hierarchy -->
<header role="banner">
  <h1>Site Title</h1>
  <nav role="navigation" aria-label="Main navigation">
    <ul>
      <li><a href="/" aria-current="page">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>

<main role="main" id="main-content">
  <article>
    <h2>Article Title</h2>
    <time datetime="2024-03-15">March 15, 2024</time>
    <p>Content with proper semantic structure.</p>
  </article>
</main>

<footer role="contentinfo">
  <p>&copy; 2024 Company. All rights reserved.</p>
</footer>
```

### Advanced ARIA Implementation
```typescript
// Accessible modal with focus trap
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

function AccessibleModal({ isOpen, onClose, title, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      previousFocus.current = document.activeElement as HTMLElement;
      modalRef.current?.focus();
      
      // Trap focus
      const handleTab = (e: KeyboardEvent) => {
        if (e.key !== 'Tab') return;
        
        const focusableElements = modalRef.current?.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        ) as NodeListOf<HTMLElement>;
        
        if (!focusableElements?.length) return;
        
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];
        
        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault();
          lastElement.focus();
        } else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault();
          firstElement.focus();
        }
      };
      
      document.addEventListener('keydown', handleTab);
      return () => document.removeEventListener('keydown', handleTab);
    } else {
      previousFocus.current?.focus();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      aria-describedby="modal-description"
      ref={modalRef}
      tabIndex={-1}
      className="modal"
    >
      <div className="modal-overlay" onClick={onClose} aria-hidden="true" />
      <div className="modal-content">
        <h2 id="modal-title">{title}</h2>
        <div id="modal-description">{children}</div>
        <button onClick={onClose} aria-label="Close modal">
          Close
        </button>
      </div>
    </div>
  );
}
```

### Complex Accessible Form
```typescript
// Multi-step form with validation and announcements
function AccessibleMultiStepForm() {
  const [currentStep, setCurrentStep] = useState(1);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const announcerRef = useRef<HTMLDivElement>(null);

  const announce = (message: string) => {
    if (announcerRef.current) {
      announcerRef.current.textContent = message;
      setTimeout(() => {
        if (announcerRef.current) {
          announcerRef.current.textContent = '';
        }
      }, 1000);
    }
  };

  const validateField = (name: string, value: string): string | null => {
    if (!value) return `${name} is required`;
    if (name === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      return 'Invalid email format';
    }
    return null;
  };

  return (
    <form
      aria-label="Registration form"
      onSubmit={(e) => e.preventDefault()}
    >
      {/* Progress indicator */}
      <div role="group" aria-label="Form progress">
        <ol className="progress-steps">
          {[1, 2, 3].map((step) => (
            <li
              key={step}
              aria-current={currentStep === step ? 'step' : undefined}
              aria-label={`Step ${step} ${currentStep === step ? '(current)' : 
                          currentStep > step ? '(completed)' : '(not started)'}`}
            >
              Step {step}
            </li>
          ))}
        </ol>
      </div>

      {/* Form fields */}
      <fieldset>
        <legend className="sr-only">Step {currentStep} of 3</legend>
        
        {currentStep === 1 && (
          <div>
            <label htmlFor="name">
              Full Name
              <span aria-label="required">*</span>
            </label>
            <input
              id="name"
              name="name"
              type="text"
              required
              aria-required="true"
              aria-invalid={!!errors.name}
              aria-describedby={errors.name ? 'name-error' : undefined}
              onChange={(e) => {
                const error = validateField('name', e.target.value);
                setErrors(prev => ({ ...prev, name: error || '' }));
              }}
            />
            {errors.name && (
              <span id="name-error" role="alert" className="error">
                {errors.name}
              </span>
            )}
          </div>
        )}
      </fieldset>

      {/* Navigation */}
      <div role="group" aria-label="Form navigation">
        <button
          type="button"
          onClick={() => {
            setCurrentStep(prev => prev - 1);
            announce(`Moved to step ${currentStep - 1}`);
          }}
          disabled={currentStep === 1}
          aria-label="Go to previous step"
        >
          Previous
        </button>
        <button
          type="button"
          onClick={() => {
            setCurrentStep(prev => prev + 1);
            announce(`Moved to step ${currentStep + 1}`);
          }}
          disabled={currentStep === 3}
          aria-label="Go to next step"
        >
          Next
        </button>
      </div>

      {/* Live region for announcements */}
      <div
        ref={announcerRef}
        role="status"
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      />
    </form>
  );
}
```

### Accessible Data Table
```typescript
// Complex data table with sorting and filtering
function AccessibleDataTable({ data }: { data: any[] }) {
  const [sortColumn, setSortColumn] = useState<string | null>(null);
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [announcement, setAnnouncement] = useState('');

  const handleSort = (column: string) => {
    const newDirection = sortColumn === column && sortDirection === 'asc' ? 'desc' : 'asc';
    setSortColumn(column);
    setSortDirection(newDirection);
    setAnnouncement(`Table sorted by ${column} in ${newDirection}ending order`);
  };

  return (
    <>
      <table role="table" aria-label="User data" aria-rowcount={data.length}>
        <caption>
          User Information Table
          <span className="sr-only">
            {sortColumn && `, sorted by ${sortColumn} in ${sortDirection}ending order`}
          </span>
        </caption>
        <thead>
          <tr role="row">
            <th
              role="columnheader"
              aria-sort={sortColumn === 'name' ? sortDirection : 'none'}
              tabIndex={0}
              onClick={() => handleSort('name')}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  handleSort('name');
                }
              }}
            >
              Name
              <span aria-hidden="true">
                {sortColumn === 'name' && (sortDirection === 'asc' ? ' ↑' : ' ↓')}
              </span>
            </th>
            <th role="columnheader">Email</th>
            <th role="columnheader">Role</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row, index) => (
            <tr key={row.id} role="row" aria-rowindex={index + 2}>
              <td role="cell">{row.name}</td>
              <td role="cell">{row.email}</td>
              <td role="cell">{row.role}</td>
            </tr>
          ))}
        </tbody>
      </table>
      
      <div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
        {announcement}
      </div>
    </>
  );
}
```

### Skip Links and Landmarks
```typescript
// Complete skip link implementation
function SkipLinks() {
  return (
    <div className="skip-links">
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <a href="#primary-navigation" className="skip-link">
        Skip to navigation
      </a>
      <a href="#footer" className="skip-link">
        Skip to footer
      </a>
    </div>
  );
}

// CSS for skip links
const skipLinkStyles = `
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px;
  text-decoration: none;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
`;
```

### Color Contrast and Visual Indicators
```css
/* WCAG AAA compliant color contrast (7:1 for normal text, 4.5:1 for large) */
:root {
  --color-text: #1a1a1a; /* Contrast ratio 18.1:1 on white */
  --color-text-light: #595959; /* Contrast ratio 7.5:1 on white */
  --color-primary: #0066cc; /* Contrast ratio 7.2:1 on white */
  --color-error: #b91c1c; /* Contrast ratio 7.1:1 on white */
  --color-success: #166534; /* Contrast ratio 7.3:1 on white */
}

/* Focus indicators that meet WCAG 2.2 requirements */
*:focus {
  outline: 3px solid var(--color-primary);
  outline-offset: 2px;
}

/* Don't rely on color alone */
.error {
  color: var(--color-error);
  font-weight: bold;
}

.error::before {
  content: "⚠ ";
  font-size: 1.2em;
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  :root {
    --color-text: #000;
    --color-bg: #fff;
    --color-primary: #0040a0;
  }
}
```

### Keyboard Navigation Utilities
```typescript
// Complete keyboard navigation hook
function useKeyboardNavigation() {
  const [isKeyboardUser, setIsKeyboardUser] = useState(false);

  useEffect(() => {
    // Detect keyboard vs mouse user
    const handleMouseDown = () => setIsKeyboardUser(false);
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Tab') {
        setIsKeyboardUser(true);
      }
    };

    document.addEventListener('mousedown', handleMouseDown);
    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('mousedown', handleMouseDown);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, []);

  return isKeyboardUser;
}

// Roving tabindex for lists
function RovingTabIndex({ children }: { children: React.ReactElement[] }) {
  const [focusedIndex, setFocusedIndex] = useState(0);

  const handleKeyDown = (e: React.KeyboardEvent, index: number) => {
    let nextIndex = index;

    switch (e.key) {
      case 'ArrowDown':
      case 'ArrowRight':
        e.preventDefault();
        nextIndex = (index + 1) % children.length;
        break;
      case 'ArrowUp':
      case 'ArrowLeft':
        e.preventDefault();
        nextIndex = (index - 1 + children.length) % children.length;
        break;
      case 'Home':
        e.preventDefault();
        nextIndex = 0;
        break;
      case 'End':
        e.preventDefault();
        nextIndex = children.length - 1;
        break;
    }

    if (nextIndex !== index) {
      setFocusedIndex(nextIndex);
      const element = document.getElementById(`item-${nextIndex}`);
      element?.focus();
    }
  };

  return (
    <div role="list">
      {React.Children.map(children, (child, index) => (
        <div
          role="listitem"
          id={`item-${index}`}
          tabIndex={focusedIndex === index ? 0 : -1}
          onKeyDown={(e) => handleKeyDown(e, index)}
          onFocus={() => setFocusedIndex(index)}
        >
          {child}
        </div>
      ))}
    </div>
  );
}
```

### Screen Reader Announcements
```typescript
// Live region manager
class ScreenReaderAnnouncer {
  private container: HTMLDivElement;
  private politeRegion: HTMLDivElement;
  private assertiveRegion: HTMLDivElement;

  constructor() {
    this.container = document.createElement('div');
    this.container.className = 'sr-only';
    
    this.politeRegion = document.createElement('div');
    this.politeRegion.setAttribute('aria-live', 'polite');
    this.politeRegion.setAttribute('aria-atomic', 'true');
    
    this.assertiveRegion = document.createElement('div');
    this.assertiveRegion.setAttribute('aria-live', 'assertive');
    this.assertiveRegion.setAttribute('aria-atomic', 'true');
    
    this.container.appendChild(this.politeRegion);
    this.container.appendChild(this.assertiveRegion);
    document.body.appendChild(this.container);
  }

  announcePolite(message: string) {
    this.politeRegion.textContent = message;
    setTimeout(() => {
      this.politeRegion.textContent = '';
    }, 1000);
  }

  announceAssertive(message: string) {
    this.assertiveRegion.textContent = message;
    setTimeout(() => {
      this.assertiveRegion.textContent = '';
    }, 1000);
  }
}

// Usage
const announcer = new ScreenReaderAnnouncer();
announcer.announcePolite('Form submitted successfully');
announcer.announceAssertive('Error: Please fix the highlighted fields');
```

## Testing and Validation Tools

```bash
# Automated testing setup
npm install --save-dev @testing-library/react @testing-library/jest-dom jest-axe

# ESLint accessibility plugin
npm install --save-dev eslint-plugin-jsx-a11y
```

```typescript
// Jest test with accessibility checks
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('should not have accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

## Production Checklist
- [ ] All images have appropriate alt text
- [ ] Color contrast meets WCAG AAA standards (7:1)
- [ ] All interactive elements are keyboard accessible
- [ ] Focus indicators are clearly visible
- [ ] ARIA attributes are correctly implemented
- [ ] Forms have proper labels and error messages
- [ ] Page has proper heading hierarchy
- [ ] Skip links are provided
- [ ] Live regions announce dynamic changes
- [ ] Tested with screen readers (NVDA, JAWS, VoiceOver)