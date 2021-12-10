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

# Test if all the files changed in the pushed commits follow the coding style
# convention, rejecting all branches if any change do not comply.
#
# Tested files:
#     * C/C++ files (clang-format)
#     * Python files (black)
#     * Shell files (shfmt)
#     * All (git whitespace check)

# Indent shell with 4 spaces
Indent=4

# Redirect output to stderr.
exec 1>&2

################################################################################
# Check formatting and whitespace
################################################################################

ExitCode=0

# For each branch
while read Ref1 Ref2 Branch; do

    # Check only branch master by default
    case "$Branch" in
    refs/heads/master)
        # Check formatting on this branch
        ;;
    *)
        # Do not check this branch
        continue
        ;;
    esac

    # Pushing new branch: diff against an empty tree object
    if [ "$Ref1" = "0000000000000000000000000000000000000000" ]; then
        Against=$(git hash-object -t tree /dev/null)
        Ref1="$Against"
    fi

    # Deleting branch: diff against an empty tree object
    if [ "$Ref2" = "0000000000000000000000000000000000000000" ]; then
        Against=$(git hash-object -t tree /dev/null)
        Ref2="$Against"
    fi

    # Test if the push is forced
    if git merge-base --is-ancestor "$Ref1" "$Ref2"; then
        ForcedPush="push"
    else
        ForcedPush="*forced push*"
    fi

    # Print change in branch
    echo "Checking $ForcedPush on branch $Branch:"
    echo

    # Print commit graph
    # Use sed to manually decorate with NEW and OLD
    Ref1Small="$(git log -1 --pretty="%h" "$Ref1")"
    Ref2Small="$(git log -1 --pretty="%h" "$Ref2")"
    SedScript="
        # Anotate OLD commit
        /$Ref1Small/{
            s/\($Ref1Small[\w]*.*\)/\1 (OLD)/
            # Finished this line
            b END
        }

        # Anotate NEW commit
        /$Ref2Small/{
            s/\($Ref2Small[\w]*.*\)/\1 (NEW)/
            # Finished this line
            b END
        }

        # Finished this line
        : END
    "
    git log --graph --oneline \
        "$Ref1" "$Ref2" --not "$(git merge-base "$Ref1" "$Ref2")^" |
        sed "$SedScript"
    echo

    # List of commits from oldest to newest
    ListOfCommits="$(
        git log --oneline --no-decorate --no-abbrev-commit "$Ref1..$Ref2" |
            tac
    )"

    # For each commit in the branch
    # Separator: new line
    IFS="
"
    for Commit in $ListOfCommits; do
        # Separator: space
        IFS=" "
        CommitOK=0

        Ref="$(echo "$Commit" | cut -f 1 -d ' ')"

        git log -1 --oneline --no-decorate "$Ref"

        ListOfFiles="$(
            git show --pretty="" --name-only --diff-filter=d "$Ref"
        )"

        # For each file in the commit
        # Separator: new line
        IFS="
"
        for File in $ListOfFiles; do
            # Separator: space
            IFS=" "
            FileOK=0

            # Get hash of the changed file
            FileHash="$(git ls-tree "$Ref" "$File" | cut -d " " -f 3 | cut -f 1)"
            if [ "$?" = "0" ]; then
                : # OK
            else
                echo "    Error: Could not find hash of file '$File'."
                ExitCode=1
                CommitOK=1
                FileOK=1
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

                # Print error and deny push if there are any problems
                if [ "$?" = "0" ]; then
                    : # OK
                elif [ "$?" = "1" ]; then
                    # Format
                    echo "    Error: clang-format $File"
                    if [ ! -f .clang-format ]; then
                        echo "    Warning: $PWD/.clang-format does not exist."
                    fi
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                else
                    # Unknown error
                    echo "    Unknown error: clang-format on file '$File'."
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                fi
                ;;
            *.py)
                # Black (Python format)

                # Test changes
                git cat-file -p "$FileHash" |
                    black - --quiet --check

                # Print error and deny push if there are any problems
                if [ "$?" = "0" ]; then
                    : # OK
                elif [ "$?" = "1" ]; then
                    # Format
                    echo "    Error: black $File"
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                elif [ "$?" = "2" ]; then
                    # Could not parse
                    echo "    Error: black could not parse file '$File'."
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                else
                    # Unknown error
                    echo "    Unknown error: black on file '$File'."
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                fi
                ;;
            *.sh)
                # shfmt (Shell format)

                # Test changes
                git cat-file -p "$FileHash" |
                    shfmt -i=$Indent -d -filename "$File" >/dev/null 2>/dev/null

                # Print error and deny push if there are any problems
                if [ "$?" = "0" ]; then
                    : # OK
                elif [ "$?" = "1" ]; then
                    # Format
                    echo "    Error: shfmt $File"
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                else
                    # Unknown error
                    echo "    Unknown error: shfmt on file '$File'."
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                fi
                ;;
            esac

            # Whitespace (git whitespace check)
            if [ "$FileOK" = "0" ]; then

                # Test changes
                git diff --check "$Against..$Ref" -- >/dev/null

                # Print error and deny push if there are any problems
                if [ "$?" = "0" ]; then
                    echo "    OK: $File"
                else
                    # Format
                    echo "    Error: whitespace '$File'"
                    ExitCode=1
                    CommitOK=1
                    FileOK=1
                fi
            fi
        done # File

        echo
    done # Commit

done # Branch

if [ "$ExitCode" != "0" ]; then
    echo "################################################################################"
    echo "# Files need reformating. Rejecting push."
    echo "################################################################################"
fi

################################################################################
# Return exit code
################################################################################

exit $ExitCode
