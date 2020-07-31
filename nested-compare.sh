#!/bin/bash

# Place this script in the root of a git repository
# It will pull the list of all remote branches then compare them with each other
# If it finds the unique pattern for git merge conflict <<<< >>>> it will report a problem

# Test two git branches for conflicts
test_conflict () {
    BRANCH_ONE=$1
    BRANCH_TWO=$2
    # Get hash of base base branch
    MERGEBASE=$(git merge-base "$BRANCH_ONE" "$BRANCH_TWO")
    if [ "$mergebase" = "" ];then
        #in case foo and bar have no common ancestor, use the empty tree as the merge base
        mergebase=4b825dc642cb6eb9a060e54bf8d69288fbee4904
    fi
    #echo "comparing $BRANCH_ONE with $BRANCH_TWO =======================================================" >> /tmp/git-compare
    # Three-way comparison between most recent parent and two branches
   OUTPUT=$(git merge-tree "$MERGEBASE" "$BRANCH_ONE" "$BRANCH_TWO" | awk '/<<<<<<</,/>>>>>>>/')  
   if [ ! -z "$OUTPUT" ];then
        echo "WARNING: $BRANCH_ONE has merge conflicts with $BRANCH_TWO"
    fi 
}

# If valid git dir
if git pull origin master; then
    # Read stdout (aka git branches) into array
    IFS=$'\n' read -r -d '' -a BRANCHES < <( git branch -r | sed 's/[\*| ]//g' && printf '\0' )

    # Array of already checked branches; itself and its remote branch
    CHECKED=("$BRANCH_CURR" "origin/$BRANCH_CURR")

    # Remove origin/HEAD from array
    REGEX="origin/HEAD"*
    for i in "${!BRANCHES[@]}"; do
        if [[ " ${BRANCHES[i]} " =~ $REGEX ]] || [[ " ${BRANCHES[i]} " == " $BASE_BRANCH " ]] || [[ " ${BRANCHES[i]} " == "origin/master" ]] ; then
            unset BRANCHES[$i]
        fi
    done

    # Length of array
    LEN=${#BRANCHES[*]}

    # Nested loop to compare branches vs each other
    for (( i=0; i < LEN; i++ )); do
        for (( j=$((i+1)); j < LEN; j++ )); do 
            # Skip if branches already compared once
            if [[ ! " ${CHECKED[@]} " =~ ${BRANCHES[$i]} ]]; then
                test_conflict "${BRANCHES[$i]}" "${BRANCHES[*]:$j:1}"
            fi
        done
        # Add to checked array
        CHECKED+=("${BRANCHES[$i]}")
    done
fi