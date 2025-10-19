# Type-Safe Functional Programming

## Advanced Type Definitions in TypeScript

```typescript
// Type-safe function composition implementation
type Fn<A, B> = (a: A) => B;

const pipe = <A>() => <B>(f: Fn<A, B>) => ({
  pipe: <C>(g: Fn<B, C>) => pipe<A>().pipe(compose(g, f)),
  value: (a: A) => f(a)
});

const compose = <A, B, C>(g: Fn<B, C>, f: Fn<A, B>): Fn<A, C> =>
  (a: A) => g(f(a));

// Usage example
const addOne = (x: number): number => x + 1;
const toString = (x: number): string => x.toString();
const addExclamation = (s: string): string => `${s}!`;

const pipeline = pipe<number>()
  .pipe(addOne)
  .pipe(toString)
  .pipe(addExclamation);

console.log(pipeline.value(5)); // "6!"

// Type-safe currying implementation
type Curry<P extends readonly unknown[], R> = 
  P extends readonly [infer A, ...infer Rest]
    ? (arg: A) => Curry<Rest, R>
    : R;

const curry = <P extends readonly unknown[], R>(
  fn: (...args: P) => R
): Curry<P, R> => 
  ((...args: P) => 
    args.length >= fn.length 
      ? fn(...args)
      : curry((fn as any).bind(null, ...args))
  ) as Curry<P, R>;

// Usage example
const add3 = (a: number, b: number, c: number): number => a + b + c;
const curriedAdd3 = curry(add3);

const result = curriedAdd3(1)(2)(3); // number type
```

## Type-Safe Monad Implementation

```typescript
// Maybe monad type definitions
abstract class Maybe<T> {
  abstract map<U>(f: (value: T) => U): Maybe<U>;
  abstract flatMap<U>(f: (value: T) => Maybe<U>): Maybe<U>;
  abstract filter(predicate: (value: T) => boolean): Maybe<T>;
  abstract getOrElse<U>(defaultValue: U): T | U;
  
  static of<T>(value: T | null | undefined): Maybe<T> {
    return value == null ? new Nothing<T>() : new Some(value);
  }
  
  static some<T>(value: T): Maybe<T> {
    return new Some(value);
  }
  
  static nothing<T>(): Maybe<T> {
    return new Nothing<T>();
  }
}

class Some<T> extends Maybe<T> {
  constructor(private value: T) {
    super();
  }
  
  map<U>(f: (value: T) => U): Maybe<U> {
    return Maybe.some(f(this.value));
  }
  
  flatMap<U>(f: (value: T) => Maybe<U>): Maybe<U> {
    return f(this.value);
  }
  
  filter(predicate: (value: T) => boolean): Maybe<T> {
    return predicate(this.value) ? this : Maybe.nothing<T>();
  }
  
  getOrElse<U>(_defaultValue: U): T {
    return this.value;
  }
}

class Nothing<T> extends Maybe<T> {
  map<U>(_f: (value: T) => U): Maybe<U> {
    return new Nothing<U>();
  }
  
  flatMap<U>(_f: (value: T) => Maybe<U>): Maybe<U> {
    return new Nothing<U>();
  }
  
  filter(_predicate: (value: T) => boolean): Maybe<T> {
    return this;
  }
  
  getOrElse<U>(defaultValue: U): U {
    return defaultValue;
  }
}

// Either monad type definitions
abstract class Either<L, R> {
  abstract map<T>(f: (value: R) => T): Either<L, T>;
  abstract flatMap<T>(f: (value: R) => Either<L, T>): Either<L, T>;
  abstract mapLeft<T>(f: (value: L) => T): Either<T, R>;
  abstract fold<T>(leftFn: (left: L) => T, rightFn: (right: R) => T): T;
  
  static left<L, R>(value: L): Either<L, R> {
    return new Left<L, R>(value);
  }
  
  static right<L, R>(value: R): Either<L, R> {
    return new Right<L, R>(value);
  }
}

class Left<L, R> extends Either<L, R> {
  constructor(private value: L) {
    super();
  }
  
  map<T>(_f: (value: R) => T): Either<L, T> {
    return new Left<L, T>(this.value);
  }
  
  flatMap<T>(_f: (value: R) => Either<L, T>): Either<L, T> {
    return new Left<L, T>(this.value);
  }
  
  mapLeft<T>(f: (value: L) => T): Either<T, R> {
    return Either.left<T, R>(f(this.value));
  }
  
  fold<T>(leftFn: (left: L) => T, _rightFn: (right: R) => T): T {
    return leftFn(this.value);
  }
}

class Right<L, R> extends Either<L, R> {
  constructor(private value: R) {
    super();
  }
  
  map<T>(f: (value: R) => T): Either<L, T> {
    return Either.right<L, T>(f(this.value));
  }
  
  flatMap<T>(f: (value: R) => Either<L, T>): Either<L, T> {
    return f(this.value);
  }
  
  mapLeft<T>(_f: (value: L) => T): Either<T, R> {
    return new Right<T, R>(this.value);
  }
  
  fold<T>(_leftFn: (left: L) => T, rightFn: (right: R) => T): T {
    return rightFn(this.value);
  }
}
```

## Functional Data Structures

