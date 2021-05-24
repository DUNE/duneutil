#!/bin/bash

# build edep-sim
# input variables:  
#   EDEPSIMVERSION  -- matches tag name in Clark McGrew's github
#   VERSIONSUFFIX   -- to append to the github tag to make our tag
#   QUAL -- compiler, e.g. e17, e19, e20, c2, c7
#   BUILDTYPE --  debug or prof
#   GEANT4VERSION -- tag for setting up GEANT4
#   ROOTVERSION   -- tag for setting up ROOT
#   WORKSPACE     -- from Jenkins
#   COMPILERQUAL_LIST -- list of all the compiler qualifiers (space separated)
#   EXTRAROOTQUALIFIERS -- to fully specify ROOT.  Needs a colon at the beginning so it can be
#          added to an existing qualifier string.  e.g. ":p383"

PRODUCT_NAME=edepsim

# designed to work on Jenkins

# for checking out from Clark McGrew's github repo

echo "edep-sim github version: $EDEPSIMVERSION"

echo "version suffix: $VERSIONSUFFIX"

echo "GEANT4 version: $GEANT4VERSION"

echo "ROOT version: $ROOTVERSION"

# -- the base qualifier is only the compiler version qualifier:  e.g. "e15"

echo "base qualifiers (compiler): $QUAL"

echo "extra root qualifiers: $EXTRAROOTQUALFIERS"
echo "these need a colon before but not after"

# note -- this script knows about the correspondence between compiler qualifiers and compiler versions.
# there is another if-block later on with the same information (apologies for the duplication).  If a new compiler
# version is added here, it must also be added where CV is set.

COMPILERVERS=unknown
COMPILERCOMMAND=unknown
CCOMPILER=unknown
if [ $QUAL = e14 ]; then
  COMPILERVERS="gcc v6_3_0"
  COMPILERCOMMAND=g++
  CCOMPILER=gcc
elif [ $QUAL = e15 ]; then
  COMPILERVERS="gcc v6_4_0"
  COMPILERCOMMAND=g++
  CCOMPILER=gcc
elif [ $QUAL = e17 ]; then
  COMPILERVERS="gcc v7_3_0"
  COMPILERCOMMAND=g++
  CCOMPILER=gcc
elif [ $QUAL = c2 ]; then
  COMPILERVERS="clang v5_0_1"
  COMPILERCOMMAND=clang++
  CCOMPILER=clang
elif [ $QUAL = e19 ]; then
  COMPILERVERS="gcc v8_2_0"
  COMPILERCOMMAND=g++
  CCOMPILER=gcc
elif [ $QUAL = e20 ]; then
  COMPILERVERS="gcc v9_3_0"
  COMPILERCOMMAND=g++
  CCOMPILER=gcc
elif [ $QUAL = c7 ]; then
  COMPILERVERS="clang v7_0_0"
  COMPILERCOMMAND=clang++
  CCOMPILER=clang
fi

echo "Compiler and version string: " $COMPILERVERS
echo "C++ Compiler command: " $COMPILERCOMMAND
echo "C Compiler command: " $CCOMPILER

echo "COMPILERQUAL_LIST: " $COMPILERQUAL_LIST

if [ "$COMPILERVERS" = unknown ]; then
  echo "unknown compiler flag: $QUAL"
  exit 1
fi

# -- prof or debug

echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

# Environment setup; look in CVMFS first

if [ -f /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh ]; then
  source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1
elif [ -f /grid/fermiapp/products/dune/setup_dune_fermiapp.sh ]; then
  source /grid/fermiapp/products/dune/setup_dune_fermiapp.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

setup -B cetbuildtools v7_15_01 || exit 1
setup -B root ${ROOTVERSION} -q ${QUAL}${EXTRAROOTQUALIFIERS}:${BUILDTYPE} || exit 1
setup -B geant4 ${GEANT4VERSION} -q ${QUAL}:${BUILDTYPE} || exit 1

# Use system git on macos, and the one in ups for linux

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
CURDIR=`pwd`

# change all dots to underscores, and capital V's to little v's in the version string
# add our own suffix as the compiler version moves more rapidly than the product version

VERSION=v`echo ${EDEPSIMVERSION} | sed -e "s/\./_/g"`${VERSIONSUFFIX}

LINDAR=linux
FLAVOR=`ups flavor -4`
if [ `uname` = Darwin ]; then
  FLAVOR=`ups flavor -2`
  LINDAR=darwin
fi

