package SAMP::Data;

use strict;
use warnings;

require Exporter;

use UNIVERSAL 'isa';
use XMLRPC::Lite;

use vars qw/ $VERSION @EXPORT_OK @ISA /;
'$Revision: 1.22 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ string list map /;

use DateTime;

=head1 NAME

SAMP::Util - Utility routines

=head1 SYNOPSIS

  use SAMP::Data;
  
  my $reference = SAMP::Data::string( $scalar );
  my $reference = SAMP::Data::list( @array );  
  my $reference = SAMP::Data::map( %hash );  
    
=head1 DESCRIPTION

This module contains utility routines to convert arrays, scalars and hashes
to SAMP data types used for transport via XMLRPC implementation.

=cut

sub string {
  my $scalar = shift;
  return XMLRPC::Data->type( string => $scalar );
}

sub list {
  my @array = @_; 
  
  my @list;
  foreach my $i ( 0 ... $#array ) {
     push @list, XMLRPC::Data->type( string => $array[$i] );
  }
  return \@list;
}

sub map { 
   my %hash = @_;
   
   my %map;
   foreach my $key ( sort keys %hash ) {
      if ( isa $hash{$key}, "HASH" ) {
         my %subhash = %{$hash{$key}};
         foreach my $subkey ( sort keys %subhash ) {
	    $subhash{$subkey} = XMLRPC::Data->type(string=>$subhash{$subkey});
	 } 
	 $map{$key} = \%subhash;
      } else {
         $map{$key} = XMLRPC::Data->type( string => $hash{$key} );
      }	 
   }
   return \%map;
}          


=back

=head1 REVISION

$Id: Util.pm,v 1.22 2008/03/17 17:23:31 aa Exp $

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
