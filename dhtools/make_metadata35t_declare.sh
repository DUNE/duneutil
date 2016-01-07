#!/bin/bash

#------------------------------------------------------------------
#                                                                  
# Name: make_metadata_35t.sh
#                                                                  
# Purpose: Using an initial .json sam metadata file as an example, 
#          make additional metadata files for all .root files in a 
#          directory.                                              
#                                                                  
# Usage:                                                           
#                                                                  
# make_metadata35t.sh <rootfiledirectory> <failedfiledirectory>
# if the metadata extraction procedure fails, then move the rootfile to the failedfiledirectory
#                                                                  
# Tom Junk, using the make_json.sh example from Qizhong Li                                                       
#------------------------------------------------------------------

source /grid/fermiapp/products/dune/setup_dune.sh
setup dunetpc v04_29_00 -q e9:prof

rdir=''
fdir=''
DHDIR=''
filelistdir=''

function dohelp {
    echo "Usage: make_metadata35t_declare.sh <rootfiledirectory> <failedfiledirectory> <dirtofindexamplejson> <dirforfilelist>"
}

# Parse arguments.

if [ $# -eq 0 ]; then
    dohelp
    exit
fi

if [ $1 = "--help" ]; then
    dohelp
    exit
fi

if [ $# -eq 4 ]; then
    rdir=$1
    fdir=$2
    DHDIR=$3
    filelistdir=$4
fi
example=$DHDIR/example2.json

cd $rdir

ls | grep lbne_r | grep '.root$' | while read root
do

    json=$root.json

  # If this .json file already exist, skip this file.

    if [ -f $json ]; then
	echo "$json already exists."
    else
	echo "Making $json."


	size=`stat -c %s $root`
	if [ $? -ne 0 ]; then
	    mv $root $fdir
	    echo "$0 Failed to get filesize for $root"
	    continue
	fi

	nev=`echo "Events->GetEntriesFast()" | root -l -b $root 2>&1 | tail -1 | cut -d')' -f2`
	if [ $? -ne 0 ]; then
	    mv $root $fdir
	    echo "$0 Failed to get event count for $root"
	    continue
	fi

	run=`echo $root | cut -d_ -f2 | cut -c2- | awk '{printf "%d\n",$0}'`
	if [ $? -ne 0 ]; then
	    mv $root $fdir
	    echo "$0 Failed to get run number for $root"
	    continue
	fi


	egrep -v 'file_name|file_size|event_count|last_event|runs' $example | \
	    awk '{print $0}/^{ *$/{printf "  \"file_name\": \"%s\",\n  \"file_size\": %d,\n  \"event_count\": %d,\n  \"last_event\": %d,\n  \"runs\": [ [ %d, \"test\" ] ],\n",'"\"$root\",${size},${nev},${nev},${run}}" > $json

	if [ $? -ne 0 ]; then
	    mv $root $fdir
	    echo "$0 Failed to replace metadata for $root"
	    mv $json $fdir/$json.failed
	    continue
	fi


	$DHDIR/dbjson.py $run >> $json
	if [ $? -ne 0 ]; then
	    mv $root $fdir
	    echo "$0 Failed to query online database for $root"
	    mv $json $fdir/$json.failed
	    continue
	fi
    echo "$root $size $run $nev" >> $filelistdir/filelist.txt
    echo "Declaring metadata to SAM: $json"
# old certificate -- switch to new one Dec. 11, 2015
#    samweb -e lbne declare-file --cert=${DHDIR}/duneprocert.pem --key=${DHDIR}/duneprokey.pem $json
    samweb -e lbne declare-file --cert=${DHDIR}/duneprocert_dec2015.pem --key=${DHDIR}/duneprokey_dec2015.pem $json
    echo "Finished declaring $json"
    fi

done


