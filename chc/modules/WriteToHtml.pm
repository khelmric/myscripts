###########################################
#                 MODULE                  #
#               WriteToHtml               #
#               03.09.2015                #
#                                         #
###########################################

package modules::WriteToHtml;

use strict;
use warnings;

require Exporter;

our $VERSION = '1.00';
our @ISA = qw(Exporter);
our @EXPORT = qw(writeToHtml);

sub writeToHtml ($$$$) {
    my $timeStamp = shift;
    my $title = shift;
    my $htmlBody = shift;
    my $htmlDest = shift;

    unlink $htmlDest;

    open (FILE, '>>', "$htmlDest") or warn "Cannot write file $htmlDest!";
        print FILE "<!DOCTYPE html>\n<HTML>\n<HEAD>\n<TITLE>\n".$title."\n</TITLE>\n</HEAD>\n<BODY>\n<TABLE bgcolor='#EEEEEE' border=none>";

        print FILE "<h2>$title</h2><br>";
        print FILE "Last run: $timeStamp<br><br>";
        
        foreach (@$htmlBody) {
            print FILE "$_"."\n";
        }

        print FILE "</TABLE>\n</BODY>\n</HTML>";
    close (FILE);

    return 1;
}


1;
