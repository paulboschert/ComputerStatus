#!/usr/bin/perl

###################################################################################
## Paul Boschert <paul@boschert.net>                                             ##
## date: 05/05/2007                                                              ##
## last update: 1:05 PM 6/6/2007                                                 ##
##                                                                               ##
##                                                                               ##
## This script generates the status of the computers specified into an XML file  ##
###################################################################################

use CGI ":standard";
use Getopt::Long;
use Net::Ping;
use Net::Wake;
use Switch;
use strict;
use Time::HiRes;
use Win32;
use Win32::NetAdmin;
use Win32::TieRegistry (Delimiter=>"/");

my @ctb56 = qw //;

my @ctb60 = qw /alvin barota bellerophon cygnus defiant elsie farstar icetrireme jaguar jupiter2 lenonov lensman lexx longshot mfalcon ncc1701 nebachadnezzar newhansea nimbus orion3 salyut serendipity serenity sisu skydiver sputnik unimara valleyforge wyvern yamato/;

my @ct152 = qw /calypso condor discovery explorer gokstad lionfish mariner nautile nautilus orion pathfinder pelican seaview seawolf solospirit soyuz surveyor telstar viking voyager/;

my @ct156 = qw /adriatic aegean andaman arabian arafura aral azov bali baltic banda beaufort bismark bohai bohol bothian caspian celebs celtic coral crete davis flores harima iyo java kara kodos koro laptev marmara mindanao molucca north ross sagami savu serak seto sibuyan tasman timor wandel/;

my @ct156a = qw /chronos quicky/;

my @ct156d = qw /dandelion neo/;

my @sh105 = qw /ahab aida alice caliban emma frankenstein gatsby gulliver hamlet hester huck ivan mcmurphy moll okonkwo piggy sophie sula switters tantalus uriah zorba/;

my @sh311 = qw /lodgepole/;

my @lib = qw /amundsen andree barents beckley bering byrd charcot cook delong franklin frobisher henson jenness lyon mackenzie magruder mawson meehan nansen peary scott shackleton stephenson watterston weddell/;

my @ctlm102 = qw /caesar/;

#my @ctlm114 = qw /moo oink quack tonic/;
my @ctlm114 = qw /moo/;

my @ctlm129 = qw /aiken anonymous arnold auden badger basho baudelaire blake bronte browing burnes byron carroll chaucer clemmens coleridge cowper cummings dickinson dodgson donne eliot emerson field goldsmith gorey graves gray hardy henley herrick hopkins keats kipling longfellow marlowe marvell mccrae milton nash owen parker poe pound roethke rossetti sandburg shakespeare shelley stevens swinburne tennyson waller whitman wordsworth wyatt yeats/;

my @ctlm223 = qw /anderson appleton barkla bohr bragg bridgman broglie chadwick dalen davisson dirac franck guillaume heisenberg hertz hess laue lawrence lorentz marconi millikan onnes ozzy perrin rabi rayleigh richardson rontgen schrodinger siegbahn stark stern waals wien wilson/;

my @ctlm229 = qw /atonal cadence canon chorale chord chromatic clef counterpoint diatonic dissonance etude fugue fundamental half-step harmony improvisation interval inversion melody meter minor note octave pitch rhythm rondo round scale tempo tone/;

my @ctlm231 = qw /abstract acrylic brush canvas charcoal collage conte crayon decoupage drawing easel fresco gouache hue line mosaic mural paint pastel pencil pigment silkscreen sketch stencil tempera tint value wash watercolor wax woodcut/;

my @misc = qw //;

my $ctb56 = 0;
my $ctb60 = 0;
my $ct152 = 0;
my $ct156 = 0;
my $ct156a = 0;
my $ct156d = 0;
my $lib = 0;
my $sh105 = 0;
my $sh311 = 0;
my $ctlm102 = 0;
my $ctlm114 = 0;
my $ctlm223 = 0;
my $ctlm229 = 0;
my $ctlm231 = 0;
my $misc = 0;

# registry key, last user logged in, and the current user logged in, the status of the computer, the processor speed, and the list of MAC addresses
my ($key, $lastUser, $currentUser, $status, $procSpeed, $macs);

