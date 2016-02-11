README for LongTail Log Analysis.
==============

WARNING
--------------
LongTail honeypots are stable now.

LongTail is "easy" to install, but is "non-trivial" to install.
AGAIN: Reasonable system administration skills are
required to run and install this software.

Licensing
--------------
LongTail is a /var/log/messages and access_log analyzer

Copyright (C) 2015,2016 Eric Wedaa

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


New SSHD Installation, The Easy Way
--------------
RHEL -- Make sure you have zlib-devel and openssl-devel installed on your
system (plus make, gcc, etc).  (The following commands are for 
RHEL, CentOS, Fedora Core.)

	yum install zlib-devel # For the openssh honeypot
	yum install openssl-devel # For the openssh honeypot
	yum install policycoreutils-python # This gives you semanage

BEAGLEBONE BLACK, rev C (Based on Debian Wheezy) -- All the packages 
required are allready installed on the BeagleBone.

RASPBERRY PI (Based on Debian) -- I am working on this.

	apt-get install libssl-dev

The EASY way: Run install_openssh.sh from the repository.  It
will download openssh, modifiy the appropriate source files,
make and install it into /usr/local/{sbin,etc}, and add startup
lines in /etc/rc.local.

You should run a "real" sshd on some very high 
number port so that you can ssh into your server and not have 
your account and password show up in the log files.  You can 
use your default /etc/ssh/sshd_config file to reset your port 
number.

You also need to run the following selinux commands if you have
selinux installed

	semanage port -a -t ssh_port_t -p tcp 2222
	semanage port -a -t ssh_port_t -p tcp <Whatever your big port # is>
	semanage port -l | grep ssh # Shows ssh ports


LongTail HTTP Honeypot setup
--------------
As of January 2016, LongTail now can analyze requests to an Apache
http honeypt.

LongTail currently uses the Apache httpd server as the honeypot.  The 
current requirement is that there is only a single index.html file
that you need to create yourself (which can be as simple as 
"<HTML><BODY>This is my webserver" in order to track down which 
IP addresses are doing blind attacks against webservers.  As LongTail 
version 2 is completed, a separate set of downloadable webpages 
is planned for development in order to attrack better attacks, payload
delivery mechanisms, and malware.

You will need to copy the perl script "LongTail_send_access_to_syslog.pl"
to your webserver machine, preferrably in /usr/local/etc and do a 
  chmod a+rx /usr/local/etc/LongTail_send_access_to_syslog.pl

You will also need to install the perl syslog module with:
  cpan Sys::Syslog

And lastly, you need to add the following line to your httpd.conf file
  #CustomLog "logs/access_log" combined # Install LongTail line AFTER this line
  CustomLog |/usr/local/etc/LongTail_send_access_to_syslog.pl combined

And then restart apache so the change takes effect.  You can test it
by pointing your browser of choice to you honeypot, and then checking
you /var/log/messages file to make sure that the request was logged to syslog.



Running rsyslog
--------------
0) PLEASE NOTE: After you have done all the following to reconfigure
your rsyslog server, you will need to stop rsyslog, delete or move
the current /var/log/messages file, and then restart rsyslog.  This
is because LongTail makes sure that the date format is correct before
trying to analyze the data.

1) This has only been tested using rsyslog.  Not syslog, not
syslog-ng.  I assume they will work too.

2) You must use the following line in your honeypot's (and if you are
using a consolidation server's ) rsyslog.conf file.

	$ActionFileDefaultTemplate RSYSLOG_FileFormat

3) If you are also logging to a remote host, and you are using 
a port OTHER than 514, AND you are running selinux, make sure
you remember to run this command on BOTH hosts

	semanage port -a -t syslogd_port_t -p tcp NewPortNumber

4) This is the line I use on my honeypot to report to my consolidation
master:

	auth.* @@#.#.#.#:####

where #.#.#.# is the IP address of the receiving host and #### is the
TCP Port where rsyslog is listening on the receiving host.  This way
we are only sending SSH messages to the remote host, instead of
filling it's logs with ALL the messages from the honeypot.

5) Make sure you are using the lines in the rsyslog.conf file to 
enable Reliable syslog reporting.

	$WorkDirectory /var/lib/rsyslog # where to place spool files
	$ActionQueueFileName fwdRule1 # unique name prefix for spool files
	$ActionQueueMaxDiskSpace 1g   # 1gb space limit (use as much as possible)
	$ActionQueueSaveOnShutdown on # save messages to disk on shutdown
	$ActionQueueType LinkedList   # run asynchronously
	$ActionResumeRetryCount -1    # infinite retries if host is down

6) Sometimes data gets lost in transmission between clients and the
consolidation server.  I have no idea why.  I have to figure out a
better way of consolidating messages files between hosts and then
re-running reports against the "Better" data.  This has been seen 
a few times unfortunately and the answer seems to be restarting 
rsyslog ON THE CONSOLIDATION SERVER via cron every night at 11:00 pm.  
(11 pm so that the remote hosts have time to dump any stored data to 
the consolidation server.)  (This does not need to be done on any of 
the honeypot servers.)

WARNING About System Hostnames
--------------

System hostnames (as reported by the hostname command) should NOT be
fully qualified, and MUST NOT include "-" (dash) characters.  I create
files with hostnames in them and use the "." and "-" characters as
delimeters.  Fully qualified hostnames are bad also (longtail is good,
longtail.it.marist.edu is BAD!).

