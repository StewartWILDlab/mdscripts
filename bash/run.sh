#!/usr/bin/bash

# VARS
STORAGE_DIR="/media/vlucet/TrailCamST/TrailCamStorage"
BASE_FOLDER="/home/vlucet/Documents/WILDLab/repos/MDtest/git"
MD_FOLDER="$BASE_FOLDER/cameratraps"
MODEL="md_v5a.0.0.pt"
CHECKPOINT_FREQ=1000

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
echo "Directory list:"
printf "%s\n" "${DIRS[@]}"

# For each folder, run md
echo "Running MD"

OLD_DIR=$PWD
cd $MD_FOLDER

for DIR in "${DIRS[@]}"; do
    
    RUN_DIR=$STORAGE_DIR/$(basename $DIR)
    echo "Running on directory: $RUN_DIR"

    OUTPUT_JSON="$(basename $DIR)_output.json"
    echo $OUTPUT_JSON
    
    CHECKPOINT_PATH="$(basename $DIR)_checkpoint.json"
    echo $CHECKPOINT_PATH

    python $MD_FOLDER/detection/run_detector_batch.py \
        $MD_FOLDER/$MODEL $RUN_DIR $OUTPUT_JSON \
        --output_relative_filenames --recursive \
        --checkpoint_frequency $CHECKPOINT_FREQ \
        --checkpoint_path $CHECKPOINT_PATH

done

cd OLD_DIR