#!/bin/sh

# This is intended to be run on Jenkins, triggered by GitHub and will
# update the references rendered from PHP sources.

BRANCH=$(echo ${payload} | jq --raw-output '.ref | match("refs/heads/(.+)") | .captures | .[0].string')

# clone distribution
if [ -d flow-${BRANCH} ] ; then
	cd flow-${BRANCH}
	git fetch origin
	git reset --hard origin/${BRANCH}
else
	git clone -b ${BRANCH} git@github.com:neos/flow-development-distribution.git flow-${BRANCH}
	cd flow-${BRANCH}
fi

# install dependencies
php ../composer.phar update --no-interaction --no-progress --no-suggest
php ../composer.phar require --no-interaction --no-progress neos/doctools

# render references
./flow cache:warmup
./flow reference:rendercollection Flow

cd Packages/Framework

# reset changes only updating the generation date
for unchanged in `git diff  --numstat | grep '1\t1\t' | cut -f3`; do
 git checkout -- $unchanged;
done

# commit and push results to Framework dev collection
echo 'Commit and push to Framework'
git commit -am 'TASK: Update references'
git config push.default simple
git push origin
cd -
