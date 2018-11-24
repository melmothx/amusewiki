# Contributing

Thanks for using Amusewiki and considering contributing to this
project!

This is a quick guideline.

## Documentation

Contributions to documentation (i.e., the Amusewiki site) should be
formatted as Muse document. You can send the document to the
[contacts listed on the site](https://amusewiki.org/special/contact) 
or produce a pull request against
[amusewiki-site](https://github.com/melmothx/amusewiki-site)

## Submitting code patches

Amusewiki strives to be a stable platform. Nobody likes breakages. For
this reason, Amusewiki comes with a large test suite. Unfortunately it
takes about an hour to run and somebody has to do that.

### Cosmetic fixes to code (reindent code, etc.)

Please don't do that unless discussed.

### Trivial fixes/enhancements

Please give the tests a run before submitting the PR. This is done
running `perl Makefile.PL && make test` in the root of the repository,
in your development tree.

Sometimes a change in a template leads to test failure (when a certain
string is expected), so the test should be adjusted (or the template
corrected).

### Bug fixes

An issue should be opened and referenced in the patch. A test file
(possibly with the issue number in its filename) is required. The
tests should illustrate the failure and fail on master, while passing
with the patch.

### New features

An issue should be opened and the feature discussed. An extensive test
file is required.

## Hacking

There is a [guide to quickly setup a development environment](https://amusewiki.org/library/hacking).

Otherwise you need to follow the [install guide](https://amusewiki.org/library/install)
(the longer version, install from Git master).

