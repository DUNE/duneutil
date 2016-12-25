#! /bin/bash
#----------------------------------------------------------------------
#
# Name: make_xml_protodune_mcc8.0.sh
#
# Purpose: Make xml files for mcc.  This script loops over all
#          generator-level fcl files in the source area of the currently 
#          setup version of dunetpc (that is, under 
#          $DUNETPC_DIR/source/fcl/dune35t/gen), and makes a corresponding xml
#          project file in the local directory.
#     This is for Dorota's samples, so there's a lot of special one-off logic in here.
#
# Usage:
#
# make_xml_protodune_mcc8.0.sh [-h|--help] [-r <release>] [-u|--user <user>] [--local <dir|tar>] [--nev <n>] [--nevjob <n>] [--nevgjob <n>]
#
# Options:
#
# -h|--help     - Print help.
# -r <release>  - Use the specified larsoft/dunetpc release.
# -u|--user <user> - Use users/<user> as working and output directories
#                    (default is to use lbnepro).
# --local <dir|tar> - Specify larsoft local directory or tarball (xml 
#                     tag <local>...</local>).
# --nev <n>     - ignored
# --nevjob <n>  - ignored
# --nevgjob <n> - Specify the maximum number of events per gen/g4 job.
#
#----------------------------------------------------------------------

# Parse arguments.

rs=v06_18_01_01
rr1=v06_18_01_01
userdir=dunepro
userbase=$userdir
nevarg=0
nevjob=100
nevjobarg=100
ls=''
lr1=''
lr2=''
tag=mcc8.0

