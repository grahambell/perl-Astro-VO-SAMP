#!/usr/bin/perl

use strict;

=head1 NAME

listener_client.pl - A SAMP Test Client

=head1 SYNOPSIS

  % ./listener_client.pl [-port 8002]

=head1 DESCRIPTION

This is a simple SAMP client which will register itself with a SAMP Hub and
listens for notify( ) messages from other SAMP clients via the Hub. By default
it will listen for coord.pointAt.sky messages, but other messages can be subsituted
using the -mtype command line arguement.

This application implements a version of the protocol defined by the Standard
Profile XML-RPC API as specified in the IVOA recommendation version 1.3.

=cut

our $VERSION = '2.00';

use Carp;
use Getopt::Long;
use Socket;
use Net::Domain qw(hostname hostdomain);

use Astro::VO::SAMP::Data;
use Astro::VO::SAMP::Client;
use Astro::VO::SAMP::Client::Util;

use sigtrap qw/ die normal-signals error-signals /;

$SIG{INT} = sub {
   print "Trapped SIGINT\n";
   exit;
};

$SIG{TERM} = sub {
   print "Trapped SIGTERM\n";
   exit;
};

# C O M MA N D   L I N E -------------------------------------------------------

print "Testbed SAMP Listener Client v$VERSION\n\n";

# Handle command line options
my ($host, $port, $mtype);

GetOptions( "port=s"  => \$port );

unless ( defined $port ) {
   $port = 8002;
}

unless ( defined $host ) {
   # localhost.localdoamin
   $host = inet_ntoa(scalar(gethostbyname(hostname())));
}

# Appliation specific metadata
my %metadata;
$metadata{"samp.name"} = "listener";
$metadata{"samp.description.text"} = "This is a SAMP test client that listens for messages.";
$metadata{"samp.description.html"} = "<p>This is a SAMP test client that listens for messages.</p>";
$metadata{$metadata{"samp.name"}.".version"} = $VERSION;
Astro::VO::SAMP::Client::metadata( %metadata );

# H U B   D I S C O V E R Y ----------------------------------------------------

my $pid;
while( 1 ) {

   Astro::VO::SAMP::Client::Util::hub_discovery( );

# X M L - R P C  D A E M O N -----------------------------------------------------

   print "Forking...\n";
   $pid = Astro::VO::SAMP::Client::Util::fork_server( $host, $port );

   print "Waiting for server to start...\n";
   sleep(5);

# R E G I S T E R   C A L L B A C K  A D D R E S S  W I T H  H U B -------------

   print "Sending XMLRPC Callback address to Hub...\n";
   my $address = Astro::VO::SAMP::Data::string( "http://$host:$port" );
   my $status = Astro::VO::SAMP::Client::Util::send_xmlrpc_callback( $address );
   if ( $status ) {
      print "Sucessfully registered callback address with Hub\n";
   } else {
      print "Problems registering callback address with Hub. Hub down?\n";
   }

# R E G I S T E R   M - T Y P E S  W I T H  H U B -----------------------------

   print "Sending list of MTypes to Hub...\n";
   my @mtypes;
   push @mtypes, "coord.pointAt.sky";
   push @mtypes, "app.event.starting";
   push @mtypes, "app.event.stopping";

   my $data = Astro::VO::SAMP::Data::map( map {$_ => {}} @mtypes );
   my $status = Astro::VO::SAMP::Client::Util::send_mtypes( $data );
   if ( $status ) {
      print "Sucessfully registered MTypes with Hub\n";
   } else {
      print "Problems registering MTypes with Hub. Hub down?\n";
   }

   print "Done registering with the hub, waiting to handle...\n";

# M A I N   L O O P -----------------------------------------------------------

   print "Main thread waiting for harvest at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   waitpid($pid, 0);
}

# C L E A N   U P -------------------------------------------------------------

END {
   if( defined $pid && $pid != 0 ) {
      print "Un-registering with Hub...";
      Astro::VO::SAMP::Client::Util::unregister();
   }
   print "Done.\n";
   exit;
}


=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

# S A M P : : C L I E N T ------------------------------------------------------

package samp::client;
use base ( "Astro::VO::SAMP::Client" );

#1;
