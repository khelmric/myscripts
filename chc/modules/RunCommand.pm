###########################################
#                 MODULE                  #
#               RunCommand                #
#               23.07.2015                #
#                                         #
###########################################

package modules::RunCommand;

use strict;
use warnings;
use Net::Ping;
use Sys::Hostname;

require Exporter;

our $VERSION = '1.00';
our @ISA = qw(Exporter);
our @EXPORT = qw(runCommand);

sub runCommand ($$$) {
    my $host = shift;
    my $command = shift;
    my $type = shift;
    my $commandOut;

    my $hostCheck = hostname;

    if (( $host =~ /LOCALHOST/ ) || ( $host =~ /$hostCheck/i )) { 
        $commandOut = `$command`;
    } else {
        
        if (pingTest($host)) {
            $commandOut = `ssh root\@$host $command`;
        } else {
            $commandOut = "NOT REACHABLE";
        }
    } 
    return $commandOut;
}

sub pingTest($)
{
     my $phost = shift;
     my $p = new Net::Ping("tcp");
     $p->{port_num}=22;
     my $result = $p -> ping($phost,2);
     return $result;    
}

1;
