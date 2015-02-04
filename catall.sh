#!/bin/sh
# Stupid program so I can cat both normal files and gzipped files
while (( "$#" )); do
	#echo "$1"
	# Let cat and zcat complain about it :-)
	#if [ ! -r $1 ] ; then
	#	>&2 echo "Can't read $1"
	#	exit
	#fi
	case $1 in
		*bz2)
			bzcat $1
		;;
		*bz)
			bzcat $1
		;;
		*gz)
			zcat $1
		;;
		*)
			cat $1
		;;
		esac
	shift
done
