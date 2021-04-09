#!/bin/bash

# build dunepdsprce

PRODUCT_NAME=dunepdsprce

# designed to work on Jenkins

# for checking out from JJ's github repo

echo "dunepdsprce JJ github: $JJVERSION"

# -- the base qualifier is only the compiler version qualifier:  e.g. "e15"

echo "base qualifiers: $QUAL"

# note -- this script knows about the correspondence between compiler qualifiers and compiler versions.
# there is another if-block later on with the same information (apologies for the duplication).  If a new compiler
# version is added here, it must also be added where CV is set.

COMPILERVERS=unknown
COMPILERCOMMAND=unknown
if [ $QUAL = e14 ]; then
  COMPILERVERS="gcc v6_3_0"
  COMPILERCOMMAND=g++
elif [ $QUAL = e15 ]; then
  COMPILERVERS="gcc v6_4_0"
  COMPILERCOMMAND=g++
elif [ $QUAL = e17 ]; then
  COMPILERVERS="gcc v7_3_0"
  COMPILERCOMMAND=g++
elif [ $QUAL = c2 ]; then
  COMPILERVERS="clang v5_0_1"
  COMPILERCOMMAND=clang++
elif [ $QUAL = e19 ]; then
  COMPILERVERS="gcc v8_2_0"
  COMPILERCOMMAND=g++
elif [ $QUAL = e20 ]; then
  COMPILERVERS="gcc v9_3_0"
  COMPILERCOMMAND=g++
elif [ $QUAL = c7 ]; then
  COMPILERVERS="clang v7_0_0"
  COMPILERCOMMAND=clang++
fi

echo "Compiler and version string: " $COMPILERVERS
echo "Compiler command: " $COMPILERCOMMAND

echo "COMPILERQUAL_LIST: " $COMPILERQUAL_LIST

if [ "$COMPILERVERS" = unknown ]; then
  echo "unknown compiler flag: $QUAL"
  exit 1
fi

# -- prof or debug

echo "build type: $BUILDTYPE"

# -- gen, avx, or avx2

echo "simd qualifier: $SIMDQUALIFIER"

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

setup ${COMPILERVERS}

# Use system git on macos, and the one in ups for linux

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi
setup gitflow || exit 1

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
CURDIR=`pwd`

# change all dots to underscores, and capital V's to little v's in the version string
# add our own suffix as the compiler version moves more rapidly than the product version

VERSION=`echo ${JJVERSION} | sed -e "s/V/v/g" | sed -e "s/\./_/g"`${VERSIONSUFFIX}

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
mkdir ${PRODUCT_NAME}/${VERSION}/data || exit 1
mkdir ${PRODUCT_NAME}/${VERSION}/ups || exit 1


TABLEFILENAME=${PRODUCT_NAME}/${VERSION}/ups/${PRODUCT_NAME}.table
touch ${TABLEFILENAME} || exit 1
rm -rf ${TABLEFILENAME} || exit 1
cat > ${TABLEFILENAME} <<EOF
File=Table
Product=dunepdsprce

#*************************************************
# Starting Group definition
Group:

EOF

for CQ in $COMPILERQUAL_LIST; do
  touch tablefrag.txt || exit 1
  rm -rf tablefrag.txt || exit 1
  cat > tablefrag.txt <<'EOF'

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:gen:debug

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-gen-debug)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:avx:debug

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-avx-debug)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:avx2:debug

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-avx2-debug)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:gen:prof

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-gen-prof)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:avx:prof

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-avx-prof)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

Flavor=ANY
Qualifiers=QUALIFIER_REPLACE_STRING:avx2:prof

  Action=DefineFQ
    envSet (DUNEPDSPRCE_FQ_DIR, ${UPS_PROD_DIR}/${UPS_PROD_FLAVOR}-QUALIFIER_REPLACE_STRING-avx2-prof)

  Action = ExtraSetup
    setupRequired( COMPILERVERS_REPLACE_STRING )

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

sed -e "s/QUALIFIER_REPLACE_STRING/${CQ}/g" < tablefrag.txt | sed -e "s/COMPILERVERS_REPLACE_STRING/${CV}/g" >> ${TABLEFILENAME} || exit 1
rm -f tablefrag.txt || exit 1

done

cat >> ${TABLEFILENAME} <<'EOF'
Common:
   Action=setup
      setupenv()
      proddir()
      ExeActionRequired(DefineFQ)
      envSet(DUNEPDSPRCE_DIR, ${UPS_PROD_DIR})
      envSet(DUNEPDSPRCE_VERSION, ${UPS_PROD_VERSION})
      envSet(DUNEPDSPRCE_INC, ${DUNEPDSPRCE_DIR}/include)
      envSet(DUNEPDSPRCE_LIB, ${DUNEPDSPRCE_FQ_DIR}/lib)
      # add the lib directory to LD_LIBRARY_PATH
      if ( test `uname` = "Darwin" )
        envPrepend(DYLD_LIBRARY_PATH, ${DUNEPDSPRCE_FQ_DIR}/lib)
      else()
        envPrepend(LD_LIBRARY_PATH, ${DUNEPDSPRCE_FQ_DIR}/lib)
      endif ( test `uname` = "Darwin" )
      # add the bin directory to the path if it exists
      if    ( sh -c 'for dd in bin;do [ -d ${DUNEPDSPRCE_FQ_DIR}/$dd ] && exit;done;exit 1' )
          pathPrepend(PATH, ${DUNEPDSPRCE_FQ_DIR}/bin )
      else ()
          execute( true, NO_UPS_ENV )
      endif ( sh -c 'for dd in bin;do [ -d ${DUNEPDSPRCE_FQ_DIR}/$dd ] && exit;done;exit 1' )
      # useful variables
