# Release Versioning

## Version Source

- The current standalone library version lives in `/Users/bermi/code/libmusictheory/VERSION`.
- The file must contain a semver-like value: `MAJOR.MINOR.PATCH` with an optional pre-release suffix.
- The current scaffold value is `0.1.0-dev`.

## Changelog Policy

- `/Users/bermi/code/libmusictheory/CHANGELOG.md` is the public-facing release log.
- Keep `## [Unreleased]` at the top while work is still in flight.
- When cutting a release, move the relevant entries into a dated version section and keep the prose focused on public surface changes.

## Compatibility Rules

- Breaking changes to the stable public C ABI or the documented standalone browser surface require a major version bump.
- New stable APIs or materially new standalone capabilities require a minor version bump.
- Backward-compatible fixes, docs-only changes, or release-process changes use a patch bump.
- Internal Harmonious regression work alone does not justify a public version bump unless it changes the standalone public surface or shipped artifacts.

## Tag Shape

- Release tags should use `vMAJOR.MINOR.PATCH`.
- Pre-release builds may use semver prerelease suffixes in `VERSION`, but the tagged release should resolve to a clean stable version.
