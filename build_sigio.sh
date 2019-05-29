#!/bin/sh

 (( $# == 0 )) && {
   echo "*** Usage: $0 wcoss|dell|cray|theia|intel_general|gnu_general [debug|build] [[local]install[only]]"
   exit 1
 }

 sys=${1,,}
 [[ $sys == wcoss || $sys == dell || $sys == cray ||\
    $sys == theia || $sys == intel_general || $sys == gnu_general ]] || {
   echo "*** Usage: $0 wcoss|dell|cray|theia|intel_general|gnu_general [debug|build] [[local]install[only]]"
   exit 1
 }
 debg=false
 inst=false
 skip=false
 local=false
 (( $# > 1 )) && {
   [[ ${2,,} == build ]] && debg=false
   [[ ${2,,} == debug ]] && debg=true
   [[ ${2,,} == install ]] && inst=true
   [[ ${2,,} == localinstall ]] && { local=true; inst=true; }
   [[ ${2,,} == installonly ]] && { inst=true; skip=true; }
   [[ ${2,,} == localinstallonly ]] && { local=true; inst=true; skip=true; }
 }
 (( $# > 2 )) && {
   [[ ${3,,} == build ]] && debg=false
   [[ ${3,,} == debug ]] && debg=true
   [[ ${3,,} == install ]] && inst=true
   [[ ${3,,} == localinstall ]] && { local=true; inst=true; }
   [[ ${3,,} == installonly ]] && { inst=true; skip=true; }
   [[ ${3,,} == localinstallonly ]] && { local=true; inst=true; skip=true; }
 }

 source ./Conf/Collect_info.sh
 source ./Conf/Gen_cfunction.sh
 source ./Conf/Reset_version.sh

 if [[ ${sys} == "intel_general" ]]; then
   sys6=${sys:6}
   source ./Conf/Sigio_${sys:0:5}_${sys6^}.sh
 elif [[ ${sys} == "gnu_general" ]]; then
   sys4=${sys:4}
   source ./Conf/Sigio_${sys:0:3}_${sys4^}.sh
 else
   source ./Conf/Sigio_intel_${sys^}.sh
 fi
 [[ -z $SIGIO_VER || -z $SIGIO_LIB4 ]] && {
   echo "??? SIGIO: module/environment not set."
   exit 1
 }

set -x
 sigioLib4=$(basename ${SIGIO_LIB4})
 sigioInc4=$(basename ${SIGIO_INC4})

#################
 cd src
#################

 $skip || {
#-------------------------------------------------------------------
# Start building libraries
#
 echo
 echo "   ... build default (i4/r4) sigio library ..."
 echo
  make clean LIB=$sigioLib4 MOD=$sigioInc4
   mkdir -p $sigioInc4
   FFLAGS4="$I4R4 $FFLAGS ${MODPATH}$sigioInc4"
   collect_info sigio 4 OneLine4 LibInfo4
   sigioInfo4=sigio_info_and_log4.txt
   $debg && make debug FFLAGS="$FFLAGS4" LIB=$sigioLib4 \
                                         &> $sigioInfo4 \
         || make build FFLAGS="$FFLAGS4" LIB=$sigioLib4 \
                                         &> $sigioInfo4
   make message MSGSRC="$(gen_cfunction $sigioInfo4 OneLine4 LibInfo4)" \
                LIB=$sigioLib4
 }

 $inst && {
#
#     Install libraries and source files
#
   $local && {
              LIB_DIR4=..
              INCP_DIR=../include
              INCP_DIR4=$INCP_DIR
              SRC_DIR=
             } || {
              LIB_DIR4=$(dirname $SIGIO_LIB4)
              INCP_DIR4=$(dirname $SIGIO_INC4)
              SRC_DIR=$SIGIO_SRC
              [ -d $LIB_DIR4 ] || mkdir -p $LIB_DIR4
              [ -d $SIGIO_INC4 ] && { rm -rf $SIGIO_INC4; } \
                                 || { mkdir -p $INCP_DIR4; }
              [ -z $SRC_DIR ] || { [ -d $SRC_DIR ] || mkdir -p $SRC_DIR; }
             }

   make clean LIB=
   make install LIB=$sigioLib4 MOD=$sigioInc4 \
                LIB_DIR=$LIB_DIR4 INC_DIR=$INCP_DIR4 SRC_DIR=$SRC_DIR
 }

