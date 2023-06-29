# Release please documentation
In our solution we have two yml files:
    - release-please.yml
    - publish-npm-package.yml
# release-please.yml overview
This file is used to create a PR release when into the main branch. It will create a release with the version number of the tag that was created. It will also create a changelog based on the commit messages.

The action is configured with the following parameters:

- release-type: Specifies the release type as "node". Adjust this value based on your project's needs.
- package-name: Specifies the name of the package. Modify this value to match the package you're working with.
- changelog-types: Specifies an array of changelog types and their corresponding sections. In this example, the types "feat" (Features), "fix" (Bug Fixes), and                "chore" (Miscellaneous) are defined. You can customize this array to match your project's changelog structure.

# publish-npm-package.yml overview
This is a GitHub Actions workflow named "Release Workflow" that automates the release process when a pull request is closed. It performs various tasks such as building the project, generating a changelog, creating a GitHub release, and publishing to NPM. Here's a breakdown of the workflow:
** Workflow Triggers
The workflow is triggered by the closing of a pull request:

on:
  pull_request:
    types:
      - closed

 ** Workflow Jobs
 The workflow consists of a single job named "build" that runs on the latest Ubuntu environment:
 jobs:
  build:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest

 ** Job Steps
 The job contains several steps that perform different tasks:
- Checkout code: This step checks out the code from the repository:
  '- name: Checkout code
  uses: actions/checkout@v3
  with:
    fetch-depth: 0 # Set fetch depth to 0 to fetch all tags
'





