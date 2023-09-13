#!/bin/bash

function addStandardProductToManifest {
  pver=`ups active | grep $1 | awk '{print $2}'`
  echo "$1 version: $pver"
  pflav=`ups active | grep $1 | awk '{print $4}'`
  echo "$1 flavor: $pflav"
  pquals=`ups active | grep $1 | awk '{print $6}'`
  echo "$1 quals: $pquals"
  pdv=`echo ${pver} | sed -e 's/_/./g' | sed -e 's/^v//'`
  echo "$1         ${pver}       $1-${pdv}-${PLATFORM}-x86_64-${DASHQUAL2}-${BUILDTYPE}.tar.bz2   -f ${pflav}    -q  ${pquals}" >>  $manifest
}

function addNullFlavoredProductToManifest {
  pver=`ups active | grep $1 | awk '{print $2}'`
  echo "$1 version: $pver"
  pflav=`ups active | grep $1 | awk '{print $4}'`
  echo "$1 flavor: $pflav"
  pdv=`echo ${pver} | sed -e 's/_/./g' | sed -e 's/^v//'`
  echo "$1         ${pver}       $1-${pdv}-noarch.tar.bz2   -f ${pflav}" >>  $manifest
}

function addNoQualsProductToManifest {
  pver=`ups active | grep $1 | awk '{print $2}'`
  echo "$1 version: $pver"
  pflav=`ups active | grep $1 | awk '{print $4}'`
  echo "$1 flavor: $pflav"
  pdv=`echo ${pver} | sed -e 's/_/./g' | sed -e 's/^v//'`
  echo "$1         ${pver}       $1-${pdv}-${PLATFORM}-x86_64.tar.bz2   -f ${pflav}  " >>  $manifest
}

function manifestProductVersionUpdate {
# edit the manifest's  version number for a product.  Modeled after a piece of the script that
# updated artdaq_core

# version of product named $1 with underscores
ARDC_UVERSION=`ups active | grep $1 | awk '{print $2}'`

# version of $1 with dots
ARDC_DVERSION=`echo $ARDC_UVERSION | sed -e 's/_/./g' | sed -e 's/^v//'`

# we're assuming the qualifiers match up between what we want and what we have for $1
# replace $1 line in manifest with our new version

if [ `grep $1 $manifest | wc -l` = 0 ]; then
  echo "LArSoft manifest lacks an $1 line"
  exit 1
fi

ARDCLINE=`grep $1 $manifest | head -1`
ARDCOLDVER=`echo $ARDCLINE | awk '{print $2}'`
ARDCOLDVERD=`echo $ARDCOLDVER | sed -e 's/_/\\\./g' | sed -e 's/^v//'`
ARDCNEWLINE=`echo $ARDCLINE | sed -e "s/${ARDCOLDVER}/${ARDC_UVERSION}/g" | sed -e "s/${ARDCOLDVERD}/${ARDC_DVERSION}/g"`

echo "Replacing $1 line the manifest:"
echo $ARDCLINE
echo "with this one:"
echo $ARDCNEWLINE
echo "and deleting others."

touch newmanifest.txt || exit 1
rm newmanifest.txt || exit 1
grep -v $1 $manifest > newmanifest.txt || exit 1
echo $ARDCNEWLINE >> newmanifest.txt
mv newmanifest.txt $manifest || exit 1

}

# build dunetpc
# use mrb
# designed to work on Jenkins

echo "dunetpc version: $DUNE"
echo "base qualifiers: $QUAL"
QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
LARVERSION=`echo ${DUNE} | sed -e "s/d..//"`
echo "modified base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"
dune_dot_version=`echo ${DUNE} |  sed -e 's/_/./g' | sed -e 's/^v//'`
echo "dune_dot: $dune_dot_version"

# Don't do ifdh build on macos.

#if uname | grep -q Darwin; then
#  if ! echo $QUAL | grep -q noifdh; then
#    echo "Ifdh build requested on macos.  Quitting."
#    exit
#  fi
#fi

# Get number of cores to use.

if [ `uname` = Darwin ]; then
  #ncores=`sysctl -n hw.ncpu`
  #ncores=$(( $ncores / 4 ))
  ncores=4
else
  ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
fi
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# Environment setup.  Just use cvmfs.  larsoft builds are not supported on /grid/fermiapp anymore

