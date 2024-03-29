#!/bin/sh

# usage:  dependency_graph.sh <product> <version> <quals>
# will make <product>_<version>_<quals>_graph.pdf dependency tree using graphviz
# it sets up the dune environment and then the product and qualifier
# requires dot for taking the graphviz file and making a PDF graph

function printdep {
    if [ x`echo $curprod | grep geant4` != x ]; then
       return
    fi

    if [ x`echo $curprod | grep mrb` != x ]; then
       return
    fi

    if [ x`echo $prod | grep cetpkgsupport` != x ]; then
       return
    fi

    if [ x`echo $prod | grep xerces_c` != x ]; then
       return
    fi

    if [ $prod = gcc ]; then
       return
    fi
 		       
    if [ $prod = gh ]; then
       return
    fi

    if [ $prod = git ]; then
       return
    fi

    echo "$curprod -> $prod"
    printprodver
}

function printprodver {
    echo $prod [label=\"$prod\\n$prodver\"]
    echo $curprod [label=\"$curprod\\n$curprodver\"]
}

function makegraph {

# make a temporary file containing all the ups active's of all setup products

    tempfile=`mktemp /tmp/deptreegraphviz.tmp.XXXXXX`
    touch $tempfile
    rm $tempfile
    ups active | grep -v "Active ups products:" | while read iline
    do
	ilct=${iline/-z * /}
	ilc=${ilct/-z */}
	ups depend $ilc >> $tempfile
    done


# need to read in without collapsing spaces.  IFS does this but ups depend gags on that,
# so run ups depend and catch the output in a separate file

    IFSSAVE=$IFS	
    IFS=$'\n' 
    cat $tempfile | while read -r iline2
    do
	matchstr="|__"
	if [ x`echo $iline2 | grep $matchstr` = x ]; then

# top-level product

	    prod=`echo $iline2 | cut -d ' ' -f1`
	    prodver=`echo $iline2 | cut -d ' ' -f2`
	    curprod=$prod
	    curprodver=$prodver
	    lastprod=$prod
	    lastprodver=$prodver
	    curlev=0
	    plist[$curlev]=$curprod
	    plistver[$curlev]=$curprodver
	else

# found a |__ -- downlevel product

	    dv1=`echo $iline2 | grep -b -o $matchstr | awk 'BEGIN {FS=":"}{print $1}'`
	    dv2=$(($dv1/3))
	    depth=$(($dv2+1))

	    jprod1=${iline2/*|__/}
	    prod=`echo $jprod1 | cut -d ' ' -f1`
	    prodver=`echo $jprod1 | cut -d ' ' -f2`
	    clp1=$((curlev+1))
	    if [ $depth = $clp1 ]; then
		printdep
	    elif [ $depth -gt $clp1 ]; then
		curprod=$lastprod
		curprodver=$lastprodver
		curlev=$clp1
		plist[$curlev]=$curprod
		plistver[$curlev]=$curprodver
		printdep
	    else
		curlev=$(($depth-1))
		curprod=${plist[$curlev]}
		curprodver=${plistver[$curlev]}
		printdep
	    fi
	    lastprod=$prod
	    lastprodver=$prodver
	fi
    done  # loop over lines in tempfile
    IFS=$IFSSAVE
    rm $tempfile
}

# begin main program

if [ "$1" == "--help" ]; then
    echo "Usage: dependency_graph.sh <product> <version> <qualifiers> to make a file <product>_<version>.pdf showing"
    echo "the dependency tree.  This version suppresses GEANT4's dependencies as well as mrb and cetpkgsupport"
    echo "be sure to set up the product first before running the script."
    exit
fi

export LANG=en_US
# now that the script is in duneutil, we assume we have the products set up.
# source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
# setup $1 $2 -q $3

TF=`mktemp /tmp/dtgv.tmp.XXXXXX`
touch $TF
rm $TF

echo digraph G { > $TF
makegraph | sort | uniq  >> $TF
echo } >> $TF

dot -Tpdf -o $1_$2_$3_graph.pdf $TF
rm $TF

