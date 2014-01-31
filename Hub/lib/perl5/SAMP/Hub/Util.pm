package SAMP::Hub::Util;

use strict;
use warnings;

require Exporter;

use vars qw/ $VERSION @EXPORT_OK @ISA /;
'$Revision: 1.22 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ delete_lock_file create_lock_file 
		 generate_samp_secret generate_app_keys
		 notify_hub_shutting_down /;

use SAMP::Discovery;
use SAMP::Util;
use SAMP::Hub::MetaData;

=head1 NAME

SAMP::Hub::Util - Utility routines

=head1 SYNOPSIS

  use SAMP::Hub::Util;
  
  my $bool = SAMP::Util::delete_lock_file( );
  my $bool = SAMP::Util::create_lock_file( $samp_xmlrpc_url );
  
  my $samp_secret = SAMP::Util::generate_samp_secret( );
  my ( $public_key, $private_key ) = SAMP::Util::generate_app_keys( );
  
  SAMP::Util::notify_hub_shutting_down( $hub_public_id );
  
=head1 DESCRIPTION

This module contains utility routines useful for SAMP Hubs and clients.

=cut


sub delete_lock_file {
   return undef unless SAMP::Discovery::lock_file_present( );
   
   my $lock_file = SAMP::Discovery::lock_file( );
   my $status;
   eval { $status = unlink $lock_file };
   return $status;
}   

sub create_lock_file {
   my $samp_xmlrpc_url = shift;

   my $text = "";
   $text .= "# SAMP lockfile written at " . SAMP::Util::time_in_UTC() . "\n";
   $text .= '# Hub implementation by Alasdair Allan <alasdair@babilim.co.uk>';
   $text .= "\n# Required keys:\n";
   $text .= "samp.secret=" . generate_samp_secret( ) . "\n";
   $text .= "samp.hub.xmlrpc.url=$samp_xmlrpc_url\n";  
   $text .= "samp.profile.version=1.0\n";

   my $lock_file = SAMP::Discovery::lock_file( );
   my $status = 0;
   if ( open ( LOCK, ">$lock_file" ) ) {
      print LOCK $text;
      close( LOCK );
      $status = 1;
   }    
   return $status;      
}   

sub generate_samp_secret {
    my $random_string = _generate_random_string( );
    return $random_string;
}

sub generate_app_keys {
    # public key
    my $public_key = "client-id:" . _generate_random_string( );

    # DES salt
    my $length = 2;
    my @chars=('a'..'z','A'..'Z','0'..'9' );
    
    #foreach my $i ( 0 ... $#chars ) {
    #  print "$chars[$i]\n";
    #}
    
    my $salt;
    foreach ( 1 ... $length ) {
       # rand @chars will generate a random 
       # number between 0 and scalar @chars
       $salt.=$chars[rand @chars];
    }    
    
    # private key
    my $private_key = "app-id:" . _generate_random_string( );
    return ($public_key, $private_key);
}

sub notify_hub_shutting_down {

    my %list = SAMP::Hub::MetaData::list_clients( );    
    my $hub_public_id = SAMP::Hub::public_key( );
    #print "Hub public_id = $hub_public_id\n"; 
    
    foreach my $key ( keys %list ) {
       my $name = SAMP::Hub::MetaData::get_metadata( $key, "samp.name" );
       print "Notifying application $name\n";
       my $callable = SAMP::Hub::MetaData::get_metadata( $key, "$name.callable" );
       
       my %hash;
       $hash{mtype} = "app.event.stopping";
       my $message = SAMP::Data::map( %hash );
       
       if( $callable ) {
          my $url = SAMP::Hub::MetaData::get_metadata( $key, "$name.xmlrpc" );
          
	  print "Application at $url\n";
	  my $rpc = new XMLRPC::Lite();
          $rpc->proxy( $url );

          my $return; 
          eval{ $return = $rpc->call( 'samp.client.recieveNotification', 
      				      $hub_public_id, $message ); };
          if ( $@ || $return->fault() ) {
             print "Couldn't contact samp.name = $name\n";
          } else {
	     print "Notified samp.name = $name\n";
	  }   
       }	  
    }
	    
    return 1;
}

=back

=head1 REVISION

$Id: Util.pm,v 1.22 2008/03/17 17:23:31 aa Exp $

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

# P R I V A T E   M E T H O D S ------------------------------------------------

sub _generate_random_string {
    my $length = 20;
    my @chars=('a'..'z','A'..'Z','0'..'9' );
    my $random_string;
    foreach ( 1 ... $length ) {
       # rand @chars will generate a random 
       # number between 0 and scalar @chars
       $random_string.=$chars[rand @chars];
    }
    return $random_string;
}
    
1;
