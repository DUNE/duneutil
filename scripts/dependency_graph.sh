#!/bin/sh

# usage:  dependency_graph.sh <product> <version> <quals>
# will make <product>_<version>_<quals>_graph.pdf dependency tree using graphviz
# it sets up the dune environment and then the product and qualifier
# requires dot for taking the graphviz file and making a PDF graph

function printdep {
    if [ x`echo $curprod | grep geant4` = x ]; then
	if [ x`echo $curprod | grep mrb` = x ]; then
	    if [ x`echo $prod | grep cetpkgsupport` = x ]; then
		if [ x`echo $prod | grep xerces_c` = x ]; then
		    if [ x`echo $prod | grep gcc` = x ]; then
			echo "$curprod -> $prod"
			printprodver
		    fi
		fi
	    fi
	fi
    fi
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
#    echo "Usage: dtgv.sh will make a graphviz input file for all setup products"
#    echo "except mrb.  It trims gcc, cetbuildtools, and the dependencies of GEANT4"
#    echo "The output is on stdout.   Redirect it to a file, and use graphviz:"
#    echo "dot -Tpdf -o deptree.pdf deptree.txt"
#    echo "where deptree.txt is the output of this script."
    echo "Usage: dtgv.sh <product> <version> <qualifiers> to make a file <product>_<version>.pdf showing"
    echo "the dependency tree.  This version suppresses GEANT4's dependencies as well as mrb and cetpkgsupport"
    exit
fi

export LANG=en_US
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
setup $1 $2 -q $3

TF=`mktemp /tmp/dtgv.tmp.XXXXXX`
touch $TF
rm $TF

echo digraph G { > $TF
makegraph | sort | uniq  >> $TF
echo } >> $TF

dot -Tpdf -o $1_$2_$3_graph.pdf $TF
rm $TF

