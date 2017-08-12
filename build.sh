#!/bin/bash -e
# Copyright 2016 C.S.I.R. Meraka Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. /etc/profile.d/modules.sh
module add ci
module add bzip2
module add xz
module add  gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}

SOURCE_FILE=${NAME}_${VERSION}.tar.gz

mkdir -p ${WORKSPACE}
mkdir -p ${SRC_DIR}
mkdir -p ${SOFT_DIR}

#  Download the source file

if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's geet the source"
  wget https://gforge.inria.fr/frs/download.php/latestfile/298/${SOURCE_FILE} -O ${SRC_DIR}/${SOURCE_FILE}
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi
tar xzf  ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files

# From the INSTALL.txt file  :
#----------------------------------------------------------------------------------------------
#  According to the libraries installed on your system, you may set
# flags "-DCOMMON_FILE_COMPRESS_BZ2", "-DCOMMON_FILE_COMPRESS_GZ" and/or
# "-DCOMMON_FILE_COMPRESS_LZMA" in the CFLAGS variable of your
# Makefile.inc configuration file, to have these formats and their
# respective extensions ".bz2", ".gz" and ".lzma", recognized and
# handled by Scotch.


# The compilation flags used to manage threads are the following:
#
# "-DCOMMON_PTHREAD" enables threads for algorithms not related to
# graph management, partitioning and/or ordering, e.g. compressed
# file handling.
#
# "-DCOMMON_PTHREAD_BARRIER" creates a replacement for missing
# pthread_barrier_t implementations, which unfortunately happens on some
# systems.
#
# "-DSCOTCH_PTHREAD" is necessary to enable multi-threaded algorithms
# in Scotch and/or PT-Scotch.
#
# "-DSCOTCH_PTHREAD_AFFINITY_LINUX" enables Linux extensions for
# handling thread affinity. As said above, this may not prove
# efficient in all cases. More options will be provided in the
# near future.
#
# "-DSCOTCH_PTHREAD_NUMBER=x" sets the overall number of threads to be
# used by multi-threaded algorithms. This number may not necessary be a
# power of two. Since some algorithms have had to be reformulated to
# accomodate for multi-threading, some algorithms will most probably be
# much more efficient than sequential processing only for a number of
# threads strictly greater than 2. Setting "-DSCOTCH_PTHREAD_NUMBER=1"
# allows one to run sequential algorithms instead of multi-threaded
# ones, while benefitting from multi-threading for file compression and
# distributed graph handling.

cd ${WORKSPACE}/${NAME}_${VERSION}/src
cp ${WORKSPACE}/Makefile.inc.${ARCH}_pc_linux2.shlib Makefile.inc

make scotch
make ptscotch
make esmumps
make ptesmumps