recolifetime=8h

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


    # All stages release.

	-r|--release )
	    if [ $# -gt 1 ]; then
		    rs=$2
		    rr1=$2
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

for topname in beamcosmics singlep
do
    find $DUNETPC_DIR/source/fcl/protodune/mcc/mcc8/$topname -name "gen*.fcl" | while read fcl
    do
	if [ $topname == beamcosmics ]; then
	    if echo $fcl | grep -q -v beam_2GeV; then
	    continue
	    fi
	fi

	find  $DUNETPC_DIR/source/fcl/protodune/mcc/mcc8/$topname -name "*g4*.fcl" | while read g4fcl_v
	do

	    if echo $g4fcl_v | grep -q 6ms; then
		continue
	    fi

#	    find  $DUNETPC_DIR/source/fcl/protodune/mcc/mcc8/$topname -name "*detsim*.fcl" ; find  $DUNETPC_DIR/source/fcl/protodune/detsim/protoDUNE_detsim.fcl | while read detsimfcl_v
	    for detsimfcl_v in $(find $DUNETPC_DIR/source/fcl/protodune/mcc/mcc8/$topname -name "*detsim*.fcl" ; find  $DUNETPC_DIR/source/fcl/protodune/detsim/protoDUNE_detsim.fcl);
	    do 

		if [ $topname == singlep ]; then
		   if echo $detsimfcl_v | grep -q noise; then
		      continue
		   fi
	        else
		   if echo $detsimfcl_v | grep -q -v noise; then
		      continue
		   fi
		fi

#		echo " Looping  " $fcl $g4fcl_v $detsimfcl_v $recofcl1_v $mergefcl_v

		genbasename=`basename $fcl .fcl`
		g4basename=`basename $g4fcl_v .fcl`
		detsimbasename=`basename $detsimfcl_v .fcl`
		
		detsimtrimname=`echo $detsimbasename | sed -e "s/3ms_//g"`

		newprj_1=${genbasename}${g4basename}${detsimtrimname}

# trim the project name down so it doesn't have extraneous or duplicate information

		newprj=ProtoDUNE`echo $newprj_1 | sed -e "s/gen_//" | sed -e "s/protoDune//g" | sed -e "s/protoDUNE//g" | sed -e "s/_detsim//g" | sed -e "s/_g4//g" | sed -e "s/_bc//g"`
		newxml=${newprj}.xml
		samprj=${newprj}
		if [ $userbase != dunepro ]; then
		    samprj=${userbase}_$newprj
		fi
		generator=SingleGen
		if echo $newprj | grep -q cosmics; then
		    generator=CORSIKA
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

		detector=protoDune


    # Generator

		genfcl=`basename $fcl`

    # G4

		g4fcl=`basename $g4fcl_v`

    # Detsim (optical + tpc).

		detsimfcl=`basename $detsimfcl_v`


    # Reco default
		recofcl1=''
	        if echo $topname | grep -q singlep; then
	           recofcl1=reco_protoDune_3ms.fcl
         	fi

    # Set number of events.
		nev=10000

    # special logic for Dorota

		if [ $topname == beamcosmics ]; then
		   if echo $g4fcl_v | grep -q sce; then
		      if echo $detsimfcl_v | grep -q low; then
			 recofcl1=protoDUNE_reco.fcl
			 nev=10000
			 recolifetime=24h
		      elif echo $detsimfcl_v | grep -q med; then
			 recofcl1=''
			 nev=10000
		      elif echo $detsimfcl_v | grep -q high; then
			 continue
		      else
			 echo Ununderstood detsim: $detsimfcl_v
		      fi
	           else
		      if echo $detsimfcl_v | grep -q low; then
			 if echo $g4fcl_v | grep -q 1ms; then
			    recofcl1=''
			    nev=1000
			 elif echo $g4fcl_v | grep -q 3ms; then
			    recofcl1=protoDUNE_reco.fcl
			    nev=10000
			    recolifetime=24h
			 else
			    echo Unexpected g4 option: $g4fcl_v with low noise no SCE beam cosmics
			    exit
			 fi

		      elif echo $detsimfcl_v | grep -q med; then
			 if echo $g4fcl_v | grep -q 1ms; then
			    recofcl1=''
			    nev=1000
			 elif echo $g4fcl_v | grep -q 3ms; then
			    recofcl1=''
			    nev=10000
			 else
			    echo Unexpected g4 option: $g4fcl_v with med noise no SCE beam cosmics
			    exit
			 fi

		      elif echo $detsimfcl_v | grep -q high; then
			 if echo $g4fcl_v | grep -q 1ms; then
			    recofcl1=''
			    nev=1000
			 elif echo $g4fcl_v | grep -q 3ms; then
			    recofcl1=''
			    nev=1000
			 else
			    echo Unexpected g4 option: $g4fcl_v with med noise no SCE beam cosmics
			    exit
			 fi
		      else
			 echo Unexpected $detsimfcl_v noise option
			 exit
		      fi
		   fi
		fi

    # Merge/Analysis

		mergefcl=protoDUNE_ana.fcl


    # Set number of events per job.
		nevjob=100


    # Calculate the number of worker jobs.

		njob=$(( $nev / $nevjob ))

    # Make xml file.

		echo "Making ${newprj}.xml"
#		echo "   " $fcl $g4fcl $detsimfcl $recofcl1 $mergefcl

#    echo $newprj, $nev, $nevjob, $njob

		cat <<EOF > $newxml
<?xml version="1.0"?>

<!-- Production Project -->

<!DOCTYPE project [
    <!ENTITY relsim "$rs">
    <!ENTITY relreco "$rr1">
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


<stage name="detsim">
<fcl>$genfcl</fcl>
<fcl>$g4fcl</fcl>
<fcl>$detsimfcl</fcl>
<outdir>/pnfs/dune/persistent/${userdir}/&relsim;/detsim/&name;</outdir>
<workdir>/pnfs/dune/scratch/${userdir}/work/&relsim;/detsim/&name;</workdir>
<output>${newprj}_\${PROCESS}_%tc_detsim.root</output>
<numjobs>$njob</numjobs>
<datatier>detector-simulated</datatier>
<defname>&name;_&tag;_detsim</defname>
</stage>

EOF
if [ x$recofcl1 != x ]; then
cat <<EOF >> $newxml

<stage name="reco">
<fcl>$recofcl1</fcl>
<outdir>/pnfs/dune/scratch/${userdir}/&relreco;/reco/&name;</outdir>
<workdir>/pnfs/dune/scratch/${userdir}/work/&relreco;/reco/&name;</workdir>
<numjobs>$njob</numjobs>
<datatier>full-reconstructed</datatier>
<defname>&name;_&tag;_reco</defname>
<jobsub>--expected-lifetime=$recolifetime</jobsub>
</stage>

<stage name="mergeana">
<fcl>$mergefcl</fcl>
<outdir>/pnfs/dune/scratch/${userdir}/&relreco;/mergeana/&name;</outdir>
<output>&name;_\${PROCESS}_%tc_merged.root</output>
<workdir>/pnfs/dune/scratch/${userdir}/work/&relreco;/mergeana/&name;</workdir>
<numjobs>$njob</numjobs>
<targetsize>8000000000</targetsize>
<datatier>full-reconstructed</datatier>
<defname>&name;_&tag;</defname>
</stage>
EOF
fi

cat <<EOF >> $newxml
<filetype>&file_type;</filetype>
<runtype>&run_type;</runtype>
</project>
</job>
EOF
	    done
	done
    done
done
