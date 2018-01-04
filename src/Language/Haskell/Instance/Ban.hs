{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}

module Language.Haskell.Instance.Ban (banInstance) where

import GHC.TypeLits
import Language.Haskell.TH.Lib
import Language.Haskell.TH.Ppr
import Language.Haskell.TH.Syntax

-- TODO: Mark instances as deprecated so haddock sees them.
-- TODO: Overlappable instances?
banInstance :: TypeQ -> String -> DecsQ
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
convertClassDecs = map go where
  -- TODO: Support type/data families?
  go (SigD name _) = funD name [clause [] (normalB [|undefined|]) []]
  go _ = error "Banning instances only supported for classes \
               \that contain only functions. Patches welcome."
