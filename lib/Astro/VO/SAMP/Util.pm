package Astro::VO::SAMP::Util;

use strict;
use warnings;

require Exporter;

use vars qw/ @EXPORT_OK @ISA /;

our $VERSION = '2.00';

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ time_in_UTC convert_from_sextuplets convert_to_sextuplets /;

use DateTime;

=head1 NAME

Astro::VO::SAMP::Util - Utility routines

=head1 SYNOPSIS

  use Astro::VO::SAMP::Util;

  my $iso_time_string = Astro::VO::SAMP::Util::time_in_UTC( );
  my ( $decimal_ra, $decimal_dec ) = Astro::VO::SAMP::Util::convert_from_sextuplets( $ra, $dec);
  my ( $ra, $dec ) = Astro::VO::SAMP::Util::convert_to_sextuplets( $decimal_ra, $decimal_dec);

=head1 DESCRIPTION

This module contains utility routines useful for Astro::VO::SAMP Hubs and Clients.

=cut

sub time_in_UTC {
  my $dt = DateTime->now();
  $dt->set_time_zone( 'UTC' );
  my $iso = $dt->strftime("%F"."T"."%H:%M:%S"."%z");
  return $iso;
}

sub convert_from_sextuplets {
 my $ra = shift;
 my $dec = shift;

 my ($ra_hour, $ra_min, $ra_sec) = split " ", $ra;
 my ($dec_deg, $dec_min, $dec_sec) = split " ",$dec;
 #$dec_deg =~ s/\+// if $dec_deg =~ "+";

 my $decimal_ra = $ra_hour*15.0 + ($ra_min/60.0) + ($ra_sec/3600.0);
 my $decimal_dec;
 if ( $dec_deg =~ "-" ) {
    $decimal_dec = $dec_deg - ($dec_min/60.0) - ($dec_sec/3600.0);
 } else {
    $decimal_dec = $dec_deg + ($dec_min/60.0) + ($dec_sec/3600.0);
 }

 return( $decimal_ra, $decimal_dec );
}

sub convert_to_sextuplets {
  my $decimal_ra = shift;
  my $decimal_dec = shift;

  my $ra_hour = $decimal_ra/15.0;
  my $ra_min = 60.0*( $ra_hour - int( $ra_hour ) );
  my $ra_sec = 60.0*( $ra_min - int( $ra_min ) );
  $ra_hour = int( $ra_hour );
  $ra_min = int( $ra_min );

  my $ra = "$ra_hour $ra_min $ra_sec";

  my $dec_hour = $decimal_dec;
  my ( $dec_min, $dec_sec );
  if ( $dec_hour =~ "-" ) {
     $dec_min = 60.0*( int( $dec_hour ) - $dec_hour );
  } else {
     $dec_min = 60.0*( $dec_hour - int( $dec_hour ) );
  }
  $dec_sec = 60.0*( $dec_min - int( $dec_min ) );
  $dec_hour = int( $dec_hour );
  $dec_min = int( $dec_min );

  my $dec = "$dec_hour $dec_min $dec_sec";

  return ( $ra, $dec );
}


=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
