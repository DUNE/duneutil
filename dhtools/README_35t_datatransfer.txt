Scripts for transferring files from the 35t DAQ to the dropbox
in dCache, and making and declaring metadata are also included in this
directory.

The necessary scripts are 

dtranslog35t.sh
   which runs 
dtr35t1.sh
   and stores the logfile in 
/data/lbnedaq/data/transfer_logs/
   with one logfile per day, labeled with the date.

dtr35t1.sh calls
make_metadata35t_declare.sh which calls
dbjson.py to query the online database to look up 
some metadata fields for each run.

The file example2.json is a template of some of the metadata
with default values which make_metadata35t_declare.sh uses to
build the final metadata.

The sam metadata upload command needs a certificate and a key.
We have been using OSG grid certificates as they have a long
expiration date.

The files

dtranslog35t.sh
dtr35t1.sh
make_metadata35t_declare.sh
example2.json
dbjson.py

are installed in 
lbne35t-gateway02:/home/lbnedaq/trj

and this directory is settable with the variable scriptdir in
dtr35t1.sh.

The subdirectories

incoming_files
transferring_files
transferred_files
failed_files
filelist
transfer_logs

are assumed to exist in lbne35t-gateway02:/data/lbnedaq/data

The file runsumdbquery.py can be used at the command line to 
check the online database entry for a particular run.  It is not
used in the automatic file transfer/metadata generation scripts.

An example crontab entry for doing hourly transfers is:

0 * * * * /home/lbnedaq/trj/dtranslog35t.sh >> /dev/null
