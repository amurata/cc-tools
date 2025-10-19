# Web Components Complete Implementation Guide

## Custom Elements v1 Implementation

### Complete Custom Element Lifecycle
```javascript
// Full custom element with all lifecycle hooks
class AdvancedElement extends HTMLElement {
  static get observedAttributes() {
    return ['theme', 'size', 'disabled', 'data-value'];
  }

  #shadowRoot;
  #internals;
  #abortController;

  constructor() {
    super();
    
    // Attach Shadow DOM
    this.#shadowRoot = this.attachShadow({ 
      mode: 'open',
      delegatesFocus: true 
    });
    
    // Element internals for form association
    if ('attachInternals' in this) {
      this.#internals = this.attachInternals();
    }
    
    // Abort controller for cleanup
    this.#abortController = new AbortController();
    
    // Initial state
    this._state = {
      value: '',
      isValid: true,
      isDirty: false
    };
    
    // Bind methods
    this.handleInput = this.handleInput.bind(this);
    this.handleClick = this.handleClick.bind(this);
  }

  connectedCallback() {
    // Element added to DOM
    this.render();
    this.attachEventListeners();
    this.upgradeProperties();
    
    // Dispatch custom event
    this.dispatchEvent(new CustomEvent('connected', {
      bubbles: true,
      composed: true,
      detail: { element: this }
    }));
  }

  disconnectedCallback() {
    // Element removed from DOM
    this.#abortController.abort();
    this.cleanup();
  }

  adoptedCallback() {
    // Element moved to new document
    console.log('Element adopted to new document');
  }

  attributeChangedCallback(name, oldValue, newValue) {
    // Attribute changed
    if (oldValue === newValue) return;
    
    switch (name) {
      case 'theme':
        this.updateTheme(newValue);
        break;
      case 'size':
        this.updateSize(newValue);
        break;
      case 'disabled':
        this.updateDisabled(newValue !== null);
        break;
      case 'data-value':
        this.updateValue(newValue);
        break;
    }
    
    this.render();
  }

  // Upgrade properties set before element defined
  upgradeProperties() {
    ['theme', 'size', 'disabled', 'value'].forEach(prop => {
      if (this.hasOwnProperty(prop)) {
        const value = this[prop];
        delete this[prop];
        this[prop] = value;
      }
    });
  }

  // Property getters/setters
  get value() {
    return this._state.value;
  }

  set value(newValue) {
    const oldValue = this._state.value;
    this._state.value = newValue;
    this._state.isDirty = true;
    
    if (this.#internals) {
      this.#internals.setFormValue(newValue);
    }
    
    this.dispatchEvent(new CustomEvent('valuechange', {
      detail: { oldValue, newValue },
      bubbles: true,
      composed: true
    }));
    
    this.render();
  }

  get disabled() {
    return this.hasAttribute('disabled');
  }

  set disabled(value) {
    if (value) {
      this.setAttribute('disabled', '');
    } else {
      this.removeAttribute('disabled');
    }
  }

  // Render method
  render() {
    const { value, isValid, isDirty } = this._state;
    
    this.#shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          position: relative;
          --primary-color: var(--theme-primary, #007bff);
          --error-color: var(--theme-error, #dc3545);
        }
        
        :host([disabled]) {
          opacity: 0.5;
          pointer-events: none;
        }
        
        :host([hidden]) {
          display: none;
        }
        
        :host(:focus-within) {
          outline: 2px solid var(--primary-color);
          outline-offset: 2px;
        }
        
        .container {
          padding: var(--spacing, 1rem);
          border: 1px solid var(--border-color, #ddd);
          border-radius: var(--radius, 4px);
        }
        
        .container[data-invalid="true"] {
          border-color: var(--error-color);
        }
        
        ::slotted(*) {
          margin: 0.5rem 0;
        }
        
        @media (prefers-color-scheme: dark) {
          :host {
            --border-color: #444;
            --bg-color: #222;
          }
        }
      </style>
      
      <div class="container" data-invalid="${!isValid}">
        <slot name="header"></slot>
        <div class="content">
          <input 
            type="text" 
            value="${value}"
            ?disabled="${this.disabled}"
            aria-invalid="${!isValid}"
          />
          ${isDirty && !isValid ? '<span class="error">Invalid input</span>' : ''}
        </div>
        <slot name="footer"></slot>
        <slot></slot>
      </div>
    `;
  }

  // Event handling
  attachEventListeners() {
    const input = this.#shadowRoot.querySelector('input');
    
    input?.addEventListener('input', this.handleInput, {
      signal: this.#abortController.signal
    });
    
    this.addEventListener('click', this.handleClick, {
      signal: this.#abortController.signal
    });
  }

  handleInput(event) {
    this.value = event.target.value;
    this.validate();
  }

  handleClick(event) {
    if (event.target === this) {
      this.focus();
    }
  }

  // Validation
  validate() {
    const isValid = this.value.length >= 3;
    this._state.isValid = isValid;
    
    if (this.#internals) {
      if (isValid) {
        this.#internals.setValidity({});
      } else {
        this.#internals.setValidity(
          { valueMissing: true },
          'Value must be at least 3 characters'
        );
      }
    }
    
    return isValid;
  }

  // Cleanup
  cleanup() {
    // Remove any external references
    this._state = null;
  }

  // Public API methods
  focus() {
    this.#shadowRoot.querySelector('input')?.focus();
  }

  reset() {
    this._state = {
      value: '',
      isValid: true,
      isDirty: false
    };
    this.render();
  }
}

