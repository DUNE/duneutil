#!/bin/sh

# creates metadata for one or more iceberg raw data files.  Puts JSON files in the
# current working directory.

# invoke this as iceberg_metadata.sh <input>
# where <input> is a file path, or a directory.  It is the input to a find command

function iceberg_metadata_single_file {

CFNAME=`mktemp`
config_dumper -P $1 | sed -e "s/\\\n/\n/g" > ${CFNAME}

TMPMD=`mktemp`
sam_metadata_dumper $1 > ${TMPMD}

CMPFILE=`mktemp`
grep Component $CFNAME | awk '{print $3}' > $CMPFILE

gain=`grep "gain:" $CFNAME | head -1 | awk '{print $2}'`
shapetime=`grep "peak_time:" $CFNAME | head -1 | awk '{print $2}'`
accouple=`grep "ac_couple:" $CFNAME | head -1 | awk '{print $2}'`
baselineHigh=`grep "baseline:" $CFNAME | head -1 | awk '{print $2}'`
leakHigh=`grep "leak:" $CFNAME | head -1 | awk '{print $2}'`
leak10x=`grep "leak_10x:" $CFNAME | head -1 | awk '{print $2}'`
if [[ ${leak10x} = false ]]; then
  leak10x=0
else
  leak10x=1
fi
pulsemode=`grep "enable_pulser:" $CFNAME | head -1 | awk '{print $2}'`
if [[ ${pulsemode} = false ]]; then
  pulsemode=0
else
  pulsemode=1
fi
configname=`grep "Config name:" $CFNAME | head -1 | awk '{print $3}'`

runno=`grep first_event $TMPMD | head -1 | awk '{print $3}' | sed -e "s/,//g"`
firstevent=`grep first_event $TMPMD | head -1 | awk '{print $5}'`
lastevent=`grep last_event $TMPMD | head -1 | awk '{print $5}'`
eventcountline=`grep event_count $TMPMD | head -1 | sed -e "s/,//g"`
starttimeline=`grep start_time $TMPMD | head -1 | sed -e "s/,//g"`
endtimeline=`grep end_time $TMPMD | head -1 | sed -e "s/,//g"`

echo "{"
echo \ \"file_name\": \"`basename $1`\",
echo \ \"file_type\": \"detector\",
echo \ \"data_tier\": \"raw\",
echo \ \"file_size\": `stat -c%s $1`,
echo \ ${starttimeline},
echo \ ${endtimeline},
echo \ ${eventcountline},
echo \ \"first_event\": ${firstevent},
echo \ \"last_event\": ${lastevent},
echo \ \"runs\": [
echo \ \ [
echo \ \ ${runno},
echo \ \ 1,
echo \ \ \"iceberg\"
echo \ \ ]
echo \ ],
echo \ \"DUNE.campaign\": \"iceberg\",
echo \ \"data_stream\": \"cosmics\",
echo \ \"DUNE_data.fegain\": ${gain},
echo \ \"DUNE_data.feshapingtime\": ${shapetime},
echo \ \"DUNE_data.acCouple\": ${accouple},
echo \ \"DUNE_data.febaselineHigh\": ${baselineHigh},
echo \ \"DUNE_data.feleakHigh\": ${leakHigh},
echo \ \"DUNE_data.feleak10x\": ${leak10x},
echo \ \"DUNE_data.calibpulsemode\": ${pulsemode},
echo \ \"DUNE_data.DAQConfigName\": \"${configname}\",
cat $CMPFILE | 
{
while read line2
do
  if [ "$components" = "" ]; then
    components=$line2
  else
    components=${line2}:${components}
  fi
done
  echo \ \"DUNE_data.detector_config\": \"${components}\"
}
echo "}"

rm ${CFNAME}
rm ${TMPMD}
rm ${CMPFILE}

}

source /home/nfs/dunecet/offlsetup.sh
source /cvmfs/oasis.opensciencegrid.org/mis/osg-wn-client/current/el7-x86_64/setup.sh
setup_fnal_security

find $1 | grep iceberg | grep root | grep -v decode | grep -v json | grep -v anal | while read line
do
  echo Making metadata json for $line
  jsonfile=`basename $line`.json
  if [ -e $jsonfile ]; then
    echo $jsonfile already exists, not re-making it.
  else
    iceberg_metadata_single_file $line > $jsonfile
    samweb declare-file $jsonfile
  fi
  echo "mv'ing $line to the dropbox"
  mv $line /data1/dropbox/
done
