#!/bin/sh
if git config remote.upstream.url > /dev/null; then
    # some repositories have a different name for the master branch
    master_branch=`git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
    git checkout $master_branch && git fetch upstream $master_branch && \
        git rebase upstream/$master_branch && \
        printf "\n$master_branch branch rebased to upstream/$master_branch\nRun 'git push origin $master_branch -f' now to push the changes\n" || \
        printf "Failed merging changes!\n"
else
    printf "No upstream branch found! Add it with 'git remote add upstream <URL>'\n"
    exit
fi
