#!/bin/bash
# DO NOT RUN THIS DIRECTLY! Use "make release" instead.
# Run this before uploading.
COMPACTDATE=$(date +"%Y%m%d")
VERSION=$(cat version.txt | sed -e "s/%(extra)s/$COMPACTDATE/")
NAME=$(echo $VERSION | sed -e "s/\\./_/g")
SVNDIR=~/svn/iterm2
ORIG_DIR=`pwd`

make Deployment || exit
./sign.sh

# Build tmux and move its tar.gz into the Deployment build directory
cd ~/tmux
git checkout mountainlion
make
rm *.o
cd ..
tar cvfz tmux-for-iTerm2-$COMPACTDATE.tar.gz tmux/* tmux/.deps
cd $ORIG_DIR
mv ~/tmux-for-iTerm2-$COMPACTDATE.tar.gz build/Deployment
cd build/Deployment

# Create the zip file
zip -r iTerm2-${NAME}.zip iTerm.app

# Update the list of changes
vi $SVNDIR/appcasts/testing_changes.html

# Prepare the sparkle xml file
LENGTH=$(ls -l iTerm2-${NAME}.zip | awk '{print $5}')
ruby "../../SparkleSigningTools/sign_update.rb" iTerm2-${NAME}.zip $PRIVKEY > /tmp/sig.txt
SIG=$(cat /tmp/sig.txt)
DATE=$(date +"%a, %d %b %Y %H:%M:%S %z")
cp $SVNDIR/appcasts/template.xml /tmp
cat /tmp/template.xml | \
sed -e "s/%VER%/${VERSION}/" | \
sed -e "s/%DATE%/${DATE}/" | \
sed -e "s/%NAME%/${NAME}/" | \
sed -e "s/%LENGTH%/$LENGTH/" |
sed -e "s,%SIG%,${SIG}," > $SVNDIR/appcasts/testing.xml
cp $SVNDIR/appcasts/testing.xml $SVNDIR/appcasts/canary.xml

echo "Go upload the iTerm2-${NAME}.zip, then run:"
echo "git tag v${VERSION}"
echo "git push --tags"
echo "pushd ${SVNDIR} && svn commit -m ${VERSION} appcasts/testing.xml appcasts/canary.xml appcasts/testing_changes.html"
echo "popd"
echo "git commit -am ${VERSION}"
echo "git push origin master"
