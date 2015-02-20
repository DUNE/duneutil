#! /bin/bash
#----------------------------------------------------------------------
#
# Name: make_xml_mcc2.0.sh
#
# Purpose: Make xml files for mcc 2.0.  This script loops over all
#          generator-level fcl files in the source area of the currently 
#          setup version of lbnecode (that is, under 
#          $LBNECODE_DIR/source/fcl/lbne35t/gen), and makes a corresponding xml
#          project file in the local directory.
#
# Usage:
#
# make_xml_mcc2.0.sh [-h|--help] [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>] [--nevgjob <n>]
#
# Options:
#
# -h|--help     - Print help.
# -r <release>  - Use the specified larsoft/lbnecode release.
# -u|--user <user> - Use users/<user> as working and output directories
#                    (default is to use lbnepro).
# --local <dir|tar> - Specify larsoft local directory or tarball (xml 
#                     tag <local>...</local>).
# --nev <n>     - Specify number of events for all samples.  Otherwise
#                 use hardwired defaults.
# --nevjob <n>  - Specify the default number of events per job.
# --nevgjob <n> - Specify the maximum number of events per gen/g4 job.
#
#----------------------------------------------------------------------

# Parse arguments.

rel=v04_00_01
userdir=lbnepro
userbase=$userdir
nevarg=0
nevjob=0
nevgjobarg=0
local=''

