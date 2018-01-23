# ban-instance - For when a type should never be an instance of a class

![Data61](http://i.imgur.com/0h9dFhl.png)

## Synopsis

```haskell
{-# LANGUAGE TemplateHaskell #-}

-- The generated code requires at least these extensions
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE UndecideableInstances #-}

import Lanuage.Haskell.Instance.Ban

data Foo = -- ...

-- Declare that Foo should never have an Eq instance
$(banInstance [t|Eq Foo|] "why Eq Foo should never be defined")
```

## Motivation

Banning an instance allows the programmer to actively declare that
this instance should never be defined, and to provide a reason why. In
terms of what programs the compiler will accept, banning an instance
is the same as leaving it undefined.

Our main use case is banning `ToJSON`/`FromJSON` instances on "core"
data structures to ensure serialisation/deserialisation is defined at
API boundaries. We have systems which send and receive values of
similar types over multiple different APIs, and which need to vary
their JSON representations independently to allow upgrades. Defining
serialisation on core data types means that changes to the
`ToJSON`/`FromJSON` instance can cause breakage at your API layer, on
the other side of the codebase. Better to ban `ToJSON`/`FromJSON` on
the core data types, and define types for presentation that live
alongside the rest of the API:

```haskell
-- In some "core types" module:
data Foo = -- ...
$(banInstance [t|ToJSON Foo|] "use a data type at the presentation layer")
$(banInstance [t|FromJSON Foo|] "use a data type at the presentation layer")

data Bar = -- ...
$(banInstance [t|ToJSON Bar|] "use a data type at the presentation layer")
$(banInstance [t|FromJSON Bar|] "use a data type at the presentation layer")

-- In the module for "API One":
data Baz = Baz Foo Int

instance ToJSON Baz where -- ...
instance FromJSON Baz where -- ...

-- In the module for "API Two":
data Quux = Quux Foo Bar

instance ToJSON Quux where -- ...
instance FromJSON Quux where -- ...
```

## Limitations

* There is currently no support for type classes with associated types
  or associated data types.
* Type quotations `[t|...|]` do not support free variables
  ([GHC#5616](https://ghc.haskell.org/trac/ghc/ticket/5616)).
