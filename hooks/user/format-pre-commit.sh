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

# Test if all the files in the index (staged files) follow the coding
# style convention, rejecting the commit if any do not comply.
#
# The code is reformatted when rejected, so the developper can stage the
# necessary chages to comply.
#
# Tested files:
#     * C/C++ files (clang-format)
#     * Python files (black)
#     * Shell files (shfmt)
#     * All (git whitespace check)
#
# Do not allow non-ascii file names.
#
# If the 'tests/' directory exists, run the tests with unstaged changes by
# calling 'cd tests; make all'. This is a compromize, to avoid messing with
# stash all the time. Uncomment some lines below to conver to 'run the tests
# with staged changes'.
#
# Based on default pre-commit.sample hook.

# Indent shell with 4 spaces
Indent=4

if git rev-parse --verify HEAD >/dev/null 2>&1; then
    Against=HEAD
else
    # Initial commit: diff against an empty tree object
    Against=$(git hash-object -t tree /dev/null)
fi

# If you want to allow non-ASCII filenames set this variable to true.
AllowNonASCII=$(git config --bool hooks.allownonascii)

# Redirect output to stderr.
exec 1>&2

# Cross platform projects tend to avoid non-ASCII filenames; prevent
# them from being added to the repository. We exploit the fact that the
# printable range starts at the space character and ends with tilde.
if [ "$AllowNonASCII" != "true" ] &&
    # Note that the use of brackets around a tr range is ok here, (it's
    # even required, for portability to Solaris 10's /usr/bin/tr), since
    # the square bracket bytes happen to fall in the designated range.
    test $(git diff --cached --name-only --diff-filter=A -z $Against |
        LC_ALL=C tr -d '[ -~]\0' | wc -c) != 0; then
    cat <<\EOF
Error: Attempt to add a non-ASCII file name.

This can cause problems if you want to work with people on other platforms.

To be portable it is advisable to rename the file.

If you know what you are doing you can disable this check using:

  git config hooks.allownonascii true
EOF
    exit 1
fi

################################################################################
# Check code formatting on index (staged) code
################################################################################

ExitCode=0

# Separator: new line
IFS="
"
for File in $(git diff --cached --name-only --diff-filter=d); do
    # Separator: space
    IFS=" "

    # Get hash of the changed file
    FileHash="$(git ls-files --stage -- "$File" | cut -d " " -f 2)"
    if [ "$?" = "0" ]; then
        : # OK
    else
        echo "    Error: Could not find hash of file '$File'."
        ExitCode=1
    fi

    # Lowercase finename to check its extension
    FileLower="$(echo "$File" | tr 'A-Z' 'a-z')"

    # Different formatting tools depending on file extension
    case "$FileLower" in
    *.c | *.cpp | *.h | *.hpp)
        # Clang-format (C/C++ format)

        # Test changes
        git cat-file -p "$FileHash" |
            clang-format --dry-run --Werror 2>/dev/null

        # Format if there are any problems
        if [ "$?" = "0" ]; then
            : # OK
        else
            echo clang-format -i "'$File'"
            clang-format -i "$File"
            ExitCode=1
        fi
        ;;
    *.py)
        # Black (Python format)

        # Test changes
        git cat-file -p "$FileHash" |
            black - --line-length=80 --quiet --check 2>/dev/null

        # Format if there are any problems
        if [ "$?" = "0" ]; then
            : # OK
        else
            echo black --line-length=80 --quiet "'$File'"
            black --line-length=80 --quiet "$File"
            ExitCode=1
        fi
        ;;
    *.sh)
        # shfmt (Shell format)

        # Test changes
        git cat-file -p "$FileHash" |
            shfmt -i=$Indent -d -filename "$File" >/dev/null 2>/dev/null

        # Format if there are any problems
        if [ "$?" = "0" ]; then
            : # OK
        else
            echo shfmt -i=$Indent -w "'$File'"
            shfmt -i=$Indent -w "$File"
            ExitCode=1
        fi
        ;;
    esac
done

# Print error and deny push if there are any problems
if [ "$ExitCode" = "0" ]; then
    : # OK
else
    echo "################################################################################"
    echo "# Files reformatted. Not commiting."
    echo "################################################################################"
fi

################################################################################
# Check whitespace on index (staged) code
################################################################################

# If there are whitespace errors, print the offending file names and fail.

# Test changes
git diff-index --check --cached $Against --

# Print error and deny push if there are any problems
if [ "$?" = "0" ]; then
    : # OK
else
    ExitCode=1
    echo "################################################################################"
    echo "# Whitespace errors. Not commiting."
    echo "################################################################################"
fi

################################################################################
# Run tests on unstaged code
#
# Uncomment steps 1, 3 and 4 to run tests on index (staged) code.
################################################################################

if [ "$ExitCode" = "0" ]; then
    # If tests/ directory exists
    if [ -d tests ]; then
        # 1. Stash changes, but keep index
        #git stash push --keep-index -m "Pre-commit test" >/dev/null

        # 2. Run tests
        cd tests &&
            make all
        if [ "$?" != "0" ]; then
            echo "################################################################################"
            echo "# Test failed. Not commiting."
            echo "################################################################################"
            ExitCode=1
        fi

        # 3. Reset hard
        #git reset --hard >/dev/null

        # 4. Restore index and changes
        #git stash pop --index  >/dev/null
    fi
fi

################################################################################
# Return exit code
################################################################################

exit $ExitCode
