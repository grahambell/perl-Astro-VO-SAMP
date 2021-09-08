package Astro::VO::SAMP::Hub::MetaData;

use strict;
use warnings;

use parent qw/Exporter/;

use Carp;
use File::Spec;

our $VERSION = '2.00';

our @EXPORT_OK = qw/ metadata_present write_metadata get_metadata delete_metadata
                 delete_files add_application remove_application is_registered
                 public_from_private private_from_public list_clients
                 client_supports_mtype /;

our $config_dir = File::Spec->catdir( $ENV{HOME}, ".samp-hub" );
our $config_file = File::Spec->catfile( $config_dir, "applications.dat" );

=head1 NAME

Astro::VO::SAMP::Hub::MetaData - Access to Hub config

=head1 SYNOPSIS

  use Astro::VO::SAMP::Hub::MetaData;

  my $bool = Astro::VO::SAMP::Hub::MetaData::metadata_present( $private_key );

  my $bool = Astro::VO::SAMP::Hub::MetaData::write_metadata( $private_key, %metadata );
  my %metadata = Astro::VO::SAMP::Hub::MetaData::slurp_metadata( $private_key );
  my $value = Astro::VO::SAMP::Hub::MetaData::get_metadata( $private_key, $key );
  my $bool = Astro::VO::SAMP::Hub::MetaData::delete_metadata( $private_key );

  my $bool = Astro::VO::SAMP::Hub::MetaData::delete_files( );

The last method will delete all backend state for the hub (used at shutdown).

=head1 DESCRIPTION

This module contains routines to encapsulate access to the Hub config files

=cut

sub metadata_present {
   my $private_key = shift;

   my $file_name = get_path_to_metadata( $private_key );
   my $status = config_file_present( $file_name );
   return $status;
}

sub slurp_metadata {
   my $private_key = shift;

   my %metadata;
   if ( metadata_present( $private_key ) ) {
      my $file_name = get_path_to_metadata( $private_key );
      %metadata = slurp_config_file( $file_name );
   }
   return %metadata;
}

sub get_metadata {
   my $private_key = shift;
   my $key = shift;

   my %metadata = slurp_metadata( $private_key );
   my $value;
   foreach my $i ( sort keys %metadata ) {
      $value = $metadata{$i} if $key eq $i;
   }
   return $value;
}

sub write_metadata {
   my $private_key = shift;
   my %new_data = @_;

   my %metadata = slurp_metadata( $private_key );

   # This will add new keys and update old ones, keys
   # in %metadata but not %new_data will remain untouched
   my %merged = ();
   while( my($k,$v) = each(%metadata)) {
      $merged{$k} = $v;
   }
   while( my($k,$v) = each(%new_data)) {
      $merged{$k} = $v;
   }

   my $file_name = get_path_to_metadata( $private_key );
   my $status = overwrite_config_file( $file_name, %merged );
   return $status;
}

sub delete_metadata {
   my $private_key = shift;
   my $file_name = get_path_to_metadata( $private_key );
   my $status = delete_config_file( $file_name );
   return $status;
}

sub delete_files {
   return 1 unless config_dir_present( );
   my $config_dir = config_dir( );

   my @files;
   if ( opendir (DIR, $config_dir )) {
     foreach ( readdir DIR ) {
        push( @files, $_ );
     }
     closedir DIR;
   } else {
      croak("Can not open directory $config_dir");
   }
   foreach my $i ( 0 ... $#files ) {

      next if $files[$i] =~ m/^\.$/;
      next if $files[$i] =~ m/^\.\.$/;

      #print "file = $files[$i]\n";
      delete_config_file( File::Spec->catfile( config_dir(), $files[$i] ) );
   }
   delete_config_file( File::Spec->catfile( config_dir(), config_file() ) );
   my $status;
   eval { $status = rmdir $config_dir };
   if( $@ ) {
     croak( "$@" );
   }
   return $status;
}

# R O U T I N E S   D E A L I N G   W I T H  L I S T   F I L E -----------------

sub add_application {
   my $private_key = shift;
   my $client_id = shift;

   my %metadata = get_config_file( );
   $metadata{$private_key} = $client_id;
   my $status = overwrite_config_file( config_file(), %metadata );

   return $status;
}

