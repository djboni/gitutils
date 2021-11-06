# UTILITIES (bin)

Useful programs.

## Git-Do

Do stuff with changed files beyond just diffing them.

Format all C and H files changed since the last commit with clang-format.

```sh
git-do.sh HEAD -- '*.[ch]' -- clang-format -i
```

Format all PY files changed since last commit with black.

```sh
git-do.sh HEAD -- '*.py' -- black --line-length=80
```

Format all SH files changed since last commit with shfmt.

```sh
git-do.sh HEAD -- '*.sh' -- shfmt -i=4 -w
```

To rebuild only the changed files since tag v1.0, you can call `touch FILE` for all C files changed since the tag, except for the deleted files.

```sh
git-do.sh v1.0.. --diff-filter=d -- '*.c' -- touch
```

There are three different ways to pass the filenames to the command.

1. Call the command once for each file with the filename as last argument (default or use `--argument`):

Format C, H, PY and SH files.

```sh
git-do.sh --argument HEAD -- '*.[ch]' -- clang-format -i
git-do.sh --argument HEAD -- '*.py' -- black --line-length=80
git-do.sh --argument HEAD -- '*.sh' -- shfmt -i=4 -w
```

2. Call the command once with all files added as additional arguments (use `--one-call`):

Format C, H, PY and SH files with one call to the commands.

```sh
git-do.sh --one-call HEAD -- '*.[ch]' -- clang-format -i
git-do.sh --one-call HEAD -- '*.py' -- black --line-length=80
git-do.sh --one-call HEAD -- '*.sh' -- shfmt -i=4 -w
```

3. Pipe the list of files to the command (use `--pipe`). The command reads one filename per line from STDIN.

```sh
git-do.sh --pipe HEAD -- '*.[ch]' -- sort
git-do.sh --pipe HEAD -- '*.[ch]' | sort
```

See `git-do.sh --help` for more information.
