# Advanced HTML Forms Implementation Guide

## Modern HTML5 Form Validation

### Complete Validation System
```typescript
// Advanced form validator with async support
class FormValidator {
  private validators: Map<string, ValidationRule[]> = new Map();
  private asyncValidators: Map<string, AsyncValidationRule[]> = new Map();
  private errors: Map<string, string[]> = new Map();
  private touched: Set<string> = new Set();

  addRule(field: string, rule: ValidationRule) {
    const rules = this.validators.get(field) || [];
    rules.push(rule);
    this.validators.set(field, rules);
  }

  addAsyncRule(field: string, rule: AsyncValidationRule) {
    const rules = this.asyncValidators.get(field) || [];
    rules.push(rule);
    this.asyncValidators.set(field, rules);
  }

  async validate(field: string, value: any): Promise<boolean> {
    const rules = this.validators.get(field) || [];
    const asyncRules = this.asyncValidators.get(field) || [];
    const errors: string[] = [];

    // Sync validation
    for (const rule of rules) {
      const result = rule.validate(value);
      if (!result.valid) {
        errors.push(result.message);
      }
    }

    // Async validation
    for (const rule of asyncRules) {
      const result = await rule.validate(value);
      if (!result.valid) {
        errors.push(result.message);
      }
    }

    this.errors.set(field, errors);
    this.touched.add(field);
    return errors.length === 0;
  }

  getErrors(field: string): string[] {
    return this.errors.get(field) || [];
  }

  isTouched(field: string): boolean {
    return this.touched.has(field);
  }

  clear() {
    this.errors.clear();
    this.touched.clear();
  }
}

interface ValidationRule {
  validate(value: any): { valid: boolean; message: string };
}

interface AsyncValidationRule {
  validate(value: any): Promise<{ valid: boolean; message: string }>;
}

// Validation rules library
const ValidationRules = {
  required: (message = 'This field is required'): ValidationRule => ({
    validate: (value) => ({
      valid: value !== null && value !== undefined && value !== '',
      message
    })
  }),

  email: (message = 'Invalid email address'): ValidationRule => ({
    validate: (value) => ({
      valid: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
      message
    })
  }),

  minLength: (min: number, message?: string): ValidationRule => ({
    validate: (value) => ({
      valid: value.length >= min,
      message: message || `Minimum length is ${min}`
    })
  }),

  pattern: (regex: RegExp, message = 'Invalid format'): ValidationRule => ({
    validate: (value) => ({
      valid: regex.test(value),
      message
    })
  }),

  asyncUnique: (checkFn: (value: any) => Promise<boolean>, message = 'Already exists'): AsyncValidationRule => ({
    validate: async (value) => {
      const isUnique = await checkFn(value);
      return { valid: isUnique, message };
    }
  })
};
```