// Define the element
customElements.define('advanced-element', AdvancedElement);
```

### Form-Associated Custom Elements
```javascript
// Form-associated custom element
class FormInput extends HTMLElement {
  static formAssociated = true;

  static get observedAttributes() {
    return ['value', 'name', 'required', 'pattern'];
  }

  #internals;
  #value = '';

  constructor() {
    super();
    this.#internals = this.attachInternals();
    this.attachShadow({ mode: 'open' });
  }

  // Form-associated callbacks
  formAssociatedCallback(form) {
    console.log('Associated with form:', form);
  }

  formDisabledCallback(disabled) {
    this.disabled = disabled;
  }

  formResetCallback() {
    this.value = this.getAttribute('value') || '';
  }

  formStateRestoreCallback(state, mode) {
    if (mode === 'restore') {
      this.value = state;
    }
  }

  // Value management
  get value() {
    return this.#value;
  }

  set value(v) {
    this.#value = v;
    this.#internals.setFormValue(v);
    this.updateValidity();
    this.render();
  }

  get validity() {
    return this.#internals.validity;
  }

  get validationMessage() {
    return this.#internals.validationMessage;
  }

  get willValidate() {
    return this.#internals.willValidate;
  }

  checkValidity() {
    return this.#internals.checkValidity();
  }

  reportValidity() {
    return this.#internals.reportValidity();
  }

  updateValidity() {
    const value = this.#value;
    const required = this.hasAttribute('required');
    const pattern = this.getAttribute('pattern');

    // Reset validity
    this.#internals.setValidity({});

    // Check required
    if (required && !value) {
      this.#internals.setValidity(
        { valueMissing: true },
        'Please fill out this field'
      );
      return;
    }

    // Check pattern
    if (pattern && value) {
      const regex = new RegExp(pattern);
      if (!regex.test(value)) {
        this.#internals.setValidity(
          { patternMismatch: true },
          `Please match the requested format`
        );
      }
    }
  }

  connectedCallback() {
    this.render();
    
    const input = this.shadowRoot.querySelector('input');
    input?.addEventListener('input', (e) => {
      this.value = e.target.value;
      this.dispatchEvent(new Event('input', { bubbles: true }));
    });
  }

  render() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
        }
        
        input {
          width: 100%;
          padding: 0.5rem;
          border: 1px solid #ccc;
          border-radius: 4px;
        }
        
        :host(:invalid) input {
          border-color: red;
        }
        
        :host(:valid) input {
          border-color: green;
        }
      </style>
      
      <input 
        type="text" 
        value="${this.#value}"
        ?required="${this.hasAttribute('required')}"
      />
    `;
  }
}

customElements.define('form-input', FormInput);
```

