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
setup dunetpc v05_07_00 -q e9:prof

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
example=$DHDIR/exampleSlice.json

cd $rdir

ls | grep lbne_r | grep '.root$' | while read root
do

    json=$root.json

  # If this .json file already exist, skip this file.

    if [ -f $json ]; then
	echo "$json already exists, so deleting it"
	rm -f *.json
    fi
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
    
    echo "Got all my parameters"

    egrep -v 'file_name|file_size|event_count|last_event|runs' $example | \
	awk '{print $0}/^{ *$/{printf "  \"file_name\": \"%s\",\n  \"file_size\": %d,\n  \"event_count\": %d,\n  \"last_event\": %d,\n  \"runs\": [ [ %d, \"test\" ] ],\n",'"\"$root\",${size},${nev},${nev},${run}}" > Tempjson1.txt
    
    echo "Next step"

    if [ $? -ne 0 ]; then
        mv $root $fdir
	echo "$0 Failed to replace metadata for $root"
	mv $json $fdir/$json.failed
	continue
    fi
    
    echo "Now to set the parent files"

    Myrun=$run
    while [ ${#Myrun} -ne 6 ]; 
    do
	Myrun="0"$Myrun
    done
    echo '"parents": [' > TempParent1.txt
    samweb list-definition-files rawdata35t_run_$Myrun >> TempParent2.txt
    cat TempParent1.txt TempParent2.txt > TempParent3.txt
    lines=$(wc -l < "TempParent3.txt")
    echo "TempParent3.txt has $lines lines"
    sed 's/lbne/{"file_name": "lbne/' TempParent3.txt > TempParent4.txt
    sed 's/.root/.root"},/' TempParent4.txt > TempParent5.txt
    sed -e "$lines s/,/\n],/" < TempParent5.txt > Tempjson2.txt
    
    echo "Done the parent file"

    $DHDIR/dbjson.py $run >> Tempjson3.txt
    cat Tempjson1.txt Tempjson2.txt Tempjson3.txt > $json
    rm Temp*
    if [ $? -ne 0 ]; then
	mv $root $fdir
	echo "$0 Failed to query online database for $root"
	mv $json $fdir/$json.failed
	continue
   fi
    
    echo "Done all I'm happy to do so far......"


    echo "Declaring metadata to SAM: $json"
    samweb -e lbne declare-file --cert=/dune/app/home/dunepro/trj/service_cert_dec9_2015/duneprocert_dec2015.pem --key=/dune/app/home/dunepro/trj/service_cert_dec9_2015/duneprokey_dec2015.pem $json
    echo "Tried to declare"
    if [ $? -ne 0 ]; then
    	mv $root $fdir
    	echo "$0 Failed to declare metadata to SAM"
    	mv $json $fdir/$json.failed
    	continue
    fi
    echo "Finished declaring $json"
    
    mv $root /pnfs/lbne/scratch/lbnepro/dropbox/data/
    echo "Moved $root to dropbox"

    rm -f TempRunning.txt
    RunningFile=/dune/data2/users/warburton/AutoSlice/GoodFileList/RunningList.txt
    echo "$root $size $run $nev" >> $filelistdir/GoodFileList.txt
    printf "%06d\n" $run >> $RunningFile
    sort --version-sort $RunningFile > TempRunning.txt
    uniq -u TempRunning.txt > $RunningFile
    rm -f TempRunning.txt
    echo "Removed $run from the Running File List in $RunningFile"
        
done