### Advanced Multi-Step Form
```typescript
// Multi-step form with progress tracking and validation
interface FormStep {
  id: string;
  title: string;
  fields: FormField[];
  validate?: () => Promise<boolean>;
}

interface FormField {
  name: string;
  type: string;
  label: string;
  required?: boolean;
  validation?: ValidationRule[];
}

function MultiStepForm({ steps }: { steps: FormStep[] }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const validator = useRef(new FormValidator());

  const handleFieldChange = async (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Debounced validation
    const isValid = await validator.current.validate(field, value);
    const fieldErrors = validator.current.getErrors(field);
    
    setErrors(prev => ({
      ...prev,
      [field]: fieldErrors.join(', ')
    }));
  };

  const canProceed = async (): Promise<boolean> => {
    const currentFields = steps[currentStep].fields;
    let isValid = true;

    for (const field of currentFields) {
      const value = formData[field.name];
      const fieldValid = await validator.current.validate(field.name, value);
      isValid = isValid && fieldValid;
    }

    if (steps[currentStep].validate) {
      isValid = isValid && await steps[currentStep].validate();
    }

    return isValid;
  };

  const handleNext = async () => {
    if (await canProceed()) {
      setCurrentStep(prev => Math.min(prev + 1, steps.length - 1));
    }
  };

  const handlePrevious = () => {
    setCurrentStep(prev => Math.max(prev - 1, 0));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // Final validation
      let allValid = true;
      for (const step of steps) {
        for (const field of step.fields) {
          const value = formData[field.name];
          const isValid = await validator.current.validate(field.name, value);
          allValid = allValid && isValid;
        }
      }

      if (allValid) {
        // Submit form data
        await submitForm(formData);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} noValidate>
      {/* Progress bar */}
      <div className="progress-container">
        <div 
          className="progress-bar" 
          style={{ width: `${((currentStep + 1) / steps.length) * 100}%` }}
        />
        <div className="progress-steps">
          {steps.map((step, index) => (
            <div 
              key={step.id}
              className={`step ${index === currentStep ? 'active' : ''} ${index < currentStep ? 'completed' : ''}`}
            >
              <span className="step-number">{index + 1}</span>
              <span className="step-title">{step.title}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Current step fields */}
      <div className="form-step">
        {steps[currentStep].fields.map(field => (
          <div key={field.name} className="form-field">
            <label htmlFor={field.name}>
              {field.label}
              {field.required && <span className="required">*</span>}
            </label>
            <input
              id={field.name}
              name={field.name}
              type={field.type}
              value={formData[field.name] || ''}
              onChange={(e) => handleFieldChange(field.name, e.target.value)}
              aria-invalid={!!errors[field.name]}
              aria-describedby={errors[field.name] ? `${field.name}-error` : undefined}
            />
            {errors[field.name] && (
              <span id={`${field.name}-error`} className="error">
                {errors[field.name]}
              </span>
            )}
          </div>
        ))}
      </div>

      {/* Navigation */}
      <div className="form-navigation">
        <button
          type="button"
          onClick={handlePrevious}
          disabled={currentStep === 0}
        >
          Previous
        </button>
        {currentStep < steps.length - 1 ? (
          <button type="button" onClick={handleNext}>
            Next
          </button>
        ) : (
          <button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Submitting...' : 'Submit'}
          </button>
        )}
      </div>
    </form>
  );
}
```

### Dynamic Form Builder
```typescript
// JSON schema-based form generator
interface FormSchema {
  fields: FieldSchema[];
  layout?: 'vertical' | 'horizontal' | 'grid';
  validation?: Record<string, ValidationRule[]>;
}

interface FieldSchema {
  name: string;
  type: 'text' | 'email' | 'number' | 'select' | 'checkbox' | 'radio' | 'textarea' | 'date';
  label: string;
  placeholder?: string;
  options?: { value: string; label: string }[];
  defaultValue?: any;
  required?: boolean;
  grid?: { col: number; row: number; colSpan?: number; rowSpan?: number };
}

function DynamicForm({ schema, onSubmit }: { schema: FormSchema; onSubmit: (data: any) => void }) {
  const [formData, setFormData] = useState<Record<string, any>>(() => {
    const initial: Record<string, any> = {};
    schema.fields.forEach(field => {
      initial[field.name] = field.defaultValue || '';
    });
    return initial;
  });

  const renderField = (field: FieldSchema) => {
    switch (field.type) {
      case 'select':
        return (
          <select
            id={field.name}
            name={field.name}
            value={formData[field.name]}
            onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
            required={field.required}
          >
            <option value="">Select...</option>
            {field.options?.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        );

      case 'checkbox':
        return (
          <input
            type="checkbox"
            id={field.name}
            name={field.name}
            checked={formData[field.name] || false}
            onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.checked }))}
          />
        );

      case 'radio':
        return (
          <div className="radio-group">
            {field.options?.map(option => (
              <label key={option.value}>
                <input
                  type="radio"
                  name={field.name}
                  value={option.value}
                  checked={formData[field.name] === option.value}
                  onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
                />
                {option.label}
              </label>
            ))}
          </div>
        );

      case 'textarea':
        return (
          <textarea
            id={field.name}
            name={field.name}
            value={formData[field.name]}
            onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
            placeholder={field.placeholder}
            required={field.required}
          />
        );

      default:
        return (
          <input
            type={field.type}
            id={field.name}
            name={field.name}
            value={formData[field.name]}
            onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
            placeholder={field.placeholder}
            required={field.required}
          />
        );
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className={`form-${schema.layout || 'vertical'}`}>
      {schema.layout === 'grid' ? (
        <div className="form-grid">
          {schema.fields.map(field => (
            <div
              key={field.name}
              className="form-field"
              style={field.grid ? {
                gridColumn: `${field.grid.col} / span ${field.grid.colSpan || 1}`,
                gridRow: `${field.grid.row} / span ${field.grid.rowSpan || 1}`
              } : undefined}
            >
              <label htmlFor={field.name}>{field.label}</label>
              {renderField(field)}
            </div>
          ))}
        </div>
      ) : (
        schema.fields.map(field => (
          <div key={field.name} className="form-field">
            <label htmlFor={field.name}>{field.label}</label>
            {renderField(field)}
          </div>
        ))
      )}
      <button type="submit">Submit</button>
    </form>
  );
}
```

