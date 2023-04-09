#!/usr/bin/bash

# ------------------------------------------------------------------

## CLI UTILITY FOR Camera trap workflow
## WARNING: Make sure to activate conda env first

# ------------------------------------------------------------------

# Export python path
export PYTHONPATH="$PYTHONPATH:$MD_FOLDER"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/ai4eutils"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/yolov5"

# ------------------------------------------------------------------

print_main_usage(){

    echo ""
    echo "  Usage: camtrap.sh [-a run all] [-p prep only]"
    echo ""
    echo "  Subcommands: md, convert"
}

# ------------------------------------------------------------------

export_default_vars(){

    # STORAGE_DIR="/media/vlucet/TrailCamST/TrailCamStorage"
    STORAGE_DIR="/home/vlucet/Documents/WILDLab/mdtools/tests/test_images/"
    BASE_FOLDER="/home/vlucet/Documents/WILDLab/repos/MDtest/git"
    
    MD_FOLDER="$BASE_FOLDER/cameratraps"
    MODEL="md_v5a.0.0.pt"
    CHECKPOINT_FREQ=1000
    THRESHOLD_FILTER=0.1
    # THRESHOLD=0.0001

    OVERWRITE_MD=true
    OVERWRITE_LS=true
    OVERWRITE_MD_CSV=true
    OVERWRITE_EXIF_CSV=true

    OVERWRITE_COMBINED=true
    OVERWRITE_MD_COMBINED=false
    OVERWRITE_EXIF_COMBINED=false
}

print_vars(){

    echo ""
    echo "Variables for MD: "
    echo "      STORAGE_DIR = $STORAGE_DIR"
    echo "      BASE_FOLDER = $BASE_FOLDER"
    echo "      MD_FOLDER = $MD_FOLDER"
    echo "      MODEL = $MODEL"
    echo "      CHECKPOINT_FREQ = $CHECKPOINT_FREQ"
    echo "      THRESHOLD_FILTER = $THRESHOLD_FILTER"
    echo ""
    echo "Variables for workflow: "
    echo "      OVERWRITE_MD = $OVERWRITE_MD"
    echo "      OVERWRITE_LS = $OVERWRITE_LS"
    echo "      OVERWRITE_MD_CSV = $OVERWRITE_MD_CSV"
    echo "      OVERWRITE_EXIF_CSV = $OVERWRITE_EXIF_CSV"
    # echo "      OVERWRITE_COMBINED = $OVERWRITE_COMBINED"
    # echo "      OVERWRITE_EXIF_COMBINED = $OVERWRITE_EXIF_COMBINED"
    echo ""
}

crawl_dirs(){

    # Start with empty array
    DIRS=()

    # Find all folders
    echo "Finding all folders"
    for FILE in $STORAGE_DIR/*; do
        [[ -d $FILE ]] && DIRS+=("$FILE")
    done

    echo "      Directory list:"
    printf "      %s\n" "${DIRS[@]}"
    echo ""

    export DIRS
}

run_prep(){
    export_default_vars
    print_vars
    crawl_dirs
}

run_all(){
    run_prep
    run_md
    run_convert
}

run_md(){

    OLD_DIR=$PWD

    for DIR in "${DIRS[@]}"; do # "P072"; do 

        echo "*** RUNNING MD ***"

        RUN_DIR=$STORAGE_DIR/$(basename $DIR)
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON="$(basename $DIR)_output.json"
        echo $OUTPUT_JSON
        
        CHECKPOINT_PATH="$(basename $DIR)_checkpoint.json"
        echo $CHECKPOINT_PATH

        if [ -f "$STORAGE_DIR/$OUTPUT_JSON" ] && [ "$OVERWRITE_MD" != true ]; then # if output exist, do nothing
            
            echo "Output file $OUTPUT_JSON exists, moving to the next folder"

        elif [ -f "$STORAGE_DIR/$CHECKPOINT_PATH" ]; then # else, if checkpoint exists, use it

            python $MD_FOLDER/detection/run_detector_batch.py \
                $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
                --output_relative_filenames --recursive \
                --checkpoint_frequency $CHECKPOINT_FREQ \
                --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
                --quiet \
                --include_max_conf \
                --resume_from_checkpoint $STORAGE_DIR/$CHECKPOINT_PATH \
                --allow_checkpoint_overwrite #--threshold $THRESHOLD

        else # else, start new run
            python $MD_FOLDER/detection/run_detector_batch.py \
                $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
                --output_relative_filenames --recursive \
                --include_max_conf \
                --checkpoint_frequency $CHECKPOINT_FREQ \
                --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
                --quiet #--threshold $THRESHOLD
        fi

    done

    cd $OLD_DIR
}

run_convert(){

    OLD_DIR=$PWD

    for DIR in "${DIRS[@]}"; do

        echo "*** RUNNING CONVERTER TO LS ***"

        RUN_DIR=$STORAGE_DIR/$(basename $DIR)
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON="$(basename $DIR)_output.json"
        echo $OUTPUT_JSON

        OUTPUT_JSON_LS="$(basename $DIR)_output_ls.json"
        echo $OUTPUT_JSON_LS

        if [ -f "$STORAGE_DIR/$OUTPUT_JSON_LS" ] && [ "$OVERWRITE_LS" != true ]; then # if output exist, do nothing
            
            echo "Output file $OUTPUT_JSON_LS exists, moving to the next folder"

        else

            mdtools convert ls $STORAGE_DIR/$OUTPUT_JSON $RUN_DIR -ct $THRESHOLD_FILTER \
                -ru "data/local-files/?d=$(basename $STORAGE_DIR)/$(basename $DIR)" \
                --write-ls --write-csv --write-coco
        fi

    done

    cd $OLD_DIR
}

# ------------------------------------------------------------------

while getopts ":ap" opt; do
  case ${opt} in
    a )
      run_all
      ;;
    p )
      run_prep
      ;;
    \? )
      print_main_usage
      echo "" 1>&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

subcommand=$1; shift # remove subcommand from the argument list
case "$subcommand" in

  md)

    run_prep
    run_md    

    shift $((OPTIND -1))
    ;;

  convert)

    run_prep
    run_convert

    shift $((OPTIND -1))
    ;;

esac

# ------------------------------------------------------------------
