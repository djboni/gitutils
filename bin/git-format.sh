#!/bin/sh
# MIT License - Copyright (c) 2021 Djones A. Boni

# Format the code and run a whitespace check.
#
# The formatting changes are not staged.
#
# Tested files:
#     * C/C++ files (clang-format)
#     * Python files (black)
#     * Shell files (shfmt)
#     * All (git whitespace check)
#
# Exit values:
# 0   OK
# 1   Whitespace error
# 128 Option errors

# Indent shell with 4 spaces
Indent=4

# Redirect output to stderr.
exec 1>&2

if git rev-parse --verify HEAD >/dev/null 2>&1; then
    Against=HEAD
else
    # Initial commit: diff against an empty tree object
    Against=$(git hash-object -t tree /dev/null)
fi

################################################################################
# Usage
################################################################################

Usage() {
    echo "Usage: git-format.sh [-a|--add] [-h|--help]"
}

################################################################################
# Options
################################################################################

Add_After_Format=

while [ $# -gt 0 ]; do
    Opt="$1"
    shift
    case "$Opt" in
    -a | --add)
        Add_After_Format=1
        ;;
    -h | --help)
        Usage
        exit 0
        ;;
    *)
        echo "Invalid option '$Opt'" >&2
        Usage
        exit 128
        ;;
    esac
done

################################################################################
# Go to top level
################################################################################

cd "$(git rev-parse --show-toplevel)"

################################################################################
# Format changed files
################################################################################

# Separator: new line
IFS="
"
for File in $(git diff $Against --name-only --diff-filter=d); do
    # Separator: space
    IFS=" "

    if [ -L "$File" ]; then
        # Ignore symlink
        continue
    fi

    # Lowercase finename to check its extension
    FileLower="$(echo "$File" | tr 'A-Z' 'a-z')"

    # Different formatting tools depending on file extension
    case "$FileLower" in
    *.c | *.cpp | *.h | *.hpp)
        # Clang-format (C/C++ format)
        cat "$File" |
            clang-format --dry-run --Werror 2>/dev/null
        if [ "$?" != "0" ]; then
            echo clang-format -i "'$File'"
            clang-format -i "$File"
        fi
        ;;
    *.py)
        # Black (Python format)
        cat "$File" |
            black - --quiet --check 2>/dev/null
        if [ "$?" != "0" ]; then
            echo black --quiet "'$File'"
            black --quiet "$File"
        fi
        ;;
    *.sh)
        # shfmt (Shell format)
        cat "$File" |
            shfmt -i=$Indent -d -filename "$File" >/dev/null 2>/dev/null
        if [ "$?" != "0" ]; then
            echo shfmt -i=$Indent -w "'$File'"
            shfmt -i=$Indent -w "$File"
        fi
        ;;
    esac
done

################################################################################
# Check whitespace
################################################################################

# If there are whitespace errors, print the offending file names.
git diff $Against --check -- ":(exclude)*/Debug/*"
if [ "$?" != "0" ]; then
    # Whitespace error
    exit 1
fi

################################################################################
# Add changes after formatting
################################################################################

if [ ! -z $Add_After_Format ]; then
    git add --all
fi

################################################################################
# Finish
################################################################################

# Success
exit 0
