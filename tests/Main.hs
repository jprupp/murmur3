module Main where

import qualified Data.Hash.Murmur.Units (tests)
import Test.Framework (defaultMain)

main :: IO ()
main = defaultMain (Data.Hash.Murmur.Units.tests)