### Advanced Shadow DOM with Slots
```javascript
// Card component with multiple named slots
class CardComponent extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          border: 1px solid #ddd;
          border-radius: 8px;
          overflow: hidden;
          background: white;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header {
          padding: 1rem;
          background: #f5f5f5;
          border-bottom: 1px solid #ddd;
        }
        
        .header ::slotted(h1),
        .header ::slotted(h2),
        .header ::slotted(h3) {
          margin: 0;
          color: #333;
        }
        
        .media {
          position: relative;
          overflow: hidden;
        }
        
        .media ::slotted(img) {
          width: 100%;
          height: auto;
          display: block;
        }
        
        .content {
          padding: 1rem;
        }
        
        .actions {
          padding: 1rem;
          border-top: 1px solid #ddd;
          display: flex;
          gap: 0.5rem;
          justify-content: flex-end;
        }
        
        .actions ::slotted(button) {
          padding: 0.5rem 1rem;
          border: none;
          border-radius: 4px;
          background: #007bff;
          color: white;
          cursor: pointer;
        }
        
        /* Slot change animation */
        slot {
          display: block;
          animation: fadeIn 0.3s ease-in;
        }
        
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      </style>
      
      <div class="card">
        <div class="header">
          <slot name="header"></slot>
        </div>
        <div class="media">
          <slot name="media"></slot>
        </div>
        <div class="content">
          <slot></slot>
        </div>
        <div class="actions">
          <slot name="actions"></slot>
        </div>
      </div>
    `;

    // Monitor slot changes
    const slots = this.shadowRoot.querySelectorAll('slot');
    slots.forEach(slot => {
      slot.addEventListener('slotchange', (e) => {
        const nodes = slot.assignedNodes();
        console.log(`Slot ${slot.name || 'default'} changed:`, nodes);
        
        // Handle specific slot changes
        if (slot.name === 'media' && nodes.length > 0) {
          this.handleMediaSlotChange(nodes);
        }
      });
    });
  }

  handleMediaSlotChange(nodes) {
    nodes.forEach(node => {
      if (node.tagName === 'IMG') {
        // Lazy load images
        if ('loading' in HTMLImageElement.prototype) {
          node.loading = 'lazy';
        }
      }
    });
  }
}

customElements.define('card-component', CardComponent);
```

### Lit Framework Integration
```typescript
// Lit element with TypeScript
import { LitElement, html, css, customElement, property, state } from 'lit';
import { classMap } from 'lit/directives/class-map.js';
import { styleMap } from 'lit/directives/style-map.js';
import { repeat } from 'lit/directives/repeat.js';
import { until } from 'lit/directives/until.js';

@customElement('lit-todo-app')
export class LitTodoApp extends LitElement {
  static styles = css`
    :host {
      display: block;
      font-family: system-ui;
      max-width: 600px;
      margin: 0 auto;
      padding: 2rem;
    }

    .todo-list {
      list-style: none;
      padding: 0;
    }

    .todo-item {
      display: flex;
      align-items: center;
      padding: 0.75rem;
      border: 1px solid #ddd;
      margin-bottom: 0.5rem;
      border-radius: 4px;
      transition: all 0.3s ease;
    }

    .todo-item.completed {
      opacity: 0.6;
      background: #f5f5f5;
    }

    .todo-item.completed .todo-text {
      text-decoration: line-through;
    }

    .todo-item.priority-high {
      border-left: 4px solid #dc3545;
    }

    .todo-item.priority-medium {
      border-left: 4px solid #ffc107;
    }

    .todo-item.priority-low {
      border-left: 4px solid #28a745;
    }

    input[type="text"] {
      width: 100%;
      padding: 0.75rem;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 1rem;
    }

    button {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 4px;
      background: #007bff;
      color: white;
      cursor: pointer;
      font-size: 0.875rem;
    }

    button:hover {
      background: #0056b3;
    }

    .filters {
      display: flex;
      gap: 0.5rem;
      margin: 1rem 0;
    }

    .filter-btn {
      background: #e9ecef;
      color: #333;
    }

    .filter-btn.active {
      background: #007bff;
      color: white;
    }

    .stats {
      display: flex;
      justify-content: space-between;
      padding: 1rem;
      background: #f8f9fa;
      border-radius: 4px;
      margin-top: 1rem;
    }

    @media (prefers-color-scheme: dark) {
      :host {
        color: #fff;
        background: #1a1a1a;
      }

      .todo-item {
        border-color: #444;
        background: #2a2a2a;
      }

      input {
        background: #2a2a2a;
        border-color: #444;
        color: #fff;
      }
    }
  `;

  @property({ type: Array }) todos: Todo[] = [];
  @property({ type: String }) filter: 'all' | 'active' | 'completed' = 'all';
  @state() private newTodoText = '';
  @state() private priority: 'low' | 'medium' | 'high' = 'medium';

  private async loadTodos() {
    // Simulate async data loading
    return new Promise<Todo[]>((resolve) => {
      setTimeout(() => {
        resolve([
          { id: 1, text: 'Learn Lit', completed: false, priority: 'high' },
          { id: 2, text: 'Build app', completed: false, priority: 'medium' }
        ]);
      }, 1000);
    });
  }

  connectedCallback() {
    super.connectedCallback();
    this.loadTodos().then(todos => {
      this.todos = todos;
    });
  }

