package Astro::VO::SAMP::Discovery;

use strict;
use warnings;

require Exporter;

use vars qw/ $VERSION @EXPORT_OK @ISA /;
'$Revision: 1.22 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ lock_file_present lock_file
                 get_xmlrpc_url get_samp_secret 
		 hub_running/;

use File::Spec;
use XMLRPC::Lite;

use vars qw / $lock_file /;
$lock_file = File::Spec->catfile( $ENV{HOME}, ".samp" );

=head1 NAME

Astro::VO::SAMP::Discovery - Routines for Hub discovery

=head1 SYNOPSIS

  use Astro::VO::SAMP::Discovery;
  
  my $bool = Astro::VO::SAMP::Discovery::lock_file_present( );
  my $lock_filename = Astro::VO::SAMP::Discovery::lock_file( );
  
  my @list_client_ids = Astro::VO::SAMP::Discovery::hub_running( );
  
  my $samp_xmlrpc_url = Astro::VO::SAMP::Discovery::get_xmlrpc_url( );
  my $samp_secret = Astro::VO::SAMP::Discovery::get_samp_secret( );
    
=head1 DESCRIPTION

This module contains routines encapsulating SAMP Hub discovery.

=cut

sub lock_file_present {
   return ( -s $lock_file ); 
}

sub lock_file {
   return $lock_file;
}   


sub get_xmlrpc_url {
   return undef unless lock_file_present( );
   
   my $samp_xmlrpc;
   if ( open( LOCK, "<$lock_file" ) )  {
   
      # slurp file
      my @file = <LOCK>;
      close( LOCK );

      foreach my $i ( 0 ... $#file ) {
        if ( $file[$i] =~ "samp.hub.xmlrpc.url" ) {
           my @line = split "=", $file[$i];
           chomp($line[1]);
           $samp_xmlrpc = $line[1];
           $samp_xmlrpc =~ s/\\//g;
        } 
      }
   }
   return $samp_xmlrpc;
}      

sub get_samp_secret {
   return undef unless lock_file_present( );
   
   my $samp_secret;
   if ( open( LOCK, "<$lock_file" ) )  {
      #print "Found existing $lock_file\n";
   
      # slurp file
      my @file = <LOCK>;
      close( LOCK );

      foreach my $i ( 0 ... $#file ) {
        if ( $file[$i] =~ "samp.secret" ) {   
           my @line = split "=", $file[$i];
           chomp($line[1]);
           $samp_secret = $line[1];
           $samp_secret =~ s/\\//g;
        } 
      }
   }   
   return $samp_secret;
}  

sub hub_running {
   return undef unless lock_file_present( );

   my $running = 0;
   my $samp_xmlrpc = get_xmlrpc_url( );
   if ( defined $samp_xmlrpc ) {
      my $rpc = new XMLRPC::Lite();
      $rpc->proxy($samp_xmlrpc); 
      my $return;
      eval{ $return = $rpc->call( 'samp.hub.isAlive' ); };
      unless ( $@ || $return->fault() ) {
        $running = $return->result();
      }
   }         
   return $running;     
   
}

=back

=head1 REVISION

$Id: Discovery.pm,v 1.22 2008/03/17 17:23:31 aa Exp $

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
