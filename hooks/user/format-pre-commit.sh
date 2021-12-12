#!/bin/sh
# MIT License - Copyright (c) 2021 Djones A. Boni

# Test if all the files in the index (staged files) follow the coding
# style convention, rejecting the commit if any do not comply.
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

# Redirect output to stderr.
exec 1>&2

if git rev-parse --verify HEAD >/dev/null 2>&1; then
    Against=HEAD
else
    # Initial commit: diff against an empty tree object
    Against=$(git hash-object -t tree /dev/null)
fi

# If you want to allow non-ASCII filenames set this variable to true.
AllowNonASCII=$(git config --bool hooks.allownonascii)

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

echo "Checking staged code formatting ..."

# Separator: new line
IFS="
"
for File in $(git diff --cached --name-only --diff-filter=d); do
    # Separator: space
    IFS=" "

    if [ -L "$File" ]; then
        # Ignore symlink
        continue
    fi

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

        if [ "$?" = "0" ]; then
            : # OK
        else
            # Format if there are any problems
            echo clang-format -i "'$File'"
            ExitCode=1
        fi
        ;;
    *.py)
        # Black (Python format)

        # Test changes
        git cat-file -p "$FileHash" |
            black - --quiet --check 2>/dev/null

        if [ "$?" = "0" ]; then
            : # OK
        else
            echo black --quiet "'$File'"
            # Error
            ExitCode=1
        fi
        ;;
    *.sh)
        # shfmt (Shell format)

        # Test changes
        git cat-file -p "$FileHash" |
            shfmt -i=$Indent -d -filename "$File" >/dev/null 2>/dev/null

        if [ "$?" = "0" ]; then
            : # OK
        else
            # Error
            echo shfmt -i=$Indent -w "'$File'"
            ExitCode=1
        fi
        ;;
    esac
done

if [ "$ExitCode" != "0" ]; then
    echo "################################################################################"
    echo "# Files need formatting. Not commiting."
    echo "################################################################################"
    echo
fi

################################################################################
# Check whitespace on index (staged) code
################################################################################

echo "Checking staged files whitespace ..."

# If there are whitespace errors, print the offending file names.
git diff $Against --cached --check --

# Print error and deny commit if there are any problems
if [ "$?" = "0" ]; then
    : # OK
else
    echo "################################################################################"
    echo "# Files have whitespace errors. Not commiting."
    echo "################################################################################"
    echo
    ExitCode=1
fi

################################################################################
# Run tests on unstaged code
#
# Uncomment steps 1, 3 and 4 to run tests on index (staged) code.
################################################################################
Staged=

if [ "$ExitCode" = "0" ]; then
    # If tests/ directory exists
    if [ -d tests ]; then

        [ ! -z $Staged ] &&
            echo "Testing staged code ..." ||
            echo "Testing unstaged code ..."

        # 1. Stash changes, but keep index
        [ ! -z $Staged ] &&
            git stash push --keep-index -m "Pre-commit test" >/dev/null

        # 2. Run tests
        cd tests &&
            make all
        if [ "$?" != "0" ]; then
            echo "################################################################################"
            echo "# Test failed. Not commiting."
            echo "################################################################################"
            echo
            ExitCode=1
        fi

        # 3. Reset hard
        [ ! -z $Staged ] &&
            git reset --hard >/dev/null

        # 4. Restore index and changes
        [ ! -z $Staged ] &&
            git stash pop --index >/dev/null
    fi
fi

################################################################################
# Return exit code
################################################################################

exit $ExitCode
