#!/usr/bin/perl
###########################################
#                                         #
#          System-Check Framework         #
#                20.05.2016               #
#                                         #
###########################################


# Set the script path
	use File::Spec::Functions qw(rel2abs);
	use File::Basename;
	my $scriptDir = dirname(rel2abs($0));
	use FindBin;
	use File::Spec;
	use lib File::Spec->catdir($FindBin::Bin, $basePath);

# My Perl modules
	use modules::RunCommand;
	use modules::DisplayCheckResult;
	use modules::WriteToLog;
	use modules::WriteToHtml;

# Other
	use Term::ANSIColor;
	use strict;

###########################################
# VAR

my $VERSION = '2.1';

#my $scriptDir = File::Spec->catdir($FindBin::Bin, '..', 'chc');

my $ISOdate = sprintf "%d-%02d-%02d %02d:%02d:%02d", map { $$_[5]+1900, $$_[4]+1, $$_[3], $$_[2], $$_[1], $$_[0] } [localtime];    # --> date in "YYYY-MM-DD HH:MM:SS" format

my %listOfErrors;
my @listOfInstructions;
my @htmlBody;

# defaults if not defined in chc.conf
my $title = "Checkscript $VERSION";    # --> Title of Checkscript
my $colDef = "white";
my $colHost = 'cyan';
my $colOk = "green";
my $colErr = "red";
my $itemListFileName = 'chc.csv';
my $logging = "off";
my $logDest = "/tmp/chc.log";
my $silentMode = "off";
my $autoRepair = "off";
my $htmlOutput = "off";
my $htmlOutputDest = "/tmp/chc.html";

# /VAR
###########################################

###########################################
# SUBS

sub printUsage {
    my $readmeFileName = 'README';
    open (my $README_FILE, '<', "$scriptDir/lib/$readmeFileName");
    while (my $line=readline($README_FILE)) {
        print "$line";
    }
    close ($README_FILE);
    exit 0;
}

sub checkArguments {
    my $nextArg = 0;
    my $argOk = "FALSE";
    my $csvPath = 0;

    foreach (@ARGV) {
        if ( "$nextArg" eq "CSV_PATH") {
            $itemListFileName = "$_";
            $scriptDir = "";
            $argOk = "FALSE";
        } elsif ( "$nextArg" eq "HTML_PATH") {
            $htmlOutputDest = "$_";
            $argOk = "FALSE";
        }elsif ( "$_" =~ /(-help|--help|-h)/) {
            printUsage;
            $argOk = "TRUE";
        } elsif ( "$_" eq "-f") {
            $nextArg = "CSV_PATH";
            $argOk = "TRUE";
        } elsif ( "$_" eq "-o") {
            $nextArg = "HTML_PATH";
            $argOk = "TRUE";
        } elsif ( "$_" eq "-s") {
            $silentMode = "on";
            $argOk = "TRUE";
        } elsif ( "$_" eq "-r") {
            $autoRepair = "on";
            $argOk = "TRUE";
        } elsif ( "$argOk" eq "FALSE") {
            die "Bad argument: $_";
        } 
    }
}

