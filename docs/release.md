# AX Stats release workflow

The `release` workflow builds the fork's macOS application and creates a
GitHub Release with these assets:

- `Stats.dmg` for the in-app updater;
- `Stats-<version>.zip` for the `AXIOMZK/homebrew-ax-stats` cask.

## Publish a release

After the change has landed on `master`, use either method:

1. Create and push a tag:

   ```bash
   git tag -a v3.0.18 -m "Release v3.0.18"
   git push origin v3.0.18
   ```

2. Open **Actions → release → Run workflow**, select `master`, and enter a
   tag such as `v3.0.18`.

The tag is the release version. Keep it in `vMAJOR.MINOR.PATCH` form. The
workflow builds the tagged commit for a tag-triggered run, or the selected
branch for a manually triggered run.

Before publishing, update `MARKETING_VERSION` for the Stats target in
`Stats.xcodeproj/project.pbxproj` to the same version (for example `3.0.18`).
The workflow rejects a tag when the built app version does not match it.

## Homebrew cask updates

The release itself works with the repository's built-in `GITHUB_TOKEN`. To
also open an automatic cask update PR, add an Actions secret named
`HOMEBREW_TAP_TOKEN` to `AXIOMZK/stats`. The token must be allowed to dispatch
workflows in `AXIOMZK/homebrew-ax-stats`; the tap workflow recalculates the
archive checksum and opens a PR instead of writing directly to `main`.
