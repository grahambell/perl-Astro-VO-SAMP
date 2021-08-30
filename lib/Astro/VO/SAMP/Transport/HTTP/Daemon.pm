package Astro::VO::SAMP::Transport::HTTP::Daemon;

use strict;
use vars qw(@ISA);

use XMLRPC::Lite;
use XMLRPC::Transport::HTTP;
use XML::Simple;

use Data::Dumper;

# Idea and implementation of Michael Douglass

@ISA = qw(XMLRPC::Transport::HTTP::Daemon);

sub handle {
  my $self = shift->new;

  while (my $c = $self->accept) {

     # Handle requests as they come in
     while (my $r = $c->get_request) {
       $self->request($r);

       # Pass the request to the super-class after retrieving
       # the method name from the XML so we can fix up the response.
       my $xml = $self->request()->{_content};
       my $xs = new XML::Simple( );
       my $doc = $xs->XMLin($xml);
       my $methodName = $doc->{methodName};
       print "\nHandling $methodName...\n";

       # DEBUGGING
       #print "Calling document:\n" . $xml . "\n";

       # Call the (super-)super-class handle() method
       $self->SOAP::Transport::HTTP::Server::handle;

       # Grab the response from the super-class and modify this to remove
       # the SOAP::Lite generated line that looks like,
       #
       # <param><value><string>registerResponse</string></value></param>
       #
       my $content = $self->response( )->{_content};
       $methodName =~ m/\.(\w*)$/;
       $content =~ s/<param><value><string>$1Response<\/string><\/value><\/param>//;
       $self->response( )->{_content} = $content;

       # DEBUGGING
       #print "Calling document:\n" . $content . "\n";

       $c->send_response($self->response);
     }
     $c->close;
  }
}

