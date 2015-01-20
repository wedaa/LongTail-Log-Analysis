README for LongTail Log Analysis.
==============

Licensing
--------------
LongTail is a messages and access_log analyzer

Copyright (C) 2015 Eric Wedaa

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

What LongTail does
--------------
Longtail analyzes your /var/log/messages files to report on 
the ssh attacks against your server.  LongTail pre-supposes
that you have compiled your own openssh daemon as described
below.

LongTail also analyzes your /var/log/httpd/access_log files
to analyze the attacks and probes that your webserver is
subject to.

LongTail is for small (1 server)  to medium size (50 servers)
organizations.  If you have a large organization, then you'll 
probably have too much data to be analyzed.  Of course if you
run this on larger installations and it works, please let me
know so I can increase this number.

Installation
--------------
Edit /usr/local/etc/LongTail for the locations of your 
/var/log/messages and /var/log/httpd/access_log files.

Edit /usr/local/etc/LongTail for the location of your 
/honey directory (or whatever you call the directory
you want your reports to go to.

Copy index.html to the $HTML_DIR/honey directory.

Edit /usr/local/etc/LongTail-exclude-accounts.grep to
add your valid local accounts.  This will exclude these
accounts from your reports.  (You wouldn't want to have
your password or account name showing up in your reports,
now would you?)

Edit /usr/local/etc/LongTail-exclude-IPs.grep to
add your local IP addresses.  This will exclude these
IPs from your reports.  (You wouldn't want to have
your personal or work IPs exposed in your reports,
now would you?)

Copy the files to /usr/local/etc (Or wherever).  See
install.sh for details.  You need to edit that before 
running it.

Download a copy of openssh from http://www.openssh.com/portable.html#ftp
Untar the file and modify auth-passwd.c to add the 
following line to the auth_password function(See the
included auth-passwd.c file for exact placing) :
 logit("PassLog: Username: %s Password: %s", authctxt->user, password);

Then configure, make, and install openssh on your server.
I assume since you're interested in HoneyPots, you 
know your OS well enough to do this.

Run LongTail by hand as the account you want it to run
as to make sure it works.  (And that it can write to 
the /honey directory.)

Add a crontab entry like this one:
59 * * * * /usr/local/etc/LongTail >> /tmp/LongTail.out 2>> /tmp/LongTail.out

