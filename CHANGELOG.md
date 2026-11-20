# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

The entries up to 1.0.6 were written in November 2026, from the git history
and the tags of each release.

## [Unreleased]

### Changed
- CI builds and tests every change with Stack, against the C libraries of
  Ubuntu and with Nix, and builds the Haddock documentation. It runs through
  the workflow that the Haskell packages of jprupp share in
  [jprupp/tools](https://github.com/jprupp/tools).
- This changelog.
- A README like those of the Haskoin packages: what the hash is for, its
  design, examples that print the reference's hashes, its use in Bitcoin's
  Bloom filters, what it is not, and how it is tested and developed.
- Haddock like that of the Haskoin packages: a module header with the
  purpose of the hash, its design and when not to use it, and examples on
  `murmur3` that give the reference's hashes, Bitcoin's Bloom filter seeds
  among them. The steps of the code say what each does.
- The code and the tests are formatted with ormolu (`haskell-format`).
- The description in `package.yaml` keeps its line breaks, so that the
  generated Cabal file has no line of 120 columns or more.
- The links to the reference implementation point to SMHasher on GitHub,
  since Google Code is gone, and the homepage, bug tracker and source
  repository of the package are those of jprupp/murmur3, where the
  repository lives now.

## [1.0.6] - 2025-05-09

### Changed
- The author is JP Rupp, and the maintainer's address is
  jprupp@protonmail.ch.
- Built with Stack's LTS 23.21 snapshot.

## [1.0.5] - 2021-09-28

### Changed
- The package is described by `package.yaml` (hpack), and the Cabal file is
  generated from it.
- The tests use the `base16` package in place of `base16-bytestring`.
- Built with Stack's LTS 18.12 snapshot, without warnings.

## [1.0.4] - 2020-06-12

### Changed
- The license is MIT, in place of the Unlicense (public domain).
- The Cabal file names its default language, as Cabal 1.10 requires, and the
  repository has a `stack.yaml`.

## [1.0.3] - 2016-08-02

### Changed
- No upper bounds on the dependencies but `base`, so that the package builds
  with newer versions of `bytestring`, `cereal` and the test libraries.

## [1.0.2] - 2016-06-14

### Changed
- Builds with `cereal` 0.5.2 and `HUnit` 1.3.

## [1.0.1] - 2016-01-10

### Changed
- Faster: the hash is computed strictly, with a strict left fold over the
  blocks, where it built up thunks for each one before.
- Reads the blocks with `cereal` in place of `binary`, from the strict
  `ByteString` as it is, without converting it to a lazy one.
- Builds without `-Werror`, so that a new warning of a new compiler does
  not stop the build.

## [1.0.0] - 2015-06-15

### Added
- `murmur3`: MurmurHash3 x86_32 of a strict `ByteString` with a seed, as in
  the reference implementation of SMHasher.

[Unreleased]: https://github.com/jprupp/murmur3/compare/v1.0.6...HEAD
[1.0.6]: https://github.com/jprupp/murmur3/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/jprupp/murmur3/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/jprupp/murmur3/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/jprupp/murmur3/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/jprupp/murmur3/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/jprupp/murmur3/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/jprupp/murmur3/releases/tag/v1.0.0
