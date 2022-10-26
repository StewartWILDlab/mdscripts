#!/usr/bin/bash

## CLI UTILITY FOR MD RUN

# VARS
STORAGE_DIR="/media/vlucet/TrailCamST/TrailCamStorage"
BASE_FOLDER="/home/vlucet/Documents/WILDLab/repos/MDtest/git"
MD_FOLDER="$BASE_FOLDER/cameratraps"
MODEL="md_v5a.0.0.pt"
CHECKPOINT_FREQ=1000
THRESHOLD_FILTER=0.1
# THRESHOLD=0.0001

# Export python path
export PYTHONPATH="$PYTHONPATH:$MD_FOLDER"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/ai4eutils"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/yolov5"

# Activate conda env (doesnt work)
# echo "Activating conda env"
# conda activate /home/vlucet/anaconda3/envs/cameratraps-detector

# Start with empty array
DIRS=()

# Find all folders
echo "Finding all folders"
for FILE in $STORAGE_DIR/*; do
    [[ -d $FILE ]] && DIRS+=("$FILE")
done

# Print the list
# echo "Directory list:"
# printf "%s\n" "${DIRS[@]}"

OLD_DIR=$PWD
cd $MD_FOLDER

for DIR in "${DIRS[@]}"; do

    #echo "*** RUNNING MD ***"
    
    RUN_DIR=$STORAGE_DIR/$(basename $DIR)
    echo "Running on directory: $RUN_DIR"

    OUTPUT_JSON="$(basename $DIR)_output.json"
    echo $OUTPUT_JSON
    
    CHECKPOINT_PATH="$(basename $DIR)_checkpoint.json"
    echo $CHECKPOINT_PATH

    if [ -f "$STORAGE_DIR/$OUTPUT_JSON" ]; then # if output exist, break the loop
        
        echo "Output file $OUTPUT_JSON exists, moving to the next folder"
        continue

    elif [ -f "$STORAGE_DIR/$CHECKPOINT_PATH" ]; then # else, if checkpoint exists, use it

        python $MD_FOLDER/detection/run_detector_batch.py \
            $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
            --output_relative_filenames --recursive \
            --checkpoint_frequency $CHECKPOINT_FREQ \
            --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
            --quiet \
            --resume_from_checkpoint $STORAGE_DIR/$CHECKPOINT_PATH \
            --allow_checkpoint_overwrite #--threshold $THRESHOLD

    else # else, start new run
        python $MD_FOLDER/detection/run_detector_batch.py \
            $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
            --output_relative_filenames --recursive \
            --checkpoint_frequency $CHECKPOINT_FREQ \
            --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
            --quiet #--threshold $THRESHOLD
    fi

    echo "*** RUNNING CONVERTER ***"

    OUTPUT_JSON_LS="$(basename $DIR)_output_ls.json"
    echo $OUTPUT_JSON_LS

    if [ -f "$STORAGE_DIR/$OUTPUT_JSON_LS" ]; then # if output exist, break the loop
        
        echo "Output file $OUTPUT_JSON_LS exists, moving to the next folder"
        continue

    else

        mdtools convert ls $STORAGE_DIR/$OUTPUT_JSON -ct $THRESHOLD_FILTER -bd $RUN_DIR \
            -ru "data/local-files/?d=$(basename $STORAGE_DIR)/$(basename $DIR)" \
            --write-coco True
    fi

    echo "*** RUNNING CSV ***"

    OUTPUT_CSV="$(basename $DIR)_output.csv"
    echo $OUTPUT_CSV

    if [ -f "$STORAGE_DIR/$OUTPUT_CSV" ]; then # if output exist, break the loop
        
        echo "Output file $OUTPUT_JSON_LS exists, moving to the next folder"
        continue

    else
        mdtools convert csv $STORAGE_DIR/$OUTPUT_JSON
    fi

done

echo "*** COMBINING CSVs ***"

csvstack *_output.csv > combined.csv

cd $OLD_DIR
