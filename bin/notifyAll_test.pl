#!/usr/bin/perl

use strict;

=head1 NAME

notifyAll_test.pl - A SAMP Test Client

=head1 SYNOPSIS

  % ./notifyAll_test.pl [-port 8003]

=head1 DESCRIPTION

This is a simple SAMP client which will register itself with a SAMP Hub and
call notifyAll( ) in the Hub periodlically. By default it will generate
coord.pointAt.sky messages.

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

print "Testbed SAMP NotifyAll Client v$VERSION\n\n";

# Handle command line options
my ($host, $port, $pid);

GetOptions( "port=s"  => \$port );

unless ( defined $port ) {
   $port = 8003;
}

unless ( defined $host ) {
   # localhost.localdoamin
   $host = inet_ntoa(scalar(gethostbyname(hostname())));
}

my %metadata;
$metadata{"samp.name"} = "notifyAll";
$metadata{"samp.description.text"} = "This is a SAMP test client that periodically calls notifyAll.";
$metadata{"samp.description.html"} = "<p>This is a SAMP test client that periodically calls notifyAll.</p>";
$metadata{$metadata{"samp.name"}.".version"} = $VERSION;
Astro::VO::SAMP::Client::metadata( %metadata );

# H U B   D I S C O V E R Y ----------------------------------------------------

my @childs;
while( 1 ) {

   Astro::VO::SAMP::Client::Util::hub_discovery( );

# X M L - R P C  D A E M O N -----------------------------------------------------

   print "Forking server...\n";
   $pid = Astro::VO::SAMP::Client::Util::fork_server( $host, $port );
   push @childs, $pid;

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

# H E A R T B E A T -----------------------------------------------------------

   print "Forking heartbeat...\n";
   if ($pid = fork) {
       print "Continuing... pid = $pid\n";
   } elsif ( defined $pid && $pid == 0 ) {
       print "Forking heartbeat process... pid = $pid\n";
       while( 1 ) {
          sleep(10);
          print "\nHeartbeat at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";

          my $status = 0;
          if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {
             print "Calling notifyAll( coord.pointAt.sky ) in Hub\n";
             my $rpc = new XMLRPC::Lite();
             my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
             $rpc->proxy( $url );

             my %message;
             $message{'samp.mtype'} = Astro::VO::SAMP::Data::string( "coord.pointAt.sky" );
             my %params = ( "ra" => "180.0", "dec" => "-45.0" );
             $message{'samp.params'} = Astro::VO::SAMP::Data::map( %params );
             print "Passing RA = $params{ra}, Dec = $params{dec} to Hub\n";

             my ( $return, $status );
             eval{ $return = $rpc->call( 'samp.hub.notifyAll',
                        Astro::VO::SAMP::Client::private_key( ), \%message ); };
             unless ( $@ || $return->fault() ) {
                $status = 1;
             }

          } else {
             print "Hub no longer running. Exiting...\n";
             exit(0);
          }

       }
   }
   push @childs, $pid;

# M A I N   L O O P -----------------------------------------------------------

   print "Main thread waiting for harvest at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   foreach ( @childs ) {
      waitpid($_, 0);
      print "Child process $_ has died\n";
   }
   undef @childs;
}

# C L E A N   U P -------------------------------------------------------------

END {

   # only unregister if we're the parent process
   if( defined $pid && $pid != 0 ) {
      print "Un-registering with Hub...\n";
      Astro::VO::SAMP::Client::Util::unregister();
      print "Parent process exiting...\n";
   } else {
      print "Child process exiting...\n";
   }
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
