# Releasing

Clipper releases are tag-driven. A release tag publishes a universal macOS
archive and updates the Homebrew tap.

## Release steps

1. Update `ClipperVersion.current` in `Sources/ClipperCore/Version.swift`.
2. Run the local verification:

   ```sh
   version=0.1.0
   swift test
   scripts/build-release-archive.sh "$version"
   ```

3. Commit and push the version change.
4. Create and push the release tag:

   ```sh
   git tag -a "v$version" -m "clipper v$version"
   git push origin "v$version"
   ```

5. Confirm the `release` workflow and Homebrew tap checks pass.