echo "ls /cvmfs/dune.opensciencegrid.org/products/dune/"
ls /cvmfs/dune.opensciencegrid.org/products/dune/
echo

if [ `uname` = Darwin -a -f /grid/fermiapp/products/dune/setup_dune_fermiapp.sh ]; then
  source /grid/fermiapp/products/dune/setup_dune_fermiapp.sh || exit 1
elif [ -f /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh ]; then
  if [ -x /cvmfs/grid.cern.ch/util/cvmfs-uptodate ]; then
    /cvmfs/grid.cern.ch/util/cvmfs-uptodate /cvmfs/dune.opensciencegrid.org/products
  fi
  source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

# Use git out of ups except use the system git on macos

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi

# skip around a version of mrb that does not work on macOS

if [ `uname` = Darwin ]; then
  if [[ x`which mrb | grep v1_17_02` != x ]]; then
    unsetup mrb || exit 1
    setup mrb v1_16_02 || exit 1
  fi
fi

setup gitflow || exit 1
export MRB_PROJECT=dune
echo "Mrb path:"
which mrb

# make the timeouts longer and accept low-speed transfers

export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600

#dla set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
#mrb newDev -v $DUNE -q $QUAL:$BUILDTYPE || exit 1
mrb newDev -v $LARVERSION -q $QUAL:$BUILDTYPE || exit 1

#dla set +x
source localProducts*/setup || exit 1

# some shenanigans so we can use getopt v1_1_6
if [ `uname` = Darwin ]; then
#  cd $MRB_INSTALL
#  curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 || \
#      { cat 1>&2 <<EOF
#ERROR: pull of http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 failed
#EOF
#        exit 1
#      }
#  tar xf getopt-1.1.6-d13-x86_64.tar.bz2 || exit 1
  setup getopt v1_1_6  || exit 1
#  which getopt
fi

#dla set -x
cd $MRB_SOURCE  || exit 1
# make sure we get a read-only copy
# put some retry logic here instead

for repo in duneana dunecalib duneutil dunecore dunedataprep duneexamples duneopdet duneprototypes dunereco dunesim protoduneana dunesw
do
  echo "Cloning $repo"
  maxtries=20
  ntries=0
  until [ $ntries -ge $maxtries ]
  do
    date
    mrb g -r -t $DUNE $repo && break
    ntries=$[$ntries+1]
    sleep 60
  done
  if [ $ntries = $maxtries ]; then
    echo "Could not clone $repo using mrb g.  Quitting."
    exit 1
  fi
done

## Extract duneutil version from dunetpc product_deps
#duneutil_version=`grep duneutil $MRB_SOURCE/dunetpc/ups/product_deps | grep -v qualifier | awk '{print $2}'`
#echo "duneutil version: $duneutil_version"
#mrb g -r -t $duneutil_version duneutil || exit 1


cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n dune -- -j$ncores || exit 1


# Extract flavor.

flvr=''
if uname | grep -q Darwin; then
  flvr=`ups flavor -2`
else
  flvr=`ups flavor -4`
fi


manifest=`ls dune-*_MANIFEST.txt`
oldmanifest="old$manifest"
mv $manifest $oldmanifest

# add flavor and qualifier to the duneana line but do it only once

dtline=`grep duneana $oldmanifest | grep -v protoduneana`
dtmodline="${dtline}    -f ${flvr}   -q   ${QUAL}:${BUILDTYPE}"
echo $dtmodline
echo $dtmodline > ${manifest}

# do all the others

for repo in dunecalib dunecore dunedataprep duneexamples duneopdet duneprototypes dunereco dunesim duneutil protoduneana dunesw
do
  dtline=`grep $repo $oldmanifest`
  dtmodline="${dtline}    -f ${flvr}   -q   ${QUAL}:${BUILDTYPE}"
  echo $dtmodline
  echo $dtmodline >> ${manifest}
done

rm ${oldmanifest}

# get platform
OS=$(uname)
case $OS in
    Linux)
        PLATFORM=$(uname -r | grep -o "el[0-9]"|sed s'/el/slf/')
        ;;
    Darwin)
        PLATFORM=$(uname -r | awk -F. '{print "d"$1}')
        ;;
esac

