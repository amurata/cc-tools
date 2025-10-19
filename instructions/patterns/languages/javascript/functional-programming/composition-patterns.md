# Function Composition Patterns

## Basic Function Composition

```javascript
// Implementation of compose and pipe
const compose = (...fns) => (value) => 
  fns.reduceRight((acc, fn) => fn(acc), value);

const pipe = (...fns) => (value) => 
  fns.reduce((acc, fn) => fn(acc), value);

// Basic usage example
const trim = str => str.trim();
const toLowerCase = str => str.toLowerCase();
const removeSpaces = str => str.replace(/\\s+/g, '');
const addPrefix = prefix => str => `${prefix}${str}`;

const normalizeString = pipe(
  trim,
  toLowerCase,
  removeSpaces,
  addPrefix('normalized_')
);

console.log(normalizeString('  Hello World  ')); // 'normalized_helloworld'
```

## Currying and Partial Application

```javascript
// Generic currying function
const curry = (fn) => {
  const arity = fn.length;
  
  return function curried(...args) {
    if (args.length >= arity) {
      return fn.apply(this, args);
    } else {
      return function(...args2) {
        return curried.apply(this, args.concat(args2));
      };
    }
  };
};

// Practical currying examples
const add = curry((a, b, c) => a + b + c);
const map = curry((fn, array) => array.map(fn));
const filter = curry((predicate, array) => array.filter(predicate));
const reduce = curry((reducer, initial, array) => array.reduce(reducer, initial));

// Partial application usage
const add1 = add(1);
const add1and2 = add1(2);
const result = add1and2(3); // 6

const numbers = [1, 2, 3, 4, 5];
const double = x => x * 2;
const isEven = x => x % 2 === 0;
const sum = (acc, x) => acc + x;

const doubledNumbers = map(double)(numbers);
const evenNumbers = filter(isEven)(numbers);
const total = reduce(sum, 0)(numbers);

// Partial application with placeholders
const _ = Symbol('placeholder');

const partialWithPlaceholders = (fn, ...args) => {
  return (...remainingArgs) => {
    let argIndex = 0;
    const finalArgs = args.map(arg => 
      arg === _ ? remainingArgs[argIndex++] : arg
    );
    return fn(...finalArgs, ...remainingArgs.slice(argIndex));
  };
};

const divide = (a, b) => a / b;
const divideBy2 = partialWithPlaceholders(divide, _, 2);
const halveTen = partialWithPlaceholders(divide, 10, _);

console.log(divideBy2(10)); // 5
console.log(halveTen(2));   // 5
```

## Async Composition

```javascript
// Async function composition
const composeAsync = (...fns) => (value) =>
  fns.reduceRight((acc, fn) => acc.then(fn), Promise.resolve(value));

const pipeAsync = (...fns) => (value) =>
  fns.reduce((acc, fn) => acc.then(fn), Promise.resolve(value));

// Async utility functions
const fetchUser = async (id) => ({ id, name: `User ${id}` });
const addTimestamp = async (user) => ({ ...user, timestamp: Date.now() });
const formatUser = async (user) => `${user.name} (${user.id}) - ${user.timestamp}`;
const logResult = async (result) => {
  console.log(result);
  return result;
};

// Async pipeline
const processUser = pipeAsync(
  fetchUser,
  addTimestamp,
  formatUser,
  logResult
);

processUser(123).then(result => console.log('Final:', result));

// Async composition with error handling
const safeComposeAsync = (...fns) => async (value) => {
  try {
    return await fns.reduceRight((acc, fn) => acc.then(fn), Promise.resolve(value));
  } catch (error) {
    console.error('Pipeline error:', error);
    throw error;
  }
};
```

## Advanced Composition Patterns

```javascript
// Conditional composition
const when = (predicate, fn) => (value) =>
  predicate(value) ? fn(value) : value;

const unless = (predicate, fn) => (value) =>
  predicate(value) ? value : fn(value);

const ifElse = (predicate, onTrue, onFalse) => (value) =>
  predicate(value) ? onTrue(value) : onFalse(value);

// Branching pipeline
const processNumber = pipe(
  when(x => x < 0, Math.abs),
  unless(x => x > 100, x => x * 2),
  ifElse(
    x => x % 2 === 0,
    x => `Even: ${x}`,
    x => `Odd: ${x}`
  )
);

console.log(processNumber(-5));  // Even: 10
console.log(processNumber(150)); // Odd: 150

// Parallel composition (functor application)
const lift2 = (fn) => (f1, f2) => (value) =>
  fn(f1(value), f2(value));

const lift3 = (fn) => (f1, f2, f3) => (value) =>
  fn(f1(value), f2(value), f3(value));

// Parallel transformation application
const getName = user => user.name;
const getAge = user => user.age;
const getEmail = user => user.email;

const combineUserInfo = lift3(
  (name, age, email) => `${name} (${age}) - ${email}`
)(getName, getAge, getEmail);

const user = { name: 'John', age: 30, email: 'john@example.com' };
console.log(combineUserInfo(user)); // John (30) - john@example.com
```

## Kleisli Composition (Monads)

```javascript
// Maybe monad and Kleisli composition
const kleisli = (f, g) => (x) => f(x).flatMap(g);

const safeDivide = (a, b) => 
  b === 0 ? Maybe.nothing() : Maybe.of(a / b);

const safeRoot = (x) => 
  x < 0 ? Maybe.nothing() : Maybe.of(Math.sqrt(x));

const safeLog = (x) =>
  x <= 0 ? Maybe.nothing() : Maybe.of(Math.log(x));

// Kleisli composition
const safeCalculation = kleisli(
  kleisli(x => safeDivide(x, 4), safeRoot),
  safeLog
);

console.log(safeCalculation(16).getOrElse('error')); // ~0.693
console.log(safeCalculation(-4).getOrElse('error')); // 'error'

// Fish operator (>=>) implementation
const fish = kleisli;

const pipeline = fish(
  fish(x => safeDivide(x, 2), safeRoot),
  safeLog
);

// Multiple Kleisli function composition
const composeK = (...fns) => (value) =>
  fns.reduce((acc, fn) => acc.flatMap(fn), Maybe.of(value));

const safeProcess = composeK(
  x => safeDivide(x, 2),
  safeRoot,
  safeLog
);

console.log(safeProcess(Math.E * Math.E * 4).getOrElse('error')); // 1
```

## Lens Combination

```javascript
// Lens-based composition
const Lens = {
  of: (getter, setter) => ({ get: getter, set: setter }),
  
  over: (lens, fn) => obj => lens.set(fn(lens.get(obj)))(obj),
  
  compose: (outerLens, innerLens) => Lens.of(
    obj => innerLens.get(outerLens.get(obj)),
    value => obj => outerLens.set(innerLens.set(value)(outerLens.get(obj)))(obj)
  )
};

const prop = (key) => Lens.of(
  obj => obj[key],
  value => obj => ({ ...obj, [key]: value })
);

// Lens composition
const userLens = prop('user');
const nameLens = prop('name');
const userNameLens = Lens.compose(userLens, nameLens);

const state = {
  user: { name: 'John', age: 30 },
  settings: { theme: 'dark' }
};

// Function composition with lens operations
const updateUserName = pipe(
  Lens.over(userNameLens, name => name.toUpperCase()),
  Lens.over(prop('timestamp'), () => Date.now())
);

const newState = updateUserName({ ...state, timestamp: 0 });
console.log(newState);
```