#      envPrepend(CMAKE_PREFIX_PATH, ${DUNEPDSPRCE_DIR} )  this package doesn't use cmake
#      envPrepend(PKG_CONFIG_PATH, ${DUNEPDSPRCE_DIR} )
      # requirements
      exeActionRequired(ExtraSetup)
End:
# End Group definition
#*************************************************

EOF

mkdir inputdir || exit 1
cd inputdir
git clone https://github.com/dune/dunepdsprce.git || exit 1
cd dunepdsprce || exit 1
git checkout tags/${JJVERSION} || exit 1

# copy all the files that do not need building.  Copy the headers later when we're done as they are in the install directory

cp -R -L dam/source/* ${CURDIR}/${PRODUCT_NAME}/${VERSION}/source || exit 1

# skip the example data files

# cp -R -L data/* ${CURDIR}/${PRODUCT_NAME}/${VERSION}/data || exit 1

DIRNAME=${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}
mkdir -p ${DIRNAME} || exit 1
rm -rf ${DIRNAME}/* || exit 1
mkdir ${DIRNAME}/bin || exit 1
mkdir ${DIRNAME}/lib || exit 1

cd ${CURDIR}/inputdir/dunepdsprce/dam/source/cc/make || exit 1
make clean || exit 1

if [ $BUILDTYPE = prof ]; then
  echo "Making optimized version"
  make CC=${COMPILERCOMMAND} CXX=${COMPILERCOMMAND} LD=${COMPILERCOMMAND} PROD=1 target=x86_64-${SIMDQUALIFIER}-${LINDAR} || exit 1
else
  echo "Making debug version"
  make CC=${COMPILERCOMMAND} CXX=${COMPILERCOMMAND} LD=${COMPILERCOMMAND} target=x86_64-${SIMDQUALIFIER}-${LINDAR} || exit 1
fi

cp -R -L ${CURDIR}/inputdir/dunepdsprce/install/x86_64-${SIMDQUALIFIER}-${LINDAR}/bin/* ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/bin

# JJ builds a program called "reader" which probably shouldn't be in the user's PATH.  Rename it if it exists

if [ -e ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/bin/reader ]; then
  mv ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/bin/reader ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/bin/${PRODUCT_NAME}_testreader
fi

# in the case of the shared libraries, we want to only copy the libraries once, and make new symlinks with relative paths

cd ${CURDIR}/inputdir/dunepdsprce/dam/export/x86_64-${SIMDQUALIFIER}-${LINDAR}/lib
for LIBFILE in $( ls ); do
	  if [ -h ${LIBFILE} ]; then
	    TMPVAR=`readlink ${LIBFILE}`
	    ln -s `basename ${TMPVAR}` ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/lib/${LIBFILE} || exit 1
	  else
	    cp ${LIBFILE} ${CURDIR}/${PRODUCT_NAME}/${VERSION}/${FLAVOR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}/lib || exit 1
	  fi
done

cp -R -L ${CURDIR}/inputdir/dunepdsprce/install/x86_64-${SIMDQUALIFIER}-${LINDAR}/include/* ${CURDIR}/${PRODUCT_NAME}/${VERSION}/include || exit 1

# assemble the UPS product and declare it

cd ${CURDIR} || exit 1

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

ups declare ${PRODUCT_NAME} ${VERSION} -f ${FLAVOR} -m ${PRODUCT_NAME}.table -z `pwd` -r ./${PRODUCT_NAME}/${VERSION} -q ${BUILDTYPE}:${QUAL}:${SIMDQUALIFIER}

rm -rf .upsfiles || exit 1

# clean up
rm -rf ${CURDIR}/inputdir || exit 1

cd ${CURDIR} || exit 1

ls -la

VERSIONDOTS=`echo ${VERSION} | sed -e "s/_/./g"`
SUBDIR=`get-directory-name subdir | sed -e "s/\./-/g"`

# use SUBDIR instead of FLAVOR

FULLNAME=${PRODUCT_NAME}-${VERSIONDOTS}-${SUBDIR}-${QUAL}-${SIMDQUALIFIER}-${BUILDTYPE}

# strip off the first "v" in the version number

FULLNAMESTRIPPED=`echo $FULLNAME | sed -e "s/${PRODUCT_NAME}-v/${PRODUCT_NAME}-/"`

tar -cjf $WORKSPACE/copyBack/${FULLNAMESTRIPPED}.tar.bz2 .

ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1

exit 0
