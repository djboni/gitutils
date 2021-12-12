#!/bin/bash
# MIT License - Copyright (c) 2021 Djones A. Boni

################################################################################
# DiffError, Usange and Help
################################################################################

DiffError() {
    echo "\
The command 'git diff --name-only ...' did not like the arguments.
See 'git-do.sh --help' for a bigger help message." >&2
    exit $1
}

Usage() {
    echo "\
Usage:  git-do.sh [-h|--help] [--pipe|--argument|--one-call] ...
            [DIFF_OPTIONS] [[-- DIFF_PATHS] -- COMMAND]"
}

Help() {
    echo "\
git-do.sh - Do stuff with changed files

Usage:
    git-do.sh [-h|--help]
    git-do.sh [OPTIONS] [DIFF_OPTIONS]
    git-do.sh [OPTIONS] [DIFF_OPTIONS] -- COMMAND
    git-do.sh [OPTIONS] [DIFF_OPTIONS] -- DIFF_PATHS --
    git-do.sh [OPTIONS] [DIFF_OPTIONS] -- DIFF_PATHS -- COMMAND

OPTIONS can be --pipe, --argument (default) or --one-call, described below.

DIFF_OPTIONS and DIFF_PATHS can be any arguments accepted by 'git diff' that are
compatible with 'git diff --name-only ...'.

To use DIFF_PATHS you need to provide an additional -- before COMMAND.

The COMMAND can have arguments too. If no command is provided the list of files
is printed to the standard output.

OPTIONS:

-h         Print short usage message.

--help     Print this help message.

--pipe     Send the list of files to the COMMAND though a pipe (stdin).
           Each line is one filename.

           echo -e \"FILE1\nFILE2\" | COMMAND

--argument Call the COMMAND once for each file listed, passing the filename
           as an additional argument to the command (default).

           COMMAND FILE1
           COMMAND FILE2

--one-call Call the COMMAND once, passing each filename as an additional
           argument to the command.

           COMMAND FILE1 FILE2

Description:

Every argument after the last -- is considered part of the COMMAND, which can
have several arguments of its own. If no COMMAND is provided, the default
action is to print the listed files.

The example below shows statistics (line, word and byte count) of each changed
C file. To show only the line count add -l as wc's argument.

git-do.sh --one-call '*.[cC]' -- wc
git-do.sh --one-call '*.[cC]' -- wc -l

This tool uses 'git diff --name-only ...' to list files and run a specified
command with the files listed.

It is possible to fine-tune the listed files by using the arguments
DIFF_OPTIONS and DIFF_PATHS..., that are passed to the command
'git diff --name-only ...', as shown below, to generate the list of changed
files.

git diff --name-only DIFF_OPTIONS -- DIFF_PATHS

Therefore, to know what you can use in these arguments, refer to 'git diff'
documentation by calling 'git diff --help'.

If you need to specify -- DIFF_PATHS you will need a second -- to
start the COMMAND. The example below shows the statistics of the changed files
in the directory named src.

git-do.sh --one-call -- src -- wc"
}

################################################################################
# Process arguments
#
# GitDo arguments must be before the first --.
# Arguments after the last -- are used as commands.
# Arguments that are not recognized by GitDo and are before the last -- are
# passed to git diff --name-only.
#
# Example:
#
# git-do.sh --argument HEAD --diff-filter=d -- 'src/*.c' -- touch
#
# This command will list all C files in the directory src/ that were changed
# since the last commit, except for the deleted ones, and will run "touch FILE"
# for every file in that list.
#
# The command used to get that list of files is
# git diff --name-only HEAD --diff-filter=d -- 'src/*.c'
################################################################################

GitDiffArgs=()
Command=()

FilesToStdin=     # --pipe
FilesAsArgument=1 # --argument
FilesInOneCall=   # --one-call

DoubleDash=0
for Arg in "$@"; do

    case $DoubleDash in
    0)
        if [ "$Arg" = -- ]; then
            DoubleDash=$((DoubleDash + 1))
        elif [ "$Arg" = --pipe ]; then
            FilesToStdin=1
            FilesAsArgument=
            FilesInOneCall=
        elif [ "$Arg" = --argument ]; then
            FilesToStdin=
            FilesAsArgument=1
            FilesInOneCall=
        elif [ "$Arg" = --one-call ]; then
            FilesToStdin=
            FilesAsArgument=
            FilesInOneCall=1
        elif [ "$Arg" = -h ]; then
            Usage
            exit 0
        elif [ "$Arg" = --help ]; then
            Help
            exit 0
        else
            GitDiffArgs=("${GitDiffArgs[@]}" "$Arg")
        fi
        ;;
    *)
        if [ "$Arg" = -- ]; then
            GitDiffArgs=("${GitDiffArgs[@]}" "--" "${Command[@]}")
            Command=()
            DoubleDash=$((DoubleDash + 1))
        else
            Command=("${Command[@]}" "$Arg")
        fi
        ;;
    esac
done

################################################################################
# Useful function to test this script
#
# git-do.sh HEAD --pipe -- PrintTest
# git-do.sh HEAD --argument -- PrintTest
# git-do.sh HEAD --one-call -- PrintTest
################################################################################

Calls=0
PrintTest() {
    echo "### CALL $Calls ###"
    Calls=$((Calls + 1))

    echo "--- STDIN ---"
    N=0
    while read Line; do
        echo "$N '$Line'"
        N=$((N + 1))
    done

    echo "--- ARGS ----"
    N=0
    while [ $# -gt 0 ]; do
        Arg="$1"
        shift
        echo "$N '$Arg'"
        N=$((N + 1))
    done

    echo
}

################################################################################
# List the files and run the command
################################################################################

if [ ${#Command[@]} -eq 0 ]; then
    # No command, force to pipe into cat
    FilesToStdin=1
    FilesAsArgument=
    FilesInOneCall=
    Command=("cat")
fi

if [ ! -z $FilesToStdin ]; then
    # git-do.sh --pipe -- PrintTest
    # git-do.sh --pipe -- cat

    {
        git diff --name-only "${GitDiffArgs[@]}"

        if [ $? != 0 ]; then
            DiffError 1
        fi
    } |
        "${Command[@]}"
elif [ ! -z $FilesAsArgument ]; then
    # git-do.sh --argument -- PrintTest
    # git-do.sh --argument -- echo
    Files="$(git diff --name-only "${GitDiffArgs[@]}")"

    if [ $? != 0 ]; then
        DiffError 1
    fi

    if [ ${#Command[@]} -eq 0 ]; then
        # Default command is echo
        Command=("echo")
    fi

    IFS=$'\n'
    for File in $Files; do
        IFS=' '
        "${Command[@]}" "$File" </dev/null
    done
elif [ ! -z $FilesInOneCall ]; then
    # git-do.sh --one-call -- PrintTest
    # git-do.sh --one-call -- echo
    Files="$(git diff --name-only "${GitDiffArgs[@]}")"

    if [ $? != 0 ]; then
        DiffError 1
    fi

    if [ ${#Command[@]} -eq 0 ]; then
        # Default command is echo
        Command=("echo")
    fi

    IFS=$'\n'
    "${Command[@]}" $Files </dev/null
    IFS=' '
else
    :
fi
