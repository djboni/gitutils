# Pre-Commit setup

[Pre-Commit Web Site](https://pre-commit.com/)

```sh
# Install pre-commit
pip install pre-commit

# Create the repository
git init

# Copy .pre-commit-config.yaml to the repository
cp PATH/.pre-commit-config.yaml .

# Install the pre-commit hook
pre-commit install

# Run the hook for all files
pre-commit run --all-files

# Update the hooks if necessary
pre-commit autoupdate
```

# Other dependencies

```sh
apt install clang-format
pip install black
snap install shfmt
```
