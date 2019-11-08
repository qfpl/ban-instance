{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}


{-|
Module      : Language.Haskell.Instance.Ban
Description : Declare that a typeclass instance
Copyright   : (c) 2017, Commonwealth Scientific and Industrial Research Organisation
License     : BSD3
Maintainer  : jack.kelly@data61.csiro.au
Stability   : experimental
Portability : Non-Portable
-}

module Language.Haskell.Instance.Ban (banInstance) where

import Data.Maybe                 (mapMaybe)
import GHC.TypeLits
import Language.Haskell.TH.Lib
import Language.Haskell.TH.Ppr
import Language.Haskell.TH.Syntax

-- TODO: Mark instances as deprecated so haddock sees them.
-- TODO: Overlappable instances?
-- | Ban an instance of a typeclass; code which tries to use the
-- banned instance will fail at compile time. This works by generating
-- an instance that depends on a custom type error:
--
-- @
-- instance TypeError (..) => ToJSON Foo where
--   ...
-- @
--
-- Use it like this:
--
-- @
-- \$(banInstance [t|ToJSON Foo|] "why ToJSON Foo should never be defined")
-- @
banInstance
  :: TypeQ
     -- ^ The instance you want to ban.
     -- Most easily written with a type-quote: @[t|ToJSON Foo|]@
  -> String -- ^ The reason that this instance is banned.
  -> DecsQ
banInstance constraintQ message = do
  loc <- qLocation
  ClassI (ClassD _ _ _ _ classDecs) _ <- className <$> constraintQ >>= reify
  let context :: CxtQ
      context = cxt [[t|TypeError ('Text "Attempt to use banned instance (" ':<>: 'ShowType $(constraintQ) ':<>: 'Text ")"
                                  ':$$: 'Text "Reason for banning: " ':<>: 'Text $(symbol message)
                                  ':$$: 'Text "Instance banned at " ':<>: 'Text $(symbol $ formatLocation loc)
                                  ':$$: 'Text ""
                                  )|]]
  pure <$> instanceD context constraintQ (convertClassDecs classDecs)

symbol :: String -> TypeQ
symbol = litT . strTyLit

formatLocation :: Loc -> String
formatLocation Loc{..} = concat ["[", loc_package, ":", loc_module, "] ", loc_filename, ":",  show $ fst loc_start]

className :: Type -> Name
className topTy = go topTy where
  go (AppT ty _) = className ty
  go (ConT name) = name
  go _ = error $ "Cannot determine class name for type: " ++ pprint topTy

convertClassDecs :: [Dec] -> [DecQ]
convertClassDecs = mapMaybe go where
  -- TODO: Support type/data families?
  go (SigD name _) = Just $ funD name [clause [] (normalB [|undefined|]) []]
  go DefaultSigD{} = Nothing
  go _ = error "Banning instances only supported for classes \
               \that contain only functions. Patches welcome."
