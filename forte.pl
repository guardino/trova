#!/usr/bin/perl

#######################################################################################
# Name:          forte.pl
# Description:   Creates call graphs for Fortran code
# Author:        Cesare Guardino
# Last modified: 18 February 2024
#######################################################################################

use strict;
use warnings;

use constant NAME    => "forte";
use constant VERSION => "0.4.8";

use File::Basename;
use File::Find;
use Getopt::Long;
use Pod::Usage;

# POD {{{1
=head1 NAME

forte.pl

=head1 SYNOPSIS

 forte.pl [options] name

 Options:
   -a,    --all                   Show all duplicated calls (takes longer to run)
   -b,    --backward              Display backward arrows from specified function to main
   -d,    --dir                   Comma-separated list of directories to search
   -e,    --ext                   Specify extra file extensions to search 
   -f,    --file                  Single file to search
   -h,    --help                  Help usage message
   -i,    --ignore                Ignore case
   -s,    --show                  Show generated graph image

=head1 DESCRIPTION

B<forte.pl> Creates call graphs for Fortran code

=cut
# POD }}}1

my ($opt_all, $opt_backward, $opt_directories, $opt_ext, $opt_file, $opt_help, $opt_ignore_case, $opt_show) = undef;

my @files;
my %types;

main();

sub main
{
    GetOptions(
        'all|a'                       => \$opt_all,
        'backward|b'                  => \$opt_backward,
        'dir|d=s'                     => \$opt_directories,
        'ext|e=s'                     => \$opt_ext,
        'file|f=s'                    => \$opt_file,
        'help|?'                      => \$opt_help,
        'ignore|i'                    => \$opt_ignore_case,
        'show|s'                      => \$opt_show,
    ) or banner(2);
    banner(1) if $opt_help;

    # Set defaults:
    $opt_all = 0 if not defined $opt_all;
    $opt_backward = 0 if not defined $opt_backward;
    $opt_ignore_case = 0 if not defined $opt_ignore_case;
    $opt_show = 0 if not defined $opt_show;

    %types = (
        'f'   => 1,
        'f77' => 1,
        'for' => 1,
        'f90' => 0,
        'f95' => 0,
        'f03' => 0,
    );
    $types{$opt_ext} = 1 if defined $opt_ext;

    die("ERROR: Please specify a subroutine or function name.\n") if scalar(@ARGV) == 0;
    my $name = $ARGV[0];

    if (defined $opt_file)
    {
        die("ERROR: Specified file $opt_file does not exist.\n") if not -f $opt_file;
        push(@files, $opt_file)
    }
    else
    {
        my @dirs;
        if (defined $opt_directories)
        {
            @dirs = split(",", $opt_directories)
        }
        else
        {
            @dirs = (".");
        }

        find({ wanted => \&wanted, no_chdir => 1 }, @dirs);
    }

    my $graph_file = "$name.dot";
    my $graph_image = "$name.png";
    remove_file($graph_file);
    remove_file($graph_image);

    my $data = "";
    my $caller_found;
    ($data, $caller_found) = recurse($data, $name);
    die("ERROR: Specified name $name not found.\n") if length($data) == 0;

    my $type = $opt_backward ? "digraph" : "graph";
    my $graph =
        "$type {\n" .
        $data .
        "}\n";
    write_file($graph_file, $graph);

    run_command("dot -Tpng $graph_file > $graph_image");
    die("ERROR: Failed to generate $graph_image.\n") if not -f $graph_image;
    if (-f $graph_image and $opt_show)
    {
        run_command($graph_image);
    }
}

sub banner
{
    my ($id) = @_;

    my $message = NAME . " " . VERSION . ", Copyright (c) 2024 Cesare Guardino";
    print "\n$message\n\n";
    pod2usage($id);
}

sub wanted
{
    if (-f $_)
    {
        my ($ext) = $_ =~ /\.([^.]+)$/;
        $ext = lc($ext);
        push(@files, $File::Find::name) if exists($types{$ext});
    }
}

sub recurse
{
    my ($data, $name) = @_;

    my $found = 0;
    my $call_regex = compile_call_regex($name);
    my $subroutine_regex = compile_subroutine_regex();
    my $function_regex = compile_function_regex();
    my $symbol = $opt_backward ? "->" : "--";

    foreach my $file (@files)
    {
        my ($ext) = $file =~ /\.([^.]+)$/;
        $ext = 'f' if not defined $ext;
        $ext = lc($ext);
        my $i = 0;
        my $fh;
        open ($fh, '<', $file) || die ("Can't open file $file: $!");
        while (<$fh>)
        {
            $i++;
            next if is_comment($_, $ext);
            if (/$call_regex/)
            {
                $found = 1;
                my $basefile = basename($file);
                my $lines = read_file($file);
                $data .= $name; 
                my $caller;
                for (my $j = $i; $j >= 1; $j--)
                {
                    my $line = $lines->[$j-1];
                    next if is_comment($line, $ext);

                    my $string;
                    if ($line =~ /$subroutine_regex/)
                    {
                        $string = $2;
                    }
                    elsif ($line =~ /$function_regex/)
                    {
                        $string = $2;
                    }

                    if (defined $string)
                    {
                        $data .= " $symbol ";
                        $caller = $string;
                        $caller =~ s/\(.*$//g;
                        $caller =~ s/^\s*(.*?)\s*$/$1/;
                        if (not $opt_all and $data =~ /$name $symbol $caller/)
                        {
                            $data .= "$caller;\n";
                            last;
                        }

                        my $caller_found;
                        ($data, $caller_found) = recurse($data, $caller);
                        $data .= "$caller;\n" if not $caller_found;
                        last;
                    }
                }

                $data .= ";\n" if not defined $caller;
            }
        }

        close ($fh);
    }

    return ($data, $found);
}

sub compile_call_regex
{
    my ($name) = @_;

    my $pattern = "CALL $name\\s|CALL $name\$|CALL $name(\\s*)?\\(|=(\\s*)?$name(\\s*)?\\(";
    return compile_regex($pattern);
}

sub compile_subroutine_regex
{
    my $pattern = "^(\\s*)?SUBROUTINE (.*)";
    return compile_regex($pattern);
}

sub compile_function_regex
{
    my $pattern = "^(\\s*)?FUNCTION (.*)\\(";
    return compile_regex($pattern);
}

sub compile_regex
{
    my ($pattern) = @_;

    my $regex = $opt_ignore_case ? eval { qr/$pattern/i } : eval { qr/$pattern/ };
    die("ERROR: Error in pattern '$pattern' [$@]\n") if $@;

    return $regex;
}

sub is_comment
{
    my ($line, $ext) = @_;

    return 1 if $line=~/^C/i and $types{$ext};
    return 1 if $line=~/^(\s*)?!/ and not $types{$ext};
    return 0;
}

sub read_file
{
    my ($file) = @_;

    my $fh;
    open ($fh, '<', $file) or die ("ERROR: Can't open '$file' [$!]");
    my @lines = <$fh>;
    close ($fh);

    return \@lines;
}

sub write_file
{
    my ($file, $string) = @_;

    remove_file($file);

    my $fh;
    open ($fh, '>', $file) or die ("ERROR: Can't open '$file' [$!]");
    print $fh $string;
    close ($fh);
}

sub remove_file
{
    unlink($_[0]) if -f $_[0];
}

sub run_command
{
    my ($cmd) = @_;

    print "RUNNING: $cmd ...\n";
    system($cmd);
}
