# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI.

- Create: `gh issue create --title "..." --body "..."`
- Read: `gh issue view <number> --comments`
- List: `gh issue list --state open`
- Comment: `gh issue comment <number> --body "..."`
- Label: `gh issue edit <number> --add-label "<label>"`
- Close: `gh issue close <number> --comment "..."`

Infer `accors/surgio-docker` from the local Git remote.

## Pull requests as a triage surface

PRs as a request surface: no.

## Skill mapping

When a skill says "publish to the issue tracker", create a GitHub issue.
When a skill says "fetch the relevant ticket", run `gh issue view <number> --comments`.
