{-# LANGUAGE BangPatterns #-}

-- |
-- Module      : Data.Hash.Murmur
-- Copyright   : (c) Haskoin Developers
-- License     : MIT
-- Maintainer  : jprupp@protonmail.ch
-- Stability   : stable
-- Portability : portable
--
-- MurmurHash3, the 32-bit x86 variant, as Austin Appleby's reference
-- implementation in
-- <https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp SMHasher>
-- computes it.
--
-- == Purpose
--
-- A hash table, a Bloom filter or a sharding scheme needs a hash that is
-- fast, spreads its input evenly over its output, and gives the same answer
-- on every machine. MurmurHash3 is such a hash. A program that has to agree
-- with another that uses it, such as a Bitcoin node that checks a Bloom
-- filter of BIP 37, needs MurmurHash3 exactly, not a hash like it. This
-- module gives it in pure Haskell, with no C code to build.
--
-- == Design
--
-- * __The x86_32 variant only.__ MurmurHash3 comes in three variants,
--   x86_32, x86_128 and x64_128, which give different hashes. Bitcoin, and
--   most protocols that name a 32-bit MurmurHash3, mean x86_32.
--
-- * __The same answer on every machine.__ The reference reads each block of
--   four bytes in the byte order of the machine, so it gives other hashes on
--   a big-endian one. This module reads the blocks little-endian everywhere:
--   what the reference gives on x86 and ARM, and what protocols specify.
--
-- * __Strict input.__ The hash mixes in the length of the input in its last
--   step, so the whole input has to be there. It takes a strict
--   'BS.ByteString'; hash a lazy one with @toStrict@ first.
--
-- * __Step by step as the reference.__ The code follows the reference's
--   body, tail and finalization, with the same constants, so that it can be
--   read against it. The blocks are folded with a strict left fold, so a
--   long input builds up no thunks.
--
-- == Example
--
-- >>> import qualified Data.ByteString.Char8 as C
-- >>> murmur3 0 (C.pack "hello")
-- 613153351
--
-- That is @0x248bfa47@, the hash that the reference gives.
--
-- == When not to use it
--
-- MurmurHash3 is not a cryptographic hash: collisions are easy to make on
-- purpose, whatever the seed. Where an attacker picks the input and gains
-- from collisions, as in a hash table that a server fills from requests,
-- use SipHash or a cryptographic hash such as SHA-256.
module Data.Hash.Murmur (murmur3) where

import Control.Monad (replicateM)
import Data.Bits
  ( rotateL,
    shiftR,
    xor,
  )
import qualified Data.ByteString as BS
  ( ByteString,
    append,
    drop,
    length,
    replicate,
  )
import Data.List (foldl')
import Data.Serialize.Get
  ( getWord32le,
    runGet,
  )
import Data.Word (Word32)

-- | The MurmurHash3 x86_32 hash of some bytes with a seed, as the
-- reference implementation gives it on a little-endian machine.
--
-- The seed picks one hash function out of a family: the same bytes give
-- unrelated hashes with different seeds. A Bloom filter, which needs
-- several hash functions, gets them from one hash with several seeds. In
-- Bitcoin's (BIP 37), hash function @i@ of a filter has the seed
-- @i * 0xFBA4C795 + tweak@, which wraps around at 2^32 as 'Word32' does:
--
-- >>> import qualified Data.ByteString.Char8 as C
-- >>> murmur3 (2 * 0xFBA4C795 + 5) (C.pack "hello")
-- 3021625566
--
-- The empty input with the seed 0 hashes to 0, as in the reference.
murmur3 ::
  -- | seed
  Word32 ->
  -- | the bytes to hash
  BS.ByteString ->
  -- | their hash
  Word32
murmur3 nHashSeed bs =
  h8
  where
    -- The input is read as blocks of four bytes, little-endian, and a tail
    -- of up to three bytes that do not fill a block.
    !nBlocks = BS.length bs `quot` 4
    !nTail = BS.length bs `rem` 4
    -- The blocks, and the tail padded with zeros to a block of its own.
    -- Neither read can fail: there are exactly enough bytes for both.
    Right blocks = runGet (replicateM nBlocks getWord32le) bs
    bsTail = BS.drop (nBlocks * 4) bs `BS.append` BS.replicate (4 - nTail) 0
    -- Body: each block is mixed into the state, from the seed.
    !h1 = foldl' mix nHashSeed blocks
    -- Tail: its bytes are scrambled as a block is, and added to the state
    -- without the rotation and multiplication that a block gets. An empty
    -- tail is a block of zeros, which changes nothing.
    Right !t1 = runGet getWord32le bsTail
    !t2 = t1 * c1
    !t3 = t2 `rotateL` 15
    !t4 = t3 * c2
    !h2 = h1 `xor` t4
    -- Finalization: the length goes in, and the final mix makes every bit
    -- of the state depend on every bit of the input.
    !h3 = h2 `xor` fromIntegral (BS.length bs)
    !h4 = h3 `xor` (h3 `shiftR` 16)
    !h5 = h4 * 0x85ebca6b
    !h6 = h5 `xor` (h5 `shiftR` 13)
    !h7 = h6 * 0xc2b2ae35
    !h8 = h7 `xor` (h7 `shiftR` 16)
    -- How a block goes into the state: it is scrambled with two
    -- multiplications and a rotation, added, and the state is rotated and
    -- multiplied in turn.
    mix !r1 !k1 = r4
      where
        !k2 = k1 * c1
        !k3 = k2 `rotateL` 15
        !k4 = k3 * c2
        !r2 = r1 `xor` k4
        !r3 = r2 `rotateL` 13
        !r4 = r3 * 5 + 0xe6546b64
    -- The constants of the reference.
    c1 = 0xcc9e2d51
    c2 = 0x1b873593
