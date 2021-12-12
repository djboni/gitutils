# SERVER formatting pre-receive hook

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
ln -s ../gitutils/pre-receive/pre-receive.sh hooks/pre-receive
# or copy
# cp gitutils/gitutils/pre-receive/pre-receive.sh hooks/pre-receive

# 3. Enable script execution
chmod +x hooks/pre-receive

# 4 Copy .clang-format and pyproject.toml
cp gitutils/format/.clang-format .
cp gitutils/format/pyproject.toml .
```

# Dependencies

Tools used by these scripts:

Tool         | Description
-------------|-----------------
clang-format | C/C++ formatter
black        | Python formatter
shfmt        | Shell formatter

To install dependencies on Ubuntu:

```sh
apt install clang-format
pip install black
snap install shfmt
```
