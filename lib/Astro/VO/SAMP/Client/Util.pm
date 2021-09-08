package Astro::VO::SAMP::Client::Util;

use strict;
use warnings;

use parent qw/Exporter/;

our $VERSION = '2.00';

our @EXPORT_OK = qw/ wait_for_hub hub_discovery fork_server
                 register unregister
                 send_metadata send_xmlrpc_callback send_mtypes
                 generate_msg_id /;

use XMLRPC::Lite;

use POSIX qw/:sys_wait_h/;
use Errno qw/EAGAIN/;

use Astro::VO::SAMP::Transport::HTTP::Daemon;
use Astro::VO::SAMP::Discovery;
use Astro::VO::SAMP::Util;

=head1 NAME

Astro::VO::SAMP::Client::Util - Utility routines

=head1 SYNOPSIS

  use Astro::VO::SAMP::Client::Util;

  my $bool = Astro::VO::SAMP::Client::Util::wait_for_hub( )
  my $private_key = Astro::VO::SAMP::Client::Util::register( $samp_secret );
  my $bool = Astro::VO::SAMP::Client::Util::unregister( );
  my $bool = Astro::VO::SAMP::Client::Util::send_metadata( Astro::VO::SAMP::Data::map( %metadata ) );
  my $bool = Astro::VO::SAMP::Client::Util::send_metadata( Astro::VO::SAMP::Data::map( %metadata ) );

=head1 DESCRIPTION

This module contains utility routines useful for SAMP clients.

=cut


sub wait_for_hub {
   my $hub_status = 0;

   REGISTER: {

   $hub_status = Astro::VO::SAMP::Discovery::hub_running( );
   unless( $hub_status ) {
      sleep( 5 );
      redo REGISTER;
   }
   }
   return $hub_status;
}

sub hub_discovery {
   my %metadata = Astro::VO::SAMP::Client::metadata();

   print "Waiting for Hub to start up...\n";

   # We wait for a hub to start up
   my $hub_status = wait_for_hub( );
   print "Found Hub at " . Astro::VO::SAMP::Discovery::get_xmlrpc_url( ) . "\n";

   # register with the Hub using $samp_secret and get our $private_key

   print "Registering with Hub...\n";
   my $reg_info = register( );
   my $private_key = $reg_info->{'samp.private-key'};
   print "Registered with Hub, private key = $private_key\n";
   Astro::VO::SAMP::Client::private_key( $private_key );

   my $hub_id = $reg_info->{'samp.hub-id'};
   print "Hub public_id = $hub_id\n";
   Astro::VO::SAMP::Client::hub_id( $hub_id );

   my $self_id = $reg_info->{'samp.self-id'};
   print "Client self_id = $self_id\n";
   Astro::VO::SAMP::Client::self_id( $self_id );

   print "Sending meta-data to Hub...\n";
   my $data = Astro::VO::SAMP::Data::map( %metadata );
   my $status = send_metadata( $data );
   if ( $status ) {
      print "Sucessfully registered meta-data with Hub\n";
   } else {
      print "Problems registering meta-data with Hub (status = $status)\n";
   }

   return $status;
}

sub fork_server {
   my $host = shift;
   my $port = shift;

   my ( $pid, $dead );
   $dead = waitpid (-1, &WNOHANG);
   #  $dead = $pid when the process dies
   #  $dead = -1 if the process doesn't exist
   #  $dead = 0 if the process isn't dead yet
   if ( $dead != 0 ) {
    FORK: {
        if ($pid = fork) {
             print "Continuing... pid = $pid\n";
        } elsif ( defined $pid && $pid == 0 ) {
              print "Forking daemon process... pid = $pid\n";
              my $daemon;
              eval { $daemon = new Astro::VO::SAMP::Transport::HTTP::Daemon(
                     LocalPort => $port, LocalHost => $host, ReuseAddr => 1 );};
              if ( $@ ) {
                 my $error = "$@";
                 croak( "Error: $error" );
              }

             $daemon->dispatch_to( "samp::client" ) ;

              my $url = $daemon->url();
              print "Starting at $url\n";

              eval { $daemon->handle; };
              if ( $@ ) {
                my $error = "$@";
                croak( "Error: $error" );
              }

          } elsif ($! == EAGAIN ) {
              # This is a supposedly recoverable fork error
              print "Error: recoverable fork error\n";
              sleep 5;
              redo FORK;
       } else {
              # Fall over and die screaming
              croak("Unable to fork(), this is fairly odd.");
       }
    }
   }

   return $pid;

}

sub register {

   my $reg_info;
   REGISTER: {

   # We wait for a hub to start up
   my $hub_status = Astro::VO::SAMP::Client::Util::wait_for_hub( );
   print "Found Hub at " . Astro::VO::SAMP::Discovery::get_xmlrpc_url( ) . "\n";

   # register with the Hub using $samp_secret and get our $private_key

   print "Registering with Hub...\n";
   $reg_info = _register(  );
   unless ( defined $reg_info ) {
      print "Unable to register with Hub, retrying in 5 seconds...\n";
      sleep( 5 );
      redo REGISTER;
   }
   }
   return $reg_info;
}

sub unregister {
   my $private_key = Astro::VO::SAMP::Client::private_key( );

   my $status = 0;
   if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {
      my $rpc = new XMLRPC::Lite();
      my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.hub.unregister', $private_key ); };
      unless ( $@ || $return->fault() ) {
        $status = 1;
      }
   }
   return $status;

}

sub send_metadata {
   my $metadata = shift;
   my $private_key = Astro::VO::SAMP::Client::private_key( );

   my $status = 0;
   if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {
      my $rpc = new XMLRPC::Lite();
      my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.hub.declareMetadata',
                                  $private_key, $metadata ); };
      unless ( $@ || $return->fault() ) {
        $status = 1;
      }
   }
   return $status;

}

sub send_xmlrpc_callback {
   my $endpoint = shift;
   my $private_key = Astro::VO::SAMP::Client::private_key( );

   my $status = 0;
   if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {
      my $rpc = new XMLRPC::Lite();
      my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.hub.setXmlrpcCallback',
                                  $private_key, $endpoint ); };
      unless ( $@ || $return->fault() ) {
        $status = 1;
      }
   }
   return $status;

}

sub send_mtypes {
   my $metadata = shift;
   my $private_key = Astro::VO::SAMP::Client::private_key( );

   my $status = 0;
   if ( Astro::VO::SAMP::Discovery::hub_running( ) ) {
      my $rpc = new XMLRPC::Lite();
      my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.hub.declareSubscriptions',
                                  $private_key, $metadata ); };
      unless ( $@ || $return->fault() ) {
        $status = 1;
      }
   }
   return $status;
}

sub generate_msg_id {
    my $random_string = _generate_random_string( );
    return "msg-id:" . $random_string;
}

# P R I V A T E   M E T H O D S ----------------------------------------------

sub _register {
   my $samp_secret = Astro::VO::SAMP::Discovery::get_samp_secret( );

   my $reg_info = undef;
   if ( Astro::VO::SAMP::Discovery::hub_running( ) && defined $samp_secret ) {
      my $rpc = new XMLRPC::Lite();
      my $url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
      $rpc->proxy( $url );

      my $return;
      eval{ $return = $rpc->call( 'samp.hub.register', $samp_secret ); };
      unless ( $@ || $return->fault() ) {
        $reg_info = $return->result();
      }
   }
   return $reg_info;
}

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

=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