sub remove_application {
   my $private_key = shift;

   my %metadata = get_config_file( );
   foreach my $key ( keys %metadata ) {
     delete $metadata{$key} if $key eq $private_key;
   }
   my $status = overwrite_config_file( config_file(), %metadata );

   return $status;

}

sub is_registered {
   my $private_key = shift;

   my %metadata = get_config_file( );
   my $status = 0;
   foreach my $key ( keys %metadata ) {
     if ( $key eq $private_key ) {
       $status = 1;
       last;
     }
   }
   return $status;
}

sub public_from_private {
   my $private_key = shift;

   my %metadata = get_config_file( );
   return $metadata{$private_key};
}

sub private_from_public {
   my $public_key = shift;

   my %metadata = get_config_file( );
   my $private_key;
   foreach my $key ( keys %metadata ) {
     if( $metadata{$key} eq $public_key ) {
        $public_key = $key;
        last;
     }
   }
   return $public_key;
}

sub list_clients {
   my %metadata = get_config_file( );
   return %metadata;
}

sub client_supports_mtype {
   my $private_key = shift;
   my $mtype = shift;

   my %metadata = slurp_metadata( $private_key );
   my $status = 0;
   foreach my $key ( keys %metadata ) {
      if ( $key =~ "mtype" ) {
         $status = 1 if $metadata{$key} eq $mtype;
      }
   }

   return $status;
}

# P R I V A T E   R O U T I N E S --------------------------------------------

sub get_path_to_metadata {
  my $private_key = shift;

  #$private_key =~ m/:(\w*)$/;
  my $file_name = File::Spec->catfile( config_dir( ), $private_key );
  return $file_name;
}

sub config_dir_present {
   return ( -d $config_dir );
}

sub config_dir {
   return $config_dir;
}

sub config_file {
   return $config_file;
}

sub get_config_file {

   my $file_name = config_file();
   my %metadata;
   if (config_file_present( $file_name ) ) {
      %metadata = slurp_config_file( $file_name );
   }
   return %metadata;
}

sub create_config_dir {
   return 1 if config_dir_present( );

   if( opendir( DIR, config_dir( ) ) ) {
      closedir( DIR );
   } else {
      eval { mkdir config_dir( ), 0755; };
      if ( $@ ) {
         croak( "Unable to create config directory " . config_dir( ) );
      }
   }
   return 1;
}

sub config_file_present {
   my $config_file = shift;
   return ( -s $config_file );
}


sub create_config_file {
   my $config_file = shift;
   return 1 if config_file_present( $config_file );

   create_config_dir( ) unless config_dir_present( );
   unless( open( CONFIG, ">$config_file" ) ) {
      croak( "Unable to create config file $config_file" );
   }
   close( CONFIG );
   return 1;

}

sub delete_config_file {
   my $config_file = shift;
   return 1 unless config_file_present( $config_file );

   my $status;
   eval { $status = unlink $config_file };
   if( $@ ) {
      croak( $@ );
   }
   return $status;
}

sub overwrite_config_file {
   my $config_file = shift;
   my %data = @_;

   # Both of these calls will croak( ) if they fail
   create_config_dir( ) unless config_dir_present( );
   create_config_file( $config_file );

   # open file in
   eval {
      open( CONFIG, ">$config_file" );
      foreach my $key ( sort keys %data ) {
         print CONFIG "$key=$data{$key}\n";
      }
      close( CONFIG );
   };
   if ( $@ ) {
      croak( "Unable to write to config file $config_file" );
   }
   return 1;
}

sub slurp_config_file {
   my $config_file = shift;
   return undef unless config_file_present( $config_file );

   my %config;
   if ( open( CONFIG, "<$config_file" ) )  {
      while (<CONFIG>) {
        chomp;                  # no newline
        s/#.*//;                # no comments
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        my ($key, $value) = split(/\s*=\s*/, $_, 2);
        $config{$key} = $value;
      }
      close( CONFIG );
   }
   return %config;
}

=back

=head1 AUTHORS

Alasdair Allan E<lt>alasdair@babilim.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Babilim Light Industries. All Rights Reserved.

=cut

1;
