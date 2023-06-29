# Release Please

This repository contains a `release-please` configuration file for automating releases using GitHub Actions.

## Workflow

The workflow defined in this configuration is triggered on a push event to the `main` branch.

### Permissions

The following permissions are required for the workflow:

- Contents: Write
- Pull Requests: Write

## Jobs

### release-please

This job runs on `ubuntu-latest` and performs the following steps:

1. It uses the `google-github-actions/release-please-action` version 3 to automate releases.
2. The `release-type` is set to `node`.
3. The `package-name` is specified as `release-please-action`.
4. The `changelog-types` are defined as follows:
   - `feat` changes will be included in the "Features" section of the changelog.
   - `fix` changes will be included in the "Bug Fixes" section of the changelog.
   - `chore` changes will be included in the "Miscellaneous" section of the changelog.

Please refer to the [release-please documentation](https://github.com/google-github-actions/release-please-action) for more details on how to use the action.

# Release Workflow

This repository contains a release workflow configuration for automating the release process using GitHub Actions. The workflow is triggered when a pull request is closed.

## Workflow

The workflow defined in this configuration has the following specifications:

- Event: Pull request closed
- Job: build

### Job: build

This job runs on `ubuntu-latest` and performs the following steps:

1. Checks out the code using the `actions/checkout` action, fetching all tags.
2. Exits the workflow if the pull request is not merged.
3. Sets up Node.js using the `actions/setup-node` action with Node.js version 16.x.
4. Sets up NPM authentication using the `npm set` command with the GitHub token stored in the `GITHUB_TOKEN` secret.
5. Installs npm globally and runs `npm ci` to install project dependencies.
6. Creates a release archive by zipping specified files and directories.
7. Retrieves the package version from the `package.json` file.
8. Generates a changelog by comparing the previous version tag with the current HEAD using Git commands.
9. Creates a GitHub release using the `softprops/action-gh-release` action, uploading the release archive, providing a tag name, release name, and release notes from the changelog file.
10. Publishes the package to NPM using the `npm publish` command with the `GITHUB_TOKEN` environment variable set to the GitHub token.

Please note that you should configure the required secrets, such as `GITHUB_TOKEN`, for this workflow to function properly.

