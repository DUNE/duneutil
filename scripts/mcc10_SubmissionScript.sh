#! /bin/bash
	
#----------------------------------------------------------------------
#	
#
# Name: mcc10_SubmissionScript.sh
#	
# Purpose: Launch batch job using project.py and different stages
#	
# Usage: sh mcc10_SubmissionScript.sh --xml <xmlfile> --stage <stage> [--test]
#	
#
#  OPTIONS:
#
#  --xml           <xmlfile>
#  --stage         <stage>; accepted values: detsim, reco, mergeana, finalize
#  --dataset       <dataset>; NOT USED
#  --mode          <mode>; NOT USED
#  --slice         <slice>; NOT USED
#  --test          ; enable POMS test mode (1 job/10 events)
#  --recovery	   <dataset>; enable POMS recovery mode  NOT USED
#
# Stage "finalize" is used to declare mergeana output.	
#	
#----------------------------------------------------------------------



overrides=""

while :
do
   case "x$1" in
   x--|x)            break;;
   x--xml)           xmlfile="$2"; 	shift; shift;;
   x--stage)         stage="$2"; 	shift; shift;;
   x--dataset)       dataset="$2"; shift; shift;;
   x--mode)          mode="$2"; shift; shift;;
   x--slice)         slice="$2"; shift; shift;; 
   x--test)          tempdir=/pnfs/dune/scratch/dunepro/mcc10_test/$(uuidgen); echo "tempdir = $tempdir" ; overrides="$overrides -Onumevents=10 -Ostage.numjobs=1 -Ostage.outdir=$tempdir -Ostage.workdir=$tempdir"; echo "overrides=$overrides"; shift;;
   x--recovery)      mode="recovery"; dataset="$2"; shift; shift;;      
   *)        break;;
   esac
done

#
# use the New and Improved! wrap_proj...
#
wrap_proj=/grid/fermiapp/products/common/prd/poms_client/v2_0_0/NULL/bin/wrap_proj


echo -e "\nRunning\n `basename $0` $@"

cd /dune/app/home/dunepro/anna/MCC10/xml/



if [ x"$stage" = x"detsim" ]; then


    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage ${stage}  --submit

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi    
    



elif [ x"$stage" = x"reco" ]; then



    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage detsim  --check

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi



    sleep 10



    $wrap_proj  $overrides project.py --xml ${xmlfile}  --stage ${stage}  --submit

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi



elif [ x"$stage" = x"mergeana" ]; then



    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage reco  --check

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi



    sleep 10



    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage ${stage}  --submit

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi



elif [ x"$stage" = x"finalize" ]; then

    
    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage mergeana  --check

    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi
    
    
    sleep 10
    
    
    
    $wrap_proj $overrides project.py --xml ${xmlfile}  --stage mergeana  --declare
    
    EXITCODE=$?

    echo "project.py terminated with exit code ${EXITCODE}"

    if [ ${EXITCODE} -ne 0 ]; then exit ${EXITCODE}; fi



else

    echo "stage $(stage) unknown, accepted value are: detsim, reco, mergeana, finalize"

    exit 1



fi

