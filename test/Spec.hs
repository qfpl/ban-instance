{-# OPTIONS_GHC -Wno-unused-matches -Wno-unused-top-binds #-}

{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE RankNTypes             #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE UndecidableInstances   #-}

import Language.Haskell.Instance.Ban

-- Test code generation. We define a class and ban an instance of it,
-- checking that the generated code throws no warnings. If this file
-- compiles cleanly, the "test" has passed.

class TestClass a b | a -> b where
  testFunction :: a -> b

$(banInstance [t|TestClass Char Int|] "because it's really bad")

-- Test that we haven't overlapped other instances by mistake.
instance TestClass Int Int where
  testFunction = const 0

main :: IO ()
main = const (testFunction '3' :: Int) $ pure ()
