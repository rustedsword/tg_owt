# libtgowt for ppa:lightofmysoul/tg

Ubuntu 26.04 (resolute) and 26.10 (stonking) packaging of tg_owt, Telegram's
WebRTC fork, for **amd64 + arm64**. Telegram Desktop needs it for calls and
screen sharing, and Ubuntu has not shipped it since it dropped `libtgowt` in
2023.

This branch (`tgowt_ubuntu`) *is* the source: a **native** package built from
the checked-out upstream tree with a `debian/` directory added. There are no
patches.

## Usage

```
./publish.sh --test-build --no-upload   # validate locally (~10 min)
./publish.sh                            # sign and upload
./publish.sh --help
```

All Debian work happens inside an Ubuntu podman container of the series being
built, so the host can be Gentoo.

## Why not Debian's package

Debian maintains `libtgowt`, and importing it works — but it is pinned to
upstream `d067233` (2025-11-17) with the newer commits carried as patches, and
its `+dfsg` repack must strip RNNoise because the trained model has no source
form. That costs the RNN voice-activity-detection path in WebRTC's AGC2.

Building the upstream tree directly turns out to be *simpler*, not harder:

- `cmake/external.cmake` already probes for system libraries. Ubuntu has
  `libabsl-dev` and `libsrtp2-dev`, so those are used automatically. It has no
  `libcrc32c-dev`, so crc32c falls back to its bundled submodule, and libyuv is
  always bundled upstream. **No unbundling patches.**
- RNNoise builds as upstream ships it. **No stripping.**
- Debian's remaining patches target toolchains newer than resolute has
  (`Fix-building-with-GCC-16`, `Migrate-to-OpenSSL-4.0.0`) or architectures we
  do not build. **None needed.**

The resulting package is layout-identical to Debian's — same
`/usr/lib/<triplet>/libtg_owt.a`, same `cmake/tg_owt/` config, same include
tree — plus the 27 libyuv and 2 RNNoise headers Debian excludes. So anything
that build-depends on Debian's `libtgowt-dev` works against this unchanged.

## Moving to a newer upstream commit

Telegram Desktop pins an exact tg_owt commit in
`Telegram/build/prepare/prepare.py` (`stage('tg_owt', ...)` → `git checkout`).
Match it:

```
git fetch origin
git rebase <pinned-commit>              # onto the commit tdesktop pins
git submodule update --init src/third_party/libyuv src/third_party/crc32c/src
dch -v 0~git<YYYYMMDD>.<short-sha>+ppa1~resolute1 --distribution resolute "..."
./publish.sh --test-build
```

Use the commit's own date for `<YYYYMMDD>` so versions stay ordered. Note that
tg_owt is a maintenance-only fork — it saw 2 commits in 2026 and 23 in 2025 —
so this is rare.

## Bundled submodules

Only two are needed and only these two should be initialised:

| submodule | why |
|---|---|
| `src/third_party/libyuv` | upstream has no system-libyuv option |
| `src/third_party/crc32c/src` | Ubuntu ships no `libcrc32c-dev` |

`abseil-cpp` and `libsrtp` are deliberately left empty — the system copies are
found instead, and pulling them would only bloat the source tarball.
`publish.sh` refuses to run if the two required ones are missing.

## Version scheme

`0~git<date>.<short-sha>+ppa1~resolute1`

No hyphens: a native package version may not contain a Debian revision.
`+ppa1` marks it as ours. The changelog targets resolute; `publish.sh` uploads
the same version to stonking as `~stonking1`, which sorts above `~resolute1`, so
upgrading Ubuntu upgrades the package.

## Static library, no runtime package

`libtgowt-dev` ships a static library only. Telegram Desktop links it in, so
**bumping this package requires rebuilding telegram-desktop** — nothing picks
up the change automatically.

## Prerequisites

- `podman`, `git`, `gpg` on the host
- GPG key registered on Launchpad; fingerprint at the top of `publish.sh`
- The key must have **no passphrase**, or `debuild` hangs on pinentry inside
  the container
