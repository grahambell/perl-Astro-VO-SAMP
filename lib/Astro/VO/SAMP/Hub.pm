package Astro::VO::SAMP::Hub;

use strict;
use warnings;

use XMLRPC::Lite;

use Astro::VO::SAMP::Util;
use Astro::VO::SAMP::Data;
use Astro::VO::SAMP::Hub::MetaData;

require Exporter;

use vars qw/ @EXPORT_OK @ISA $PRIVATE_KEY $PUBLIC_KEY /;

our $VERSION = '2.00';

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ private_key public_key
                 isAlive getHubId register unregister
                 setMetadata setXmlrpcCallback setMTypes /;

=head1 NAME

Astro::VO::SAMP::Hub - Routines to handle SAMP calls

=head1 SYNOPSIS

  use Astro::VO::SAMP::Hub;

=head1 DESCRIPTION

This module contains routines to handle the SAMP Standard Profile.

=cut

sub private_key {
  if (@_) {
    $PRIVATE_KEY = shift;
  }
  return $PRIVATE_KEY;


}

sub public_key {
  if (@_) {
    $PUBLIC_KEY = shift;
  }
  return $PUBLIC_KEY;


}


sub isAlive {
   print "isAlive( ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   return Astro::VO::SAMP::Data::string( 1 );
}

sub getHubId {
   print "getHubId( ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   return Astro::VO::SAMP::Data::string( public_key() );
}

sub register {
   my $self = shift;
   my $token = shift;
   print "register(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";

   my ( $public_id, $private_id);
   if ( $token eq Astro::VO::SAMP::Discovery::get_samp_secret( ) ) {
      ( $public_id, $private_id) = Astro::VO::SAMP::Hub::Util::generate_app_keys( );
      print "Registering client...\n";
      print "client-id = $public_id\n";
      print "private-key = $private_id\n";

      eval{ Astro::VO::SAMP::Hub::MetaData::write_metadata(
                 $private_id, "client.id" => $public_id ); };
      if ( $@ ) {
         print "$@";
         undef $private_id;
      }
      eval{ Astro::VO::SAMP::Hub::MetaData::add_application( $private_id, $public_id ); };
      if ( $@ ) {
         print "$@";
         undef $private_id;
      }

   }

   # TO DO - Broadcast to all registered clients the $public_id of the client

   return Astro::VO::SAMP::Data::string( $private_id );
}

sub unregister {
   my $self = shift;
   my $private_key = shift;
   print "unregister(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );

   # Deal with clients that aren't registered
   unless( $app ) {
      print "Client private-key = $private_key\n";
      print "Client doesn't seem to be registed. Ignorning request\n";
      return Astro::VO::SAMP::Data::string( 1 );
   }

   # deal wit the rest
   print "Un-registering client samp.name = $app\n";
   print "private-key = $private_key\n";
   my $status;
   print "Deleting metadata file...\n";
   eval{ $status = Astro::VO::SAMP::Hub::MetaData::delete_metadata( $private_key ); };
   if ( $@ ) {
      print "$@";
   } else {
      print "Deleted metadata cache file\n";
   }
   print "Deleting entry from application list...\n";
   eval{ Astro::VO::SAMP::Hub::MetaData::remove_application( $private_key ); };
   if ( $@ ) {
      print "$@";
   } else {
      print "Deleted application from mappings file\n";
   }
   print "Done.\n";

   # TO DO - Broadcast to all registered clients the $public_id of the client

   return Astro::VO::SAMP::Data::string( $status );

}


sub setMetadata {
   my $self = shift;
   my $private_key = shift;
   my $reference = shift;
   my %metadata = %$reference;

   print "setMetaData(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   print "Called by samp.name = $metadata{'samp.name'}\n";

   my $status;
   eval{ $status = Astro::VO::SAMP::Hub::MetaData::write_metadata( $private_key, %metadata ); };
   if ( $@ ) {
      print "$@";
      $status = 0;
   }

   # TO DO - Broadcast to all registered clients the new metadata of the client


   return Astro::VO::SAMP::Data::string( $status )

}

sub setXmlrpcCallback {
   my $self = shift;
   my $private_key = shift;
   my $endpoint = shift;
   print "setXmlrpcCallback(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";

   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my %metadata;
   $metadata{ "$app.callable" } = 1;
   $metadata{ "$app.xmlrpc" } = $endpoint;
   my $status;
   eval{ $status = Astro::VO::SAMP::Hub::MetaData::write_metadata( $private_key, %metadata ); };
   if ( $@ ) {
      print "$@";
      $status = 0;
   }

   # TO DO - Broadcast to all registered clients the new metadata of the client

   return Astro::VO::SAMP::Data::string( $status )

}

