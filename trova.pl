#!/usr/bin/perl

#######################################################################################
# Name:          trova.pl
# Description:   Recursive directory search and replacement utility
# Author:        Cesare Guardino
# Last modified: 22 March 2024
#######################################################################################

use strict;
use warnings;

use constant NAME    => "trova";
use constant VERSION => "0.5.0";

use Cwd;
use File::Basename;
use File::Find;
use File::Path;
use Getopt::Long;
use List::Util qw(min max);
use Pod::Usage;

# POD {{{1
=head1 NAME

trova.pl

=head1 SYNOPSIS

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
   -j,    --j                     Search only in specified line number
   -k,    --nuke                  Recursively remove directories and contents if --remove is enabled
   -l,    --line                  Print line number of all matches found in files
   -m,    --matches               Print number of matches found in files instead of matched lines
   -max,  --maxdepth              Set maximum directory depth to search for
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

=head1 DESCRIPTION

B<trova.pl> Recursive directory search and replacement utility.

=cut
# POD }}}1

my ($opt_binary, $opt_summarize, $opt_datestamp, $opt_directories, $opt_extra_pattern, $opt_extra_lines, $opt_extra_search_direction, $opt_exclude_pattern, $opt_filter_pattern, $opt_first, $opt_help, $opt_ignore_case,
    $opt_j, $opt_line_count, $opt_line_number, $opt_matches, $opt_max_depth, $opt_name_pattern, $opt_noexclude, $opt_nuke, $opt_print, $opt_remove,
    $opt_rename, $opt_size, $opt_substitute, $opt_type, $opt_verbose, $opt_word) = undef;

GetOptions(
    "binary|b!"                   => \$opt_binary,
    'count|c'                     => \$opt_line_count,
    "dir|d=s"                     => \$opt_directories,
    "extra|e=s"                   => \$opt_extra_pattern,
    "extralines|el=s"             => \$opt_extra_lines,
    "extradirection|ed=s"         => \$opt_extra_search_direction,
    "filter|f=s"                  => \$opt_filter_pattern,
    "first|1"                     => \$opt_first,
    'help|?'                      => \$opt_help,
    'ignore|i'                    => \$opt_ignore_case,
    'j|j=i'                       => \$opt_j,
    'nuke|k!'                     => \$opt_nuke,
    'line|l'                      => \$opt_line_number,
    "matches|m"                   => \$opt_matches,
    "maxdepth|max=i"              => \$opt_max_depth,
    "name|n=s"                    => \$opt_name_pattern,
    "noexclude|nox"               => \$opt_noexclude,
    "print|p!"                    => \$opt_print,
    "remove|rm"                   => \$opt_remove,
    "rename|mv=s"                 => \$opt_rename,
    "substitute|s=s"              => \$opt_substitute,
    "type|t=s"                    => \$opt_type,
    "summarize|u!"                => \$opt_summarize,
    "verbose|v"                   => \$opt_verbose,
    "word|w"                      => \$opt_word,
    "exclude|x=s"                 => \$opt_exclude_pattern,
    "datestamp|y"                 => \$opt_datestamp,
    "size|z"                      => \$opt_size,
) or banner(2);
banner(1) if $opt_help;

# Set defaults:
$opt_noexclude   = 0 if not defined $opt_noexclude;
$opt_binary      = 0 if not defined $opt_binary;
$opt_summarize   = 1 if not defined $opt_summarize;
$opt_extra_lines = 0 if not defined $opt_extra_lines and defined $opt_extra_pattern;
$opt_first       = 0 if not defined $opt_first;
$opt_ignore_case = 0 if not defined $opt_ignore_case;
$opt_line_count  = 0 if not defined $opt_line_count;
$opt_line_number = 0 if not defined $opt_line_number;
$opt_line_number = 1 if defined $opt_j;
$opt_matches     = 0 if not defined $opt_matches;
$opt_max_depth   = 1024 if not defined $opt_max_depth;
$opt_nuke        = 0 if not defined $opt_nuke;
$opt_print       = 1 if not defined $opt_print;
$opt_remove      = 0 if not defined $opt_remove;
$opt_verbose     = 0 if not defined $opt_verbose;
$opt_word        = 0 if not defined $opt_word;
$opt_datestamp   = 0 if not defined $opt_datestamp;
$opt_size        = 0 if not defined $opt_size;
$opt_type        = "a" if not defined $opt_type;
$opt_type        = lc($opt_type);

