#!/bin/bash

# check to see if there's already another instance of this script running -- that is a process with
# the name but not being edited

scriptdir=/home/lbnedaq/trj
inputremoteuser=lbnedaq@lbnedaq6
inputremote=/storage/data
inputtransferred=/storage/data/transferred
localincomingdir=/data/lbnedaq/data/incoming_files
localtransdir=/data/lbnedaq/data/transferring_files
localdonedir=/data/lbnedaq/data/transferred_files
locallogdir=/data/lbnedaq/data/transfer_logs
localfaildir=/data/lbnedaq/data/failed_files
dropboxdir=/pnfs/lbne/scratch/lbnepro/dropbox/data
filelistdir=/data/lbnedaq/data/filelist

ntrylimit=10

myscriptname=`basename $0 .sh`
# echo $myscriptname

ps aux | grep ${myscriptname} | grep -v emacs | grep -v vim

numprocsp2=`ps aux | grep ${myscriptname} | grep -v emacs | grep -v vim |  wc -l`

# echo $numprocsp2

if [ $numprocsp2 -gt 3 ]; then
    exit 0
fi

# get our Kerberos ticket

#KEYTAB=/var/adm/krb5/`/usr/krb5/bin/kcron -f`
KEYTAB=/var/adm/krb5/lbnedaq.keytab
KEYUSE=`/usr/krb5/bin/klist -k ${KEYTAB} | grep FNAL.GOV | head -1 | cut -c 5- | cut -f 1 -d /`
/usr/krb5/bin/kinit -5 -A  -kt ${KEYTAB} ${KEYUSE}/dune/`hostname`@FNAL.GOV
#/usr/krb5/bin/kx509

phost=lbnedaq@lbnegpvm01.fnal.gov


for filename in `ssh ${inputremoteuser} ls ${inputremote}/lbne_r*.root | grep -v lbne_r-_sr-_`
do

    fbase=`basename $filename`
    for itry in `seq 1 $ntrylimit`
    do 

	remotechecksum=`ssh ${inputremoteuser} cksum ${filename}`
	checksumvalue_inputremote=`echo $remotechecksum | cut -f 1 -d " "`
	checksumsize_inputremote=`echo $remotechecksum | cut -f 2 -d " "`
	success=0

	scp -q ${inputremoteuser}:${filename} $localincomingdir/
	if [ $? -ne 0 ]
        then
            continue
	fi
	localchecksum=`cksum $localincomingdir/$fbase`
	checksumvalue_inputlocal=`echo $localchecksum | cut -f 1 -d " "`
	checksumsize_inputlocal=`echo $localchecksum | cut -f 2 -d " "`

	echo $fname
	echo $checksumvalue_inputlocal
	echo $checksumvalue_inputremote
	echo $checksumsize_inputlocal
	echo $checksumsize_inputremote

	if [ $checksumvalue_inputlocal -eq $checksumvalue_inputremote ]
        then
          if [ $checksumsize_inputlocal -eq $checksumsize_inputremote ]
          then
	    echo "Succeeded in copying $fbase"
	    mv -v $localincomingdir/$fbase $localtransdir
	    ssh $inputremoteuser mv $filename $inputtransferred
	    success=1
	    break
	  fi
	fi
	if [ $success -ne 1 ]
	then
	    mv -v $localincomingdir/$fbase $localfaildir
	fi
    done
done

$scriptdir/make_metadata35t_declare.sh $localtransdir $localfaildir $scriptdir $filelistdir

# to update -- need to check the checksum and retry here if it fails
# only mv the file to the localdonedir if the copy succeded.  Otherwise we'll try again when
# this script runs again, leaving the file in the localtransdir
# consider using dccp here instead in order to get checksum validation

cd $localtransdir
for filename in `ls *.root`
do
  cp -v $filename $dropboxdir
  if [ $? -eq 0 ]
  then
    mv -v $filename $localdonedir
    mv -v $filename.json $localdonedir
  fi
done
