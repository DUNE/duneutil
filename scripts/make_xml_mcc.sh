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

rs=v06_16_00
rr1=v06_16_00
rr2=v06_16_00
userdir=persistent/dunepro
userbase=dunepro
nevarg=0
nevjob=0
nevjobarg=0
ls=''
lr1=''
lr2=''
tag=devel

while [ $# -gt 0 ]; do
  case "$1" in

    # User directory.

    -h|--help )
      echo "Usage: make_xml_mcc.sh [-h|--help] [-r <release>] [-t|--tag <tag>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>]"
      exit
    ;;

    # Simulation release.

    -rs )
    if [ $# -gt 1 ]; then
      rs=$2
      shift
    fi
    ;;

    # Reconstruction 1 release.

    -rr1 )
    if [ $# -gt 1 ]; then
      rr1=$2
      shift
    fi
    ;;

    # Reconstruction 1 release.

    -rr2 )
    if [ $# -gt 1 ]; then
      rr2=$2
      shift
    fi
    ;;

    # All stages release.

    -r|--release )
    if [ $# -gt 1 ]; then
      rs=$2
      rr1=$2
      rr2=$2
      shift
    fi
    ;;

    # User.

    -u|--user )
    if [ $# -gt 1 ]; then
      userdir=scratch/users/$2
      userbase=$2
      shift
    fi
    ;;

    # Local simulation release.

    -ls )
    if [ $# -gt 1 ]; then
      ls=$2
      shift
    fi
    ;;

    # Local reconstruction release.

    -lr1 )
    if [ $# -gt 1 ]; then
      lr1=$2
      shift
    fi
    ;;

    -lr2 )
    if [ $# -gt 1 ]; then
      lr2=$2
      shift
    fi
    ;;

    # Local release.

    --local )
    if [ $# -gt 1 ]; then
      ls=$2
      lr1=$2
      lr2=$2
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
      nevjobarg=$2
      shift
    fi
    ;;

    # Sample tag.

    -t|--tag )
    if [ $# -gt 1 ]; then
      tag=$2
      shift
    fi
    ;;

  esac
  shift
done

# Get qualifier.

qual=e10
ver=`echo $rs | cut -c2-3`
echo ver=$ver
if [ $ver -gt 2 ]; then
  qual=e10
fi

# Delete existing xml files.

rm -f *.xml

find $DUNETPC_DIR/source/fcl/dune35t/gen $DUNETPC_DIR/source/fcl/dunefd/gen $DUNETPC_DIR/source/fcl/protodune/gen -name \*.fcl | while read fcl
do
  if ! echo $fcl | grep -q 'common\|protoDUNE_gensingle'; then
    newprj=`basename $fcl .fcl`
    newxml=${newprj}.xml
    samprj=${newprj}
    if [ $userbase != dunepro ]; then
	samprj=${userbase}_$newprj
    fi
    generator=SingleGen
    if echo $newprj | grep -q cosmics; then
      generator=CRY
    fi
    if echo $newprj | grep -q AntiMuonCutEvents; then
      generator=TextFileGen
    fi
    if echo $newprj | grep -q genie; then
      generator=GENIE
    fi
    if echo $newprj | grep -q MUSUN; then
      generator=MUSUN
    fi
    if echo $newprj | grep -q supernova; then
      generator=SNNueAr40CCGen
    fi
    if echo $newprj | grep -q prodndk; then
      generator=NDKGen
    fi
    if echo $newprj | grep -q prodmarley; then
      generator=MARLEY
    fi
    if echo $newprj | grep -q prodbackground_ar39; then
      generator=RadioGen
    fi

    detector=35t
    if echo $newprj | grep -q dune10kt; then
      detector=10kt
    fi
    if echo $newprj | grep -q protoDune; then
      detector=protoDune
    fi

    # Make xml file.

    echo "Making ${newprj}.xml"

    # Generator

    genfcl=`basename $fcl`

    # G4

    g4fcl=standard_g4_dune35t.fcl

    # Detsim (optical + tpc).

    detsimfcl=standard_detsim_dune35t.fcl

    # Reco 2D

#    reco2dfcl=standard_reco_uboone_2D.fcl

    # Reco 3D

#    reco3dfcl=standard_reco_uboone_3D.fcl

    # Reco
    recofcl1=standard_reco_dune35tsim.fcl
    recofcl2=''

    # Merge/Analysis

    mergefcl=standard_ana_dune35t.fcl

    if echo $newprj | grep -q protonpi0; then
	g4fcl=standard_g4_dune35t_protonpi0.fcl
    fi

    if echo $newprj | grep -q countermu; then
	g4fcl=standard_g4_dune35t_countermu.fcl
    fi

#    if echo $newprj | grep -q 'pi0\|gamma'; then
#      recofcl1=reco_dune35t_blur.fcl
#      mergefcl=ana_energyCalib.fcl
#    fi

#    if echo $newprj | grep -q 'piminus'; then
#      recofcl1=emhits.fcl
#      mergefcl=standard_merge_dune35t.fcl
#    fi

    if echo $newprj | grep -q milliblock; then
      detsimfcl=standard_detsim_dune35t_milliblock.fcl
      recofcl1=standard_reco_dune35t_milliblock.fcl
      mergefcl=standard_ana_dune35t_milliblock.fcl
    fi

    if echo $newprj | grep -q dune10kt; then
      g4fcl=standard_g4_dune10kt.fcl
      detsimfcl=standard_detsim_dune10kt.fcl
      recofcl1=standard_reco_dune10kt.fcl
      mergefcl=standard_ana_dune10kt.fcl
    fi

    if echo $newprj | grep -q 'dune10kt_1x2x6\|dune10kt_r90deg_1x2x6'; then
      g4fcl=standard_g4_dune10kt_1x2x6.fcl
      detsimfcl=standard_detsim_dune10kt_1x2x6.fcl
      recofcl1=standard_reco_dune10kt_1x2x6.fcl
      mergefcl=standard_ana_dune10kt_1x2x6.fcl
      if echo $newprj | grep -q 'genie_nu\|genie_anu'; then
	recofcl1=standard_reco1_dune10kt_nu_1x2x6.fcl
	recofcl2=standard_reco2_dune10kt_nu_1x2x6.fcl
      fi
      if echo $newprj | grep -q 'supernova\|marley'; then
        g4fcl=supernova_g4_dune10kt_1x2x6.fcl
      fi
    fi

    if echo $newprj | grep -q dune10kt_3mmpitch_1x2x6; then
      g4fcl=standard_g4_dune10kt_3mmpitch_1x2x6.fcl
      detsimfcl=standard_detsim_dune10kt_3mmpitch_1x2x6.fcl
      recofcl1=standard_reco_dune10kt_3mmpitch_1x2x6.fcl
      mergefcl=standard_ana_dune10kt_3mmpitch_1x2x6.fcl
      if echo $newprj | grep -q 'genie_nu\|genie_anu'; then
	recofcl1=standard_reco1_dune10kt_3mmpitch_nu_1x2x6.fcl
	recofcl2=standard_reco2_dune10kt_3mmpitch_nu_1x2x6.fcl
      fi
      if echo $newprj | grep -q 'supernova\|marley'; then
        g4fcl=supernova_g4_dune10kt_3mmpitch_1x2x6.fcl
      fi
     fi

    if echo $newprj | grep -q dune10kt_45deg_1x2x6; then
      g4fcl=standard_g4_dune10kt_45deg_1x2x6.fcl
      detsimfcl=standard_detsim_dune10kt_45deg_1x2x6.fcl
      recofcl1=standard_reco_dune10kt_45deg_1x2x6.fcl
      mergefcl=standard_ana_dune10kt_45deg_1x2x6.fcl
      if echo $newprj | grep -q 'genie_nu\|genie_anu'; then
	recofcl1=standard_reco1_dune10kt_45deg_nu_1x2x6.fcl
	recofcl2=standard_reco2_dune10kt_45deg_nu_1x2x6.fcl
      fi
      if echo $newprj | grep -q 'supernova\|marley'; then
        g4fcl=supernova_g4_dune10kt_45deg_1x2x6.fcl
      fi
    fi

    if echo $newprj | grep -q protoDune; then
      g4fcl=protoDUNE_g4single.fcl
      detsimfcl=protoDUNE_detsim_single.fcl
      recofcl1=protoDUNE_reco.fcl
      mergefcl=protoDUNE_ana.fcl
    fi

    if echo $newprj | grep -q dphase; then
      g4fcl=standard_g4_dune10kt_dp.fcl
      detsimfcl=standard_detsim_dune10kt_dp.fcl
      recofcl1=standard_reco_dune10ktdphase.fcl
      mergefcl=standard_ana_dune10kt_dp.fcl
    fi



    # Set number of events per job.
    nevjob=$nevjobarg
    if [ $nevjob -eq 0 ]; then
      if [ $newprj = prodcosmics_dune35t_milliblock ]; then
        nevjob=100
      elif [ $newprj = prodcosmics_dune35t_onewindow ]; then
	nevjob=100
      elif [ $newprj = AntiMuonCutEvents_LSU_dune35t ]; then
	nevjob=100
      elif [ $newprj = prodcosmics_dune35t_milliblock_countermu ]; then
	nevjob=10000
      elif [ $newprj = prodcosmics_dune35t_milliblock_protonpi0 ]; then
	nevjob=100
      else
        nevjob=100
      fi
    fi

    # Set number of events.

    nev=$nevarg
    if [ $nev -eq 0 ]; then
      if [ $newprj = prodcosmics_dune35t_milliblock ]; then
        nev=10000
      elif [ $newprj = prodcosmics_dune35t_onewindow ]; then
	nev=10000
      elif [ $newprj = AntiMuonCutEvents_LSU_dune35t ]; then
	nev=10000
      elif [ $newprj = prodcosmics_dune35t_milliblock_countermu ]; then
	nev=10000000
      elif [ $newprj = prodcosmics_dune35t_milliblock_protonpi0 ]; then
	nev=100000
      elif echo $newprj | grep -q dune10kt; then
	if echo $newprj | grep -q 'genie_nu\|genie_anu'; then
	    nev=1000000
          if echo $newprj | grep -q dphase; then
            nev=10000
          fi
	else
	    nev=10000
	fi
      elif echo $newprj | grep -q protoDune; then
        nev=30000
      else
        nev=10000
      fi
    fi

    # Calculate the number of worker jobs.

    njob=$(( $nev / $nevjob ))
#    echo $newprj, $nev, $nevjob, $njob
  cat <<EOF > $newxml
<?xml version="1.0"?>

<!-- Production Project -->

<!DOCTYPE project [
<!ENTITY relsim "$rs">
<!ENTITY relreco1 "$rr1">
<!ENTITY relreco2 "$rr2">
<!ENTITY file_type "mc">
<!ENTITY run_type "physics">
<!ENTITY name "$samprj">
<!ENTITY tag "$tag">
]>

<job>

<project name="&name;">

  <!-- Group -->
  <group>dune</group>

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
    <tag>&relsim;</tag>
    <qual>${qual}:prof</qual>
EOF
  if [ x$ls != x ]; then
    echo "ls=$ls"
    echo "    <local>${ls}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <check>1</check>

  <!-- Project stages -->

  <stage name="detsim">
    <fcl>$genfcl</fcl>
    <fcl>$g4fcl</fcl>
    <fcl>$detsimfcl</fcl>
EOF
  if echo $newprj | grep -q AntiMuonCutEvents_LSU_dune35t; then
      echo "    <inputmode>textfile</inputmode>" >> $newxml
      echo "    <inputlist>/pnfs/dune/persistent/dunepro/AntiMuonCutEvents_LSU_100.txt</inputlist>" >> $newxml
  fi
  cat <<EOF >> $newxml
    <outdir>/pnfs/dune/${userdir}/&relsim;/detsim/&name;</outdir>
    <workdir>/pnfs/dune/${userdir}/work/&relsim;/detsim/&name;</workdir>
    <output>${newprj}_\${PROCESS}_%tc_detsim.root</output>
    <numjobs>$njob</numjobs>
    <datatier>detector-simulated</datatier>
    <defname>&name;_&tag;_detsim</defname>
  </stage>

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>
EOF
  if [ x$recofcl2 == x ]; then
  cat <<EOF >> $newxml

<project name="&name;_reco">

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
    <tag>&relreco1;</tag>
    <qual>${qual}:prof</qual>
EOF
  if [ x$lr1 != x ]; then
    echo "lr1=$lr1"
    echo "    <local>${lr1}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <check>1</check>

  <!-- Project stages -->
  <stage name="reco">
    <fcl>$recofcl1</fcl>
    <outdir>/pnfs/dune/${userdir}/&relreco1;/reco/&name;</outdir>
    <workdir>/pnfs/dune/${userdir}/work/&relreco1;/reco/&name;</workdir>
    <numjobs>$njob</numjobs>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;_reco</defname>
  </stage>

  <stage name="mergeana">
    <fcl>$mergefcl</fcl>
    <outdir>/pnfs/dune/${userdir}/&relreco1;/mergeana/&name;</outdir>
    <output>&name;_\${PROCESS}_%tc_merged.root</output>
    <workdir>/pnfs/dune/${userdir}/work/&relreco1;/mergeana/&name;</workdir>
    <numjobs>$njob</numjobs>
    <targetsize>8000000000</targetsize>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;</defname>
  </stage>
EOF
  else
cat <<EOF >> $newxml

<project name="&name;_reco1">

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
    <tag>&relreco1;</tag>
    <qual>${qual}:prof</qual>
EOF
  if [ x$lr1 != x ]; then
    echo "lr1=$lr1"
    echo "    <local>${lr1}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <check>1</check>

  <!-- Project stages -->
  <stage name="reco1">
    <fcl>$recofcl1</fcl>
    <outdir>/pnfs/dune/${userdir}/&relreco1;/reco1/&name;</outdir>
    <workdir>/pnfs/dune/${userdir}/work/&relreco1;/reco1/&name;</workdir>
    <numjobs>$njob</numjobs>
    <datatier>hit-reconstructed</datatier>
    <defname>&name;_&tag;_reco1</defname>
  </stage>

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>

<project name="&name;_reco2">

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
    <tag>&relreco2;</tag>
    <qual>${qual}:prof</qual>
EOF
  if [ x$lr2 != x ]; then
    echo "lr2=$lr2"
    echo "    <local>${lr2}</local>" >> $newxml
  fi
  cat <<EOF >> $newxml
  </larsoft>

  <check>1</check>

  <!-- Project stages -->
  <stage name="reco2">
    <fcl>$recofcl2</fcl>
    <outdir>/pnfs/dune/${userdir}/&relreco2;/reco2/&name;</outdir>
    <workdir>/pnfs/dune/${userdir}/work/&relreco2;/reco2/&name;</workdir>
    <numjobs>$njob</numjobs>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;_reco2</defname>
  </stage>

  <stage name="mergeana">
    <fcl>$mergefcl</fcl>
    <outdir>/pnfs/dune/${userdir}/&relreco2;/mergeana/&name;</outdir>
    <output>&name;_\${PROCESS}_%tc_merged.root</output>
    <workdir>/pnfs/dune/${userdir}/work/&relreco2;/mergeana/&name;</workdir>
    <numjobs>$njob</numjobs>
    <targetsize>8000000000</targetsize>
    <datatier>full-reconstructed</datatier>
    <defname>&name;_&tag;</defname>
  </stage>
EOF
  fi
  
  cat <<EOF >> $newxml

  <!-- file type -->
  <filetype>&file_type;</filetype>

  <!-- run type -->
  <runtype>&run_type;</runtype>

</project>
</job>

EOF
  fi
done
