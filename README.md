# murmur3

[![Hackage](https://img.shields.io/hackage/v/murmur3.svg)](https://hackage.haskell.org/package/murmur3)
[![CI](https://github.com/jprupp/murmur3/actions/workflows/ci.yml/badge.svg)](https://github.com/jprupp/murmur3/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jprupp/murmur3/blob/master/LICENSE)

MurmurHash3 in pure Haskell: the 32-bit x86 variant, as Austin Appleby's
reference implementation in [SMHasher][smhasher] computes it, of a strict
`ByteString` with a seed. It is the hash of the Bloom filters of Bitcoin
(BIP 37), which [haskoin-core](https://github.com/jprupp/haskoin-core) builds
with it.

- [API documentation](https://hackage.haskell.org/package/murmur3)
- [Changelog](https://github.com/jprupp/murmur3/blob/master/CHANGELOG.md)
- [Report a bug](https://github.com/jprupp/murmur3/issues)

## Contents

- [Why murmur3](#why-murmur3)
- [Design](#design)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Bloom filters](#bloom-filters)
- [What it is not](#what-it-is-not)
- [Testing](#testing)
- [Development](#development)
- [License](#license)

## Why murmur3

A hash table, a Bloom filter or a sharding scheme needs a hash that is fast,
spreads its input evenly over the output, and gives the same answer on every
machine. MurmurHash3 is such a hash, and a common one. When a program has to
agree with another that uses it, such as a Bitcoin node checking a Bloom
filter, it needs MurmurHash3 exactly, not a hash like it.

This package gives that one function, with no C code to build and no
dependencies past `bytestring` and `cereal`. It follows the reference
implementation step by step, so that it gives the reference's answers.

## Design

- **The x86_32 variant only.** MurmurHash3 comes in three variants, x86_32,
  x86_128 and x64_128, which give different hashes. Bitcoin, and most
  protocols that name a 32-bit MurmurHash3, mean x86_32, and this package is
  that one.
- **The same answer on every machine.** The reference reads each block of four
  bytes in the byte order of the machine, so a big-endian machine gets other
  hashes. This package reads them little-endian everywhere, which is what the
  reference gives on x86 and ARM, and what protocols specify.
- **Strict input.** The whole input is in memory: the hash mixes in its
  length in its last step. Hash a lazy `ByteString` with `toStrict` first.
- **Strict computation.** The blocks are folded with a strict left fold, so a
  long input does not build up thunks.

## Installation

Add it to the dependencies of your package:

```yaml
dependencies:
  - murmur3 >= 1.0.6
```

It builds with Stack and Cabal, on any platform that GHC supports.

## Quick start

`murmur3` takes the seed and the bytes, and gives the hash:

```haskell
import Data.Hash.Murmur (murmur3)
import qualified Data.ByteString.Char8 as C
import Text.Printf (printf)

main :: IO ()
main = do
  printf "0x%08x\n" (murmur3 0 (C.pack "hello"))
  printf "0x%08x\n" (murmur3 1 (C.pack "hello"))
```

It prints `0x248bfa47` and `0xbb4abcad`. Another seed gives another hash of
the same bytes: a seed picks one hash function of a family, which is what a
Bloom filter needs several of.

## Bloom filters

A Bloom filter of Bitcoin (BIP 37) sets, for each item, one bit for each of
its hash functions. Hash function `i` of a filter is MurmurHash3 with the seed
`i * 0xFBA4C795 + tweak`, where the tweak is a number that the filter's owner
picks, and the bit is the hash modulo the number of bits of the filter:

```haskell
import Data.ByteString (ByteString)
import Data.Hash.Murmur (murmur3)
import Data.Word (Word32)

-- | The bit that hash function i of a filter of so many bytes sets for an
-- item. The seed wraps around at 2^32, as BIP 37 says.
bloomBit :: Word32 -> Word32 -> Int -> ByteString -> Word32
bloomBit tweak i bytes item = murmur3 (i * 0xFBA4C795 + tweak) item `mod` (fromIntegral bytes * 8)
```

`Haskoin.Network.Bloom` in haskoin-core computes it the same way.

## What it is not

- **Not a cryptographic hash.** Collisions are easy to make on purpose, and a
  seed does not keep them out of reach. Where an attacker chooses the input
  and gains from collisions, as in a hash table that a server fills from
  requests, use SipHash or a cryptographic hash such as SHA-256.
- **Not x64_128.** The 128-bit variants are not here.
- **Not incremental.** The input comes in one piece; there is no interface to
  feed it in parts.

## Testing

The tests check the hash of every length of input from none to nine bytes,
and of the empty and one-byte inputs with other seeds, against the hashes of
the reference implementation:

```sh
stack test
```

## Development

CI builds and tests every change with Stack, against the libraries of Ubuntu
and with Nix, through the workflow that the Haskell packages of jprupp share.
That workflow and the scripts below are in
[jprupp/tools](https://github.com/jprupp/tools):

```sh
haskell-format             # format every Haskell file with ormolu
check-stack-paths          # refuse local paths in stack.yaml
haskell-release --dry-run  # build, test and pack a release without publishing
```

Changes are described in [CHANGELOG.md](CHANGELOG.md). Contributions are
welcome as pull requests on GitHub.

## License

MIT; see [LICENSE](LICENSE).

[smhasher]: https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp
