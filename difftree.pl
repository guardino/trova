#!/usr/bin/perl

#################################################################
# Name:          difftree.pl
# Description:   Recursively compares two directory trees.
# Author:        Cesare Guardino
# Last modified: 16 April 2016
#################################################################

use strict;
use warnings;
use File::Find;
use Getopt::Long;
use Pod::Usage;

# POD {{{1
=head1 NAME

difftree.pl

=head1 SYNOPSIS

 difftree.pl [options] <dir1> <dir2>

 Options:
   -d,  --difftool                Full path to diff program 
   -h,  --help                    Help usage message
   -s,  --show_same               Show same (identical) files
   -t,  --tree_only               Compare directory structures only (do not diff file contents) 
   -v,  --verbose                 Turn on verbosity
   -xd, --exclude_dir_pattern     Regex to exclude directories
   -xf, --exclude_file_pattern    Regex to exclude files

 Compulsory arguments:
   <dir1> <dir2>                  Directories to compare

=head1 DESCRIPTION

B<difftree.pl> Recursively compares two directory trees.

=cut
# POD }}}1

my ($opt_difftool, $opt_exclude_dir_pattern, $opt_exclude_file_pattern, $opt_help,
    $opt_show_same, $opt_tree_only, $opt_verbose) = undef;

GetOptions(
    "difftool|d=s"                => \$opt_difftool,
    "exclude_dir_pattern|xd=s"    => \$opt_exclude_dir_pattern,
    "exclude_file_pattern|xf=s"   => \$opt_exclude_file_pattern,
    'help|?'                      => \$opt_help,
    "show_same|s"                 => \$opt_show_same,
    "tree_only|t"                 => \$opt_tree_only,
    "verbose|v"                   => \$opt_verbose,
) or pod2usage(2);
pod2usage(1) if $opt_help;

if (scalar(@ARGV) != 2)
{
    print "ERROR: You must specify two directories\n";
    print "\n";
    pod2usage(1);
}
my ($dir1, $dir2) = @ARGV;

my @dirs;
my $start_dir;
start_recursive_diff($dir1, $dir2);

sub start_recursive_diff
{
    my ($dir1, $dir2) = @_;

    $dir1 =~ s/\\/\//g;
    $dir2 =~ s/\\/\//g;

    my $opt_exclude_dir_regex = compile_regex($opt_exclude_dir_pattern);
    my $opt_exclude_file_regex = compile_regex($opt_exclude_file_pattern);

    diff_dirs($dir1, $dir2, $opt_exclude_file_regex);

    $start_dir = $dir1;
    find(\&wanted, $start_dir);
    $start_dir = $dir2;
    find(\&wanted, $start_dir);

    @dirs = uniq(@dirs);

    foreach my $dir (sort @dirs)
    {
        next if defined $opt_exclude_dir_regex and $dir =~ /$opt_exclude_dir_regex/;

        if (-d "$dir1/$dir")
        {
            if (-d "$dir2/$dir")
            {
                diff_dirs("$dir1/$dir", "$dir2/$dir", $opt_exclude_file_regex);
            }
            else
            {
                print_result("only", "$dir1/$dir");
            }
        }
        elsif (-d "$dir2/$dir")
        {
            print_result("only", "$dir2/$dir");
        }
    }
}

sub wanted
{
    if (-d $_)
    {
        my $subdir = $File::Find::name;
        $subdir =~ s/$start_dir\///;
        push(@dirs, $subdir) if $subdir ne $dir1 and $subdir ne $dir2; 
    }
}

sub read_dir
{
    my ($dir) = @_;

    opendir(DIR, $dir) or die("ERROR: Cannot open $dir [$!]\n");

    return readdir(DIR);
}

sub uniq
{
    my %seen = ();
    my @r = ();
    foreach my $a (@_)
    {
        unless ($seen{$a})
        {
            push @r, $a;
            $seen{$a} = 1;
        }
    }

    return @r;
}

sub compile_regex
{
    my ($pattern) = @_;

    return undef if not defined $pattern;

    my $regex = eval { qr/$pattern/ };
    die("ERROR: Error in pattern '$pattern' [$@]\n") if $@;

    return $regex;
}

sub diff_dirs
{
    my ($dir1, $dir2, $opt_exclude_file_regex) = @_;

    my @files = uniq(read_dir($dir1), read_dir($dir2));

    foreach my $file (sort @files)
    {
        next if defined $opt_exclude_file_regex and $file =~ /$opt_exclude_file_regex/;

        if (-e "$dir1/$file" and not -d "$dir1/$file")
        {
            if (-e "$dir2/$file" and not -d "$dir2/$file")
            {
                diff_files("$dir1/$file", "$dir2/$file") if not $opt_tree_only;
            }
            else
            {
                print_result("only", "$dir1/$file");
            }
        }
        elsif (-e "$dir2/$file" and not -d "$dir2/$file")
        {
            print_result("only", "$dir2/$file");
        }
    }
}

sub diff_files
{
    my ($file1, $file2) = @_;

    my $default_diff_exe = "diff -q";
    my $diff_exe = defined $opt_difftool ? $opt_difftool : defined $ENV{'DIFF_EXE'} ? $ENV{'DIFF_EXE'} : $default_diff_exe;

    my $cmd = "$diff_exe \"$file1\" \"$file2\"";
    print_result("#(info)", $cmd) if $opt_verbose;
    my $diff_output = `$cmd`;
    if ($diff_output)
    {
        print_result("diff", $file1, $file2);
    }
    elsif ($opt_show_same)
    {
        print_result("#same", $file1, $file2);
    }
}

sub print_result
{
    my ($status, $a, $b) = @_;

    $a = "\"$a\"" if ($a =~ /\s+/);

    $a =~ s/\//\\/g if not posix_shell();

    my $line = "$status:   $a";
    if (defined $b)
    {
        $b =~ s/\//\\/g if not posix_shell();
        $b = "\"$b\"" if ($b =~ /\s+/);
        $line .= "  $b";
    }

    print "$line\n";
}

sub posix_shell
{
    return ($^O ne "MSWin32" or defined $ENV{'TERM'} and $ENV{'TERM'} =~ /cygwin/ or defined $ENV{'MSYSCON'} and $ENV{'MSYSCON'} =~ /sh/) ? 1 : 0;
}