### File Upload with Progress
```typescript
// Advanced file upload component
function FileUploadField() {
  const [files, setFiles] = useState<File[]>([]);
  const [uploadProgress, setUploadProgress] = useState<Record<string, number>>({});
  const [uploadStatus, setUploadStatus] = useState<Record<string, 'pending' | 'uploading' | 'success' | 'error'>>({});
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []);
    const validFiles = selectedFiles.filter(file => {
      // Validation
      if (file.size > 10 * 1024 * 1024) { // 10MB limit
        alert(`${file.name} is too large`);
        return false;
      }
      if (!['image/jpeg', 'image/png', 'application/pdf'].includes(file.type)) {
        alert(`${file.name} has invalid type`);
        return false;
      }
      return true;
    });

    setFiles(prev => [...prev, ...validFiles]);
    
    // Auto-upload
    validFiles.forEach(file => uploadFile(file));
  };

  const uploadFile = async (file: File) => {
    const formData = new FormData();
    formData.append('file', file);

    setUploadStatus(prev => ({ ...prev, [file.name]: 'uploading' }));

    try {
      await axios.post('/api/upload', formData, {
        onUploadProgress: (progressEvent) => {
          const percentCompleted = Math.round(
            (progressEvent.loaded * 100) / (progressEvent.total || 1)
          );
          setUploadProgress(prev => ({ ...prev, [file.name]: percentCompleted }));
        }
      });

      setUploadStatus(prev => ({ ...prev, [file.name]: 'success' }));
    } catch (error) {
      setUploadStatus(prev => ({ ...prev, [file.name]: 'error' }));
    }
  };

  const removeFile = (fileName: string) => {
    setFiles(prev => prev.filter(f => f.name !== fileName));
    delete uploadProgress[fileName];
    delete uploadStatus[fileName];
  };

  return (
    <div className="file-upload">
      <div
        className="upload-zone"
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => {
          e.preventDefault();
          const droppedFiles = Array.from(e.dataTransfer.files);
          handleFileSelect({ target: { files: droppedFiles } } as any);
        }}
        onClick={() => fileInputRef.current?.click()}
      >
        <svg className="upload-icon" />
        <p>Drag & drop files here or click to browse</p>
        <p className="upload-hint">Supported: JPG, PNG, PDF (max 10MB)</p>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        multiple
        accept="image/jpeg,image/png,application/pdf"
        onChange={handleFileSelect}
        style={{ display: 'none' }}
      />

      {files.length > 0 && (
        <div className="file-list">
          {files.map(file => (
            <div key={file.name} className="file-item">
              <div className="file-info">
                <span className="file-name">{file.name}</span>
                <span className="file-size">{(file.size / 1024).toFixed(2)} KB</span>
              </div>
              
              {uploadStatus[file.name] === 'uploading' && (
                <div className="progress-bar">
                  <div 
                    className="progress-fill"
                    style={{ width: `${uploadProgress[file.name] || 0}%` }}
                  />
                </div>
              )}
              
              <div className="file-status">
                {uploadStatus[file.name] === 'success' && <span className="success">✓</span>}
                {uploadStatus[file.name] === 'error' && <span className="error">✗</span>}
                <button onClick={() => removeFile(file.name)}>Remove</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

### Autosave and Draft Management
```typescript
// Form with autosave functionality
function AutosaveForm() {
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [lastSaved, setLastSaved] = useState<Date | null>(null);
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved' | 'error'>('idle');
  const saveTimeoutRef = useRef<NodeJS.Timeout>();

  // Load draft on mount
  useEffect(() => {
    const draft = localStorage.getItem('form-draft');
    if (draft) {
      setFormData(JSON.parse(draft));
      setLastSaved(new Date(localStorage.getItem('form-draft-time') || ''));
    }
  }, []);

  // Autosave logic
  const autosave = useCallback(async (data: Record<string, any>) => {
    setSaveStatus('saving');
    
    try {
      // Save to localStorage
      localStorage.setItem('form-draft', JSON.stringify(data));
      localStorage.setItem('form-draft-time', new Date().toISOString());
      
      // Optional: Save to server
      await fetch('/api/draft', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      
      setLastSaved(new Date());
      setSaveStatus('saved');
      
      setTimeout(() => setSaveStatus('idle'), 2000);
    } catch (error) {
      setSaveStatus('error');
    }
  }, []);

  const handleFieldChange = (field: string, value: any) => {
    const newData = { ...formData, [field]: value };
    setFormData(newData);
    
    // Debounced autosave
    clearTimeout(saveTimeoutRef.current);
    saveTimeoutRef.current = setTimeout(() => {
      autosave(newData);
    }, 1000);
  };

  const clearDraft = () => {
    localStorage.removeItem('form-draft');
    localStorage.removeItem('form-draft-time');
    setFormData({});
    setLastSaved(null);
  };

  return (
    <form>
      <div className="form-header">
        <div className="save-status">
          {saveStatus === 'saving' && <span>Saving...</span>}
          {saveStatus === 'saved' && <span>✓ Saved</span>}
          {saveStatus === 'error' && <span>⚠ Save failed</span>}
          {lastSaved && (
            <span className="last-saved">
              Last saved: {lastSaved.toLocaleTimeString()}
            </span>
          )}
        </div>
      </div>

      <input
        type="text"
        name="title"
        value={formData.title || ''}
        onChange={(e) => handleFieldChange('title', e.target.value)}
        placeholder="Title"
      />

      <textarea
        name="content"
        value={formData.content || ''}
        onChange={(e) => handleFieldChange('content', e.target.value)}
        placeholder="Content"
      />

      <div className="form-actions">
        <button type="button" onClick={clearDraft}>
          Clear Draft
        </button>
        <button type="submit">
          Submit
        </button>
      </div>
    </form>
  );
}
```

### Complex Conditional Logic
```typescript
// Form with dynamic conditional fields
interface ConditionalField {
  name: string;
  condition: (formData: any) => boolean;
  component: React.ComponentType<any>;
}

function ConditionalForm() {
  const [formData, setFormData] = useState<Record<string, any>>({
    userType: 'individual'
  });

  const conditionalFields: ConditionalField[] = [
    {
      name: 'companyName',
      condition: (data) => data.userType === 'business',
      component: ({ value, onChange }) => (
        <input
          type="text"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Company Name"
        />
      )
    },
    {
      name: 'taxId',
      condition: (data) => data.userType === 'business' && data.country === 'US',
      component: ({ value, onChange }) => (
        <input
          type="text"
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Tax ID"
          pattern="[0-9]{2}-[0-9]{7}"
        />
      )
    }
  ];

  const handleFieldChange = (field: string, value: any) => {
    setFormData(prev => {
      const newData = { ...prev, [field]: value };
      
      // Clear conditional fields that no longer meet conditions
      conditionalFields.forEach(cf => {
        if (!cf.condition(newData) && newData[cf.name]) {
          delete newData[cf.name];
        }
      });
      
      return newData;
    });
  };

  return (
    <form>
      <select
        value={formData.userType}
        onChange={(e) => handleFieldChange('userType', e.target.value)}
      >
        <option value="individual">Individual</option>
        <option value="business">Business</option>
      </select>

      {formData.userType === 'business' && (
        <select
          value={formData.country || ''}
          onChange={(e) => handleFieldChange('country', e.target.value)}
        >
          <option value="">Select Country</option>
          <option value="US">United States</option>
          <option value="UK">United Kingdom</option>
        </select>
      )}

      {conditionalFields.map(field => {
        if (!field.condition(formData)) return null;
        
        const Component = field.component;
        return (
          <div key={field.name}>
            <Component
              value={formData[field.name]}
              onChange={(value: any) => handleFieldChange(field.name, value)}
            />
          </div>
        );
      })}
    </form>
  );
}
```

## Production Checklist
- [ ] HTML5 validation attributes implemented
- [ ] Custom validation with proper error messages
- [ ] Async validation for unique checks
- [ ] Multi-step forms with progress tracking
- [ ] File upload with validation and progress
- [ ] Autosave functionality for long forms
- [ ] Conditional fields properly managed
- [ ] Accessibility features (labels, ARIA)
- [ ] Mobile-responsive form layouts
- [ ] Performance optimized with debouncing