# Releasing

Clipper releases are tag-driven. A release tag builds one universal macOS
binary archive, publishes it to GitHub Releases, and opens a pull request
against `h3nock/homebrew-tap`.

## One-time setup

Create a fine-grained token that can write contents and pull requests in
`h3nock/homebrew-tap`, then store it in the `h3nock/clipper` repository:

```sh
gh secret set HOMEBREW_TAP_TOKEN --repo h3nock/clipper
```

The built-in `GITHUB_TOKEN` can publish the `h3nock/clipper` release, but it
cannot write to the separate tap repository.

## Release steps

1. Update `ClipperVersion.current` in `Sources/ClipperCore/Version.swift`.
2. Run the local verification:

   ```sh
   version=0.1.0
   swift test
   scripts/build-release-archive.sh "$version"
   ```

3. Commit the version change.
4. Create and push the release tag:

   ```sh
   git tag -a "v$version" -m "clipper v$version"
   git push origin "v$version"
   ```

5. Wait for the `release` workflow to create the GitHub Release and the
   `h3nock/homebrew-tap` formula pull request.
6. Merge the tap pull request after its Homebrew checks pass.

After the tap pull request is merged:

```sh
brew install h3nock/tap/clipper
```