# return code, duration of packet, ip, and ping status for the computer in question
my ($retCode, $duration, $ip, $pingStatus);

# holds computers to be checked
my @computers;

my ($shortTime, $longTime);

my ($refresh, $wol, $shutdown, $restart);

my $changeFile = "computers.xml";
my $outputFile = "computers.xml";
my $actionFile = "modifyComputers.txt";

open (TESTFILE, ">output.txt") || die "ERROR: Unable to read output.txt\n";
print TESTFILE "Login Name: " . Win32::LoginName() . "\n\n";

my $useragent = $ENV{'HTTP_USER_AGENT'};
if ($useragent) {
	print TESTFILE "WEB!\n";

	open (ACTIONFILE, ">$actionFile") || die "ERROR: Unable to read $actionFile\n";

	my $match;
#	if(param("refresh")) { $refresh = 1; $match = "refresh"; }
#	elsif(param("wol")) { $wol = 1; $match = "wol"; }
#	elsif(param("shutdown")) { $shutdown = 1; $match = "shutdown"; }
#	elsif(param("restart")) { $restart = 1; $match = "restart"; }

	if(param("refresh"))     { $match = "refresh"; }
	elsif(param("wol"))      { $match = "wol"; }
	elsif(param("shutdown")) { $match = "shutdown"; }
	elsif(param("restart"))  { $match = "restart"; }

	print ACTIONFILE "$match\n";

	my $arg;
	my $CGI = new CGI;
	my @cgiParams = $CGI->param();
	foreach my $param (@cgiParams) {
		chomp($param);
		
		if($param =~ m/$match/) {
			(undef, $arg) = split(":", $param);

			if($arg) {
				print ACTIONFILE "$arg\n";
			}
		}
	}

	close TESTFILE;
	
	`runasspc.exe /cryptfile:"crypt.spc" /quiet`;
	
	$CGI->redirect(-URL => "http://grebe.mines.edu/computerStatus/computers.xml");
}

else {
	print TESTFILE "COMMAND LINE!\n";
	close TESTFILE;

	GetOptions("e"=>\$refresh,
	           "w"=>\$wol,
	           "s"=>\$shutdown,
	           "r"=>\$restart);

	foreach my $arg (@ARGV) {
	    switch ($arg) {
	        case "ctb56"    { $ctb56   = 1; }
	        case "ctb60"    { $ctb60   = 1; }
	        case "ct152"    { $ct152   = 1; }
	        case "ct156"    { $ct156   = 1; }
	        case "ct156a"   { $ct156a  = 1; }
	        case "ct156d"   { $ct156d  = 1; }
	        case "lib"      { $lib     = 1; }
	        case "library"  { $lib     = 1; }
	        case "sh105"    { $sh105   = 1; }
	        case "writing"  { $sh105   = 1; }
	        case "sh311"    { $sh311   = 1; }
	        case "ctlm102"  { $ctlm102 = 1; }
	        case "ctlm114"  { $ctlm114 = 1; }
	        case "ctlm223"  { $ctlm223 = 1; }
	        case "ctlm229"  { $ctlm229 = 1; }
	        case "ctlm231"  { $ctlm231 = 1; }
	        case "all" {
	        	$ctb56   = 0;
	        	$ctb60   = 1;
	        	$ct152   = 1;
	        	$ct156   = 1;
	        	$ct156a  = 1;
	        	$ct156d  = 1;
	        	$lib     = 1;
	        	$sh105   = 1;
	        	$sh311   = 1;
	        	$ctlm102 = 1;
	        	$ctlm114 = 1;
	        	$ctlm223 = 1;
	        	$ctlm229 = 1;
	        	$ctlm231 = 1;
	        }
	
	        else {
	        	push(@misc, $arg);
	        	$misc = 1;
	        }
	    }
	}

	$pingStatus = Net::Ping->new("icmp", 1);
	$pingStatus->hires();
	
	getTime();
}

if($refresh) {
	open (CHANGEFILE, "$changeFile") || die "ERROR: Unable to read $changeFile\n";
	getMac();
	setComputers();
	getComputerStatus(undef, 1);
}