sub setMTypes {
   my $self = shift;
   my $private_key = shift;
   my $reference = shift;
   my @mtypes = @$reference;

   print "setMTypes(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   # TO DO - Serialise list of MTypes to metadata file. How?
   my %metadata;
   foreach my $i ( 0 ... $#mtypes ) {
      $metadata{"mtype.$i"} = $mtypes[$i];
      print "samp.name = $app supports $mtypes[$i]\n";
   }

   my $status;
   eval{ $status = Astro::VO::SAMP::Hub::MetaData::write_metadata( $private_key, %metadata ); };
   if ( $@ ) {
      print "$@";
      $status = 0;
   }

   # TO DO - Broadcast to all registered clients the new metadata of the client

   return Astro::VO::SAMP::Data::string( $status )
}


sub getMTypes {
   my $self = shift;
   my $private_key = shift;
   my $client_id = shift;

   print "getMTypes(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my $look_up = Astro::VO::SAMP::Hub::MetaData::private_from_public( $client_id );
   my %metadata = Astro::VO::SAMP::Hub::MetaData::slurp_metadata( $look_up );
   my @mtypes;
   foreach my $key ( keys %metadata ) {
      push @mtypes, $metadata{$key} if $key =~ "mtype";
   }

   return Astro::VO::SAMP::Data::list( @mtypes );
}

sub getMetadata {
   my $self = shift;
   my $private_key = shift;
   my $client_id = shift;

   print "getMetadata(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my $look_up = Astro::VO::SAMP::Hub::MetaData::private_from_public( $client_id );
   my %metadata = Astro::VO::SAMP::Hub::MetaData::slurp_metadata( $look_up );

   return Astro::VO::SAMP::Data::map( %metadata );
}

sub getRegisteredClients {
   my $self = shift;
   my $private_key = shift;

   print "getRegisteredClients(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my %clients = Astro::VO::SAMP::Hub::MetaData::list_clients( );
   my @list;
   foreach my $key ( keys %clients ) {
      push @list, $clients{$key};
   }

   return Astro::VO::SAMP::Data::list( @list );
}

sub getSubscribedClients {
   my $self = shift;
   my $private_key = shift;
   my $mtype = shift;

   print "getSubscribedClients(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my %clients = Astro::VO::SAMP::Hub::MetaData::list_clients( );
   my @client_ids;
   foreach my $client ( keys %clients ) {
      if( Astro::VO::SAMP::Hub::Config::client_supports_mtype( $client, $mtype ) ) {
         push @client_ids, $clients{$client};
      }
   }

   return Astro::VO::SAMP::Data::list( @client_ids );
}

sub notify {
   my $self = shift;
   my $private_key = shift;
   my $recipient_id = shift;
   my $reference = shift;
   my %message = %$reference;

   print "notify(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my $public_id = Astro::VO::SAMP::Hub::MetaData::public_from_private( $private_key );
   my $recipient_key = Astro::VO::SAMP::Hub::MetaData::private_from_public( $recipient_id );

   my $name = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "samp.name" );
   my $callable = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "$name.callable" );
   $callable = 0 unless defined $callable; # might just be registering

   my $mtype = $message{mtype};
   my $supported = Astro::VO::SAMP::Hub::MetaData::client_supports_mtype($recipient_key, $mtype);
   $supported = 0 unless defined $supported; # might just be registering

   print "samp.name = $name, callable = $callable, supported = $supported\n";

   if( $callable && $supported ) {
      print "Passing notification to samp.name = $name\n";
      my $relayed = Astro::VO::SAMP::Data::map( %message );
      my $url = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "$name.xmlrpc" );

      print "Application is at $url\n";
      my $rpc = new XMLRPC::Lite();
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.client.recieveNotification',
                                  $public_id, $relayed ); };
      if ( $@ ) {
         print "Couldn't contact samp.name = $name\n";
         print "$@\n";
      } elsif ( $return->fault() ) {
         print "Couldn't contact samp.name = $name\n";
         print $return->faultstring( ) . "\n";
      } else {
         print "Notified samp.name = $name\n";
      }
   }

   my $status;
   if ( $callable && $supported ) {
      $status = 1;
   } else {
      $status = 0;
   }
   return Astro::VO::SAMP::Data::string( $status );

}

sub notifyAll {
   my $self = shift;
   my $private_key = shift;
   my $reference = shift;
   my %message = %$reference;

   #use Data::Dumper;
   #print Dumper( $reference );

   print "notifyAll(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my %list = Astro::VO::SAMP::Hub::MetaData::list_clients( );
   foreach my $key ( keys %list ) {
      my $recipient_id = Astro::VO::SAMP::Hub::MetaData::public_from_private( $key );
      notify( $self, $private_key, $recipient_id, $reference );
   }

   return Astro::VO::SAMP::Data::string( 1 );

}