touch ${PRODUCT_NAME} || exit 1
rm -rf ${PRODUCT_NAME} || exit 1
touch inputdir || exit 1
rm -rf inputdir || exit 1
mkdir -p ${PRODUCT_NAME}/${VERSION}/source || exit 1
mkdir ${PRODUCT_NAME}/${VERSION}/include || exit 1
mkdir ${PRODUCT_NAME}/${VERSION}/ups || exit 1
mkdir ${PRODUCT_NAME}/${VERSION}/share || exit 1

# in the table, add ROOT and GEANT4 required setups

TABLEFILENAME=${PRODUCT_NAME}/${VERSION}/ups/${PRODUCT_NAME}.table
touch ${TABLEFILENAME} || exit 1
rm -f ${TABLEFILENAME} || exit 1
cat > ${TABLEFILENAME} <<EOF
File=Table
Product=edepsim

#*************************************************
# Starting Group definition
Group:

EOF

for CQ in $COMPILERQUAL_LIST; do
  touch tablefrag.txt || exit 1
  rm -f tablefrag.txt || exit 1
  cat > tablefrag.txt <<'EOF'

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:debug

  Action=DefineFQ
    envSet (EDEPSIM_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-debug)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )
    setupRequired( geant4 GEANT4VERS_REPLACE_STRING -q QUALIFIER_REPLACE_STRING:debug )
    setupRequired( root ROOTVERS_REPLACE_STRING -q QUALIFIER_REPLACE_STRINGROOTEXTRAQUALS_RS:debug )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:prof

  Action=DefineFQ
    envSet (EDEPSIM_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-prof)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )
    setupRequired( geant4 GEANT4VERS_REPLACE_STRING -q QUALIFIER_REPLACE_STRING:prof )
    setupRequired( root ROOTVERS_REPLACE_STRING -q QUALIFIER_REPLACE_STRINGROOTEXTRAQUALS_RS:prof )

EOF

CV=unknown
if [ $CQ = e14 ]; then
  CV="gcc v6_3_0"
elif [ $CQ = e15 ]; then
  CV="gcc v6_4_0"
elif [ $CQ = e17 ]; then
  CV="gcc v7_3_0"
elif [ $CQ = c2 ]; then
  CV="clang v5_0_1"
elif [ $CQ = e19 ]; then
  CV="gcc v8_2_0"
elif [ $CQ = e20 ]; then
  CV="gcc v9_3_0"
elif [ $CQ = c7 ]; then
  CV="clang v7_0_0"
fi
if [ "$CV" = unknown ]; then
  echo "unknown compiler flag in COMPILERQUAL_LIST : $CQ"
  exit 1
fi

sed -e "s/QUALIFIER_REPLACE_STRING/${CQ}/g" < tablefrag.txt \
 | sed -e "s/COMPILERVERS_REPLACE_STRING/${CV}/g" \
 | sed -e "s/GEANT4VERS_REPLACE_STRING/${GEANT4VERSION}/g" \
 | sed -e "s/ROOTVERS_REPLACE_STRING/${ROOTVERSION}/g" \
 | sed -e "s/ROOTEXTRAQUALS_RS/${EXTRAROOTQUALIFIERS}/g" \
 >> ${TABLEFILENAME} || exit 1
rm -f tablefrag.txt || exit 1

done

cat >> ${TABLEFILENAME} <<'EOF'
Common:
   Action=setup
      setupenv()
      proddir()
      ExeActionRequired(DefineFQ)
      envSet(EDEPSIM_DIR, ${UPS_PROD_DIR})
      envSet(EDEPSIM_ROOT, ${UPS_PROD_DIR})
      envSet(EDEPSIM_VERSION, ${UPS_PROD_VERSION})
      envSet(EDEPSIM_INC, ${EDEPSIM_DIR}/include)
      envSet(EDEPSIM_SHARE, ${EDEPSIM_DIR}/share)
      envSet(EDEPSIM_LIB, ${EDEPSIM_FQ_DIR}/lib)
      # add the lib directory to LD_LIBRARY_PATH
      if ( test `uname` = "Darwin" )
        envPrepend(DYLD_LIBRARY_PATH, ${EDEPSIM_FQ_DIR}/lib)
      else()
        envPrepend(LD_LIBRARY_PATH, ${EDEPSIM_FQ_DIR}/lib)
      endif ( test `uname` = "Darwin" )
      # add the bin directory to the path if it exists
      if    ( sh -c 'for dd in bin;do [ -d ${EDEPSIM_FQ_DIR}/$dd ] && exit;done;exit 1' )
          pathPrepend(PATH, ${EDEPSIM_FQ_DIR}/bin )
      else ()
          execute( true, NO_UPS_ENV )
      endif ( sh -c 'for dd in bin;do [ -d ${EDEPSIM_FQ_DIR}/$dd ] && exit;done;exit 1' )
      # useful variables
       pathPrepend(ROOT_INCLUDE_PATH, ${EDEPSIM_DIR}/include/EDepSim )
