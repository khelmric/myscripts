###########################################
#                 MODULE                  #
#            DisplayCheckResult           #
#                                         #
#               23.08.2015                #
#                                         #
###########################################

package modules::DisplayCheckResult;

use strict;
use warnings;
use Term::ANSIColor;
#use Term::ReadKey;
use Sys::Hostname;

require Exporter;

our $VERSION = '1.00';
our @ISA = qw(Exporter);
our @EXPORT = qw(displayCheckResult);

sub displayCheckResult ($$$$$$$$) {
    my $host = shift;
    my $description = shift;
    my $result = shift;
    my $type = shift;
    my $severity = shift;
    my $colHost = shift;
    my $colDefault = shift;
    my $colSeverity = shift;

    chomp($result);

    if ( $host =~ /LOCALHOST/ ) {
        $host = hostname;
        $host = uc $host;
    }

    my $rowLength = length("$host$description$result");
    my $maxLength = setMaxLength();
    my $dotLength = $maxLength - $rowLength;
    if ( $type =~ /PS/ ) {
        print colored ("[ ", $colDefault);
        print colored ("$host", $colHost);
        print colored (" ] ($description)".'.' x $dotLength."[ ", $colDefault);
        print colored ("$result", $colSeverity);
        print colored (" ]\n", $colDefault);
    } elsif ( $type =~ /CMD/ ) {
        $result = addTabToOutput($result, $maxLength);
        print colored ("[ ", $colDefault);
        print colored ("$host", $colHost);
        print colored (" ] ($description)\n", $colDefault);
        if ( $result =~ /[a-z|A-Z]/ ) {
            print colored ("$result", $colDefault);
        }
    } elsif ( $type =~ /LOG/ ) {
        $result = addTabToOutput($result, $maxLength);
        print colored ("[ ", $colDefault);
        print colored ("$host", $colHost);
        print colored (" ] ($description)\n", $colDefault);
        print colored ("$result", $colSeverity);
        print colored ("\n", $colDefault);
    }
    return 1;
}

sub addTabToOutput ($) {
    my $tabSize = 8;
    my $beforeAddTab = shift;
    my $afterAddTab = "";
    my $maxLength = shift;
    my $maxTabbedWith = $maxLength-$tabSize;
    my @lines = split(/\n/, $beforeAddTab);
    foreach (@lines) {
        my @lineSplit = split(/(.{$maxTabbedWith})/, $_);
        foreach (@lineSplit) {
        $afterAddTab = "$afterAddTab".' ' x $tabSize.$_."\n";
        }
    }
    return $afterAddTab;
}

sub setMaxLength () {
    my ($wchar) = `echo \$(tput cols)`;
    my $maxLength = ($wchar-20);

    if ($maxLength > 100) {
        $maxLength = 100;
    }
    return $maxLength;
}

1;