sub call {
   my $self = shift;
   my $private_key = shift;
   my $recipient_id = shift;
   my $msg_id = shift;
   my $reference = shift;
   my %message = %$reference;

   print "call(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";
   print "Message has id = $msg_id\n";

   my $public_id = Astro::VO::SAMP::Hub::MetaData::public_from_private( $private_key );
   my $recipient_key = Astro::VO::SAMP::Hub::MetaData::private_from_public( $recipient_id );

   my $name = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "samp.name" );
   my $callable = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "$name.callable" );
   $callable = 0 unless defined $callable; # might just be registering

   my $mtype = $message{mtype};
   my $supported = Astro::VO::SAMP::Hub::MetaData::client_supports_mtype($recipient_key, $mtype);
   $supported = 0 unless defined $supported; # might just be registering

   print "samp.name = $name, callable = $callable, supported = $supported\n";

   if( $callable && $supported ) {
      print "Passing call to samp.name = $name\n";
      my $relayed = Astro::VO::SAMP::Data::map( %message );
      my $url = Astro::VO::SAMP::Hub::MetaData::get_metadata( $recipient_key, "$name.xmlrpc" );

      print "Application is at $url\n";
      my $rpc = new XMLRPC::Lite();
      $rpc->proxy( $url );

      my $hub_msg_id = $public_id . "_" . "$msg_id";
      $hub_msg_id =~ s/msg-id://;
      $hub_msg_id =~ s/client-id:/msg-id:/;
      my $return;
      eval{ $return = $rpc->call( 'samp.client.recieveCall',
                                  $public_id, $hub_msg_id, $relayed ); };
      if ( $@ ) {
         print "Couldn't contact samp.name = $name\n";
         print "$@\n";
      } elsif ( $return->fault() ) {
         print "Couldn't contact samp.name = $name\n";
         print $return->faultstring( ) . "\n";
      } else {
        print "Notified samp.name = $name\n";
      }
   }

   my $status;
   if ( $callable && $supported ) {
      $status = 1;
   } else {
      $status = 0;
   }
   return Astro::VO::SAMP::Data::string( $status );
}

sub callAll {
   my $self = shift;
   my $private_key = shift;
   my $msg_id = shift;
   my $reference = shift;
   my %message = %$reference;

   #use Data::Dumper;
   #print Dumper( $reference );

   print "callAll(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";

   my %list = Astro::VO::SAMP::Hub::MetaData::list_clients( );
   foreach my $key ( keys %list ) {
      my $recipient_id = Astro::VO::SAMP::Hub::MetaData::public_from_private( $key );
      call( $self, $private_key, $recipient_id, $msg_id, $reference );
   }

   return Astro::VO::SAMP::Data::string( 1 );


}

sub callAndWait {
   my $self = shift;
   my $private_key = shift;
   my $public_id = shift;
   my $reference = shift;
   my %message = %$reference;

   print "callAndWait(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";
   print "Intended for public id = $public_id\n";
   my $private_id = Astro::VO::SAMP::Hub::MetaData::private_from_public( $public_id );
   print "Private key of this application is $private_id\n";
   my $recipient = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_id, "samp.name" );
   my $callable = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_id, "$recipient.callable" );
   $callable = 0 unless defined $callable; # might just be registering
   print "Intended for samp.name = $recipient, callable = $callable\n";

   print "WARNING: CallAndWait( ) NOT IMPLEMENTED\n";
   print "WARNING: RETURNING EMPTY MAP TO CLIENT\n";

   my %response = ( );
   return Astro::VO::SAMP::Data::map( %response );
}

sub reply {
   my $self = shift;
   my $private_key = shift;
   my $hub_msg_id = shift;
   my $success = shift;
   my $reference = shift;
   my %message = %$reference;

   print "reply(  ) called at " . Astro::VO::SAMP::Util::time_in_UTC() . "\n";
   my $app = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, "samp.name" );
   print "Called by samp.name = $app\n";
   print "Message has id = $hub_msg_id\n";

   my $sender_id = Astro::VO::SAMP::Hub::MetaData::public_from_private( $private_key );

   my ( $public_id, $msg_id) = split "_", $hub_msg_id;
   $public_id =~ s/msg-id:/client-id:/;
   $msg_id = "msg-id:" . $msg_id;

   print "Intended for public id = $public_id\n";
   my $private_id = Astro::VO::SAMP::Hub::MetaData::private_from_public( $public_id );
   print "Private key of this application is $private_id\n";
   my $recipient = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_id, "samp.name" );
   my $callable = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_id, "$recipient.callable" );
   $callable = 0 unless defined $callable; # might just be registering
   print "Intended for samp.name = $recipient, callable = $callable\n";

   if( $callable ) {
      print "Returning reply to samp.name = $recipient\n";
      print "Success state = $success\n";
      my $relayed = Astro::VO::SAMP::Data::map( %message );
      my $url = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_id, "$recipient.xmlrpc" );

      print "Application is at $url\n";
      my $rpc = new XMLRPC::Lite();
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.client.recieveResponse',
                                  $sender_id, $msg_id, $success, $relayed ); };
      if ( $@ ) {
         print "Couldn't contact samp.name = $recipient\n";
         print "$@\n";
      } elsif ( $return->fault() ) {
         print "Couldn't contact samp.name = $recipient\n";
         print $return->faultstring( ) . "\n";
      } else {
         print "Forwared reply from samp.name = $app to samp.name = $recipient\n";
      }
   }

   my $status;
   if ( $callable ) {
      $status = 1;
   } else {
      $status = 0;
   }
   return Astro::VO::SAMP::Data::string( $status );

}


=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
