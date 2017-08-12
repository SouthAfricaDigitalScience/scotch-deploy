#!/bin/bash -e
# this should be run after check-build finishes.
. /etc/profile.d/modules.sh
module add deploy
module add bzip2
module add xz
module add  gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
cd ${WORKSPACE}/${NAME}_${VERSION}
make realclean

echo "All tests have passed, will now build into ${SOFT_DIR}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}"
make scotch
make ptscotch
make esmumps
make ptesmumps


make install

echo "Creating the modules file directory ${LIBRARIES}"
mkdir -p ${LIBRARIES}/${NAME}
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION : See https://github.com/SouthAfricaDigitalScience/SCOTCH-deploy"
setenv SCOTCH_VERSION       $VERSION
setenv SCOTCH_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
prepend-path PATH                            $::env(SCOTCH_DIR)/bin
prepend-path LD_LIBRARY_PATH   $::env(SCOTCH_DIR)/lib
setenv CFLAGS            "-I$::env(SCOTCH_DIR)/include ${CFLAGS}"
setenv LDFLAGS           "-L$::env(SCOTCH_DIR)/lib ${LDFLAGS}"
MODULE_FILE
) > ${LIBRARIES}/${NAME}/${VERSION}
