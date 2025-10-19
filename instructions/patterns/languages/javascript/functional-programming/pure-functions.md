# Pure Functions and Side Effects

## Basic Principles of Pure Functions

```javascript
// Pure function examples
const add = (a, b) => a + b;
const multiply = (x, y) => x * y;
const capitalize = str => str.charAt(0).toUpperCase() + str.slice(1);

// Impure functions and their pure alternatives
// Impure: depends on external state
let counter = 0;
const impureIncrement = () => ++counter;

// Pure: returns new state
const pureIncrement = (count) => count + 1;

// Impure: modifies input
const impurePush = (arr, item) => {
  arr.push(item);
  return arr;
};

// Pure: returns new array
const purePush = (arr, item) => [...arr, item];
```

## Managing Side Effects

```javascript
// Wrapping side effects with pure functions
const createEffectWrapper = (sideEffect) => {
  return (pureFunction) => {
    return (...args) => {
      const result = pureFunction(...args);
      sideEffect(result);
      return result;
    };
  };
};

const logEffect = createEffectWrapper(console.log);
const addWithLogging = logEffect(add);

const result = addWithLogging(2, 3); // Logs: 5, Returns: 5

// Expressing IO operations as pure functions
const createIO = (effect) => ({
  effect,
  map: (fn) => createIO(() => fn(effect())),
  flatMap: (fn) => createIO(() => fn(effect()).effect()),
  run: () => effect()
});

const readFile = (filename) => createIO(() => {
  return `Contents of ${filename}`;
});

const processFile = (content) => content.toUpperCase();

const fileOperation = readFile('test.txt')
  .map(processFile)
  .map(content => `Processed: ${content}`);

console.log(fileOperation.run());
```

## State Management Patterns

```javascript
// State updates with pure functions
const updateState = (state, action) => {
  switch (action.type) {
    case 'INCREMENT':
      return { ...state, count: state.count + 1 };
    case 'DECREMENT':
      return { ...state, count: state.count - 1 };
    case 'SET_NAME':
      return { ...state, name: action.payload };
    default:
      return state;
  }
};

// Lens pattern for deep object manipulation
const lens = (getter, setter) => ({
  get: getter,
  set: setter,
  over: (fn) => (obj) => setter(fn(getter(obj)))(obj)
});

const prop = (key) => lens(
  obj => obj[key],
  value => obj => ({ ...obj, [key]: value })
);

const path = (keys) => keys.reduce((acc, key) => 
  lens(
    obj => acc.get(obj)[key],
    value => obj => acc.set({ ...acc.get(obj), [key]: value })(obj)
  ),
  lens(x => x, value => _ => value)
);

// Usage example
const user = { name: 'John', address: { city: 'Tokyo', zip: '123' } };
const nameLens = prop('name');
const cityLens = path(['address', 'city']);

const newUser = cityLens.set('Osaka')(user);
const upperName = nameLens.over(str => str.toUpperCase())(user);
```

## Error Handling

```javascript
// Managing errors with Result type
const Result = {
  Ok: (value) => ({ type: 'Ok', value }),
  Error: (error) => ({ type: 'Error', error }),
  
  map: (fn) => (result) => 
    result.type === 'Ok' ? Result.Ok(fn(result.value)) : result,
    
  flatMap: (fn) => (result) => 
    result.type === 'Ok' ? fn(result.value) : result,
    
  unwrapOr: (defaultValue) => (result) =>
    result.type === 'Ok' ? result.value : defaultValue
};

// Pure calculations with error handling
const safeDivide = (a, b) => 
  b === 0 ? Result.Error('Division by zero') : Result.Ok(a / b);

const calculate = (x, y, z) =>
  Result.flatMap(result1 =>
    Result.map(result2 => result1 + result2)(safeDivide(y, z))
  )(safeDivide(x, 2));

console.log(calculate(10, 4, 2)); // Ok(7)
console.log(calculate(10, 4, 0)); // Error('Division by zero')
```