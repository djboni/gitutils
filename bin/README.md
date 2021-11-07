# UTILITIES (bin)

Useful programs.

## Git-Format

Format your code and check for whitespace errors.

```
Usage: git-format.sh [-h|--help] [-f|--force]
```

Install:

Copy (or link) the script somewhere in your PATH, maybe `$HOME/bin`.

```sh
# Make sure $HOME/bin exists
mkdir -p $HOME/bin
cd $HOME/bin

# Copy
cp /PATH-TO/git-format.sh git-format
chmod +x git-format

# Link
ln -s /PATH-TO/git-format.sh git-format
chmod +x git-format
```

Hint: Naming the script `git-format` and putting it in your path allows you to
call `git format` (without the dash).

## Git-Do

Do stuff with changed files beyond just diffing them.

```
Usage:  git-do.sh [-h|--help] [--pipe|--argument|--one-call] ...
            [DIFF_OPTIONS] [[-- DIFF_PATHS] -- COMMAND]
```

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

To rebuild only the changed files since tag v1.0, you can call `touch FILE` for
all C files changed since the tag, except for the deleted files.

```sh
git-do.sh v1.0.. --diff-filter=d -- '*.c' -- touch
```

There are three different ways to pass the filenames to the command.

1. Call the command once for each file with the filename as last argument
(default or use `--argument`):

Format C, H, PY and SH files.

```sh
git-do.sh --argument HEAD -- '*.[ch]' -- clang-format -i
git-do.sh --argument HEAD -- '*.py' -- black --line-length=80
git-do.sh --argument HEAD -- '*.sh' -- shfmt -i=4 -w
```

2. Call the command once with all files added as additional arguments
(use `--one-call`):

Format C, H, PY and SH files with one call to the commands.

```sh
git-do.sh --one-call HEAD -- '*.[ch]' -- clang-format -i
git-do.sh --one-call HEAD -- '*.py' -- black --line-length=80
git-do.sh --one-call HEAD -- '*.sh' -- shfmt -i=4 -w
```

3. Pipe the list of files to the command (use `--pipe`). The command reads one
filename per line from STDIN.

```sh
git-do.sh --pipe HEAD -- '*.[ch]' -- sort
git-do.sh --pipe HEAD -- '*.[ch]' | sort
```

See `git-do.sh --help` for more information.
