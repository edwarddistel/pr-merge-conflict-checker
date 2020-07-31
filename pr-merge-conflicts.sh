#!/bin/bash

# Test two git branches for conflicts
test_conflict () {
    BRANCH_ONE=$1
    BRANCH_TWO=$2
    # Get the most recent shared parent
    MERGEBASE=$(git merge-base "$BRANCH_ONE" "$BRANCH_TWO")
    if [ "$mergebase" = "" ];then
        #in case foo and bar have no common ancestor, use the empty tree as the merge base
        mergebase=4b825dc642cb6eb9a060e54bf8d69288fbee4904
    fi
    # Test if the output has conflict markers of "merge" style
    OUTPUT=$(git merge-tree "$MERGEBASE" "$BRANCH_ONE" "$BRANCH_TWO" | awk '/<<<<<<</,/>>>>>>>/')  
    if [ ! -z "$OUTPUT" ];then
        echo "WARNING: $BRANCH_ONE has merge conflicts with $BRANCH_TWO"
    fi 
}

if git pull origin master; then
    # Get current branch and remove special characters
    BRANCH_CURR=$(git rev-parse --abbrev-ref HEAD | sed 's/[\*| ]//g')
    # Read stdout (aka git branches) into array
    IFS=$'\n' read -r -d '' -a BRANCHES < <( git branch -r | sed 's/[\*| ]//g' && printf '\0' )
    # Length of array
    LEN=${#BRANCHES[*]}
    # Array of already checked branches; itself and its remote branch
    CHECKED=("$BRANCH_CURR" "origin/$BRANCH_CURR")

    for (( i=0; i < LEN; i++ )); do
        if [[ ! " ${CHECKED[@]} " =~ " ${BRANCHES[$i]} " ]]; then
            test_conflict "$BRANCH_CURR" "${BRANCHES[$i]}"
        fi
        # Add to checked array
        CHECKED+=("${BRANCHES[$i]}")
    done
fi