die("ERROR: No file contents or file name patterns specified. This command will remove all files in directory!\n") if ($opt_remove and not $opt_name_pattern and scalar(@ARGV) == 0);
die("ERROR: File name pattern '.' is too dangerous. This command will remove all files in directory!\n") if ($opt_remove and defined $opt_name_pattern and $opt_name_pattern eq '.');
die("ERROR: Cannot specify --remove with --substitute.\n") if ($opt_remove and defined $opt_substitute);
die("ERROR: Cannot specify --count with --size.\n") if ($opt_line_count and $opt_size);
die("ERROR: Cannot specify --count with --datestamp.\n") if ($opt_line_count and $opt_datestamp);
die("ERROR: Cannot specify --datestamp with --size.\n") if ($opt_datestamp and $opt_size);
die("ERROR: Cannot specify --line with --count or --datestamp or --size.\n") if $opt_line_number and ($opt_line_count or $opt_datestamp or $opt_size);
die("ERROR: --matches option can only be used if a content pattern is specified.\n") if ($opt_matches and scalar(@ARGV) == 0);
die("ERROR: --first option can only be used if a content pattern is specified.\n") if ($opt_first and scalar(@ARGV) == 0);
die("ERROR: --extralines option can only be used if an extra content pattern is specified with --extra.\n") if (defined $opt_extra_lines and not defined $opt_extra_pattern);
die("ERROR: --extradirection option can only be used if an extra content pattern is specified with --extra.\n") if (defined $opt_extra_search_direction and not defined $opt_extra_pattern);

my @dirs;
if (defined $opt_directories)
{
    @dirs = split(",", $opt_directories)
}
else
{
    @dirs = (".");
}

foreach my $dir (@dirs)
{
    die("ERROR: Too risky to delete files in '$dir'.\n") if ($opt_remove and $dir=~/^\\|^\/|^\w:/);
    die("ERROR: Specified argument '$dir' is not a valid directory.\n") if not -d $dir;
}

if (not $opt_noexclude)
{
    my $default_exclude_pattern = q(\.git|\.svn|~$);
    if (defined $opt_exclude_pattern)
    {
        $opt_exclude_pattern = $default_exclude_pattern . "|" . $opt_exclude_pattern;
    }
    else
    {
        $opt_exclude_pattern = $default_exclude_pattern;
    }
}

my @content_regexes;
foreach my $content_pattern (@ARGV)
{
    push(@content_regexes, compile_regex($content_pattern, $opt_word));
}

my $search_in_files = scalar(@content_regexes) > 0;

my $name_regex = compile_regex($opt_name_pattern, 0);
my $exclude_regex = compile_regex($opt_exclude_pattern, 0);
my $extra_regex = compile_regex($opt_extra_pattern, $opt_word);
my $filter_regex = compile_regex($opt_filter_pattern, $opt_word);
my $num_files_found = 0;
my $num_content_found = 0;
my $num_lines_found = 0;
my $sum_size_found = 0;
my $print_matched_lines = not($opt_matches or $opt_line_count or $opt_datestamp or $opt_size);

find({ wanted => \&wanted, no_chdir => 1, preprocess => \&preprocess }, @dirs);

if ($opt_summarize)
{
    if ($search_in_files)
    {
        print "Found $num_content_found occurrences in $num_files_found files.";
        print "\t*** WARNING ***: Only first occurrence in each file is recorded." if $opt_first;
    }
    else
    {
        print "Found $num_files_found files.";
    }

    if ($opt_line_count)
    {
        print " Total number of lines in all matched files was $num_lines_found.";
    }
    elsif ($opt_size)
    {
        print " Total file size of all matched files was $sum_size_found bytes.";
    }
}
print "\n";

sub banner
{
    my ($id) = @_;

    my $message = NAME . " " . VERSION . ", Copyright (c) 2016-2024 Cesare Guardino";
    print "\n$message\n\n";
    pod2usage($id);
}

