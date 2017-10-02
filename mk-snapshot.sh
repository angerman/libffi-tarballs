#!/bin/bash -e

# Create a snapshot of the libffi repository from github, as a workaround for
# the lack of recent releases of libffi (see https://github.com/libffi/libffi/issues/296)

GVERS=3.99999 # see configure.ac / AC_INIT
# make a temporary directory and perform operations in there.
TMPD=$(mktemp -d)
TDIR=$(pwd)

# get the directory of the script
SCRIPTDIR=$(dirname "$0")
# find it's absolute path.

# drop all preexisting libffi-* tarballs.
# that way there will only be one after
# the generation of the tarball.
rm libffi-*

(cd "$TMPD" || exit
 # clone the repository (shallow is sufficient)
 git clone --depth 1 https://github.com/libffi/libffi.git
 # record the revision and create a copy of only the files
 # contained in the repository at libffi-<revision>
 GHASH=$(cd libffi && git rev-parse --short HEAD)
 GDATE=$(cd libffi && git log -1 --pretty=format:%cd --date=format:%Y%m%d)
 SUFFIX="${GVERS}+git${GDATE}+${GHASH}"
 (cd libffi && ./autogen.sh && ./configure && make dist)
 # package it up
 DISTLIB="libffi-${GVERS}.tar.gz"
 FINALLIB="libffi-${SUFFIX}.tar.gz"
 mv "libffi/${DISTLIB}" "${TDIR}/${FINALLIB}"
)

# we can't extract those information from the subshell, rejoice!
GHASH=$(cd "$TMPD/libffi" && git rev-parse --short HEAD)
GDATE=$(cd "$TMPD/libffi" && git log -1 --pretty=format:%cd --date=format:%Y%m%d)
SUFFIX="${GVERS}+git${GDATE}+${GHASH}"

# create orphan branch
git checkout --orphan "libffi-${SUFFIX}"
git add libffi-${SUFFIX}
cat >README.md <<EOF
# libffi snapshot tarball for GHC

This source snapshot was produced from
[libffi](https://github.com/libffi/libffi) commit
[${GHASH}](https://github.com/libffi/libffi/commit/${GHASH}) for GHC. See the
\`master\` branch of this repository for more information about the rationale
and tools for producing these snapshots.
EOF
git add README.md
git rm --cached mk-snapshot.sh
git commit -m "Snapshot of libffi ${GHASH}"
git checkout -f master

echo "Created branch libffi-${SUFFIX}"
