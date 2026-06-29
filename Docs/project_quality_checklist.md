# Project Quality Checklist

This checklist is used during the weekly project quality review. The goal is to keep the repository clean, understandable, reproducible and portfolio-ready.

## Git

* Run `git status`.
* Check that the working tree is clean before starting new work.
* Review changes with `git diff` before committing.
* Use clear English commit messages.
* Push important commits to GitHub.
* Confirm that the local branch is up to date with `origin/main`.

## README

* Check that the README reflects the current project status.
* Remove temporary notes or study block notes.
* Keep the README in English.
* Make sure the current milestone is clear.
* Make sure limitations are honest and up to date.
* Check that the reproducible run order is still correct.

## Documentation

* Keep project-facing documentation in English.
* Keep learning logs separate from portfolio-facing documentation.
* Update `Docs/project_structure.md` when new folders or important files are added.
* Update `Docs/validation_contract.md` when expected validation results change.
* Check whether old notes should be moved, rewritten or archived.

## Code and SQL

* Keep SQL scripts numbered and clearly named.
* Keep Python scripts in `src/`.
* Keep exploratory work in `Notebooks/`.
* Do not commit temporary files or duplicate exports.
* Check that file names are consistent and do not contain accidental spaces.

## Data Validation

* Compare Python outputs against SQL validation results.
* Update the validation contract when the SQL source changes.
* Document validation failures before fixing them.
* Check whether exported CSV files still match the SQL source view.

## Weekly Review Question

Is the repository easier to understand, reproduce and review than last week?