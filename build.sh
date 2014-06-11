#!/bin/bash

REPO_NAME=$(echo ${TRAVIS_REPO_SLUG} | cut -d/ -f2)
OWNER_NAME=$(echo ${TRAVIS_REPO_SLUG} | cut -d/ -f1)
GIT_REVISION=$(git log --pretty=format:'%h' -n 1)
LAST_COMMIT_AUTHOR=$(git log --pretty=format:'%an' -n1)

function check {
    "$@"
    status=$?
    if [ $status -ne 0 ]; then
        echo "error run $@"
        exit $status
    fi
    return $status
}

function package {
    local REVISION=$1

    tar -czf ${REPO_NAME}-cookbooks-${REVISION}.tar.gz cookbooks
}

function publish {
    local REVISION=$1

    package $REVISION

    aws s3 cp ${REPO_NAME}-cookbooks-${REVISION}.tar.gz s3://qubell-starter-kit-artifacts/${OWNER_NAME}/ --acl public-read-write
}

function replace {
    local REVISION=$1

    check sed -i.bak -e 's/'${REPO_NAME}'-cookbooks-stable-[[:alnum:]]*.tar.gz/'${REPO_NAME}'-cookbooks-'${REVISION}'.tar.gz/g' ${REPO_NAME}.yml
    cat ${REPO_NAME}.yml
}

function publish_github {
    GIT_URL=$(git config remote.origin.url)
    NEW_GIT_URL=$(echo $GIT_URL | sed -e 's/^git:/https:/g' | sed -e 's/^https:\/\//https:\/\/'${GH_TOKEN}':@/')

    git remote rm origin
    git remote add origin ${NEW_GIT_URL}
    git fetch -q
    git config user.name ${GIT_NAME}
    git config user.email ${GIT_EMAIL}
    rm -rf *.tar.gz
    git commit -a -m "CI: Success build ${TRAVIS_BUILD_NUMBER}"
    git checkout -b build
    git push -q origin build:master
}

if [[ ${TRAVIS_PULL_REQUEST} == "false" ]]; then
    if [[ ${LAST_COMMIT_AUTHOR} != "CI" ]]; then
        publish "stable-${GIT_REVISION}"
        replace "stable-${GIT_REVISION}"

        pushd test

        check python test_runner.py

        popd

        publish_github
    fi
fi