#      envPrepend(CMAKE_PREFIX_PATH, ${EDEPSIM_DIR} )  figure out what to do here
#      envPrepend(PKG_CONFIG_PATH, ${EDEPSIM_DIR} )
      # requirements
      exeActionRequired(ExtraSetup)
End:
# End Group definition
#*************************************************

EOF

mkdir installdir || exit 1
mkdir builddir || exit 1
mkdir inputdir || exit 1
cd inputdir
git clone https://github.com/DUNE/edep-sim.git || exit 1
cd edep-sim || exit 1
git checkout tags/${EDEPSIMVERSION} || exit 1

# copy all the source to the install directory

cp -R -L * ${CURDIR}/${PRODUCT_NAME}/${VERSION}/source || exit 1

DIRNAME=${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${BUILDTYPE}
mkdir -p ${DIRNAME} || exit 1
rm -rf ${DIRNAME}/* || exit 1
mkdir ${DIRNAME}/bin || exit 1
mkdir ${DIRNAME}/lib || exit 1
mkdir ${DIRNAME}/share || exit 1
mkdir ${DIRNAME}/include || exit 1

cd ${CURDIR}/builddir

CFLAGS="-O3"
if [ $BUILDTYPE = "debug" ]; then
CFLAGS="-O0"
fi
echo "Compiler flags: " $CFLAGS

cmake -DCMAKE_C_COMPILER=${CCOMPILER} -DCMAKE_C_FLAGS=${CFLAGS} -DCMAKE_CXX_COMPILER=${COMPILERCOMMAND} -DCMAKE_CXX_FLAGS=${CFLAGS} -DCMAKE_INSTALL_PREFIX=${CURDIR}/installdir ${CURDIR}/inputdir/edep-sim

make -j4  || exit 1
# make doc || exit 1
make install  || exit 1

cd ${CURDIR} || exit 1
cp -r installdir/lib/* ${DIRNAME}/lib
cp -r installdir/bin/* ${DIRNAME}/bin
cp -r installdir/share/* ${DIRNAME}/../share
cp -r installdir/include/* ${DIRNAME}/../include
# duplicate in the flavored versions in case cmake files assume include is flavored.
cp -r installdir/share/* ${DIRNAME}/share
cp -r installdir/include/* ${DIRNAME}/include

# for testing the tarball, remove so we keep .upsfiles as is when
# unwinding into a real products area

mkdir .upsfiles || exit 1
cat <<EOF > .upsfiles/dbconfig
FILE = DBCONFIG
AUTHORIZED_NODES = *
VERSION_SUBDIR = 1
PROD_DIR_PREFIX = \${UPS_THIS_DB}
UPD_USERCODE_DIR = \${UPS_THIS_DB}/.updfiles
EOF

ups declare ${PRODUCT_NAME} ${VERSION} -f ${FLAVOR} -m ${PRODUCT_NAME}.table -z `pwd` -r ./${PRODUCT_NAME}/${VERSION} -q ${BUILDTYPE}:${QUAL}:${SIMDQUALIFIER} || exit 1

rm -rf .upsfiles || exit 1

# clean up
rm -rf ${CURDIR}/inputdir || exit 1

cd ${CURDIR} || exit 1

ls -la

VERSIONDOTS=`echo ${VERSION} | sed -e "s/_/./g"`
SUBDIR=`get-directory-name subdir | sed -e "s/\./-/g"`

# use SUBDIR instead of FLAVOR

FULLNAME=${PRODUCT_NAME}-${VERSIONDOTS}-${SUBDIR}-${QUAL}-${BUILDTYPE}

# strip off the first "v" in the version number

FULLNAMESTRIPPED=`echo $FULLNAME | sed -e "s/${PRODUCT_NAME}-v/${PRODUCT_NAME}-/"`

rm -rf installdir || exit 1
rm -rf builddir || exit 1

tar -cjf $WORKSPACE/copyBack/${FULLNAMESTRIPPED}.tar.bz2 . || exit 1

ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1

exit 0