while [ $# -gt 0 ]; do
  case "$1" in

    # User directory.

    -h|--help )
      echo "Usage: make_xml_mcc5.0.sh [-h|--help] [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>] [--nevgjob <n>]"
      exit
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
      nevarg=$2
      shift
    fi
    ;;

    # Number of events per job.

    --nevjob )
    if [ $# -gt 1 ]; then
      nevjob=$2
      shift
    fi
    ;;

    # Number of events per gen/g4 job.

    --nevgjob )
    if [ $# -gt 1 ]; then
      nevgjobarg=$2
      shift
    fi
    ;;

  esac
  shift
done

# Get qualifier.

qual=e5
ver=`echo $rel | cut -c2-3`
if [ $ver -gt 2 ]; then
  qual=e6
fi

# Delete existing xml files.

rm -f *.xml

find $LBNECODE_DIR/source/fcl/lbne35t/gen -name \*.fcl | while read fcl
do
  if ! echo $fcl | grep -q common; then
    newprj=`basename $fcl .fcl`
    newxml=${newprj}.xml
    filt=1
    generator=SingleGen
    if echo $newprj | grep -q cosmics; then
      generator=CRY
    fi
    if echo $newprj | grep -q AntiMuonCutEvents; then
      generator=TextFileGen
    fi
    
    # Make xml file.

    echo "Making ${newprj}.xml"

    # Generator

    genfcl=`basename $fcl`

    # G4

    g4fcl=standard_g4_lbne35t.fcl

    # Detsim (optical + tpc).

    detsimfcl=standard_detsim_lbne35t.fcl
    if echo $newprj | grep -q milliblock; then
      detsimfcl=standard_detsim_lbne35t_milliblock.fcl
    fi
    # Reco 2D

#    reco2dfcl=standard_reco_uboone_2D.fcl

    # Reco 3D

#    reco3dfcl=standard_reco_uboone_3D.fcl

    # Reco
    recofcl=standard_reco_lbne35t.fcl
    if echo $newprj | grep -q milliblock; then
      recofcl=standard_reco_lbne35t_milliblock.fcl
    fi

    # Merge/Analysis

    mergefcl=standard_ana_lbne35t.fcl

    # Set number of events per job.
    if [ $nevjob -eq 0 ]; then
      if [ $newprj = prodcosmics_lbne35t_milliblock ]; then
        nevjob=100
      elif [ $newprj = prodcosmics_lbne35t_onewindow ]; then
	nevjob=100
      elif [ $newprj = AntiMuonCutEvents_LSU_lbne35t ]; then
	nevjob=100
      else
        nevjob=100
      fi
    fi
    # Set number of gen/g4 events per job.

    nevgjob=$nevgjobarg
    if [ $nevgjob -eq 0 ]; then
      if echo $newprj | grep -q dirt; then
        if echo $newprj | grep -q cosmic; then
          nevgjob=200
        else
          nevgjob=2000
        fi
      else
        nevgjob=nevjob
      fi
    fi

    # Set number of events.

    nev=$nevarg
    if [ $nev -eq 0 ]; then
      if [ $newprj = prodcosmics_lbne35t_milliblock ]; then
        nev=1000
      elif [ $newprj = prodcosmics_lbne35t_onewindow ]; then
	nev=10000
      elif [ $newprj =  AntiMuonCutEvents_LSU_lbne35t ]; then
	nev=10000
      else
        nev=10000
      fi
    fi
    nev=$(( $nev * $filt ))

    # Calculate the number of worker jobs.

    njob1=$(( $nev / $nevgjob ))         # Pre-filter (gen, g4)
    njob2=$(( $nev / $nevjob / $filt ))  # Post-filter (detsim and later)
    if [ $njob1 -lt $njob2 ]; then
      njob1=$njob2
    fi

  cat <<EOF > $newxml
<?xml version="1.0"?>

<!-- Production Project -->

<!DOCTYPE project [
<!ENTITY release "$rel">
<!ENTITY file_type "mc">
<!ENTITY run_type "physics">
<!ENTITY name "$newprj">
<!ENTITY tag "mcc2.0">
]>

<project name="&name;">

  <!-- Group -->
  <group>lbne</group>

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

  <!-- lbne35t metadata parameters -->

  <parameter name ="MCName">${newprj}</parameter>
  <parameter name ="MCDetectorType">35t</parameter>
  <parameter name ="MCGenerators">${generator}</parameter>

  <!-- Project stages -->

  <stage name="gen">
    <fcl>$genfcl</fcl>
EOF
  if echo $newprj | grep -q AntiMuonCutEvents_LSU_lbne35t; then
      echo "    <inputmode>textfile</inputmode>" >> $newxml
      echo "    <inputlist>/lbne/data2/users/jti3/txtfiles/AntiMuonCutEvents_LSU_100.txt</inputlist>" >> $newxml
  fi
  cat <<EOF >> $newxml
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/gen/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/gen/&name;</workdir>
    <logdir>/lbne/data/${userdir}/log/&release;/gen/&name;</logdir>
    <output>${newprj}_\${PROCESS}_%tc_gen.root</output>
    <numjobs>$njob1</numjobs>
    <datatier>generated</datatier>
    <defname>&name;_&tag;_gen</defname>
  </stage>

  <stage name="g4">
    <fcl>$g4fcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/g4/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/g4/&name;</workdir>
    <logdir>/lbne/data/${userdir}/log/&release;/g4/&name;</logdir>
    <numjobs>$njob1</numjobs>
    <datatier>simulated</datatier>
    <defname>&name;_&tag;_g4</defname>
  </stage>

EOF
  if [ x$detsimfcl != x ]; then
    cat <<EOF >> $newxml
  <stage name="detsim">
    <fcl>$detsimfcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/detsim/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/detsim/&name;</workdir>
    <logdir>/lbne/data/${userdir}/log/&release;/detsim/&name;</logdir>
    <numjobs>$njob2</numjobs>
    <datatier>detector-simulated</datatier>
    <defname>&name;_&tag;_detsim</defname>
  </stage>

EOF
  fi
  if [ x$optsimfcl != x ]; then
    cat <<EOF >> $newxml
  <stage name="optsim">
    <fcl>$optsimfcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/optsim/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/optsim/&name;</workdir>
    <numjobs>$njob2</numjobs>
    <datatier>optical-simulated</datatier>
    <defname>&name;_&tag;_optsim</defname>
  </stage>

EOF
  fi
  if [ x$tpcsimfcl != x ]; then
    cat <<EOF >> $newxml
  <stage name="tpcsim">
    <fcl>$tpcsimfcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/tpcsim/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/tpcsim/&name;</workdir>
    <numjobs>$njob2</numjobs>
    <datatier>tpc-simulated</datatier>
    <defname>&name;_&tag;_tpcsim</defname>
  </stage>

EOF
  fi
  cat <<EOF >> $newxml
  <stage name="reco">
    <fcl>$recofcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/reco/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/reco/&name;</workdir>
    <logdir>/lbne/data/${userdir}/log/&release;/reco/&name;</logdir>
    <numjobs>$njob2</numjobs>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;_reco</defname>
  </stage>

  <stage name="mergeana">
    <fcl>$mergefcl</fcl>
    <outdir>/pnfs/lbne/scratch/${userdir}/&release;/mergeana/&name;</outdir>
    <workdir>/lbne/app/users/${userbase}/&release;/mergeana/&name;</workdir>
    <logdir>/lbne/data/${userdir}/log/&release;/mergeana/&name;</logdir>
    <numjobs>$njob2</numjobs>
    <targetsize>8000000000</targetsize>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;</defname>
  </stage>

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>
EOF

  fi

done
