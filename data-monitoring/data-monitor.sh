#!/bin/bash
IFS=$'\n'
RAW_PATH="/home/data/NDClab/datasets/social-context-dataset/sourcedata/raw"
CHECK_PATH="/home/data/NDClab/datasets/social-context-dataset/sourcedata/checked"
PAVLOV = "pavlovia"

function verify_sub
{
    name=$1
    if [[ $name = *[[:space:]]* ]]; then
        echo "improper subject name, contains space."
        return 1
    fi
    echo 1
}

function verify_file
{
    ind=$1
    name=$2[@]
    arr=("${!name}")

    sub_name="${arr[$ind]}"
    if [[ $sub_name = *[[:space:]]* ]]; then
        echo "improper subject name, contains space."
        return 1
    fi
    echo 1
}


echo "Finding pavlovia datasets"
for DIR in `ls $RAW_PATH`
do
    if [ -e "$DATA_PATH/$DIR/$PAVLOV" ]; then
        echo "Accessing $DATA_PATH/$DIR/$PAVLOV"
        cd $DATA_PATH/$DIR/$PAVLOV

        # store dir names in array
        sub_names=(*/)
        for i in "${!sub_names[@]}"; do
            # check if name is duplicate or improperly named
            valid_name=$(verify_name ${sub_names[$i]})
            if [ "$valid_name" != 1 ]; then
                echo "${array[$i]} $valid_name" 
                exit 9999 
            fi
            echo "\t Checking files of $DATA_PATH/$DIR/$PAVLOV/${sub_names[$i]}"
            cd $DATA_PATH/$DIR/$PAVLOV/${sub_names[$i]}

            # store file names in array
            file_names=(*/)
            for i in "${!file_names[@]}"; do
                # check if files contain all tasks, appropriatley named, 
                # and contain correct ID's
                valid_name=$(verify_name $i $sub_names)
                if [ "$valid_name" != 1 ]; then
                    echo "${array[$i]} $valid_name" 
                    exit 9999 
                fi
