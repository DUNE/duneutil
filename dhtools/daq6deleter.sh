#!/bin/sh

scriptdir=/home/lbnedaq/trj
remotenode=lbnedaq6

# clean up transferred rootfiles from this directory

dirtoclean=/storage/data/transferred

# clean up unclosed files and stubs from this directory

dirtoclean2=/storage/data

source $scriptdir/senv.sh

for filename in `ssh lbnedaq@${remotenode} find ${dirtoclean} -mtime +3 -name lbne*.root`
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

# clean up empty stub files -- no run or subrun number

ssh lbnedaq@${remotenode} rm -f ${dirtoclean2}/lbne_r-_sr-_*.root

# clean up files that were not closed properly

for filename in `ssh lbnedaq@${remotenode} find ${dirtoclean2} -mtime +3 -name RootOutput*.root`
do
  rm -f $filename
done
