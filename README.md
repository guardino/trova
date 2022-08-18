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
trova 0.4.4, Copyright (c) 2016-2022 Cesare Guardino

Usage:
     trova.pl [options] <content_patterns>

     Options:
       -b,    --binary                Specify whether to search inside binary files
       -c,    --count                 Print number of lines in matched files
       -d,    --dir                   Comma-separated list of directories to search
       -f,    --first                 Exit on first occurrence in each file (runs faster)
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
- Search for `memcpy` in all `.cpp|.h` files and print number of lines in matching files:
```
    trova.pl -n ".cpp|.h"  memcpy -c
```
- Search for `memcpy` in all `.cpp|.h` files and print number of matches in each file:
```
    trova.pl -n ".cpp|.h"  memcpy -m
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

## License

Licensed under MIT License (see LICENSE.txt).
