#!/usr/bin/perl

###################
# RPMs to install:
# 
# perl-XML-Simple
# perl-HTTP-Message
# perl-LWP-Protocol-https
# perl-Term-UI.noarch

use strict;
use warnings;
use Term::ReadKey;
use Term::UI;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

my $address = "https://something.example.com/api"; # put your API URL here
my %vdcList;
my %selected_vdcList;
my %vappList;
my %selected_vappList;

my $vorg = "vorg-example1"; # put the default vOrg here
my $vorgs = "vorg-example1 vorg-example2 vorg-example3"; # put your vOrgs here
my $username;
my $pass;
my $csvout;
my $sessionID;
my $vOrgID;

my $CurrentHASH = "";
my $CurrentARRAY = "";
my $CurrentSCALAR = "";

my $ask_end = "back quit";
my $ask_end_all = "all back quit";
my $answer = "";

my $browser;
my $req;
my $page;

my $term = Term::ReadLine->new('brand');


###################
# clear screen

sub clear_screen {
  system('clear');
}

###################
# halt until Enter

sub halt {
  print "\nPress <Enter> to continue...";
  <>;
}

###################
# custom or y/n questrions

sub ask($$$$) {
  my $type = shift;
  my $prompt = shift;
  my $choices = shift;
  my @choices = split / /,$choices;
  my $default = shift;  
  my $reply;

  if ( $type =~ /yesno/ ) {
    $reply = $term->ask_yn(
                        prompt => "$prompt",
                        default => "$default",
                );    
  } else {
    $reply = $term->get_reply(
                    prompt => "$prompt",
                    choices => [@choices],
                    default => "$default",
    );
  }
  return $reply
}

###################
# screen init

sub screen_init($) {
  my $desc = shift;
  clear_screen;
  print "--------------------------------------------------\n";
  print "         vCloud API script - FW check             \n";
  print "--------------------------------------------------\n\n";
  print "--> $desc\n\n";
}

###################
# select vorg

sub select_vorg {
  screen_init("select VOrg");
  $vorg = ask("custom", "Select VOrg:", "$vorgs quit", $vorg);

  if ( $vorg =~ /quit/ ) {
    exit 1;
  }

  screen_init("Login to $vorg");
  print "Username: ";
    chomp($username = <STDIN>);
    $username = $username.'@'.$vorg;
  print "Password: ";
    ReadMode('noecho');
    chomp($pass = <STDIN>);
    ReadMode(0);  
  print "\n";
  $csvout = ask("yesno", "Do you need a csv-formatted output?", "none", "n");
  print "\n";
}

###################
# array to STDOUT

sub write_to_output(@) {
  my @output = @{$_[0]};
  if ( $csvout == 0 ) {
    foreach (@output) {
      if ( \$_ == \$output[-1] ) {
        print " --> $_\n";
      } else {
        print "[$_] ";
      }
    }
  } else {
    foreach (@output) {
      print "$_".";";
    }
    print "\n";
  }
}

###################
# authentication

sub vorg_authentication {
  $vOrgID = "";
  $browser = LWP::UserAgent->new;
  $browser->cookie_jar( {} );
  $browser->agent("Mozilla/4.76 [en] (Windows NT 5.0; U)");
  $req =  HTTP::Request->new( POST => "$address/sessions");
  $req->authorization_basic( "$username", "$pass" );
  $req->header('Accept' => 'application/*+xml;version=5.6');
  $page = $browser->request( $req );
  ($sessionID) = $page->headers()->as_string() =~ /Authorization\:\s([^\n]*?)\n/gis;
  ($vOrgID) = $page->content() =~ /api\/org\/([^\n]*?)\"\sname/gis;
  my $http_status = $page->code( );

  return "$http_status";
}

###################
# http request

sub http_req($) {
  my $url = shift;
  my $req =  HTTP::Request->new( GET => "$url");
  $req->authorization_basic( "$username", "$pass" );
  $req->header('Accept' => 'application/*+xml;version=5.6');
  $req->header('x-vcloud-authorization' => $sessionID );
  return $browser->request( $req );
}


###################
# get vdcs

sub get_vdc_list {
  $page = http_req("$address/org/$vOrgID");
  my @vdcs_raw = $page->as_string =~ /api\/vdc\/([^\n]*?)\stype/gis;
  foreach my $line (@vdcs_raw) {
    my ($vdc_id, $none1, $vdc_name, $none2) = split /"/, $line;
    $vdcList{$vdc_name} = $vdc_id;
  }
}

###################
# select vdc

sub select_vdc {
  screen_init("select VDC ($vorg -> )");
  my $vdc_list = "";
  foreach my $vdcName (sort keys %vdcList) {
    $vdc_list = "$vdc_list $vdcName";
  }
  substr($vdc_list, 0, 1) = "";
  my $selectedVDC = ask("custom", "Select VDC:", "$vdc_list $ask_end_all", "all");
  
  if ( $selectedVDC =~ /quit/ ) {
    exit 1;
  } elsif ($selectedVDC =~ /back/) {
    return "back_to_vorg";
  }
 
  %selected_vdcList = ();
  if ( $selectedVDC !~ /all/ ) {
    $selected_vdcList{$selectedVDC} = $vdcList{$selectedVDC};
  } else {
    %selected_vdcList = %vdcList;
  }
  return "ok";
}

###################
# select vapp

