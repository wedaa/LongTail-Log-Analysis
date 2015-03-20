#!/bin/sh
# This is an example script of how to deal with 
# multiple hosts reporting.  We do it this way
# for now until I can figure out how to do it 
# properly in a config file AND account for hosts
# no longer reporting.
/usr/local/etc/LongTail.sh shepherd
/usr/local/etc/LongTail.sh erhp
/usr/local/etc/LongTail.sh erhp2
/usr/local/etc/LongTail.sh syrtest
/usr/local/etc/LongTail.sh 