sub loadConfig {
    my $configFileName = 'chc.conf';
    open (my $CONFIG_FILE, '<', "$scriptDir/lib/$configFileName");   # if not exist, the default will be used
    while (my $line=readline($CONFIG_FILE)) {
        my @configLine = split /=/, $line;
        chomp($configLine[1]);

        if (($configLine[1] !~ /auto/) && ($configLine[0] !~ /^#.*/)) {
            if ($configLine[0] =~ /title/) {
                $title = $configLine[1];
            } elsif ($configLine[0] =~ /color_default/) {
                $colDef = $configLine[1];
            } elsif ($configLine[0] =~ /color_host/) {
                $colHost = $configLine[1];
            } elsif ($configLine[0] =~ /color_ok/) {
                $colOk = $configLine[1];
            } elsif ($configLine[0] =~ /color_err/) {
                $colErr = $configLine[1];
            } elsif ($configLine[0] =~ /checklist_file/) {
                $itemListFileName = $configLine[1];
            } elsif ($configLine[0] =~ /html_out/) {
                $htmlOutput = $configLine[1];
            } elsif ($configLine[0] =~ /html_dest/) {
                $htmlOutputDest = $configLine[1];
            } elsif ($configLine[0] =~ /logging/) {
                $logging = $configLine[1];
            } elsif ($configLine[0] =~ /log_dest/) {
                $logDest = $configLine[1];
            } elsif ($configLine[0] =~ /silent_mode/) {
                $silentMode = $configLine[1];
            }
        }
    }

    close ($CONFIG_FILE);    
}

sub checkItem {
    my $severity = "INFO";    # OK, ERROR (default OK)
    open (my $ITEMS_FILE, '<', "$scriptDir/lib/$itemListFileName") or die ("Error: can't open $scriptDir/lib/$itemListFileName!");

    while (my $line=readline($ITEMS_FILE)) {
        my $colSev = $colOk;
        if ($line !~ /^#.*/) {
            my ($server, $checkType, $desc, $checkCmd, $countMin, $countMax, $okMsg, $errMsg, $repairCmd, $instructionMsg) = split /;/, $line;
            my $checkResult = runCommand($server, $checkCmd, $checkType);

            if ($countMin =~ /^\s*$/) {
                $countMin = 1;
            }
            if ($countMax =~ /^\s*$/) {
                $countMax = 99999999;
            }

            if (($checkType =~ /PS/) && ($checkResult !~ /NOT REACHABLE/)) {
                if (($checkResult >= $countMin) && ($checkResult <= $countMax)) {
                    $checkResult="$okMsg";
                    $severity = "INFO";
                    $colSev = $colOk;
                } else {
                    $checkResult="$errMsg";
                    $severity = "ERROR";
                    $colSev = $colErr;
                }
            } elsif ($checkResult =~ /NOT REACHABLE/) {
                $severity = "ERROR";
                $colSev = $colErr;
            } elsif ($checkType =~ /LOG/) {
                $severity = "ERROR";
                $colSev = $colErr;
            }

            if ($checkType =~ /DESC/) {
                print colored ("[ ", $colDef);
                print colored ("$server", $colOk);
                print colored (" ]\n", $colDef);
            }

            if ($silentMode =~ /off/) {
                displayCheckResult($server, $desc, $checkResult, $checkType, $severity, $colHost, $colDef, $colSev);
                if (($severity !~ /INFO/) && (length($instructionMsg) != 0)) {
                    push @listOfInstructions, "$instructionMsg";
                }
            }

            # if there ist an error, put it into the hash-list: 
            if (($severity =~ /ERROR/) && ($checkType !~ /LOG/) && ($silentMode =~ /off/) && (length($repairCmd) != 0))  {
                $listOfErrors{"$server $desc"} = "$repairCmd";
            }

            if (($logging =~ /on/) && ($checkType !~ /DESC/)) {
                $ISOdate = sprintf "%d-%02d-%02d %02d:%02d:%02d", map { $$_[5]+1900, $$_[4]+1, $$_[3], $$_[2], $$_[1], $$_[0] } [localtime];
                if ( $checkType !~ /PS/ ) {
                    $checkResult = "\n$checkResult";
                }
                writeToLog($ISOdate, $severity, "($server $desc) $checkResult", $logDest);
            }

            if (($htmlOutput =~ /on/) && ($checkType !~ /DESC/)) {
                my $cellColor;
                if ($severity =~ /ERROR/) {
                    $cellColor = "bgcolor='#FF6666'";
                } else {
                    $cellColor = "bgcolor='#66FF66'";
                }
                push @htmlBody, '<tr><td '.$cellColor.'>'.$severity.'</td><td>['.$server.'] ('.$desc.')</td><td>'.$checkResult.'</td></tr>';
            }

        }
    }

    close ($ITEMS_FILE);
     
}

sub printInstructions {
    my $instFileName = 'chc.instructions';
    my $displayCurrentLine = "FALSE";
    open (my $INST_FILE, '<', "$scriptDir/lib/$instFileName") or warn ("Error: can't open $scriptDir/lib/$instFileName!");
    while (my $line=readline($INST_FILE)) {
        my $linePart = $line;
        $linePart =~ s/_BEGIN|_END//;
        chomp($linePart);
        if (grep(/$linePart/, @listOfInstructions)) {
            if ($line =~ /.*BEGIN/) {
                $displayCurrentLine = "TRUE";
            } elsif ($line =~ /.*END/) {
                $displayCurrentLine = "FALSE";
            } 
        } elsif ($displayCurrentLine =~ /TRUE/) {
                print $line."\n";
        }
    }
}

sub repairErrors {
    my $answer;
    while ((my $key, my $value) = each(%listOfErrors)) {
        if ($autoRepair =~ /off/) {
            do {
                print "Repair this error: $key? [y/n] : ";
                $answer = <>;
            } until (($answer =~ /y/) || ($answer =~ /n/));
        } else {
                $answer = "y";
                print "Auto-Repair this error: $key\n";
        }
            if ($answer =~ /y/) {
                my @desc = split / /, $key;
                #print "$desc[0]";
                print runCommand($desc[0], $value, "REPAIR");
                if ($logging =~ /on/) {
                    $ISOdate = sprintf "%d-%02d-%02d %02d:%02d:%02d", map { $$_[5]+1900, $$_[4]+1, $$_[3], $$_[2], $$_[1], $$_[0] } [localtime];
                    writeToLog($ISOdate, "INFO", "Auto-repair error: $key($value)", $logDest);
                }
            }

    }
}

# /SUBS
###########################################

###########################################
# MAIN

loadConfig;
checkArguments;
if ($silentMode =~ /off/) {
    print colored ("\n[ ", $colDef);
    print colored ("$title", $colHost);
    print colored (" ] ($ISOdate)\n\n", $colDef);
}
checkItem;
print "\n";

if ($htmlOutput =~ /on/) {
    writeToHtml($ISOdate, $title, \@htmlBody, $htmlOutputDest);
}

if (@listOfInstructions) {
    my $answer;
    do {
        print "Display the instructions? [y/n] : ";
        $answer = <>;
    } until (($answer =~ /y/) || ($answer =~ /n/));

    if ($answer =~ /y/) {
        printInstructions;
    }
}

if (%listOfErrors) {
    my $answer;
    if ($autoRepair =~ /off/) {
        do {
            print "Try repair errors? [y/n] : ";
            $answer = <>;
        } until (($answer =~ /y/) || ($answer =~ /n/));
    } else {
        $answer = "y";
    }
    if ($answer =~ /y/) {
        repairErrors;
    }
}

# /MAIN
###########################################


###########################################
# POST COMMANDS


# /POST COMMANDS
###########################################

