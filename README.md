perl-Astro-VO-SAMP
==================

A SAMP implementation in Perl.

The code comes with no guarantees except there will be horrendous bugs. There is no documentation. Many of the Perl modules have inline POD, however most of it didn't keep up with the pace of development so it's out of date. However, once you install the additional modules, open up a terminal window and start the Hub as follows,

    % ./samp_hub.pl

you can put the Hub through its paces by opening up two more terminal windows and running the testbed clients. You should start the listener client in all cases,

    % ./listener_client.pl

this is the test client that listens for notify( ) and call( )'s from the Hub. In the second window you can either start the client that exercises the notify( ) method, or the other than exercises the call( ) method. So

    % ./callAll_test.pl

or

    % ./notifyAll_test.pl

These two clients have a heart beat which will dispatch a call or a notification periodically. The first heartbeat will happen 15 seconds (or so) after the client has completed its registering with the Hub.

_**Note:** This code is out of date, it was last touched back in 2008. It will need work to bring it back into line with the [current standard](http://www.ivoa.net/documents/SAMP/). Amongst other things the current implementation lacks callAndWait( ) functionality._

_However if you want to get your feet dirty ahead of that, you'll need the following Perl modules installed: XMLRPC::Lite (part of the SOAP::Lite module), XML::Simple, DateTime, File::Spec, Carp, Data::Dumper, Getopt::Long, Socket, Net::Domain, POSIX and Errno. Depending on your version of Perl some, but not all, of these will ship with the core distribution._

##License

This software has been released under the MIT License (MIT)

Copyright (c) 2008 Alasdair Allan

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