  private addTodo() {
    if (!this.newTodoText.trim()) return;

    const newTodo: Todo = {
      id: Date.now(),
      text: this.newTodoText,
      completed: false,
      priority: this.priority
    };

    this.todos = [...this.todos, newTodo];
    this.newTodoText = '';
    
    this.dispatchEvent(new CustomEvent('todo-added', {
      detail: newTodo,
      bubbles: true,
      composed: true
    }));
  }

  private toggleTodo(id: number) {
    this.todos = this.todos.map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    );
  }

  private deleteTodo(id: number) {
    this.todos = this.todos.filter(todo => todo.id !== id);
  }

  private get filteredTodos() {
    switch (this.filter) {
      case 'active':
        return this.todos.filter(t => !t.completed);
      case 'completed':
        return this.todos.filter(t => t.completed);
      default:
        return this.todos;
    }
  }

  private get stats() {
    return {
      total: this.todos.length,
      active: this.todos.filter(t => !t.completed).length,
      completed: this.todos.filter(t => t.completed).length
    };
  }

  render() {
    return html`
      <h1>Todo App</h1>
      
      <div class="input-group">
        <input
          type="text"
          .value=${this.newTodoText}
          @input=${(e: InputEvent) => this.newTodoText = (e.target as HTMLInputElement).value}
          @keydown=${(e: KeyboardEvent) => e.key === 'Enter' && this.addTodo()}
          placeholder="What needs to be done?"
        />
        
        <select @change=${(e: Event) => this.priority = (e.target as HTMLSelectElement).value as any}>
          <option value="low">Low</option>
          <option value="medium" selected>Medium</option>
          <option value="high">High</option>
        </select>
        
        <button @click=${this.addTodo}>Add Todo</button>
      </div>

      <div class="filters">
        ${['all', 'active', 'completed'].map(f => html`
          <button
            class=${classMap({ 
              'filter-btn': true, 
              'active': this.filter === f 
            })}
            @click=${() => this.filter = f as any}
          >
            ${f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        `)}
      </div>

      <ul class="todo-list">
        ${repeat(
          this.filteredTodos,
          todo => todo.id,
          todo => html`
            <li
              class=${classMap({
                'todo-item': true,
                'completed': todo.completed,
                [`priority-${todo.priority}`]: true
              })}
            >
              <input
                type="checkbox"
                .checked=${todo.completed}
                @change=${() => this.toggleTodo(todo.id)}
              />
              <span class="todo-text">${todo.text}</span>
              <button @click=${() => this.deleteTodo(todo.id)}>Delete</button>
            </li>
          `
        )}
      </ul>

      <div class="stats">
        <span>Total: ${this.stats.total}</span>
        <span>Active: ${this.stats.active}</span>
        <span>Completed: ${this.stats.completed}</span>
      </div>

      ${until(
        this.loadTodos().then(() => html`<p>Todos loaded!</p>`),
        html`<p>Loading todos...</p>`
      )}
    `;
  }
}

interface Todo {
  id: number;
  text: string;
  completed: boolean;
  priority: 'low' | 'medium' | 'high';
}
```

## Testing Web Components

```typescript
// Testing with @open-wc/testing
import { expect, fixture, html } from '@open-wc/testing';
import '../src/my-element.js';

describe('MyElement', () => {
  it('has a default title', async () => {
    const el = await fixture(html`<my-element></my-element>`);
    expect(el.title).to.equal('Default Title');
  });

  it('renders slot content', async () => {
    const el = await fixture(html`
      <my-element>
        <p slot="content">Test content</p>
      </my-element>
    `);
    
    const slot = el.shadowRoot!.querySelector('slot[name="content"]');
    const nodes = (slot as HTMLSlotElement).assignedNodes();
    expect(nodes).to.have.length(1);
  });

  it('fires custom event on click', async () => {
    const el = await fixture(html`<my-element></my-element>`);
    let eventFired = false;
    
    el.addEventListener('my-event', () => {
      eventFired = true;
    });
    
    el.click();
    expect(eventFired).to.be.true;
  });
});
```

## Production Checklist
- [ ] Custom elements properly registered
- [ ] Shadow DOM encapsulation configured
- [ ] Observed attributes defined
- [ ] Lifecycle callbacks implemented
- [ ] Form association added where needed
- [ ] Proper event handling with cleanup
- [ ] Accessibility attributes included
- [ ] CSS custom properties for theming
- [ ] Slot change monitoring
- [ ] Testing coverage for components