elsif($wol) {
	getMac();
	setComputers();
	wakeComputers();
}

elsif($shutdown) {
	setComputers();
	shutdownComputers();
}

elsif($restart) {
	setComputers();
	restartComputers();
}

else {
	getMac();

	open (OUTFILE, ">$outputFile") || die "ERROR: Unable to open ./$outputFile for writing\n";

	print OUTFILE '<?xml version="1.0" encoding="UTF-8"?>' . "\n" .
				  '<?xml-stylesheet type="text/xsl" href="computers.xsl"?>' . "\n\n" .
				  "<!-- Paul Boschert <paul [at] boschert [dot] net> -->\n" .
				  "<!-- Generated XML from computers.pl -->\n\n" .
				  "<lab_status>\n" .
				  "  <long_time>$longTime</long_time>\n";
				  "  <short_time>$shortTime</short_time>\n";

	if($ctb56) {
		@computers = @ctb56;
		getComputerStatus("CTLM B56 - Classroom C");
	}

	if($ctb60) {
		@computers = @ctb60;
		getComputerStatus("CTLM B60 - Classroom D");
	}

	if($ct152) {
		@computers = @ct152;
		getComputerStatus("CTLM 152 - Classroom A");
	}

	if($ct156) {
		@computers = @ct156;
		getComputerStatus("CTLM 156 - Commons");
	}

	if($ct156a) {
		@computers = @ct156a;
		getComputerStatus("CTLM 156A - Front Desk");
	}

	if($ct156d) {
		@computers = @ct156d;
		getComputerStatus("CTLM 156D - Consultants");
	}

	if($lib) {
		@computers = @lib;
		getComputerStatus("Library");
	}

	if($sh105) {
		@computers = @sh105;
		getComputerStatus("Stratton Hall 105 - Writing Center");
	}

	if($sh311) {
		@computers = @sh311;
		getComputerStatus("Stratton Hall 311");
	}

	if($ctlm102) {
		@computers = @ctlm102;
		getComputerStatus("CTLM 102");
	}

	if($ctlm114) {
		@computers = @ctlm114;
		getComputerStatus("CTLM 114");
	}

	if($ctlm223) {
		@computers = @ctlm223;
		getComputerStatus("CTLM 223");
	}

	if($ctlm229) {
		@computers = @ctlm229;
		getComputerStatus("CTLM 229");
	}

	if($ctlm231) {
		@computers = @ctlm231;
		getComputerStatus("CTLM 231");
	}

	if($misc) {
		@computers = @misc;
		getComputerStatus("Miscellaneous");
	}

	print OUTFILE "</lab_status>\n";

	close OUTFILE;
}

