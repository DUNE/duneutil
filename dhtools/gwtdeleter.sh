#!/bin/sh

scriptdir=/home/lbnedaq/trj

localdonedir=/data/lbnedaq/data/transferred_files
localjsonarchive=/data/lbnedaq/data/metadata_forstoredfiles

source $scriptdir/senv.sh

cd $localdonedir

for filename in `find . -mtime +2 -name "*.root"`
do
  fbase=`basename $filename`
  samlocation=`samweb -e lbne locate-file $fbase`
  if [ $? -ne 0 ]
  then
    continue
  fi
  if [[ $samlocation == enstore* ]]
  then
    echo "Found location in enstore: " $samlocation
    echo "Deleting " $filename
    rm -f $filename
    mv -v ${fbase}.json $localjsonarchive
  else
    echo "Did not find location in enstore: " $samlocation
  fi
done
