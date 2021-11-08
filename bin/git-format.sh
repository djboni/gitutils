#!/bin/sh
#
# Copyright (C) 2021 Djones A. Boni
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>

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
    echo "Usage: git-format.sh [-h|--help]"
}

################################################################################
# Options
################################################################################

while [ $# -gt 0 ]; do
    Opt="$1"
    shift
    case "$Opt" in
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
            black - --line-length=80 --quiet --check 2>/dev/null
        if [ "$?" != "0" ]; then
            echo black --line-length=80 --quiet "'$File'"
            black --line-length=80 --quiet "$File"
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
git diff $Against --check --
if [ "$?" != "0" ]; then
    # Whitespace error
    exit 1
fi

################################################################################
# Finish
################################################################################

# Success
exit 0