sub select_vapp($) {
  my $currentVDC = shift;
  my $selectedVApp;
  if (keys %selected_vdcList == 1) {
    my $vapp_list = "";
    screen_init("select VApp ($vorg -> $currentVDC -> )");
    foreach my $vappName (sort keys %vappList) {
      $vapp_list = "$vapp_list $vappName";
    }
    substr($vapp_list, 0, 1) = "";
    $selectedVApp = ask("custom", "Select VApp on $currentVDC:", "$vapp_list $ask_end_all", "all");

    if ( $selectedVApp =~ /quit/ ) {
      exit 1;
    } elsif ($selectedVApp =~ /back/) {
      return "back";
    }
  } else {
    $selectedVApp = "all";
  }

  %selected_vappList = ();
  if ( $selectedVApp !~ /all/ ) {
    $selected_vappList{$selectedVApp} = $vappList{$selectedVApp};
  } else {
    %selected_vappList = %vappList;
  }
  return "ok";
}

###################
# get vapps

sub get_vapp_list {
  foreach my $vdcName (sort keys %selected_vdcList) {
    %vappList = ();
    $page = http_req("$address/vdc/$vdcList{$vdcName}");

    my @vapps_raw =  $page->as_string =~ /api\/vApp\/([^\n]*?)\stype/gis;

    foreach my $line (@vapps_raw) {
      my ($vapp_id, $none1, $vapp_name, $none2) = split /"/, $line;
      $vappList{$vapp_name} = $vapp_id;
    }
    $answer = select_vapp($vdcName);
    if ($answer =~ /back/) {
      return "back_to_vdc";
    }
    
    foreach my $vappName (sort keys %selected_vappList) {
      check_vapp_settings($vdcName, $vappName);
    }
  }
  halt;
  return "ok";
}

###################
# get xml-content

sub xmlParser($) {
  my $Options = shift;
#  print (ref $Options)." -- ";
  if ( (ref $Options) =~ /ARRAY/ ) {
#    print "  it is an array\n";
    getArray($Options);
    $CurrentARRAY = $Options;
  } elsif ( (ref $Options) =~ /HASH/ ) {
#    print "  it is a hash\n";
    $CurrentHASH = $Options;
    getHash($Options);
  } elsif ( (ref $Options) =~ /SCALAR/ ) {
    print "  $Options\n";

  } elsif ( (ref $CurrentHASH->{$Options}) =~ /ARRAY/ ) {
    print $CurrentHASH->{$Options}[0]."\n";
  } else {
    print "Value: ";
    print $CurrentHASH->{$Options};
    print "\n";
  }
 #else {
#    if ( (ref($CurrentHASH->{$Options}[0])) !~ /HASH/ ) {
#      print "$Options  --  $CurrentHASH->{$Options}[0] \n";
#      my $CurrentValue = $CurrentHASH->{$Options}[0];
#      my $CurrentValue = $Options;
#      print "   $CurrentValue \n";
#    }
#  }
}

sub getArray($) {
  my @Arr = shift;

  foreach my $Opt (@Arr) {
    print " $Opt ";
    xmlParser($Opt);
  }
}

sub getHash($) {
  my $Hsh = shift;

  foreach my $Opt (keys $Hsh) {
    print " $Opt ";
#    xmlParser($Opt);
#    if ( (ref $Hsh->{$Opt}) =~ /HASH/ ) {
#    if ( (ref $Hsh->{$Opt}) =~ /HASH/ ) {
#      print "Value: ";
#      print $Hsh->{$Opt};
#      print "\n";
#    } elsif ( (ref $Hsh->{$Opt}) =~ /ARRAY/ ) {
#      print $Hsh->{$Opt}[0]."\n";
#    } else {
      xmlParser($Opt);
#    }

  }

}

###################
# check vapp settings

sub check_vapp_settings($$) {
  my $vdcName = shift;
  my $vappName = shift;
  my $netwName;
  $page = http_req("$address/vApp/$vappList{$vappName}");

  my $content_page_raw = $page->content();
  my $content_page_xml = XML::Simple->new(KeepRoot => 1, KeyAttr => 1, ForceArray => 1);
  my $content_page_ref = $content_page_xml->XMLin($content_page_raw);

print "$vappName\n";

  foreach my $Options ( @{$content_page_ref->{VApp}[0]{NetworkConfigSection}[0]{NetworkConfig}} ) {
#    my $nName = $Option->{networkName};

#print "  $nName \n";

#foreach my $Features ($NetworkName->{Configuration}[0]) {
#  foreach my $FOption (keys $Features) {
#    print "    $FOption\n";
#my @FOptions = $Features->{$FOption};
#foreach my $FOptionValue (@FOptions) {

xmlParser($Options);

#if ( (ref $Options) =~ /ARRAY/ ) {
#  print "  it is an array\n";
#  getArray($Options);
#} elsif ( (ref $Options) =~ /HASH/ ) {
#  print "  it is a hash\n";
#  getHash($Options);
#} elsif ( (ref $Options) =~ /SCARLAR/ ) {
#  print "  it is a scalar\n";

#}



#print "\n";
#}
#print "      ".$Features->{$FOption}."\n";
#  }
#}
#print "\n";

#    my $nState = $NetworkName->{Configuration}[0]{Features}[0]{FirewallService}[0]{IsEnabled}[0];
#    if (!defined $nState) {
#      $nState="";
#    } 
#    my @to_output = ($vdcName, $vappName, $nName, $nState);
#      write_to_output(\@to_output);
  }
}  


#########################################################################

###################
# Main

until (0) {
  $answer = "";
  select_vorg();
  until ($answer =~ /200|back_to_vorg/) {
    $answer = vorg_authentication();
    if ($answer !~ /200/) {
      screen_init("VOrg login error: $answer");
      halt;
      $answer = "back_to_vorg";
    }
  }

  while ($answer !~ /back_to_vorg/) {  
    get_vdc_list();
    $answer = select_vdc();
    if ($answer !~ /back_to_vorg/) {
      until ($answer =~ /back_to_vdc/) {
        $answer = get_vapp_list();
      }
    }
  }
}

