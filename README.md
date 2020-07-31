# PR Merge Conflicts Checker

Merge conflicts. Who needs them?

When you create a pull request in GitHub it will tell you if there’s a merge conflict but only with the branch you want to merge into.

What if I’m on a team where two people submit PRs to work on the same files?

## Typical process

Usually here’s what happens:

- I submit my PR
- Team Member X submits his PR
- They conflict but we didn’t realize we were working on the same files
- Days later a build occurs for a release and the merge fails because the two PRs conflicted with each other, not the parent branch
- Devs, who’ve moved on to a new task, must drop what they’re doing and resolve the conflict manually

This stinks. Wouldn’t it be cool if there was a better way? If you could know there’s a merge conflict before you commit?

There is. This [bash script](./pr-merge-conflicts.sh).

## How it works

The above script does the following:

1. Runs `git pull origin master` to update the repo (remove/change `origin master` to the default of your repo)
1. Gets a list of all the remote branches, cycles through all of them with the following logic:
    A. Uses `git merge-base` to get the most recent common ancestor of your branch and all remote branches
    B. Uses `git merge-tree` to do a 3-way comparison between the ancestor, your branch and the remote branch
    C. Use `awk` to look for the telltale sign of a git merge conflict `<<<<<<<` and `>>>>>>`
    D. Reports if conflict is found


## Git hooks

Then you can add the following to your `package.json` as a git hook:

    scripts: {  
      "hooks:pre-commit": "bash ./pr-merge-conflicts.sh",
      "hooks:pre-push": "bash ./pr-merge-conflicts.sh"
    },

## Nested compare of all branches

If you'd like a slightly different workflow, perhaps a background task that checks all branches against each other daily instead of a git hook that's tied to commits, I created this [nested compare bash script](./nested-compare.sh). Same concept, just slightly more complex looping.

## What’s the catch?

There is one: for this to really work well a team will need to consistently delete all closed and merged branches.

Go to the "branches" section of your repo. Often devs will not delete merged/closed branches.

Personally I think it’s good repo hygiene to delete all closed/merged branches but if your team does not then this script will inevitably report conflicts with those branches.

`git` has no concept of a remote branch status, that is a GitHub concept, and to filter out these branches you’d need a server-side GH app that fetches the status of each branch before running the comparison, which greatly complexifies this process.


## If I delete a branch, is it gone forever?

No! Not if it was part of a GitHub pull request. See: https://help.github.jp/enterprise/2.11/user/articles/deleting-and-restoring-branches-in-a-pull-request/

You can restore a deleted branch that was part of a PR so you should have total confidence in deleting closed/merged branches.
