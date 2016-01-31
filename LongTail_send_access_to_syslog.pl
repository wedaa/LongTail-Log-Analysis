#!/usr/bin/perl
    use Sys::Syslog qw( :DEFAULT setlogsock );

    setlogsock('unix');
    openlog('LongTail_apache', 'pid', 'auth');

    while ($log = <STDIN>) {
                syslog('notice', $log);
    }
    closelog;
