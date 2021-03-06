{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
module HooglePluginSpec where

import           Control.Monad
import           Control.Monad.IO.Class
import           Data.Maybe
import           Haskell.Ide.Engine.MonadTypes
import           Haskell.Ide.Engine.Support.Hoogle
import           Hoogle
import           System.Directory
import           System.FilePath
import           Test.Hspec
import           TestUtils

-- ---------------------------------------------------------------------

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "hoogle plugin" hoogleSpec

-- ---------------------------------------------------------------------

testPlugins :: IdePlugins
testPlugins = pluginDescToIdePlugins []

dispatchRequestP :: IdeGhcM a -> IO a
dispatchRequestP act = do
  cwd <- liftIO $ getCurrentDirectory
  runIGM testPlugins (cwd </> "test" </> "testdata" </> "File.hs") act

-- ---------------------------------------------------------------------

hoogleSpec :: Spec
hoogleSpec = do
  describe "hoogle environment" $
    it "Checks the default dababase location" $ do
      db <- defaultDatabaseLocation
      exists <- doesFileExist db
      unless exists $ hoogle ["generate"]
  describe "hoogle initialization" $ do
    it "initialization succeeds" $ do
      r <- dispatchRequestP initializeHoogleDb
      isJust r `shouldBe` True

  ---- ---------------------------------

  describe "hoogle plugin commands(new plugin api)" $ do
    it "runs the info command" $ do
      let req = liftToGhc $ info "head"
      r <- dispatchRequestP $ initializeHoogleDb >> req
      r `shouldBe` Right "```haskell\nhead :: [a] -> a\n```\nExtract the first element of a list, which must be non-empty.\n\n[More info](https://hackage.haskell.org/package/base/docs/Prelude.html#v:head)"

    -- ---------------------------------

    it "runs the lookup command" $ do
      let req = liftToGhc $ Haskell.Ide.Engine.Support.Hoogle.lookup 1 "[a] -> a"
      r <- dispatchRequestP $ initializeHoogleDb >> req
      r `shouldBe` Right ["Prelude head :: [a] -> a"]