sub wanted
{
    my $file = $_;
    my $path = $File::Find::name;

    if ((defined $name_regex and $path =~ /$name_regex/) or (not defined $name_regex))
    {
        my $found = $&;
        return if (defined $exclude_regex and $path =~ /$exclude_regex/);
        my $canonical_path = $path;
        $canonical_path =~ s/\//\\/g if not posix_shell();
        print "### Searching in $canonical_path ...\n" if ($opt_verbose and -d $file);

        if (not $search_in_files and -d $file and defined $name_regex and $opt_type ne "f")
        {
            if ($opt_print and $opt_datestamp)
            {
                my $file_datestamp = get_datestamp($file);
                print "[$file_datestamp] " . $canonical_path . "\n";
            }
            elsif ($opt_print)
            {
                print $canonical_path . "\n"; 
            }

            if ($opt_remove and $opt_nuke)
            {
                $File::Find::prune = 1;
                rmtree($file);
            }
            return;
        }
        elsif (-f $file and $opt_type ne "d")
        {
            $num_files_found += 1;

            if ($search_in_files)
            {
                return if (-B $file and not $opt_binary);
                my $contents_match = $opt_extra_pattern ? search_file_extra_contents($file, $path) : search_file_contents($file, $path);
                if ($contents_match > 0)
                {
                    if ($opt_print and $opt_line_count)
                    {
                        my $num_lines = get_line_count($file, $path);
                        $num_lines_found += $num_lines;
                        print "[$num_lines lines] " . $canonical_path . "\n";
                    }
                    elsif ($opt_print and $opt_size)
                    {
                        my $file_size = -s $file;
                        $sum_size_found += $file_size;
                        print "[$file_size bytes] " . $canonical_path . "\n";
                    }
                    elsif ($opt_print and $opt_datestamp)
                    {
                        my $file_datestamp = get_datestamp($file);
                        print "[$file_datestamp] " . $canonical_path . "\n";
                    }
                    elsif ($opt_print and $opt_matches)
                    {
                        print "[$contents_match matches] " . $canonical_path . "\n";
                    }
                    unlink($file) if $opt_remove;
                }
            }
            else
            {
                if ($opt_print and $opt_line_count)
                {
                    my $num_lines = get_line_count($file, $path);
                    $num_lines_found += $num_lines;
                    print "[$num_lines lines] " . $canonical_path . "\n";
                }
                elsif ($opt_print and $opt_size)
                {
                    my $file_size = -s $file;
                    $sum_size_found += $file_size;
                    print "[$file_size bytes] " . $canonical_path . "\n";
                }
                elsif ($opt_print and $opt_datestamp)
                {
                    my $file_datestamp = get_datestamp($file);
                    print "[$file_datestamp] " . $canonical_path . "\n";
                }
                elsif ($opt_print)
                {
                    print $canonical_path . "\n";
                }
                unlink($file) if $opt_remove;
                if ($opt_rename)
                {
                    my $file2 = $file; $file2 =~ s/$found/$opt_rename/;
                    rename($file, $file2);
                }
            }
        }
    }
}

# https://stackoverflow.com/questions/9919909/when-using-perls-filefind-whats-a-quick-easy-way-to-limit-search-depth
sub preprocess
{
    my $depth = $File::Find::dir =~ tr[/][];
    return @_ if $depth < $opt_max_depth;
    return grep { not -d } @_ if $depth == $opt_max_depth;
    return;
}

sub compile_regex
{
    my ($pattern, $word) = @_;

    return undef if not defined $pattern;

    $pattern = q(\b) . $pattern . q(\b) if $word;

    my $regex = $opt_ignore_case ? eval { qr/$pattern/i } : eval { qr/$pattern/ };
    die("ERROR: Error in pattern '$pattern' [$@]\n") if $@;

    return $regex;
}

sub search_file_contents
{
    my ($file, $path) = @_;

    my @new_lines if $opt_substitute;
    my $contents_match = 0;
    my $line_number = 0;
    open (FILE, '<', $file) or die ("ERROR: Can't open '$File::Find::name' [$!]");
    while (<FILE>)
    {
        $line_number++ if $opt_line_number;
        next if defined $opt_j and $line_number < $opt_j;
        next if defined $opt_filter_pattern and (/$filter_regex/);
        my $new_line = $_ if $opt_substitute;
        foreach my $content_regex (@content_regexes)
        {
            if (/($content_regex)/)
            {
                $new_line =~ s/$1/$opt_substitute/g if $opt_substitute;
                my $file_name = $File::Find::name;
                $file_name =~ s/\//\\/g if not posix_shell();
                my $line_info = ($opt_print and $opt_line_number) ? "[line $line_number]\t" : "";
                print $line_info . "$file_name : $_" if $opt_print and $print_matched_lines;
                $contents_match++;
                $num_content_found += 1;
                if ($opt_first)
                {
                    close (FILE);
                    return $contents_match;
                }
            }
        }

        last if defined $opt_j and $line_number == $opt_j;
        push(@new_lines, $new_line) if $opt_substitute;
    }
    close (FILE);

    if ($opt_substitute and $contents_match > 0)
    {
        open (FILE, '>', $file) or die ("ERROR: Can't open '$File::Find::name' [$!]");
        foreach my $new_line (@new_lines)
        {
            print FILE $new_line;
        }
        close (FILE);
    }

    return $contents_match;
}

