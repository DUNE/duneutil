#! /bin/bash
#------------------------------------------------------------------
#
# Name: declare_files.sh
#
# Purpose: Declare all .json files in the current directory.
#
# Usage: 
#
# declare_files.sh
#
# Qizhong Li
#------------------------------------------------------------------

for json in *.json
do
  echo "Declaring $json"
  samweb -e lbne declare-file $json
done
