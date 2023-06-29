# Create release pull request

This repository contains a configuration to automate the creation of release pull requests using GitHub Actions.

## Workflow

The workflow defined in this configuration is triggered on a push event to the `main` branch.

### Permissions

The following permissions are required for the workflow:

- Contents: Write
- Pull Requests: Write

## Jobs

### release-please

This job runs on `ubuntu-latest` and performs the following steps:

1. It uses the `google-github-actions/release-please-action` version 3 to automate the creation of release pull requests.
2. The `release-type` is set to `node`.
3. The `package-name` is specified as `release-please-action`.
4. The `changelog-types` are defined as follows:
   - `feat` changes will be included in the "Features" section of the changelog.
   - `fix` changes will be included in the "Bug Fixes" section of the changelog.
   - `chore` changes will be included in the "Miscellaneous" section of the changelog.

Please refer to the [release-please documentation](https://github.com/google-github-actions/release-please-action) for more details on how to use the action.

# Deploy new version to NPM

This repository contains a configuration to automate the deployment of a new version to NPM using GitHub Actions.

## Workflow

The workflow defined in this configuration is triggered when a pull request is closed.

### Job: build

This job runs on `ubuntu-latest` and performs the following steps:

1. Checks out the code using the `actions/checkout` action, fetching all tags.
2. Exits the workflow if the pull request is not merged.
3. Sets up Node.js using the `actions/setup-node` action with Node.js version 16.x.
4. Sets up NPM authentication using the `npm set` command with the GitHub token stored in the `GITHUB_TOKEN` secret.
5. Installs npm globally and runs `npm ci` to install project dependencies.
6. Configures NPM authentication using the `npm set` command with the GitHub token.
7. Installs project dependencies using `npm ci`.
8. Creates a release archive by zipping specified files and directories.
9. Retrieves the package version from the `package.json` file.
10. Generates a changelog by comparing the previous version tag with the current HEAD using Git commands.
11. Creates a GitHub release using the `softprops/action-gh-release` action, uploading the release archive, providing a tag name, release name, and release notes from the changelog file.
12. Publishes the package to NPM using the `npm publish` command with the `NPM_TOKEN` environment variable set to the GitHub token.

Please note that you should configure the required secrets, such as `GITHUB_TOKEN`, for this workflow to function properly.

# Explanation what does  version means: v4.3.1
- "v": The letter "v" often stands for "version" and is commonly used to indicate the start of a version number.
- "4": This number denotes the major version. Major versions usually represent significant updates to a software product, often including new features, major changes, or architectural modifications.
- "3": The first digit after the major version represents a minor version. Minor versions usually indicate smaller updates or enhancements to the software, such as bug fixes or additional functionality.
- "1": The second digit after the major version signifies a patch or revision number. Patch versions generally consist of minor updates or bug fixes intended to address issues or improve stability.
### How to increase "1"
In case if you need increase second digit after the major version you can use this commit message:
- git commit -am 'chore:Update documentation'
- git commit -am 'fix:bug#123'

### How to increase "3"
In case if you need increase first digit after the major version you can use this commit message:
-  git commit -am 'feat:new features & updates'

### How to increase "4"
In case if you need increase first digit you can use this commit message:
-  git commit --allow-empty -m "chore: release 4.3.1" -m "Release-As: 5.0.0"
