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
        echo "Improper subject name, contains space."
        exit 1
    fi
    exit 0
}

function verify_files
{
    elements=("$@")
    id=${elements[-1]}
    
    # potential bug in REDcap?
    # unset elements[-1]
    last_idx=$(expr ${#elements[@]} - 1)

    # set presence vars as 0
    flanker=0
    dccs=0
    nback=0

    for i in "${!elements[@]}"; do
        # if last index is accessed (id), exit loop
        if [[ $i == $last_idx ]]; then
            continue
        fi

        file_name="${elements[$i]}"
        # skip if log file
        if [[ $file_name == *.log.gz ]]; then
            continue
        fi
        # check if file name contains unexpected chars
        if [[ $file_name = *[[:space:]]* ]]; then
            echo -e "Improper file name $file_name, contains space."
            exit 1
        fi

        # select standard portion of file
        segment=$(echo "$file_name" | grep -oP "ft-(flanker|dccs|nback)(-o)?_s\d_r\d_e\d")
        # check if file follows naming conv
        if [[ -z "$segment" ]]; then
            echo -e "Improper file name $file_name, does not meet standard"
            exit 1
        fi

        # extract task
        task=$(echo "$file_name" | grep -oP "(flanker|dccs|nback)")
        if [[ $task == "flanker" ]]; then
            flanker=1
        fi
        if [[ $task == "dccs" ]]; then
            dccs=1
        fi
        if [[ $task == "nback" ]]; then
            nback=1
        fi

        # check if file contains only valid id's
        id_col=$(head -1 $file_name | tr ',' '\n' | cat -n | grep -w "id" | awk '{print $1}')
        mapfile -t ids < <(cat $file_name | cut -d ',' -f $id_col)
        unset ids[0]

        for val in "${!ids[@]}"; do
            if [[ ${ids[$val]} != "$id" ]]; then
                echo "Improper id value of ${ids[$val]} in $file_name. Must equal $id"
                exit 2
            fi
	done
    done

    # check if all 3 tasks appeared in file-group
    if [[ $flanker != 1 || $dccs != 1 || $nback != 1 ]]; then
        echo "Subject folder does not contain all tasks."
        exit 3
    fi
    exit 0
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

 	    # check accessibility of file system
	    if ! [[ -x "$RAW_PATH/$DIR/$PAVLOV/$subject" ]]; then
                echo -e "\\t $subject is not accessible via your permissions \\n" 
                continue
            fi

            # get sub id
            id="$(cut -d'-' -f2 <<<$subject)"
            id=${id::-1}

            # check if name is improperly named
            valid_name=$(verify_sub $subject)
            res=$?
            if [ $res != 0 ]; then
                echo "error: $subject $valid_name" 
                exit 9999 
            fi
            echo -e "\\t Checking files of $RAW_PATH/$DIR/$PAVLOV/$subject"
            cd $RAW_PATH/$DIR/$PAVLOV/$subject

            # store file names in array
            file_names=(*)

            # check if files contain all tasks, appropriatley named, 
            # and contain correct ID's
            valid_files=$(verify_files "${file_names[@]}" $id)
            res=$?
            if [ $res != 0 ]; then
                echo "error: $subject $valid_files \\n" 
                exit 9999 
            fi

            # if passes all checks, create and move to `checked` folder
            echo -e "\\t Data passes criteria, moving to $CHECK_PATH/$DIR/$PAVLOV/$subject \\n"
            if [ ! -e "$CHECK_PATH/$DIR" ]; then
            	mkdir $CHECK_PATH/$DIR
	    fi
	    if [ ! -e "$CHECK_PATH/$DIR/$PAVLOV" ]; then
                mkdir $CHECK_PATH/$DIR/$PAVLOV
            fi
            if [ ! -e "$CHECK_PATH/$DIR/$PAVLOV/$subject" ]; then
               mkdir $CHECK_PATH/$DIR/$PAVLOV/$subject
            fi 
            cp -r $RAW_PATH/$DIR/$PAVLOV/$subject $CHECK_PATH/$DIR/$PAVLOV/$subject             
        done
    fi
done        
