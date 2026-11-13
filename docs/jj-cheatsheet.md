# jj cheatsheet (git → jj)

Jujutsu (`jj`, version from nixpkgs, configured in `home/jujutsu.nix`) works on top of Git.
Repositories are **colocated**: a normal `.git` sits next to `.jj`, so `git`, lazygit and
Neovim's gitsigns keep working. Pull requests are made in the browser (no `gh`).

The big difference: **the working copy is a commit** (`@`). There is no staging area. Every
`jj` command first snapshots your files into `@`. You describe it, start a new change on top,
and move bookmarks (jj's branches) when you are ready to push.

| Git | jj | Notes |
| --- | --- | --- |
| `git clone URL` | `jj git clone URL` | colocated by default (`git.colocate = true`) |
| `git init` | `jj git init` | in an existing git checkout, run it at the repo root: it reuses `.git` |
| `git status` | `jj st` (`jj status`) | |
| `git log` | `jj` (= `jj log`), `jj l` | `jj l` (alias): your changes not on `trunk()` yet |
| `git diff` | `jj diff` | shown through delta |
| `git add -A && git commit -m "msg"` | `jj commit -m "msg"` | describes `@` and starts a new empty change on top |
| (write message first) | `jj describe -m "msg"` | set/replace the description of `@` |
| `git commit --amend` | just edit files (they go into `@`) | or put `@`'s changes into its parent: `jj squash` |
| `git add -p` + amend | `jj squash -i` | pick hunks to move into the parent |
| `git checkout -b feat` | `jj bookmark create feat -r @-` | bookmark the last finished change |
| move branch to latest | `jj bookmark move feat --to @-`, or `jj tug` | `tug` (alias) moves the nearest bookmark to `@-` |
| `git checkout <rev>` | `jj new <rev>` | new change on top of `<rev>` (safe) |
| edit an older commit | `jj edit <rev>` | descendants are rebased automatically |
| `git rebase main` | `jj rebase -o main` | jj 0.47 uses `-o/--onto`; `-b` (branch, default), `-s` (subtree), `-r` (single revisions) |
| `git fetch` | `jj git fetch` | |
| `git pull` | `jj git fetch`, then `jj rebase -o main@origin` | |
| `git push` | `jj git push --bookmark feat` | or `jj git push -c @-`: creates a bookmark for that change and pushes it |
| track a remote branch | `jj bookmark track main@origin` | |
| `git reset --hard` / drop commit | `jj abandon <rev>` | |
| `git stash` | `jj new @-` | your work stays in its own change; come back with `jj edit` |
| `git reflog` + reset | `jj undo` | undoes the last operation (any command) |
| look at history of operations | `jj op log` | every command is recorded |
| go back to any point | `jj op restore <operation-id>` | ids from `jj op log` |
| TUI | `jjui` | log, rebase, squash, bookmarks, op log |

Typical feature flow:

```bash
jj new main -m "feat: thing"
```

Edit files, then:

```bash
jj commit -m "feat: thing"
```

```bash
jj bookmark create thing -r @-
```

```bash
jj git push --bookmark thing
```

Then open the pull request in the browser. After review fixes, edit `@` and run:

```bash
jj squash
```

```bash
jj git push --bookmark thing
```

SSH: `services.ssh-agent` runs an agent for the session. Load your key once with `ssh-add`.
No keys are created by this config.