```typescript
// Type-safe immutable list implementation
class List<T> {
  constructor(private items: ReadonlyArray<T>) {}
  
  static empty<T>(): List<T> {
    return new List<T>([]);
  }
  
  static of<T>(...items: T[]): List<T> {
    return new List(items);
  }
  
  cons(item: T): List<T> {
    return new List([item, ...this.items]);
  }
  
  head(): Maybe<T> {
    return this.items.length > 0 
      ? Maybe.some(this.items[0])
      : Maybe.nothing<T>();
  }
  
  tail(): List<T> {
    return new List(this.items.slice(1));
  }
  
  map<U>(f: (item: T) => U): List<U> {
    return new List(this.items.map(f));
  }
  
  filter(predicate: (item: T) => boolean): List<T> {
    return new List(this.items.filter(predicate));
  }
  
  reduce<U>(reducer: (acc: U, item: T) => U, initial: U): U {
    return this.items.reduce(reducer, initial);
  }
  
  flatMap<U>(f: (item: T) => List<U>): List<U> {
    return this.reduce(
      (acc, item) => acc.concat(f(item)),
      List.empty<U>()
    );
  }
  
  concat(other: List<T>): List<T> {
    return new List([...this.items, ...other.items]);
  }
  
  isEmpty(): boolean {
    return this.items.length === 0;
  }
  
  toArray(): ReadonlyArray<T> {
    return this.items;
  }
}

// Usage example
const numbers = List.of(1, 2, 3, 4, 5);
const doubled = numbers.map(x => x * 2);
const evens = numbers.filter(x => x % 2 === 0);
const nested = List.of(
  List.of(1, 2),
  List.of(3, 4),
  List.of(5, 6)
);
const flattened = nested.flatMap(x => x);
```

## Higher Kinded Types and Kind

```typescript
// HKT (Higher Kinded Type) implementation
interface HKT<F, A> {
  readonly _F: F;
  readonly _A: A;
}

// Functor type class
interface Functor<F> {
  map<A, B>(fa: HKT<F, A>, f: (a: A) => B): HKT<F, B>;
}

// Monad type class
interface Monad<F> extends Functor<F> {
  of<A>(a: A): HKT<F, A>;
  flatMap<A, B>(fa: HKT<F, A>, f: (a: A) => HKT<F, B>): HKT<F, B>;
}

// Maybe HKT implementation
const MaybeURI = 'Maybe';
type MaybeURI = typeof MaybeURI;

declare module './HKT' {
  interface URItoKind<A> {
    [MaybeURI]: Maybe<A>;
  }
}

const MaybeFunctor: Functor<MaybeURI> = {
  map: <A, B>(fa: Maybe<A>, f: (a: A) => B): Maybe<B> => fa.map(f)
};

const MaybeMonad: Monad<MaybeURI> = {
  ...MaybeFunctor,
  of: <A>(a: A): Maybe<A> => Maybe.of(a),
  flatMap: <A, B>(fa: Maybe<A>, f: (a: A) => Maybe<B>): Maybe<B> => 
    fa.flatMap(f)
};

// Generic functions
const sequence = <F>(M: Monad<F>) => 
  <A>(mas: Array<HKT<F, A>>): HKT<F, Array<A>> =>
    mas.reduce(
      (acc, ma) => M.flatMap(acc, as => M.map(ma, a => [...as, a])),
      M.of([])
    );

// Usage example
const maybeSequence = sequence(MaybeMonad);
const maybes = [Maybe.of(1), Maybe.of(2), Maybe.of(3)] as Array<Maybe<number>>;
const result = maybeSequence(maybes); // Maybe<number[]>
```

## Type-Level Programming

```typescript
// Type-level calculations
type Length<T extends readonly unknown[]> = T['length'];
type Head<T extends readonly unknown[]> = T extends readonly [infer H, ...unknown[]] ? H : never;
type Tail<T extends readonly unknown[]> = T extends readonly [unknown, ...infer Rest] ? Rest : [];

type Reverse<T extends readonly unknown[]> = T extends readonly [...infer Rest, infer Last]
  ? [Last, ...Reverse<Rest>]
  : [];

// Type-safe Path operations
type PathValue<T, P extends string> = 
  P extends `${infer Key}.${infer Rest}`
    ? Key extends keyof T
      ? PathValue<T[Key], Rest>
      : never
    : P extends keyof T
      ? T[P]
      : never;

type SetPath<T, P extends string, V> = 
  P extends `${infer Key}.${infer Rest}`
    ? Key extends keyof T
      ? {
          [K in keyof T]: K extends Key 
            ? SetPath<T[K], Rest, V>
            : T[K]
        }
      : never
    : P extends keyof T
      ? {
          [K in keyof T]: K extends P ? V : T[K]
        }
      : never;

// Type-safe lens
type Lens<S, A> = {
  get: (s: S) => A;
  set: (a: A) => (s: S) => S;
};

const lens = <S, A>(
  get: (s: S) => A,
  set: (a: A) => (s: S) => S
): Lens<S, A> => ({ get, set });

const prop = <S, K extends keyof S>(key: K): Lens<S, S[K]> =>
  lens(
    (s: S) => s[key],
    (value: S[K]) => (s: S) => ({ ...s, [key]: value })
  );

// Usage example
interface User {
  name: string;
  age: number;
  address: {
    street: string;
    city: string;
  };
}

const user: User = {
  name: 'John',
  age: 30,
  address: { street: '123 Main St', city: 'Tokyo' }
};

const nameLens = prop<User, 'name'>('name');
const newUser = nameLens.set('Jane')(user);

// Type-level path validation
type UserNamePath = PathValue<User, 'name'>; // string
type UserCityPath = PathValue<User, 'address.city'>; // string
// type InvalidPath = PathValue<User, 'invalid.path'>; // never (compile error)
```