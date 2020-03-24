#!/usr/bin/perl

#######################################################################################
# Name:          which.pl
# Description:   Simple Perl version of standard Linux which utility
# Author:        Cesare Guardino
# Last modified: 18 April 2016
#######################################################################################

use strict;
use warnings;
#use File::Which;                  # exports which()
use File::Which qw(which where);  # exports which() and where()
use Getopt::Long;
use Pod::Usage;

# POD {{{1
=head1 NAME

which.pl

=head1 SYNOPSIS

 which.pl [options] <program_name>

 Options:
   -a,    --all                   Prints all occurrences found
   -h,    --help                  Help usage message

 Optional arguments:
   <program_name>                 Program name to find

=head1 DESCRIPTION

B<which.pl> Simple Perl version of standard Linux which utility.

=cut
# POD }}}1

my ($opt_all, $opt_help) = undef;

GetOptions(
    "all|a"                       => \$opt_all,
    'help|?'                      => \$opt_help,
) or pod2usage(2);
pod2usage(1) if $opt_help;

# Set defaults:
$opt_all = 0 if not defined $opt_all;

if ($opt_all)
{
    my @paths = where $ARGV[0];
    # Or
    #my @paths = which 'gmake'; # an array forces search for all of them
    foreach my $exe_path (@paths)
    {
        print_path($exe_path);
    }
}
else
{
    my $exe_path = which $ARGV[0];
    print_path($exe_path);
}

sub print_path
{
    my ($exe_path) = @_;

    return if not defined $exe_path;

    if (posix_shell())
    {
        $exe_path =~ s/\\/\//g;
    }
    else
    {
        $exe_path =~ s/\//\\/g;
    }
    print "$exe_path\n";
}

sub posix_shell
{
    return ($^O ne "MSWin32" or defined $ENV{'TERM'} and $ENV{'TERM'} =~ /cygwin/ or defined $ENV{'MSYSCON'} and $ENV{'MSYSCON'} =~ /sh/) ? 1 : 0;
}
