#!/bin/sh
# This is an example wrapper program for you to use if you
# are monitoring more than just ssh and/or want to break out
# statistics by server.
#
# This example monitors all hosts, and then breaks out statistics
# for hosts named erhp, erhp2, and shepherd
#
# Please note the use of "-midnight" in the section for $START_HOUR -eq 0 
# This is because when you have 60 million data points, the midnight
# scripts can take more than an hour running on LongTail V1.5.  This
# will be fixed in LongTail V2.0

function print_divider {
	echo ""
	echo "================================================================"
	echo ""
}

print_divider
START_HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
if [ $START_HOUR -eq 0 ]; then
	echo "It's MIDNIGHT, running midnight scripts"
	date; /usr/local/etc/LongTail.sh -protocol http -midnight ; print_divider # This runs first since it's fastest
	date; /usr/local/etc/LongTail.sh -protocol 2222 -midnight ; print_divider # This runs first since it's fastest
	date; /usr/local/etc/LongTail.sh -protocol ssh  ; print_divider # This should still run at midnight
	date; /usr/local/etc/LongTail.sh -protocol ssh -host erhp -midnight ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh -host erhp2 -midnight ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh -host shepherd -midnight ; print_divider

	date; /usr/local/etc/LongTail.sh -protocol 2222 -host shepherd -midnight ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol 2222 -host erhp -midnight ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol 2222 -host erhp2 -midnight ; print_divider
else
	date; /usr/local/etc/LongTail.sh -protocol http ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh -host erhp ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh -host erhp2 ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol ssh -host shepherd ; print_divider

	date; /usr/local/etc/LongTail.sh -protocol 2222  ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol 2222 -host shepherd ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol 2222 -host erhp ; print_divider
	date; /usr/local/etc/LongTail.sh -protocol 2222 -host erhp2 ; print_divider
fi

