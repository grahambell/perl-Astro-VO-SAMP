#!/usr/bin/perl

use strict;

=head1 NAME

samp_hub.pl - A SAMP Hub

=head1 SYNOPSIS

  % ./samp_hub.pl [-port 8001]

=head1 DESCRIPTION

This is a prototype SAMP Hub implementing the IVOA's Simple Application
Messaging Protocol Version 1.00 (IVOA Working Draft 2008-04-30). SAMP is a
direct decendent of the PLASTIC protocol. Broadly speaking, SAMP is an abstract
framework for loosely coupled asynchronous RPC-like and/or event-based
communication with extensible message semantics using structured but
weakly-typed data and based on a central service providing multi-directional
publish/subscribe message brokering.

This application implements a version of the protocol defined by the Standard
Profile XML-RPC API as specified in the IVOA Working Draft document.

=cut

use vars qw/ $VERSION $host $port /;
'$Revision: 1.22 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

use Carp;
use Getopt::Long;
use Socket;
use Net::Domain qw(hostname hostdomain);

use XMLRPC::Lite;

use Astro::VO::SAMP::Transport::HTTP::Daemon;
use Astro::VO::SAMP::Discovery;
use Astro::VO::SAMP::Hub;
use Astro::VO::SAMP::Hub::Util;

use sigtrap qw/ die normal-signals error-signals /;

$SIG{INT} = sub {
   print "Trapped SIGINT\n";
   print "Notify all clients...\n";
   Astro::VO::SAMP::Hub::Util::notify_hub_shutting_down( );
   print "Deleting lock file...\n";
   Astro::VO::SAMP::Hub::Util::delete_lock_file( );
   print "Deleting state files...\n";
   Astro::VO::SAMP::Hub::MetaData::delete_files( );
   exit;
};

$SIG{TERM} = sub {
   print "Trapped SIGTERM\n";
   print "Notify all clients...\n";
   Astro::VO::SAMP::Hub::Util::notify_hub_shutting_down( );
   print "Deleting lock file...\n";
   Astro::VO::SAMP::Hub::Util::delete_lock_file( );
   print "Deleting state files...\n";
   Astro::VO::SAMP::Hub::MetaData::delete_files( );
   exit;
};

# C O M MA N D   L I N E -------------------------------------------------------

print "Prototype SAMP Hub v$VERSION\n\n";

# Handle command line options
GetOptions( "port=s" => \$port );
unless ( defined $port ) {
   $port = 8001;
}

unless ( defined $host ) {
   # localhost.localdoamin
   $host = inet_ntoa(scalar(gethostbyname(hostname())));
}

# H U B   D I S C O V E R Y ----------------------------------------------------

print "Checking for running Hub process...\n";

# We check for an existing SAMP lockfile, if file exists try to connect to
# the running hub. If the hub is running we should shut down, if it's died
# then we should delete the lock file and start up our own hub process.

# Is the Hub running?
my $hub_status = Astro::VO::SAMP::Discovery::hub_running( );
if ( $hub_status ) {
  print "Found a existing Hub process\n";
  print "Exiting...\n";
  exit;
}

print "No running Hub found\n";

# No hub running, might have an existing lock file?
my $file_status = Astro::VO::SAMP::Discovery::lock_file_present( );
if ( $file_status ) {
   print "Found and orphan lock file\n";
   eval { Astro::VO::SAMP::Hub::Util::delete_lock_file( ); };
   if ( $@ ) {
      croak( "$@" );
   } else {
      print "Unlinked orphan lock file\n";
   }
   print "Cleaning up previous Hub's metadata files...\n";
   Astro::VO::SAMP::Hub::MetaData::delete_files( );
}

# A P P L I C A T I O N   K E Y S ---------------------------------------------

print "Generating public and private keys for Hub\n";

# Generate application keys for the Hub itself.
my ( $hub_public_id, $hub_private_id) = Astro::VO::SAMP::Hub::Util::generate_app_keys( );
print "public_id = $hub_public_id\n";
print "private_id = $hub_private_id\n";

# store them in the Astro::VO::SAMP::Hub class for later retrieveal from forked threads
Astro::VO::SAMP::Hub::public_key( $hub_public_id );
Astro::VO::SAMP::Hub::private_key( $hub_private_id );

# X M L - R P C   S E R V E R -------------------------------------------------

# We should start an XML-RPC server, after sucessfully doing so we need to
# create a SAMP lock file to point to our new XML-RPC end point.

print "Starting XMLRPC Daemon...\n";

my $daemon;
eval { $daemon = new Astro::VO::SAMP::Transport::HTTP::Daemon(
       LocalPort => $port, LocalHost => $host, ReuseAddr => 1 ); };
if ( $@ ) {
   croak( "$@" );
}

# We're using inheritence as syntactic to work around the auto-dispatch path
# problems and dispatch to properly camel cased objects. We probably should
# do $daemon->dispatch_to('samp::hub::isAlive' => 'Astro::VO::SAMP::Hub::isAlive') for
# each method but the "use base" hack seems cleaner.

$daemon->dispatch_to( "samp::hub" ) ;

my $url = $daemon->url();
print "Started at $url\n";

eval { Astro::VO::SAMP::Hub::Util::create_lock_file( $url ); };
if ( $@ ) {
   croak( "$@" );
} else {
   print "Created a lock file\n";
}

eval { $daemon->handle; };
if ( $@ ) {
  croak( "$@" );
}

# C L E A N   U P -------------------------------------------------------------

# Send notifications to all clients
Astro::VO::SAMP::Hub::Util::notify_hub_shutting_down( );

# Clean up after ourselves
Astro::VO::SAMP::Hub::Util::delete_lock_file( );
Astro::VO::SAMP::Hub::MetaData::delete_files( );

END {

   # TO DO - send shutdown message to all registered clients
   print "Done.\n";
   exit;
}


=back

=head1 REVISION

$Id: samp_hub.pl,v 1.22 2008/03/17 17:23:31 aa Exp $

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

# S A M P : : H U B ------------------------------------------------------------

package samp::hub;
use base ( "Astro::VO::SAMP::Hub" );

1;
