#!/usr/bin/env cabal-script-run
{- cabal:
build-depends: base ^>= 4.14
               , text ^>= 1.2
               , shelly ^>= 1.8.1
-}

-- Also, this needs to run a new version of cabal so that it doesn't
-- recompile the script every time I run it, due to a missing feature
-- in older versions of cabal.
-- https://github.com/haskell/cabal/commit/bbc11f1c71651e910976c16498bc4871d7b416ea
-- $HOME/.ghcup/bin/cabal-3.10.3.0
-- See installed versions of cabal with: ghcup tui
-- Install the required version with: ghcup install cabal 3.10.3.0

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
import Data.Text.Lazy as LT
import Shelly
import Prelude hiding (FilePath)
default (LT.Text)

-- main = putStrLn "hello"

-- main :: IO ()
-- main = do
--     ...

sudo_ com args = run_ "cmd" (com:args)

main = shelly $ verbosely $ do
    apt_get "update" []
    apt_get "install" ["haskell-platform"]
    where
    apt_get mode more = sudo_ "apt-get" (["-y", "-q", mode] ++ more)


-- https://cabal.readthedocs.io/en/3.6/cabal-commands.html#cabal-v2-run
-- https://www.yesodweb.com/blog/2012/03/shelly-for-shell-scripts