## USAGE: getComputerStatus($description, $doRefresh)
## This subroutine generates the XML
sub getComputerStatus {

	my $doRefresh = $_[1];

	if($doRefresh) {
		my $found = 0;
	    my @lines = <CHANGEFILE>;
	    close CHANGEFILE;
	
		open (OUTFILE, ">$outputFile") || die "ERROR: Unable to open ./outputFile for writing\n";
	
		foreach my $line (@lines) {
			$found = 0;
			foreach my $computer (@computers) {
				if($line =~ m/$computer/) {
					$found = 1;
	
			        ($currentUser, $lastUser, $status, $procSpeed) = ("&#160;", "&#160;", "active", "&#160;");
			
			        $retCode = 0;
			        ($retCode, $duration, $ip) = $pingStatus->ping($computer);
			
			        if(length $computer < 5) { print "$computer : \t\t $retCode\n"; }
			        elsif(length $computer > 12) { print "$computer : $retCode\n"; }
			        else { print "$computer : \t $retCode\n"; } 
			
			        # active
			        if ($retCode == 1) {
			            $currentUser = getCurrentUser($ip);
			            $lastUser = getLastUser($ip);
			            $procSpeed = getProcSpeed($ip);
			        }
			
			        # unreachable
			        else {
			            $status = "unreachable";
			        }
			
			        # login error (as in unable to login with current privileges)
			        if($lastUser =~ m/!login error/) {
			            $status = "login error";
			            $lastUser = "&#160;";
			        }
					
					if(!$currentUser) { $currentUser = "&#160;"; }
					if(!$lastUser) { $lastUser = "&#160;"; }
					if(!$procSpeed) { $procSpeed = "&#160;"; }
					if(!$ip) { $ip = "&#160;"; }
			
	                print OUTFILE "      <hostname>$computer</hostname>\n" .
	                			  "      <status>$status</status>\n" .
	                			  "      <ip>$ip</ip>\n" .
	                			  "      <mac>$macs->{$computer}</mac>\n" .
	                              "      <last_user>$lastUser</last_user>\n" .
	                              "      <current_user>$currentUser</current_user>\n" .
	                              "      <date_updated>$shortTime</date_updated>\n";
	            }
			}
	
			if(!$found) { print OUTFILE $line; }
		}
	}

	else {
		print OUTFILE "  <lab>\n";
	    print OUTFILE "    <description>$_[0]</description>\n";
	
	    foreach my $computer (@computers) {
	        ($currentUser, $lastUser, $status, $procSpeed) = ("&#160;", "&#160;", "active", "&#160;");
	
	        $retCode = 0;
	        ($retCode, $duration, $ip) = $pingStatus->ping($computer);
	
	        if(length $computer < 5) { print "$computer : \t\t $retCode\n"; }
	        elsif(length $computer > 12) { print "$computer : $retCode\n"; }
	        else { print "$computer : \t $retCode\n"; } 
	
	        # active
	        if ($retCode == 1) {
	            $currentUser = getCurrentUser($ip);
	            $lastUser = getLastUser($ip);
	            $procSpeed = getProcSpeed($ip);
	        }
	
	        # unreachable
	        else {
	            $status = "unreachable";
	        }
	
	        # login error (as in unable to login with current privileges)
	        if($lastUser =~ m/!login error/) {
	            $status = "login error";
	            $lastUser = "&#160;";
	        }
			
			if(!$currentUser) { $currentUser = "&#160;"; }
			if(!$lastUser) { $lastUser = "&#160;"; }
			if(!$procSpeed) { $procSpeed = "&#160;"; }
			if(!$ip) { $ip = "&#160;"; }
	
	        print OUTFILE "    <computer>\n" .
	        			  "      <hostname>$computer</hostname>\n" .
	        			  "      <status>$status</status>\n" .
	        			  "      <ip>$ip</ip>\n" .
	        			  "      <mac>$macs->{$computer}</mac>\n" .
	                      "      <last_user>$lastUser</last_user>\n" .
	                      "      <current_user>$currentUser</current_user>\n" .
	                      "    </computer>\n";
	    }
	
	    print OUTFILE "  </lab>\n";	
	}
}

sub wakeComputers {
	foreach my $computer (@computers) {
		Net::Wake::by_udp(undef, $macs->{$computer});
	}
}

sub shutdownComputers {
	foreach my $computer (@computers) {
		Win32::InitiateSystemShutdown($computer, "Broadcast message from administrator\@grebe ($longTime):\n The system is going down NOW!", 0, 1, 0);
	}
}

sub restartComputers {
	foreach my $computer (@computers) {
		Win32::InitiateSystemShutdown($computer, "Broadcast message from administrator\@grebe ($longTime):\n The system is going down for restart NOW!", 0, 1, 1);
	}
}

## USAGE: getProcSpeed($computer)
## RETURN: processor speed of $computer
sub getProcSpeed {
    my $computer = $_[0];

    my $key = $Registry->{"//$computer/LMachine/HARDWARE/DESCRIPTION/System/CentralProcessor/0/"};

	if($key) {
		# necessary if a computer is active yet I can't read the registry
	    my $procSpeed = "";
	    $procSpeed = $key->{"ProcessorNameString"};
	    if($procSpeed) {
		    $procSpeed =~ s/\(R\)//g;
		    $procSpeed =~ s/\(TM\)/ /g;
		    $procSpeed =~ s/\@//g;
		    $procSpeed =~ s/CPU //;
		    $procSpeed =~ s/ {14}//;
		}
	
	    undef $key;
	}

    $procSpeed;
}

