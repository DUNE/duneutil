#! /bin/bash
#----------------------------------------------------------------------
#
# Name: make_xml_35tdata.sh
#
# Purpose: Make xml files for 35tdata.
#
# Usage:
#
# make_xml_35tdata.sh [-h|--help] --run <run> [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>]
#
# Options:
#
# -h|--help         - Print help.
# --run             - Specify the run number.
# -r <release>      - Use the specified larsoft/dunetpc release.
# -u|--user <user>  - Use users/<user> as working and output directories
#                     (default is to use dunepro).
# --local <dir|tar> - Specify larsoft local directory or tarball (xml 
#                     tag <local>...</local>).
# --nev <n>         - Specify number of events for all samples.  
#                     Otherwise use hardwired defaults.
#
#----------------------------------------------------------------------

# Parse arguments.

run=''
rel=v04_34_00
userdir=dunepro
userbase=$userdir
nev=-1
local=''

while [ $# -gt 0 ]; do
  case "$1" in

    # User directory.

    -h|--help )
      echo "Usage: make_xml_mcc.sh [-h|--help] --run <run> [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] "
      exit
    ;;

    # Run

    --run )
    if [ $# -gt 1 ]; then
      run=$2
      shift
    fi
    ;;


    # Release.

    -r )
    if [ $# -gt 1 ]; then
      rel=$2
      shift
    fi
    ;;

    # User.

    -u|--user )
    if [ $# -gt 1 ]; then
      userdir=users/$2
      userbase=$2
      shift
    fi
    ;;

    # Local release.

    --local )
    if [ $# -gt 1 ]; then
      local=$2
      shift
    fi
    ;;

    # Total number of events.

    --nev )
    if [ $# -gt 1 ]; then
      nev=$2
      shift
    fi
    ;;

    # Number of events per job.

    --nevjob )
    if [ $# -gt 1 ]; then
      nevjobarg=$2
      shift
    fi
    ;;

  esac
  shift
done

# Get qualifier.

qual=e9

# Delete existing xml files.

#rm -f *.xml
newprj=run${run}
newxml=run${run}.xml

rm -f newxml

slicefcl=RunSplitterDefault.fcl

kx509
samweb delete-definition rawdata35t_run_${run}
samweb create-definition rawdata35t_run_${run} "run_number=${run} and data_tier=raw and lbne_data.detector_type like 35t"

cat <<EOF > $newxml
<?xml version="1.0"?>

<!-- Production Project -->

<!DOCTYPE project [
<!ENTITY release "$rel">
<!ENTITY file_type "data">
<!ENTITY run_type "physics">
<!ENTITY name "$newprj">
<!ENTITY tag "35tdata">
]>

<project name="&name;">

  <!-- Group -->
  <group>dune</group>

  <!-- Project size -->
  <numevents>$nev</numevents>

  <!-- Operating System -->
  <os>SL6</os>

  <!-- Batch resources -->
  <resource>DEDICATED,OPPORTUNISTIC</resource>

  <!-- Larsoft information -->
  <larsoft>
    <tag>&release;</tag>
    <qual>${qual}:prof</qual>
EOF
  echo "local=$local"
  if [ x$local != x ]; then
    echo "    <local>${local}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <!-- Project stages -->

  <stage name="slice">
    <fcl>$slicefcl</fcl>
    <inputdef>rawdata35t_run_${run}</inputdef>
    <outdir>/pnfs/dune/scratch/${userdir}/&release;/slice/&name;</outdir>
    <workdir>/dune/app/users/${userbase}/work/&release;/slice/&name;</workdir>
    <numjobs>1</numjobs>
    <datatier>sliced</datatier>
    <defname>&name;_&tag;_slice</defname>
  </stage>

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>

EOF

