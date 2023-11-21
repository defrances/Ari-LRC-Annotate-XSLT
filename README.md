# LRC-Annotate-XSLT

XSLT to annotate bills with classification data 

Note the default branch is the main branch, and uses USLM2.

To run the XSLT with saxon (requires version 9.8+) use the command

`java -jar /path/to/saxon/saxon9he.jar -s:{name of input file}.xml -o:{name of output file} inputJSON={path to JSON file} -xsl:{path to}/addClassification.xsl`

Note: the path to the JSON file, if relative, must be relative to the XSLT file addClassification.xsl

## Xspec tests

Xspec tests are in the `tests` directory. They are run automatically from GH Actions upon push or pull request to the main branch.

## Release process and NPM Publish

1. Pull request (PR) to `main`
2. Merge to `main` (ideally after review and approval)
3. Tag with new version number of the form `v*.*.*`. To create a tag from command line: `git tag vx.x.x; git push; git push --tags`.
4. Push tags

Upon pushing a new tag, the GH action updates the version number in `package.json` and `package-lock.json` and builds a new npm package. The release includes an automated CHANGELOG, from commit messages. The tag version will overwrite the version in `package.json` upon publishing.
