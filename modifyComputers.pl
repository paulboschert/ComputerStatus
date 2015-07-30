#!/usr/bin/perl

###################################################################################
## Paul Boschert <paul@boschert.net>                                             ##
## date: 06/07/2007                                                              ##
##                                                                               ##
##                                                                               ##
## Instead of SUEXEC with Apache on Linux, it's Apache + Windows + this!         ##
###################################################################################

use strict;

my $perlLocation = "c:/usr/bin/perl.exe";
my $perlScript = "computers.pl";
my $modifyFile = "modifyComputers.txt";


open (MODIFYFILE, "$modifyFile") || die "ERROR: Unable to open $modifyFile for reading\n";
my @computers = <MODIFYFILE>;
close MODIFYFILE;

open (WRITEFILE, ">$modifyFile") || die "ERROR: Unable to open $modifyFile for writing\n";
print WRITEFILE "\n";
close WRITEFILE;

my $action = shift @computers;
print "action: $action\n";

my $param;
if($action =~ m/refresh/)     { print "refresh!\n"; $param = "-e";  }
elsif($action =~ m/wol/)      { print "WOL!\n"; $param = "-w";      }
elsif($action =~ m/shutdown/) { print "shutdown!\n"; $param = "-s"; }
elsif($action =~ m/restart/)  { print "restart!\n"; $param = "-r";  }

exec("$perlLocation $perlScript $param @computers");

