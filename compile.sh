#!/bin/bash

# exit immediately on error
set -e
UNAME=`uname`

if [ -z $HT ]; then
    echo "We can't see the HDK, exiting."
    exit 1
fi

usage () 
{
    echo "./compile.sh [flags]"
    echo
    echo " Flags:"
    echo
    echo "    -f|--fast - skip the 3rd party compile stage"
    echo "    -n|--noinstall - just build, don't install"
    echo
}


# command line args

while [ $# -gt 0 ]; do

    case "$1" in 
        -f|--fast)
            FAST=1
            ;;
        -n|--noinstall)
            NOINSTALL=1
            ;;
        *)
            echo "Unknown flag \"${1}\""
            usage
            exit 1
    esac

    shift
done


case $UNAME in
    "Darwin")
        DLLEXT="dylib"
        ;;
    "Linux")
        DLLEXT="so"
        ;;
    *)
        echo "Unsupported architecture \"${UNAME}\", exiting."
        exit 1
        ;;
esac

echo
echo " *** Testing compilation environment ***"
echo

mkdir -p tmp
cp $HT/samples/SOP/SOP_Star.* ./tmp
chmod u+rw tmp/SOP_Star.*
pushd tmp
hcustom -i . SOP_Star.C
if [ ! -e SOP_Star.${DLLEXT} ]; then
    echo
    echo "Sorry, we couldn't compile SOP_Star.C so you need to get that in order first!"
    echo "Start by reading about the HDK at http://www.sidefx.com/docs"
    echo
    exit 1
fi
popd




HIH="${HOME}/houdini${HOUDINI_MAJOR_RELEASE}.${HOUDINI_MINOR_RELEASE}"

if [ -z $FAST ]; then

    echo
    echo " *** Compiling the 3rdparty dependencies. *** "
    echo

    pushd 3rdparty 

    case $UNAME in
        "Darwin")
            ./build_osx.sh
            ;;
        "Linux")
            ./build_linux.sh
            ;;
    esac

    popd
fi

echo
echo " *** Compiling the HOT. *** "
echo

case $UNAME in
    "Darwin")
        IFLAGS="-I. -I./3rdparty/include -I ./3rdparty/osx/include"
        LFLAGS="-L ./3rdparty/osx/lib  -l fftw3f -l blitz"
        FLAGS="$IFLAGS $LFLAGS -i ${HIH}/dso"
        ;;
    "Linux")
        IFLAGS="-I. -I./3rdparty/include -I ./3rdparty/linux/include"
        LFLAGS="-L ./3rdparty/linux/lib  -l fftw3f -l blitz"
        FLAGS="$IFLAGS $LFLAGS -i ${HIH}/dso"
        hcustom  -e $FLAGS SOP_Ocean.C 
        hcustom  -e $FLAGS VEX_Ocean.C 
        hcustom  SOP_Cleave.C
        ;;
esac

hcustom  -e $FLAGS SOP_Ocean.C 
hcustom  -e $FLAGS VEX_Ocean.C 
hcustom  SOP_Cleave.C

VEXDSO="${HIH}/vex"
mkdir -p ${VEXDSO}
cp VEXdso_${UNAME} ${VEXDSO}/VEXdso

echo
echo " *** Finished installing, go make waves. *** "
echo
