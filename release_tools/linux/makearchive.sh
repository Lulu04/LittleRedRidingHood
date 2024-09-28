#!/bin/bash

create_no_install_archive(){
  echo "making ${NO_INSTALL_ARCHIVE_NAME}..."
  # delete the old archive
  if [ -f "${NO_INSTALL_ARCHIVE_NAME}" ]; then
    rm "${NO_INSTALL_ARCHIVE_NAME}"
  fi
 
  # delete and recreate the staging directory
  rm -rf "${STAGING_DIR}"
  mkdir "${STAGING_DIR}"

  # copy the binary to lower case name in the staging directory
  cp -p ${PROJECT_EXECUTABLE} "${STAGING_EXECUTABLE}"
  # set executable mode
#  chmod 0755 "${STAGING_EXECUTABLE}"
  
  #create the version file
  echo ${VERSION} > "${STAGING_DIR}/version"
  
  # copy the license file
  cp "${PROJECT_DIR}/LICENSE.txt" "${STAGING_DIR}/LICENSE"
  
  # copy the changelog file
  cp "${PROJECT_DIR}/changelog.txt" "${STAGING_DIR}/changelog.txt" 
  
  # copy the cheat codes list
  cp "${PROJECT_DIR}/cheatcodes.txt" "${STAGING_DIR}/cheatcodes.txt" 
  
  # copy readme file
  cp readme "${STAGING_DIR}/readme"
  
  # copy the right library directory
  cp -r "${PROJECT_BINARY_DIR}/${LIB_DIR}" "${STAGING_DIR}/${LIB_DIR}"

  # copy directory Data
  cp -r "${PROJECT_BINARY_DIR}/Data" "${STAGING_DIR}/Data"
  # rename languages files in lowercase
  # mv "${STAGING_DIR}/Data/Languages/LittleRedRidingHood.fr.po" "${STAGING_DIR}/Data/Languages/littleredridinghood.fr.po"
  # mv "${STAGING_DIR}/Data/Languages/LittleRedRidingHood.pot" "${STAGING_DIR}/Data/Languages/littleredridinghood.pot"
  
  # compress the temporary directory
  pushd ${STAGING_DIR}
  tar -czf "../../${NO_INSTALL_ARCHIVE_NAME}" *
  popd

  # delete the staging directory
  rm -rf "${STAGING_DIR}"

  echo "ARCHIVE GENERATED"
}

# begin

VERSION=$(cat "../../version.txt")

TARGET_ARCHITECTURE="$(dpkg --print-architecture)"
if [ ${TARGET_ARCHITECTURE} = "amd64" ]; then
  OS_NAME="linux64"
  WIDGETSET="gtk2"
  TARGET_CPU="x86_64"
  LIB_DIR="x86_64-linux"
# elif [ ${TARGET_ARCHITECTURE} = "i386" ]; then
#   OS_NAME="linux32"
#   WIDGETSET="gtk2"
#  TARGET_CPU="i386"
#  LIB_DIR="i386-linux"
else
  echo "${TARGET_ARCHITECTURE} not supported"
  exit 1
fi

echo "${LIB_DIR} detected"

PROJECT_DIR="/media/sf_Pascal/LittleRedRidingHood"
PROJECT_BINARY_DIR="${PROJECT_DIR}/Binary"
PROJECT_EXECUTABLE="${PROJECT_BINARY_DIR}/LittleRedRidingHood"
LAZARUS_PROJECT="${PROJECT_DIR}/LittleRedRidingHood.lpi"
STAGING_DIR=./staging
STAGING_EXECUTABLE="${STAGING_DIR}/LittleRedRidingHood"
NO_INSTALL_ARCHIVE_NAME="little_red_riding_hood_${VERSION}_${OS_NAME}_${WIDGETSET}_portable.tar.gz"
LAZBUILD_DIR="/home/lulu/fpcupdeluxe/lazarus"

# delete the old project binary file
if [ -f "${PROJECT_EXECUTABLE}" ]; then
  rm "${PROJECT_EXECUTABLE}"
fi

# compile project
echo "compiling Lazarus project ${VERSION}..."
# going to the directory where is lazbuild
pushd "${LAZBUILD_DIR}"
# compile and redirect output to /dev/null because we don't want to see the huge amount of message
# only error message are displayed on console
./lazbuild --build-all --quiet --widgetset=${WIDGETSET} --cpu=${TARGET_CPU} --build-mode=Release \
           --no-write-project ${LAZARUS_PROJECT} 1> /dev/null
popd

# check if binary file was created
if [ ! -f "${PROJECT_EXECUTABLE}" ]; then
  echo "COMPILATION FAILED..."
  exit 1
fi
           
echo "Success"

create_no_install_archive

# delete executable
rm "${PROJECT_EXECUTABLE}"

read -p "Press enter to exit"