## USAGE: getCurrentUser($computer)
## RETURN: current user logged into $computer
sub getCurrentUser {
    my $computer = $_[0];

	my $key = $Registry->{"//$computer/Users/"};

	if($key) {
		foreach my $subKey ($key->SubKeyNames) {
			if($subKey =~ m/^S-1-5-21.*\d$/) {
				$currentUser = $Registry->{"//$computer/Users/$subKey/Software/Microsoft/Windows/CurrentVersion/Explorer/Logon User Name"};
				if($currentUser =~ m/administrator/i) { $currentUser = "&#160;" }
				else { last; }
			}
		}
	    undef $key;
	}

    $currentUser;
}

## USAGE: getLastUser($computer)
## RETURN: last user logged into $computer
sub getLastUser {
    my $computer = $_[0];

    my $key = $Registry->{"//$computer/LMachine/SOFTWARE/INTEL/LANDesk/VirusProtect6/CurrentVersion/ProductControl/"};    
    my $lastUser = $key->{"LastLoggedUser"};
    undef $key;

    if(!$lastUser) { $lastUser = "!login error"; }

    $lastUser;
}

## USAGE: getTime()
## Gets the current time and sets the global variables $shortTime and $longTime
sub getTime {
	my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime();
	$year += 1900;

	if($min < 10) { $min = "0" . $min; }
	if($sec < 10) { $sec = "0" . $sec; }

	$shortTime = "$hour:$min:$sec $mday/$month/$year";

	if($hour == 12) { $sec = $sec . "PM"; }
	if($hour > 12) { $hour -= 12; $sec = $sec . "PM"; }
	else {$sec = $sec . "AM"; }

	switch($wday) {
		case 0 {$wday = "Sunday"};
		case 1 {$wday = "Monday"};
		case 2 {$wday = "Tuesday"};
		case 3 {$wday = "Wednesday"};
		case 4 {$wday = "Thursday"};
		case 5 {$wday = "Friday"};
		case 6 {$wday = "Saturday"};
	}
	
	switch($month) {
		case 0  {$month = "January"};
		case 1  {$month = "February"};
		case 2  {$month = "March"};
		case 3  {$month = "April"};
		case 4  {$month = "May"};
		case 5  {$month = "June"};
		case 6  {$month = "July"};
		case 7  {$month = "August"};
		case 8  {$month = "September"};
		case 9  {$month = "October"};
		case 10 {$month = "November"};
		case 11 {$month = "December"};
	}

	$longTime = "$hour:$min:$sec $wday, $month, $mday $year";
}

## USAGE: getMac()
## Gets the list of MAC addresses from a file (static because if a computer is down WOL will only work with a valid MAC address)
sub getMac {
	# contains the MAC addresses of computers
	my $macFile = "macaddresses.txt";

	open (MAC, "$macFile") || die "ERROR: Unable to read $macFile\n";

	my ($computer, $mac);
	foreach (<MAC>) {
	    ($computer, $mac) = split(' ', $_);
	    $macs->{$computer} = $mac;
	}

	close MAC;
}

## USAGE: setComputers()
## Sets the global array @computers according to the list of computers specified
sub setComputers {
	if($ctb56)   { push(@computers, @ctb56);   }
	if($ctb60)   { push(@computers, @ctb60);   }
	if($ct152)   { push(@computers, @ct152);   }
	if($ct156)   { push(@computers, @ct156);   }
	if($ct156a)  { push(@computers, @ct156a);  }
	if($ct156d)  { push(@computers, @ct156d);  }
	if($lib)     { push(@computers, @lib);     }
	if($sh105)   { push(@computers, @sh105);   }
	if($sh311)   { push(@computers, @sh311);   }
	if($ctlm102) { push(@computers, @ctlm102); }
	if($ctlm114) { push(@computers, @ctlm114); }
	if($ctlm223) { push(@computers, @ctlm223); }
	if($ctlm229) { push(@computers, @ctlm229); }
	if($ctlm231) { push(@computers, @ctlm231); }
	if($misc)    { push(@computers, @misc);    }
}