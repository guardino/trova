# trova

## Introduction

`trova` is a simple directory recursive search tool ("trova" means "find" in
Italian). It can be used as an alternative to utilities like "find" or "grep".
It works on both Windows and Linux operating systems. It even has some limited
support for doing text replacements or renaming/deleting files. By default,
`.svn` or `.git` directories are excluded from searches (this can be
overridden).

The repo also includes some extra bonus utilities (see below for details)

## Prerequisites

Requires an up-to-date version of Perl. Tested using Strawberry Perl v5.30.0.

On Microsoft Windows you can use the 64-bit pre-compiled executable versions which
do not require Perl to be installed. These can be found under [Releases](https://github.com/guardino/trova/releases).
In this case you can replace the `.pl` extension in the usage examples below with either `.exe` or nothing at all.
This means you can simply type `trova`, `confronta` and `quale` to run the pre-compiled versions.

## Usage
```
trova 0.4.7, Copyright (c) 2016-2023 Cesare Guardino

Usage:
     trova.pl [options] <content_patterns>

     Options:
       -1,    --first                 Exit on first occurrence in each file (runs faster)
       -b,    --binary                Specify whether to search inside binary files
       -c,    --count                 Print number of lines in matched files
       -d,    --dir                   Comma-separated list of directories to search
       -e,    --extra                 Regex for extra patterns to search for around main search regex
       -el,   --extralines            Number of +/- extra lines to search for --extra option (default = 0)
       -ed,   --extradirection        Direction for --extra pattern search (u: up, d: down, a: all)
       -f,    --filter                Regex for fitering out file content matches
       -h,    --help                  Help usage message
       -i,    --ignore                Ignore case
       -k,    --nuke                  Recursively remove directories and contents if --remove is enabled
       -l,    --line                  Print line number of all matches found in files
       -m,    --matches               Print number of matches found in files instead of matched lines
       -mv,   --rename                Rename files which match specified pattern
       -n,    --name                  Search pattern for file/directory names
       -nox,  --noexclude             Search all files, ignoring any excluded files by default
       -p,    --print                 Print matched file names
       -rm,   --remove                Remove files which match specified pattern
       -s,    --substitute            Substitute any string in files matching specified patterns with substitution text
       -t,    --type                  Type of entities to find (f: files, d: directories, a: all)
       -u,    --summarize             Summarize total number of matches found
       -v,    --verbose               Print extra information and progress
       -w,    --word                  Add word-boundaries to file content regexes
       -x,    --exclude               Regex to exclude files
       -y,    --datestamp             Print datestamp for matched files and directories
       -z,    --size                  Print file sizes in bytes

     Optional arguments:
       <content_patterns>             Search patterns for file contents
```

## Examples

- List all files in current working directory:
```
    trova.pl
```
- Search for `foo` and `bar` in all files:
```
    trova.pl foo bar
```
- Search for `double` in all `.cpp|.h` files and print out line numbers of matches:
```
    trova.pl -n ".cpp|.h" double -l
```
- List all `.java` files:
```
    trova.pl -n \.java
```
- Search for `foo` in all `.c` files in `src` directory (but not `.cpp` files):
```
    trova.pl -n \.c$ -d src foo
```
- Search for `foo` in all `.dll` files in `lib` directory, but only show number of matches:
```
    trova.pl -n \.dll$ -d lib foo -m
```
- Search for `foo` in all `.py` files and replace with `bar`:
```
    trova.pl -n \.py foo -s bar
```
- Search for `red` in all `.py` files with word boundaries, equivalent to "\bred\b" (avoids matches like redistribute, credit etc.):
```
    trova.pl -n \.py red -w
```
- Search for `memcpy` in all `.cpp|.h` files and print number of lines in matching files:
```
    trova.pl -n ".cpp|.h" memcpy -c
```
- Search for `memcpy` in all `.cpp|.h` files and print number of matches in each file:
```
    trova.pl -n ".cpp|.h" memcpy -m
```
- Search for `memcpy` in all `.cpp|.h` files, but filter out lines beginning with "#":
```
    trova.pl -n ".cpp|.h" memcpy -m -f "^#"
```
- Search for `malloc` in all `.cpp|.h` files which have `free` within +/- 10 lines of it and display number of extra matches:
```
    trova.pl -n ".cpp|.h" malloc -e free -el 10
```
- Search for `malloc` in all `.cpp|.h` files which have `free` within +5 lines of it (below) and display number of extra matches and line numbers (use `-ed=u` to search upwards for extra matches):
```
    trova.pl -n ".cpp|.h" malloc -e free -el 5 -ed=d -l
```
- Search for `malloc` in all `.cpp|.h` files which have `free` within the entire file and display number of extra matches and line numbers:
```
    trova.pl -n ".cpp|.h" malloc -e free -ed=a -l
```
- Remove all files in current directory ending in `~`, but do not search in `.git` or `.svn` folders:
```
    trova.pl -u -n "~$" -nox -x "\.svn|\.git" -rm
```

## Extras

### confronta.pl

This is a simple recursive directory comparison tool ("confronta" means "compare" in Italian). For more info run `confronta.pl --help`.
```
confronta 0.4.4, Copyright (c) 2016-2022 Cesare Guardino

Usage:
     confronta.pl [options] <dir1> <dir2>

     Options:
       -d,  --difftool                Full path to diff program 
       -f,  --filter                  Regex filter to ignore diffs
       -h,  --help                    Help usage message
       -s,  --show_same               Show same (identical) files
       -t,  --tree_only               Compare directory structures only (do not diff file contents) 
       -v,  --verbose                 Turn on verbosity
       -xd, --exclude_dir_pattern     Regex to exclude directories
       -xf, --exclude_file_pattern    Regex to exclude files
       -y,  --datestamp               Compare file datestamps only
       -z,  --size                    Compare file sizes only

     Compulsory arguments:
       <dir1> <dir2>                  Directories to compare
```

## Examples

- Compare directories `foo` and `bar`
```
    trova.pl foo bar
```
- Compare directories `foo` and `bar` based on file sizes only (runs faster):
```
    trova.pl -z foo bar
```
- Compare directories `foo` and `bar`, excluding `.git` folder and any `.log` and `.out` files:
```
    trova.pl foo bar -xd \.git -xf "\.log|\.out"
```
- Compare directories `foo` and `bar`, ignoring differences in lines with date-stamps of the form `17/02/2021 16:10:47`, and listing all identical files:
```
    trova.pl -s -f "\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d" foo bar
```

## quale.pl

This is a simple Perl replacement for `which` or `where` ("quale" means "which" in Italian). For more info run `quale.pl --help`.
```
quale 0.4.4, Copyright (c) 2016-2022 Cesare Guardino

Usage:
     quale.pl [options] <program_name>

     Options:
       -a,    --all                   Prints all occurrences found
       -h,    --help                  Help usage message

     Optional arguments:
       <program_name>                 Program name to find
```

## forte.pl

This is a Perl script which generates a recursive call graph for Fortran code ("forte" means "strong" in Italian).
Given a function or subroutine name, it will find which functions or subroutines call it, and in turn which call those recursively.
For more info run `forte.pl --help`. It requires the `dot` program from Graphviz (see https://graphviz.org/).
```
forte 0.4.8, Copyright (c) 2024 Cesare Guardino

Usage:
     forte.pl [options] <subroutine or function name>

     Options:
       -a,    --all                   Show all duplicated calls (takes longer to run)
       -b,    --backward              Display backward arrows from specified function to main
       -d,    --dir                   Comma-separated list of directories to search
       -e,    --ext                   Specify extra file extensions to search 
       -f,    --file                  Single file to search
       -h,    --help                  Help usage message
       -i,    --ignore                Ignore case
       -s,    --show                  Show generated graph image
```

## License

Licensed under MIT License (see LICENSE.txt).
