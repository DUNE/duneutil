#!/bin/sh

scriptdir=/home/lbnedaq/trj
remotenode=lbnedaq6
dirtoclean=/storage/data/transferred

source $scriptdir/senv.sh

cd $localdonedir

for filename in `ssh lbnedaq@${remotenode} find ${dirtoclean} -mtime +3 -name *.root`
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
    ssh lbnedaq@${remotenode} rm -f $filename
  else
    echo "Did not find location in enstore: " $samlocation
    echo "Not deleting file: " $filename
  fi
done
