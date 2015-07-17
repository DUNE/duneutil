#! /bin/bash
#------------------------------------------------------------------
#
# Name: make_json.sh
#
# Purpose: Using an initial .json sam metadata file as an example,
#          make additional metadata files for all .root files in a
#          directory.
#
# Usage: 
#
# make_json.sh <example-json-file>
#
# Qizhong Li
#------------------------------------------------------------------

# Help function.

function dohelp {
  echo "Usage: make_json.sh <example-json-file>"
}

# Parse arguments.

if [ $# -eq 0 ]; then
  dohelp
  exit
fi

example=''

while [ $# -gt 0 ]; do
  case "$1" in

    # Help.
    -h|--help )
      dohelp
      exit
      ;;

    # Example .json file.
    * )
      if [ x$example = x ]; then
        example=$1
      else
        echo "Too many arguments."
        dohelp
        exit 1
      fi

  esac
  shift

done

# Make sure example file exists.

if [ ! -f $example ]; then
  echo "Example file $example does not exist."
  exit 1
fi

# Loop over .root files.

ls | grep '.root$' | while read root
do

  # Construct the name of the .json file corresponding to this root file.

  json=${root}.json

  # If this .json file already exist, skip this file.

  if [ -f $json ]; then
    echo "$json already exists."
  else
    echo "Making $json."

    # Get the size in bytes of this root file.

    size=`stat -c %s $root`

    # Get number of events.

    nev=`echo "Events->GetEntriesFast()" | root -l $root 2>&1 | tail -1 | cut -d')' -f2`

    # Get the run number.

    run=`echo $root | cut -d_ -f2 | cut -c2- | awk '{printf "%d\n",$0}'`

    # Generate new .json file using example.

    egrep -v 'file_name|file_size|event_count|last_event|runs' $example | \
      awk '{print $0}/^{ *$/{printf "  \"file_name\": \"%s\",\n  \"file_size\": %d,\n  \"event_count\": %d,\n  \"last_event\": %d,\n  \"runs\": [ [ %d, \"test\" ] ],\n",'"\"$root\",${size},${nev},${nev},${run}}" > $json
  fi

done
