# Immutability Patterns

## Basic Immutable Operations

```javascript
// Immutable array updates
const addItem = (arr, item) => [...arr, item];
const removeItem = (arr, index) => [
  ...arr.slice(0, index),
  ...arr.slice(index + 1)
];
const updateItem = (arr, index, newItem) => [
  ...arr.slice(0, index),
  newItem,
  ...arr.slice(index + 1)
];

// Immutable object updates
const setProperty = (obj, key, value) => ({
  ...obj,
  [key]: value
});

const updateProperty = (obj, key, updater) => ({
  ...obj,
  [key]: updater(obj[key])
});

const deleteProperty = (obj, key) => {
  const { [key]: deleted, ...rest } = obj;
  return rest;
};
```

## Deep Object Updates

```javascript
// Path-based deep updates
const setIn = (obj, path, value) => {
  const [head, ...tail] = path;
  
  if (tail.length === 0) {
    return { ...obj, [head]: value };
  }
  
  return {
    ...obj,
    [head]: setIn(obj[head] || {}, tail, value)
  };
};

const updateIn = (obj, path, updater) => {
  const [head, ...tail] = path;
  
  if (tail.length === 0) {
    return { ...obj, [head]: updater(obj[head]) };
  }
  
  return {
    ...obj,
    [head]: updateIn(obj[head] || {}, tail, updater)
  };
};

// Usage example
const state = {
  user: {
    profile: {
      name: 'John',
      age: 30
    },
    preferences: {
      theme: 'dark'
    }
  }
};

const newState = setIn(state, ['user', 'profile', 'name'], 'Jane');
const incrementedAge = updateIn(state, ['user', 'profile', 'age'], age => age + 1);
```

## Custom Immutable Data Structures

```javascript
// Immutable List
class ImmutableList {
  constructor(items = []) {
    this.items = Object.freeze([...items]);
  }
  
  add(item) {
    return new ImmutableList([...this.items, item]);
  }
  
  remove(index) {
    return new ImmutableList([
      ...this.items.slice(0, index),
      ...this.items.slice(index + 1)
    ]);
  }
  
  update(index, updater) {
    return new ImmutableList(
      this.items.map((item, i) => 
        i === index ? updater(item) : item
      )
    );
  }
  
  map(fn) {
    return new ImmutableList(this.items.map(fn));
  }
  
  filter(predicate) {
    return new ImmutableList(this.items.filter(predicate));
  }
  
  reduce(reducer, initial) {
    return this.items.reduce(reducer, initial);
  }
  
  get(index) {
    return this.items[index];
  }
  
  get length() {
    return this.items.length;
  }
  
  toArray() {
    return [...this.items];
  }
}

// Immutable Map
class ImmutableMap {
  constructor(entries = []) {
    this.data = Object.freeze(
      entries.reduce((acc, [key, value]) => ({ ...acc, [key]: value }), {})
    );
  }
  
  set(key, value) {
    return new ImmutableMap([
      ...Object.entries(this.data),
      [key, value]
    ]);
  }
  
  delete(key) {
    const { [key]: deleted, ...rest } = this.data;
    return new ImmutableMap(Object.entries(rest));
  }
  
  get(key) {
    return this.data[key];
  }
  
  has(key) {
    return key in this.data;
  }
  
  keys() {
    return Object.keys(this.data);
  }
  
  values() {
    return Object.values(this.data);
  }
  
  entries() {
    return Object.entries(this.data);
  }
  
  map(fn) {
    return new ImmutableMap(
      this.entries().map(([key, value]) => [key, fn(value)])
    );
  }
  
  filter(predicate) {
    return new ImmutableMap(
      this.entries().filter(([key, value]) => predicate(value, key))
    );
  }
}
```

## Structural Sharing Optimization

```javascript
// Efficient array updates (structural sharing)
class PersistentVector {
  constructor(items = [], trie = null) {
    this.items = items;
    this.trie = trie;
    this.length = items.length;
  }
  
  push(item) {
    // Simplified implementation (actual would use trie structure)
    if (this.length < 32) {
      return new PersistentVector([...this.items, item]);
    }
    // More efficient trie-based implementation needed
    return new PersistentVector([...this.items, item]);
  }
  
  set(index, value) {
    if (index >= this.length) {
      throw new Error('Index out of bounds');
    }
    
    const newItems = [...this.items];
    newItems[index] = value;
    return new PersistentVector(newItems);
  }
  
  get(index) {
    return this.items[index];
  }
}

// Copy-on-Write optimization
class COWArray {
  constructor(items = [], isCopied = false) {
    this._items = items;
    this._isCopied = isCopied;
  }
  
  _ensureCopy() {
    if (!this._isCopied) {
      this._items = [...this._items];
      this._isCopied = true;
    }
  }
  
  push(item) {
    const newArray = new COWArray(this._items);
    newArray._ensureCopy();
    newArray._items.push(item);
    return newArray;
  }
  
  set(index, value) {
    const newArray = new COWArray(this._items);
    newArray._ensureCopy();
    newArray._items[index] = value;
    return newArray;
  }
  
  get(index) {
    return this._items[index];
  }
  
  get length() {
    return this._items.length;
  }
  
  toArray() {
    return [...this._items];
  }
}
```

## Functional Updates with Lenses

```javascript
// Lens pattern implementation
const Lens = {
  of: (getter, setter) => ({ get: getter, set: setter }),
  
  prop: (key) => Lens.of(
    obj => obj[key],
    value => obj => ({ ...obj, [key]: value })
  ),
  
  path: (keys) => keys.reduce((lens, key) => 
    Lens.compose(lens, Lens.prop(key)),
    Lens.identity
  ),
  
  compose: (outerLens, innerLens) => Lens.of(
    obj => innerLens.get(outerLens.get(obj)),
    value => obj => outerLens.set(innerLens.set(value)(outerLens.get(obj)))(obj)
  ),
  
  identity: Lens.of(x => x, value => _ => value),
  
  over: (lens, fn) => obj => lens.set(fn(lens.get(obj)))(obj),
  view: (lens, obj) => lens.get(obj),
  set: (lens, value) => obj => lens.set(value)(obj)
};

// Usage example
const userLens = Lens.prop('user');
const nameLens = Lens.path(['user', 'name']);
const ageLens = Lens.path(['user', 'age']);

const state = {
  user: { name: 'John', age: 30 },
  settings: { theme: 'dark' }
};

const updateName = Lens.set(nameLens, 'Jane');
const incrementAge = Lens.over(ageLens, age => age + 1);

const newState = pipe(
  updateName,
  incrementAge
)(state);

console.log(newState);
```