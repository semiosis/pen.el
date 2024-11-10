#!/usr/bin/env -S stack runhaskell
-- stack --resolver lts-6.25 script --package turtle
{-# LANGUAGE OverloadedStrings #-}
import Turtle
main = echo "Hello World!"

-- This scripting method requires stack

-- ghcup install stack 2.15.7
-- stack install turtle

-- Need to use the runhaskell from stack, not the ghcup runhaskell. Hence the shebang line
-- Sadly, LSP isn't working well but the script works.
