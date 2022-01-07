#!/bin/bash
IFS=$'\n'
RAW_PATH="/home/data/NDClab/datasets/social-context-dataset/sourcedata/raw"
CHECK_PATH="/home/data/NDClab/datasets/social-context-dataset/sourcedata/checked"
PAVLOV="pavlovia"

function verify_sub
{
    name=$1
    # check if sub name contains unexpected chars
    if [[ $name = *[[:space:]]* ]]; then
        echo "improper subject name, contains space."
        return 1
    fi
    echo 1
}

function verify_file
{
    name=$2[@]
    id=$3
    arr=("${!name}")

    # set presence vars as 0
    flanker=0
    dccs=0
    nback=0

    for i in "${!arr[@]}"; do
        file_name="${arr[$i]}"
        # skip if log file
        if [[ $FILE == *.log.gz ]]; then
            continue
        fi
        # check if sub name contains unexpected chars
        if [[ $file_name = *[[:space:]]* ]]; then
            echo "Improper subject name, contains space."
            return 1
        fi

        # select standard portion of file
        segment=$(echo "$file_name" | grep -oP "ft-(flanker|dccs|nback)(-o)?_s\d_r\d_e\d")
        # check if file follows naming conv
        if [[ -z "$segment" ]]; then
            echo "Improper subject name, does not meet standard"
            return 1
        fi

        # extract task
        task=$(echo "$file_name" | grep -oP "(flanker|dccs|nback)")
        if [[ task == "flanker" ]]; then
            flanker=1
        fi
        if [[ task == "dccs" ]]; then
            dccs=1
        fi
        if [[ task == "nback" ]]; then
            nback=1
        fi

        # check if file contains only valid id's
        mapfile -t ids < (cat $file_name | cut -d ',' -f36)
        unset ids[0]

        for val in "${!ids[@]}"; do
            if [[ ${ids[$val]} != id ]]; then
                echo "Improper id value in $file_name"
                return 2
            fi

    # check if all 3 tasks appeared in file-group
    if [[ flanker != 1 || dccs != 1 || nback != 1]]; then
        echo "Subject folder does not contain all tasks."
        return 3
    fi
    echo 1
}


echo "Finding pavlovia datasets"
for DIR in `ls $RAW_PATH`
do
    if [ -e "$RAW_PATH/$DIR/$PAVLOV" ]; then
        echo "Accessing $RAW_PATH/$DIR/$PAVLOV"
        cd $RAW_PATH/$DIR/$PAVLOV

        # store dir names in array
        sub_names=(*/)
        for i in "${!sub_names[@]}"; do
            subject=${sub_names[$i]}
            # get sub id
            id="$(cut -d' ' -f2 <<<$subject)"
            id=${id::-1}

            # check if name is duplicate or improperly named
            valid_name=$(verify_sub $subject)
            if [ "$valid_name" != 1 ]; then
                echo "${array[$i]} $valid_name" 
                exit 9999 
            fi
            echo -e "\\t Checking files of $RAW_PATH/$DIR/$PAVLOV/$subject"
            cd $RAW_PATH/$DIR/$PAVLOV/$subject

            # store file names in array
            file_names=(*)
            # check if files contain all tasks, appropriatley named, 
            # and contain correct ID's
            valid_name=$(verify_file $file_names $id)
            if [ "$valid_name" != 1 ]; then
                echo "${array[$i]} $valid_name \\n" 
                exit 9999 
            fi

            # if passes all checks, create and move to `checked` folder
            echo "\\t Data passes criteria, moving to $CHECK_PATH/$DIR/$PAVLOV/$subject \\n"
            mkdir $CHECK_PATH/$DIR/$PAVLOV/$subject 
            cp $RAW_PATH/$DIR/$PAVLOV/${sub_names[$i]} $CHECK_PATH/$DIR/$PAVLOV/$subject             
                