#!/bin/bash
set -e

function usage() {
    echo
    echo "    Usage: $0 github-tag"
    echo
    echo "    e.g.   $0 blacklight-1.0.2-rc2"
    echo
    exit
}

# check the command line parameters
if [ ! $# -eq 1 ]; then
    usage
fi

MUSEUM="omca"
RUN_DIR=$1

cd webapps  || { echo "could not cd to webapps github repo" ; exit 1; }
REPO=$(pwd)
git checkout main
git pull -v
git -c advice.detachedHead=false checkout ${RUN_DIR} || { echo "could not checkout tag ${RUN_DIR}" ; exit 1; }

cd ~/projects || { echo "could not cd to ~/projects" ; exit 1; }
if [ -d ${RUN_DIR} ] ; then echo "$1 already exists... exiting" ; exit 1 ; fi
mkdir ${RUN_DIR} || { echo "could not create ${RUN_DIR} in ~/projects" ; exit 1; }

cp -r ${REPO}/blacklight ~/projects/${RUN_DIR}/portal
cd ${RUN_DIR}/portal || { echo "could not cd to ${RUN_DIR}/portal" ; exit 1; }

# regenerate creds
EDITOR=cat rails credentials:edit

# do migrations (nb: we do not need to keep any db content from previous deployments)
export RAILS_ENV=production
rails db:migrate

# set up symlink so passenger can find the app
cd ~/projects
LINK_DIR=search_${MUSEUM}
if [ -d ${LINK_DIR} ] && [ ! -L ${LINK_DIR} ] ; then echo "${LINK_DIR} exists and is not a symlink ... cowardly refusal to rm it and relink it" ; exit 1 ; fi
rm -f ${LINK_DIR}
ln -s ${RUN_DIR}/portal ${LINK_DIR}

echo "deployed tag ${TAG} to ${RUN_DIR}, symlink is ${LINK_DIR}, environment is production"
echo "Restarting portal, you can too! enter: cd ~/projects/${RUN_DIR}/portal/ ; rake restart."
echo "Or just restart Apache"

cd ~/projects/${RUN_DIR}/portal/
rake restart

# reset repo to main branch
cd ${REPO}
git checkout main
