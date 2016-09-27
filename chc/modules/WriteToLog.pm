###########################################
#                 MODULE                  #
#               WriteToLog                #
#               12.08.2015                #
#                                         #
###########################################

package modules::WriteToLog;

use strict;
use warnings;

require Exporter;

our $VERSION = '1.00';
our @ISA = qw(Exporter);
our @EXPORT = qw(writeToLog);

sub writeToLog ($$$$) {
    my $timeStamp = shift;
    my $severity = shift;
    my $logText = shift;
    my $logDest = shift;


#    print "$logDest --> $timeStamp $severity $logText\n";

    open (FILE, '>>', "$logDest");
        print FILE "$timeStamp $severity $logText\n";
    close (FILE);

    return 1;
}


1;