sub search_file_extra_contents
{
    my ($file, $path) = @_;

    my @new_lines if $opt_substitute;
    my $contents_match = 0;
    my $line_number = 0;
    open (FILE, '<', $file) or die ("ERROR: Can't open '$File::Find::name' [$!]");
    my @contents = <FILE>;
    foreach (@contents)
    {
        $line_number++;
        next if defined $opt_filter_pattern and (/$filter_regex/);
        my $new_line = $_ if $opt_substitute;
        foreach my $content_regex (@content_regexes)
        {
            my $num_extra = 0;
            if (/($content_regex)/)
            {
                my ($jmin, $jmax);
                my $i = $line_number - 1;
                if (not defined $opt_extra_search_direction)
                {
                    $jmin = max($i - $opt_extra_lines, 0);
                    $jmax = min($i + $opt_extra_lines, scalar(@contents) - 1);
                }
                elsif (lc $opt_extra_search_direction eq 'u')
                {
                    $jmin = max($i - $opt_extra_lines, 0);
                    $jmax = $i;
                }
                elsif (lc $opt_extra_search_direction eq 'd')
                {
                    $jmin = $i;
                    $jmax = min($i + $opt_extra_lines, scalar(@contents) - 1);
                }
                elsif (lc $opt_extra_search_direction eq 'a')
                {
                    $jmin = 0;
                    $jmax = scalar(@contents) - 1;
                }

                for (my $j = $jmin; $j <= $jmax; $j++)
                {
                    next if defined $opt_filter_pattern and ($contents[$j] =~ /$filter_regex/);
                    $num_extra++ if $contents[$j] =~ /$extra_regex/;
                }
            }

            if (/($content_regex)/ and $num_extra > 0)
            {
                $new_line =~ s/$1/$opt_substitute/g if $opt_substitute;
                my $file_name = $File::Find::name;
                $file_name =~ s/\//\\/g if not posix_shell();
                my $line_info = "[extra $num_extra]\t";
                $line_info .= ($opt_print and $opt_line_number) ? "[line $line_number]\t" : "";
                print $line_info . "$file_name : $_" if $opt_print and $print_matched_lines;
                $contents_match++;
                $num_content_found += 1;
                if ($opt_first)
                {
                    close (FILE);
                    return $contents_match;
                }
            }
        }

        push(@new_lines, $new_line) if $opt_substitute;
    }
    close (FILE);

    if ($opt_substitute and $contents_match > 0)
    {
        open (FILE, '>', $file) or die ("ERROR: Can't open '$File::Find::name' [$!]");
        foreach my $new_line (@new_lines)
        {
            print FILE $new_line;
        }
        close (FILE);
    }

    return $contents_match;
}

sub get_line_count
{
    my ($file, $path) = @_;

    open (FILE, '<', $file) or die ("ERROR: Can't open '$File::Find::name' [$!]");
    my $i = 0;
    while (<FILE>)
    {
        $i++;
    }
    close (FILE);
    return $i;
}

sub get_datestamp
{
    my ($filename) = @_;
    return get_datetime_string((stat($filename))[9]);
}

sub get_datetime_string
{
    my ($time) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($time);

    ++$mon;
    $year += 1900;

    $sec = zero_pad($sec);
    $min = zero_pad($min);
    $hour = zero_pad($hour);
    $mday = zero_pad($mday);
    $mon = zero_pad($mon);

    return "$year-$mon-$mday" . "_" . "$hour:$min:$sec";
}

sub zero_pad
{
    my ($x) = @_;

    return $x < 10 ? "0$x" : $x;
}

sub posix_shell
{
    return ($^O ne "MSWin32" or defined $ENV{'TERM'} and $ENV{'TERM'} =~ /cygwin|xterm/ or defined $ENV{'MSYSCON'} and $ENV{'MSYSCON'} =~ /sh/) ? 1 : 0;
}
