#!/usr/bin/env haskellscript
--#aeson
{-# LANGUAGE OverloadedStrings #-}
import Data.Aeson
import Data.ByteString.Lazy hiding (putStrLn, unpack)
import Data.Text
import Data.Text.Encoding
main = putStrLn $ unpack $ decodeUtf8 $ toStrict $ encode $ object ["Test" .= True, "Example" .= True]

-- This scripting method requires haskellscript and a sandbox capable install of Cabal

-- Sadly, haskellscript just seems a little dated.
-- `cabal install --allow-newer haskellscript` has trouble
