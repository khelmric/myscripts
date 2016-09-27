#!/usr/bin/perl -w

use strict;
use warnings;
use Term::ANSIColor;
 
########################################
# GLOBAL VARIABLES
 
    my %logContents = ();
    my $currentHour = undef;
    my $interval = "HOURLY";
    my $errorsOnly = 0;
 
########################################
# PARAMETER CHECK
 
    # Example: ./logstat.pl -D -f access2.log

    my $next = 0;
    my $param = "FALSE";
    my $file = 0;

    foreach (@ARGV) {
        if ( "$next" eq "PATH") {
            $file = "$_";
        }
 
        if ( "$_" =~ /(-help|--help|-h)/) {
            &printUsage;
        } elsif ( "$_" eq "-f") {
            $next = "PATH";
            $param = "TRUE";
        } elsif ( "$_" eq "-H") {
            $interval = "HOURLY";
            $param = "TRUE";
        } elsif ( "$_" eq "-D") {
            $interval = "DAILY";
            $param = "TRUE";
        } elsif ( "$_" eq "-E") {
            $errorsOnly = 1;
            $param = "TRUE";
        }
 
    }
 
########################################
# OPEN FILE

    my $logType = 0;
    open (our $fd, '<', "$file") or die "cannot open file $file";

    if (<$fd> =~ /\[\d+\/\w+\/\d+:\d+:\d+:\d+\s.*\]\s"[POST|GET|HEAD|PUT|DELETE|TRACE|OPTIONS|CONNECT].*HTTP.*"/) {
        &apacheAccessLog;
    } else {
        print "Not an Apache log.";
    }
 

########################################
# FUNCTIONS

    sub printUsage {
        print "\nLOGSTAT - Logfile statistics\n";
        print "Usage: logstat [OPTIONS] -f FILE\n";
        print "OPTIONS:\n";
        print " -E : show errors only\n";
        print " -H : print houly statistics\n";
        print " -D : print daily statistics\n\n";
        exit;
    }

    sub apacheAccessLog {
        while (<$fd>) {
            if ( "$interval" eq "HOURLY" ) {
                if ((!( $errorsOnly ) | ( $_ =~ /^.*\[\d{1,2}\/\w{3}\/\d{4}:\d{1,2}.*" (4\d{2}|5\d{2}).*$/ )) & ($_ =~ /^.*\[((\d{1,2}\/\w{3}\/\d{4}):(\d{1,2})).*" (\d{3}).*$/)) {
                        $logContents{"$2 $3:00-$3:59 $4"} += 1;
                } elsif  ($_ !~  /^.*\[((\d{1,2}\/\w{3}\/\d{4}):(\d{1,2})).*" (\d{3}).*$/) {
                    $logContents{unknown} += 1;
                }
            } else {
                if ((!( $errorsOnly ) | ( $_ =~ /^.*\[\d{1,2}\/\w{3}\/\d{4}:\d{1,2}.*" (4\d{2}|5\d{2}).*$/ )) & ($_ =~ /^.*\[((\d{1,2}\/\w{3}\/\d{4}):(\d{1,2})).*" (\d{3}).*$/)) {
                    $logContents{"$2 $4"} += 1;
                } elsif  ($_ !~  /^.*\[((\d{1,2}\/\w{3}\/\d{4}):(\d{1,2})).*" (\d{3}).*$/) {
                    $logContents{unknown} += 1;
                }
            }
        }

        $currentHour = -1;
        foreach (sort keys %logContents) {
            # Insert hourly separator
            if ("$interval" eq "HOURLY") {
                if (($_ =~ /\s(\d{1,2}):\d{2}-/) & ($currentHour ne $1)) {
                    print "--------------------------------\n";
                    $currentHour = $1;
                }
            }

            print "$_ : ";

            # Colorized Output:
            # HTTP Status Codes 100-101 - Informational Status Codes - white
            # HTTP Status Codes 200-206 - Successful Status Codes    - green
            # HTTP Status Codes 300-307 - Redirection Status Codes   - cyan
            # HTTP Status Codes 400-416 - Client Error Status Codes  - yellow
            # HTTP Status Codes 500-505 - Server Error Status Codes  - red
            if ($_ =~ /\d{2}\s1\d{2}/) {
                print colored ("$logContents{$_}\n", 'white');
            } elsif ($_ =~ /\d{2}\s2\d{2}/) {
                print colored ("$logContents{$_}\n", 'green');
            } elsif ($_ =~ /\d{2}\s3\d{2}/) {
                print colored ("$logContents{$_}\n", 'cyan');
            } elsif ($_ =~ /\d{2}\s4\d{2}/) {
                print colored ("$logContents{$_}\n", 'yellow');
            } elsif ($_ =~ /\d{2}\s5\d{2}/) {
                print colored ("$logContents{$_}\n", 'red');
            }

        }

    }
