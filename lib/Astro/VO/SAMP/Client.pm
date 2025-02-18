package Astro::VO::SAMP::Client;

use strict;
use warnings;

use parent qw/Exporter/;

use Scalar::Util qw/reftype/;

our ($PRIVATE_KEY, $HUB_ID, $SELF_ID, $METADATA);

our $VERSION = '2.00';

our @EXPORT_OK = qw/ private_key hub_id metadata
                 recieveNotification recieveCall recieveResponse /;

=head1 NAME

Astro::VO::SAMP::Client - Routines to handle SAMP calls

=head1 SYNOPSIS

  use Astro::VO::SAMP::Client;

  my $status = Astro::VO::SAMP::Client::private_key( $private_key );
  my $private_key = Astro::VO::SAMP::Client::private_key( );
  my $status = Astro::VO::SAMP::Client::hub_id( $hub_public_id );
  my $hub_public_id = Astro::VO::SAMP::Client::hub_id( );

=head1 DESCRIPTION

This module contains routines to handle the SAMP Standard Profile.

=cut

sub private_key {
  if (@_) {
    $PRIVATE_KEY = shift;
  }
  return $PRIVATE_KEY;


}

sub hub_id {
  if (@_) {
    $HUB_ID = shift;
  }
  return $HUB_ID;


}

sub self_id {
  if (@_) {
    $SELF_ID = shift;
  }
  return $SELF_ID;
}

sub metadata {
  if (@_) {
     my %metadata = @_;
     $METADATA = \%metadata;
  }
  my %metadata = %$METADATA;
  return %metadata;
}

sub recieveNotification {
   my $self = shift;
   my $sender_id = shift;
   my $reference = shift;
   my %message = %$reference;

   print "recieveNotification( ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   print "Called by sender-id = $sender_id\n";

   foreach my $key ( sort keys %message ) {
      my $reftype = reftype($message{$key});
      if ((defined $reftype) and ($reftype eq "HASH")) {
         print "$key = {\n";
         my %subhash = %{$message{$key}};
         foreach my $subkey ( sort keys %subhash ) {
            print "    $subkey = $subhash{$subkey}\n";
         }
         print "}\n";
      } else {
         print "$key = $message{$key}\n";
      }
   }

   if( $message{mtype} eq "app.event.stopping" && $sender_id eq hub_id( ) ) {
      print "Hub stopping...\n";
      exit(0);
   }

   print "Done.\n";

   return Astro::VO::SAMP::Data::string( 1 );

}

sub recieveCall {
   my $self = shift;
   my $sender_id = shift;
   my $msg_id = shift;
   my $reference = shift;
   my %message = %$reference;

   print "recieveCall( ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   print "sender-id = $sender_id\n";
   print "msg-id = $msg_id\n";

   foreach my $key ( sort keys %message ) {
      my $reftype = reftype($message{$key});
      if ((defined $reftype) and ($reftype eq "HASH")) {
         print "$key = {\n";
         my %subhash = %{$message{$key}};
         foreach my $subkey ( sort keys %subhash ) {
            print "    $subkey = $subhash{$subkey}\n";
         }
         print "}\n";
      } else {
         print "$key = $message{$key}\n";
      }
   }

   # TO-DO The client must at a later time make a matching call to reply()
   print "Forking call to reply( )...\n";
   if ( my $pid = fork) {
       print "Continuing... pid = $pid\n";
   } elsif ( defined $pid && $pid == 0 ) {
       print "Forking reply process... pid = $pid\n";
       sleep(1);
       print "Calling reply(  ) in Hub\n";

       my $status = 0;
       if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {

          print "Hub is still running...\n";
          my $rpc = new XMLRPC::Lite();
          my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
          $rpc->proxy( $url );

          my %message = ( );
          print "Passing empty map to hub and claiming success...\n";

          my ( $return, $status );
          eval{ $return = $rpc->call( 'samp.hub.reply',
                    Astro::VO::SAMP::Client::private_key( ), $msg_id,
                    Astro::VO::SAMP::Data::string( 1 ),
                    \%message ); };
          unless ( $@ || $return->fault() ) {
             $status = 1;
          }

       } else {
          print "Hub no longer running...\n";
       }
       exit(0);
   }

   print "Done.\n";
   return Astro::VO::SAMP::Data::string( 1 );

}

sub recieveResponse {
   my $self = shift;
   my $responder_id = shift;
   my $msg_id = shift;
   my $success = shift;
   my $reference = shift;
   my %response = %$reference;

   print "recieveResponse( ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   print "sender-id = $responder_id\n";
   print "msg-id = $msg_id\n";
   print "success state = $success\n";

}

=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
