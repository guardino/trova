# trova

## Introduction

`trova` is a simple directory recursive search tool ("trova" means "to find" in
Italian). It can be used as an alternative to utilities like "find" or "grep".
It works on both Windows and Linux operating systems. It even has some limited
support for doing text replacements or renaming/deleting files. By default,
`.svn` or `.git` directories are excluded from searches (this can be
overridden).

The repo also includes some extra bonus utilities (see below for details)

## Prerequisites

Requires an up-to-date version of Perl. Tested using Strawberry Perl v5.30.0.

## Usage
```
Usage:
     trova.pl [options] <content_patterns>

     Options:
       -b,    --binary                Specify whether to search inside binary files
       -c,    --count                 Count and print total number of matches found
       -d,    --dir                   Comma-separated list of directories to search
       -f,    --first                 Exit on first occurrence in each file (runs faster)
       -h,    --help                  Help usage message
       -i,    --ignore                Ignore case
       -l,    --lines                 Print number of lines in matched files
       -k,    --nuke                  Recursively remove directories and contents if --remove is enabled
       -m,    --matches               Print number of matches found in files instead of matched lines
       -n,    --name                  Search pattern for file/directory names
       -nox,  --noexclude             Search all files, ignoring any excluded files by default
       -p,    --print                 Print matched file names
       -rm,   --remove                Remove files which match specified pattern
       -mv,   --rename                Rename files which match specified pattern
       -s,    --substitute            Substitute any string in files matching specified patterns with substitution text
       -t,    --type                  Type of entities to find (f: files, d: directories, a: all)
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
- Search for `foo` in all files:
```
    trova.pl foo
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
- Remove all files ending in `~`:
```
    trova.pl -c -n "~$" -nox -x "\.svn|\.git" -rm
```

## Extras

### difftree.pl

This is a simple recursive directory comparison tool. For more info run `difftree.pl --help`.

## which.pl

This is a simple Perl replacement for `which` or `where`. For more info run `which.pl --help`.

## License

Licensed under MIT License (see LICENSE.txt).
