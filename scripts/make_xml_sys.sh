#! /bin/bash
#----------------------------------------------------------------------
#
# Name: make_xml_mcc.sh
#
# Purpose: Make xml files for mcc.  This script loops over all
#          generator-level fcl files in the source area of the currently 
#          setup version of dunetpc (that is, under 
#          $DUNETPC_DIR/source/fcl/dune35t/gen), and makes a corresponding xml
#          project file in the local directory.
#
# Usage:
#
# make_xml_mcc4.0.sh [-h|--help] [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>] [--nevgjob <n>]
#
# Options:
#
# -h|--help     - Print help.
# -r <release>  - Use the specified larsoft/dunetpc release.
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

rel=v06_64_00
userdir=scratch/dunepro
userbase=dunepro
nev=100000
nevjob=100
ls=''
sys=25pcbadchans
tag=mcc10.1

while [ $# -gt 0 ]; do
  case "$1" in

    # User directory.

    -h|--help )
      echo "Usage: make_xml_mcc5.0.sh [-h|--help] [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>] [--sys <sys>]"
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
      nev=$2
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

    # Name of systematic effect

    --sys )
    if [ $# -gt 1 ]; then
      sys=$2
      shift
    fi
    ;;


  esac
  shift
done

# Get qualifier.

quals=e14
if [[ $rel < 'v06_32_00'  ]]; then
  quals=e10
fi

echo $quals 

# Delete existing xml files.

rm -f *.xml

find $DUNETPC_DIR/source/fcl/dune35t/gen $DUNETPC_DIR/source/fcl/dunefd/gen $DUNETPC_DIR/source/fcl/protodune/gen -name \*.fcl | while read fcl
do
  if echo $fcl | grep -q 'prodgenie_nu_dune10kt_1x2x6\|prodgenie_nue_dune10kt_1x2x6\|prodgenie_nutau_dune10kt_1x2x6\|prodgenie_anu_dune10kt_1x2x6\|prodgenie_anue_dune10kt_1x2x6\|prodgenie_anutau_dune10kt_1x2x6'; then
    newprj=`basename $fcl .fcl`_${tag}_${sys}
    newxml=${newprj}.xml
    samprj=${newprj}
    if [ $userbase != dunepro ]; then
	samprj=${userbase}_$newprj
    fi
    generator=GENIE

    detector=10kt
    # Make xml file.

    echo "Making ${newxml}"

    # Reco
    recoinputdef=''
    recofcl=/dune/app/users/tjyang/larsoft_mydev/srcs/dunetpc/fcl/dunefd/reco/syst/standard_reco_dune10kt_nu_1x2x6_${sys}.fcl

    # Merge/Analysis

    caffcl=''

    if echo $newprj | grep -q '_nu_'; then
        recoinputdef=prodgenie_nu_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_nue_'; then
        recoinputdef=prodgenie_nue_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_nutau_'; then
        recoinputdef=prodgenie_nutau_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_anu_'; then
        recoinputdef=prodgenie_anu_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_anue_'; then
        recoinputdef=prodgenie_anue_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_anutau_'; then
        recoinputdef=prodgenie_anutau_dune10kt_1x2x6_mcc10.0_detsim
    fi
    if echo $newprj | grep -q '_nu'; then
        caffcl=select_ana_dune10kt_nu.fcl
    fi
    if echo $newprj | grep -q '_anu'; then
        caffcl=select_ana_dune10kt_anu.fcl
    fi


    njob=$(( $nev / $nevjob ))
#    echo $newprj, $nev, $nevjob, $njob
    cat <<EOF > $newxml
<?xml version="1.0"?>

<!-- Production Project -->

<!DOCTYPE project [
<!ENTITY rel "$rel">
<!ENTITY file_type "mc">
<!ENTITY run_type "physics">
<!ENTITY name "$samprj">
<!ENTITY tag "${tag}_${sys}">
]>

<job>

<project name="&name;">

  <!-- Project size -->
  <numevents>$nev</numevents>

  <!-- Operating System -->
  <os>SL6</os>

  <!-- Batch resources -->
  <resource>DEDICATED,OPPORTUNISTIC</resource>

  <!-- metadata parameters -->

  <parameter name ="MCName">${samprj}</parameter>
  <parameter name ="MCDetectorType">${detector}</parameter>
  <parameter name ="MCGenerators">${generator}</parameter>

  <!-- Larsoft information -->
  <larsoft>
    <tag>&rel;</tag>
    <qual>${quals}:prof</qual>
EOF
  if [ x$local != x ]; then
    echo "local=$local"
    echo "    <local>${local}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <check>1</check>

  <!-- Project stages -->
  <stage name="reco">
    <jobsub>--expected-lifetime=24h --subgroup=prod</jobsub>
    <maxfilesperjob>1</maxfilesperjob>
    <inputdef>${recoinputdef}</inputdef>
    <!-- disable trajcluster -->
    <fcl>$recofcl</fcl>
    <outdir>/pnfs/dune/${userdir}/&rel;/reco/&name;</outdir>
    <workdir>/pnfs/dune/${userdir}/work/&rel;/reco/&name;</workdir>
    <numjobs>$njob</numjobs>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_reco</defname>
  </stage>

  <stage name="mergeana">
    <jobsub>--memory=4000 --expected-lifetime=24h --subgroup=prod</jobsub>
    <fcl>$caffcl</fcl>
    <outdir>/pnfs/dune/${userdir}/&rel;/mergeana/&name;</outdir>
    <output>&name;_\${PROCESS}_%tc_merged.root</output>
    <workdir>/pnfs/dune/${userdir}/work/&rel;/mergeana/&name;</workdir>
    <numjobs>$njob</numjobs>
    <targetsize>8000000000</targetsize>
    <datatier>full-reconstructed</datatier>
    <defname>&name;</defname>
  </stage>

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>
</job>

EOF
  fi
done
