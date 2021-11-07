# HOOKS

Git hooks for developers and servers.

## Enfororce formatting on code

### Dependencies

Tools used by these scripts:

Tool         | Description
-------------|-----------------
clang-format | C/C++ formatter
black        | Python formatter
shfmt        | Shell formatter

To install dependencies on Ubuntu:

```sh
sudo apt install clang-format black
sudo snap install shfmt
```

### DEVELOPPER formatting pre-commit hook

Before comitting, check changed files for formatting,
whitespace errors and run tests.

Install:

1. Clone gitutils in the repository's .git directory;
2. Link (or copy) the script; and
3. Enable script execution.
4. Provide a .clang-format file in the repository root.

```sh
# 0. Change to repository's .git directory
cd REPO/.git/

# 1. Clone gitutils
git clone https://github.com/djboni/gitutils

# 2 Link pre-commit
ln -s ../gitutils/hooks/user/format-pre-commit.sh hooks/pre-commit
# or copy
# cp gitutils/hooks/user/format-pre-commit.sh hooks/pre-commit

# 3. Enable script execution
chmod +x hooks/pre-commit

# 4 Copy .clang-format
cp gitutils/format/clang-format ../.clang-format
```

### SERVER formatting pre-receive hook

Check and accept (or reject) changes when a developper pushes.

Install:

1. Clone gitutils in the repository's bare directory;
2. Link (or copy) the script; and
3. Enable script execution.
4. Provide a .clang-format file in the repository root.

```sh
# 0. Change to repository's bare directory
cd REPO.git/

# 1. Clone gitutils
git clone https://github.com/djboni/gitutils

# 2 Link pre-receive
ln -s ../gitutils/hooks/server/format-pre-receive.sh hooks/pre-receive
# or copy
# cp gitutils/hooks/server/format-pre-receive.sh hooks/pre-receive

# 3. Enable script execution
chmod +x hooks/pre-receive

# 4 Copy .clang-format
cp gitutils/format/clang-format .clang-format
```
