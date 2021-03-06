module Data.Path.Pathy.Gen
  ( genAbsDirPath
  , genAbsFilePath
  , genAbsAnyPath
  , genRelDirPath
  , genRelFilePath
  , genRelAnyPath
  )where

import Prelude

import Control.Monad.Gen (class MonadGen)
import Control.Monad.Gen as Gen
import Control.Monad.Rec.Class (class MonadRec)
import Data.Char.Gen as CG
import Data.Either (Either(..))
import Data.Foldable (foldr)
import Data.List as L
import Data.NonEmpty ((:|))
import Data.Path.Pathy (AbsPath, AbsFile, AbsDir, RelDir, RelFile, RelPath, Sandboxed, (</>))
import Data.Path.Pathy as P
import Data.String.Gen as SG

genName ∷ ∀ m. MonadGen m ⇒ MonadRec m ⇒ m String
genName = SG.genString $ Gen.oneOf $ CG.genDigitChar :| [CG.genAlpha]


genAbsDirPath :: forall m. MonadGen m => MonadRec m => m (AbsDir Sandboxed)
genAbsDirPath = Gen.sized \size → do
  newSize ← Gen.chooseInt 0 size
  Gen.resize (const newSize) do
    parts ∷ L.List String ← Gen.unfoldable genName
    pure $ foldr (flip P.appendPath <<< P.dir) P.rootDir parts

genAbsFilePath :: forall m. MonadGen m => MonadRec m => m (AbsFile Sandboxed)
genAbsFilePath = do
  dir ← genAbsDirPath
  file ← genName
  pure $ dir </> P.file file

genAbsAnyPath :: forall m. MonadGen m => MonadRec m => m (AbsPath Sandboxed)
genAbsAnyPath = Gen.oneOf $ (Left <$> genAbsDirPath) :| [Right <$> genAbsFilePath]

genRelDirPath :: forall m. MonadGen m => MonadRec m => m (RelDir Sandboxed)
genRelDirPath = Gen.sized \size → do
  newSize ← Gen.chooseInt 0 size
  Gen.resize (const newSize) do
    parts ∷ L.List String ← Gen.unfoldable genName
    pure $ foldr (flip P.appendPath <<< P.dir) P.currentDir parts

genRelFilePath :: forall m. MonadGen m => MonadRec m => m (RelFile Sandboxed)
genRelFilePath = do
  dir ← genRelDirPath
  file ← genName
  pure $ dir </> P.file file

genRelAnyPath :: forall m. MonadGen m => MonadRec m => m (RelPath Sandboxed)
genRelAnyPath = Gen.oneOf $ (Left <$> genRelDirPath) :| [Right <$> genRelFilePath]