cd $MRB_SOURCE || exit 1

# find our set qualifier from artdaq_core's qualifier

SQUAL=`ups active | grep artdaq_core | tr : '\n' | grep ^s | awk '{print $1}'`
echo "Set qualifier from artdaq_core:  $SQUAL"

DQTMP=${QUAL}-${SQUAL}
DASHQUAL=`echo ${DQTMP} | sed -e "s/:/-/g" | sed -e "s/-/-nu-/"`
DASHQUAL2=`echo ${QUAL} | sed -e "s/:/-/g"`

fci=`expr index "$QUAL" :`
let "fct = $fci - 1"
COMPILER=$QUAL
if [[ $fci != 0 ]]; then
  COMPILER=${QUAL:0:$fct}
fi
echo "Compiler is: $COMPILER"

cd $MRB_BUILDDIR

# some of these are already in the larsoft manifest but with
# different versions from the ones in use in the present build

addStandardProductToManifest dunepdlegacy
addStandardProductToManifest duneanaobj
addStandardProductToManifest highfive
addStandardProductToManifest nlohmann_json
addNullFlavoredProductToManifest dunedetdataformats
addNullFlavoredProductToManifest dunedaqdataformats
addNullFlavoredProductToManifest dune_pardata
addNullFlavoredProductToManifest larbatch
addNoQualsProductToManifest castxml
addNoQualsProductToManifest valgrind

# add srproxy to the manifest -- hardwire py3 and noarch.  Also keep the dots in the version string as this one's special

srproxy_version=`ups active | grep srproxy | awk '{print $2}'`
echo "srproxy version: $srproxy_version"
srproxy_dot_version=`echo ${srproxy_version} | sed -e 's/^v//'`
srproxy_underscore_version=`echo ${srproxy_version} | sed -e 's/\./_/g'`
echo "srproxy    ${srproxy_underscore_version}   srproxy-${srproxy_dot_version}-noarch-py3.tar.bz2  -f NULL" >> $manifest

# Extract larsoft version from product_deps.

larsoft_version=`grep larsoft $MRB_SOURCE/dunecore/ups/product_deps | grep -v qualifier | awk '{print $2}'`
larsoft_dot_version=`echo ${larsoft_version} |  sed -e 's/_/./g' | sed -e 's/^v//'`

# Construct name of larsoft manifest.

larsoft_manifest=larsoft-${larsoft_dot_version}-${flvr}-${SQUAL}-${DASHQUAL2}-${BUILDTYPE}_MANIFEST.txt
echo "Larsoft manifest:"
echo $larsoft_manifest
echo

# Fetch laraoft manifest from scisoft and append to dunetpc manifest.

echo "curl --fail --silent --location --insecure http://scisoft.fnal.gov/scisoft/bundles/larsoft/${larsoft_version}/manifest/${larsoft_manifest} >> $manifest || exit 1"

curl --fail --silent --location --insecure http://scisoft.fnal.gov/scisoft/bundles/larsoft/${larsoft_version}/manifest/${larsoft_manifest} >> $manifest || exit 1

echo "Done with the curl command."

# Special handling of noifdh builds goes here.

if echo $QUAL | grep -q noifdh; then

  if uname | grep -q Darwin; then

    # If this is a macos build, then rename the manifest to remove noifdh qualifier in the name

    noifdh_manifest=`echo $manifest | sed 's/-noifdh//'`
    mv $manifest $noifdh_manifest

  else

    # Otherwise (for slf builds), delete the manifest entirely.

    rm -f $manifest

  fi
fi

manifestProductVersionUpdate artdaq_core
manifestProductVersionUpdate geant4reweight

# Save artifacts.

echo "Moving tarballs to copyBack"

mv *.bz2  $WORKSPACE/copyBack/ || exit 1

echo "Moving manifest to copyBack"

newmanifest_name=`echo $manifest | sed -e "s/$larsoft_dot_version/$dune_dot_version/"`
mv $manifest $newmanifest_name

manifest=dune-*_MANIFEST.txt
if [ -f $manifest ]; then
  mv $manifest  $WORKSPACE/copyBack/ || exit 1
fi
#cp $MRB_BUILDDIR/dunetpc/releaseDB/*.html $WORKSPACE/copyBack/
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
#dla set +x

exit 0
