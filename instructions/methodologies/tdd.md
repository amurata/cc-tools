# Test-Driven Development (TDD)

Following Kent Beck's Test-Driven Development methodology with strict adherence to the Red-Green-Refactor cycle and Tidy First principles.

## Core TDD Cycle

### Red → Green → Refactor

1. **RED**: Write a failing test
   - Define desired behavior
   - Test must fail initially
   - Failure validates test correctness

2. **GREEN**: Make test pass
   - Write minimal code
   - Focus only on passing
   - Avoid over-engineering

3. **REFACTOR**: Improve structure
   - Clean up code
   - Remove duplication
   - Maintain all tests passing

## Development Principles

### Test First
- Never write production code without a failing test
- Tests define requirements
- Tests guide implementation
- Tests document behavior

### Incremental Development
- Small steps, frequent commits
- One test at a time
- Minimal implementation
- Continuous validation

### Simplicity
- Simplest solution that works
- YAGNI (You Aren't Gonna Need It)
- Defer complexity until proven necessary
- Eliminate speculation

## Tidy First Approach

### Change Separation

**Structural Changes** (Tidy)
- Renaming variables/methods
- Extracting functions
- Moving code
- Formatting improvements
- No behavior modification

**Behavioral Changes** (Feature)
- New functionality
- Bug fixes
- Logic modifications
- Algorithm changes
- Observable differences

### Change Order
1. Make structural improvements first
2. Commit structural changes separately
3. Then add behavioral changes
4. Never mix types in one commit

## Test Writing Guidelines

### Test Structure
```javascript
describe('Component/Feature', () => {
  it('should perform expected behavior', () => {
    // Arrange
    const input = setupTestData();
    
    // Act
    const result = executeFunction(input);
    
    // Assert
    expect(result).toBe(expectedValue);
  });
});
```

### Test Naming
- Describe behavior, not implementation
- Use "should" statements
- Be specific and clear
- Examples:
  - ✅ `shouldCalculateTotalWithTax`
  - ✅ `shouldRejectInvalidEmail`
  - ❌ `test1`
  - ❌ `checkFunction`

### Test Characteristics
- **Fast**: Run quickly
- **Independent**: No test dependencies
- **Repeatable**: Same results every time
- **Self-Validating**: Clear pass/fail
- **Timely**: Written just before code

## Implementation Process

### Step-by-Step Workflow

1. **Understand Requirement**
   - Read Issue/Story
   - Identify smallest testable unit
   - Plan test scenarios

2. **Write Failing Test**
   ```javascript
   it('should add two numbers', () => {
     expect(add(2, 3)).toBe(5);
   });
   // Test fails: add() not defined
   ```

3. **Minimal Implementation**
   ```javascript
   function add(a, b) {
     return a + b;
   }
   // Test passes
   ```

4. **Refactor If Needed**
   - Extract constants
   - Improve naming
   - Remove duplication
   - Run tests after each change

5. **Commit**
   - Separate commits for structure vs behavior
   - Clear commit messages
   - Reference Issue number

6. **Repeat**
   - Next test case
   - Build incrementally
   - Maintain momentum

## Refactoring Guidelines

### When to Refactor
- After test passes (Green phase)
- When duplication appears
- When intent unclear
- Before adding complexity

### Safe Refactoring
1. Ensure all tests passing
2. Make single change
3. Run tests
4. If fail, revert immediately
5. If pass, continue or commit

### Common Refactorings
- Extract Method
- Rename Variable
- Inline Function
- Replace Magic Number
- Introduce Parameter Object

## Code Quality Standards

### Principles
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **SRP**: Single Responsibility Principle
- **Clear Intent**: Code reads like documentation

### Practices
- Small, focused methods
- Descriptive naming
- Minimal state
- Explicit dependencies
- Immutability preference

## Commit Discipline

### Commit Rules
1. Only commit when ALL tests pass
2. No compiler warnings
3. Single logical change
4. Clear commit type (structural/behavioral)

### Commit Messages
```bash
# Structural change
refactor(auth): extract validation logic [structural]

# Behavioral change  
feat(auth): add email validation [behavioral]

# Test addition
test(auth): add edge cases for validation
```

## Anti-Patterns to Avoid

### Testing Anti-Patterns
- ❌ Writing multiple tests at once
- ❌ Writing code before tests
- ❌ Skipping refactor phase
- ❌ Testing implementation details
- ❌ Dependent tests

### Code Anti-Patterns
- ❌ Premature optimization
- ❌ Speculative generality
- ❌ Mixed structural/behavioral changes
- ❌ Large commits
- ❌ Ignoring test failures

## Integration with Issue-Driven Development

1. Read Issue for requirements
2. Break into testable units
3. Write test for first unit
4. Implement minimal solution
5. Refactor and commit
6. Update Issue with progress
7. Repeat until complete

## Tools and Commands

### Running Tests
```bash
# Run all tests
npm test

# Run specific test file
npm test auth.test.js

# Watch mode for TDD
npm test -- --watch

# Coverage report
npm test -- --coverage
```

### TDD Workflow Commands
```bash
# 1. Create feature branch
git checkout -b feature/123_add_validation

# 2. Write test (it fails)
# 3. Run test to confirm failure
npm test

# 4. Implement minimum code
# 5. Run test to confirm pass
npm test

# 6. Refactor if needed
# 7. Commit
git add .
git commit -m "feat(auth): add validation [behavioral]"

# 8. Repeat for next test
```

## Benefits of TDD

### Immediate
- Faster debugging
- Clear requirements
- Confident refactoring
- Living documentation

### Long-term
- Maintainable codebase
- Reduced regression
- Lower defect rate
- Easier onboarding