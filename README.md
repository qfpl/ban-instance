# ban-instance - For when a type should never have an instance

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

Our main use case is banning `FromJSON`/`ToJSON` instances on common
data structures, because we want to force the programmer to select a
specific serialisation by using `newtype`.

We have systems which send and receive the same data type over
multiple different APIs, and these APIs need to vary their JSON
representations independently to allow upgrades. Defining
serialisation on the bare data type means that changes to the
`FromJSON`/`ToJSON` instance can cause breakage at your API layer,
potentially several layers away. Banning `FromJSON`/`ToJSON` on the
bare data type and using a `newtype` allows the serialisation format
to be defined alongside the rest of the API:

```haskell
-- In some "core types" module:
data Foo = -- ...
$(banInstance [t|FromJSON Foo|]
  "use a newtype wrapper to select a serialisation format")
$(banInstance [t|ToJSON Foo|]
  "use a newtype wrapper to select a serialisation format")

-- In the module for "API One":
newtype ApiOne a = ApiOne a

instance FromJSON (ApiOne Foo) where -- ...
instance ToJSON (ApiOne Foo) where -- ...

-- In the module for "API Two":
newtype ApiTwo a = ApiTwo a

instance FromJSON (ApiTwo Foo) where -- ...
instance ToJSON (ApiTwo Foo) where -- ...
```

## Limitations

* There is currently no support for type classes with associated types
  or associated data types.
* Type quotations `[t|...|]` do not support free variables
  ([GHC#5616](https://ghc.haskell.org/trac/ghc/ticket/5616)).
