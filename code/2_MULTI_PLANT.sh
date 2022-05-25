#!/bin/bash

GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

echo ""
echo ""
echo -e "${GREEN}*********************************** WELCOME TO USE MULTI_PLANTS PIPELINE FOR IMAGES ***********************************${NC}"
echo -e "${GREEN}*******************************Please answer the following questions to launch analysis********************************${NC}"
echo ""
echo ""
read -p "Please provide the directory where source codes were saved: " CODE_DIR
read -p "Please provide the directory where images for analysis were saved: " IMAGE_DIR
read -p "Which plant rig ID is for those images been saved ? (Example: raspiA): " RIG_ID
read -p "Which camera ID is for those images been saved ? (Please type in cameraA or cameraB): " CAMERA
read -p "Are different parameters been used for plants under ${RIG_ID} ${CAMERA} across different batches ? (Type in "Yes" or "No") " ANSWER1
if [[ $ANSWER1 == "Yes" ]]
then
    read -p "What is the name for this pairticular batch (Warning: The name of batch should be identical to the name in meta-table, eg: BATCH1): " BATCH_NAME
fi
echo ""
read -p "What is the year when experiment started (FORMAT: YYYY, eg: 2022): " START_YEAR
read -p "What is the year when experiment ended (FORMAT: YYYY, eg: 2022): " END_YEAR
read -p "What is the month when experiment started (FORMAT: MM, eg: 08): " START_MONTH
read -p "What is the month when experiment ended (FORMAT: MM, eg: 08): " END_MONTH
read -p "What is the date when experiment started (FORMAT: DD, eg: 01): " START_DATE
read -p "What is the date when experiment end (FORMAT: DD, eg: 01): " END_DATE
echo ""
read -p "What is the time when the light on for your experiments (Hour and minute, FORMAT: HH.MM, 09.30): " START_TIME
read -p "What is the time when the light off for your experiments (Hour and minute, FORMAT: HH.MM, 20.30): " END_TIME
echo ""
read -p "Please provide the directory where results to be saved after analysis " OUTPUT_DIR
echo ""
echo ""

### Define the name of projects
if [[ $ANSWER1 == "No" ]]
then 
    ### Define project name
    PROJECT=$(echo ${RIG_ID}_${CAMERA})
else
    PROJECT=$(echo ${RIG_ID}_${CAMERA}_${BATCH_NAME})
fi

### Create new directory for projects
if [ -d "${OUTPUT_DIR}/$PROJECT" ]
then
    echo ""
    echo ""
    echo -e "${BLUE}WARNING: Directory ${OUTPUT_DIR}/$PROJECT exists. Results will be overwritten${NC}"
    rm -r ${OUTPUT_DIR}/$PROJECT
fi

### Build file for parameter results output
mkdir ${OUTPUT_DIR}/$PROJECT
### for images
mkdir ${OUTPUT_DIR}/$PROJECT/Clean_image
mkdir ${OUTPUT_DIR}/$PROJECT/Test_image
### for results
mkdir ${OUTPUT_DIR}/$PROJECT/Configure
mkdir ${OUTPUT_DIR}/$PROJECT/Results
mkdir ${OUTPUT_DIR}/$PROJECT/Results_images

echo -e "${GREEN}*** STEP 1 Images for experiments will be loaded ***${NC}" 

### Define the start and end data of experiments based on input and output
START_DATE=$(expr $START_DATE - 1)
if (( $START_DATE >= 10 ))
then
    START_DATE="$START_DATE"
else
    START_DATE="0$START_DATE"
fi

startdate=$START_YEAR$START_MONTH$START_DATE
enddate=$END_YEAR$END_MONTH$END_DATE
dates=()
for (( date="$startdate"; date != enddate; )); do
    dates+=( "$date" )
    date="$(date --date="$date + 1 days" +'%Y%m%d')"

    ### extract the specific timestamp based on start-end date interval
    date_update=$(date -d $date +'%Y.%m.%d')
    # redefine the INFO for extracting images 

    INFO=$(echo ${RIG_ID}_${CAMERA})

    ### copy images with specific date from intervals
    PATTERN=${IMAGE_DIR}/${INFO}.$date_update-??.??.??.jpg

    if ls $PATTERN 1> /dev/null 2>&1
    then
        cp ${IMAGE_DIR}/${INFO}.$date_update-??.??.??.jpg ${OUTPUT_DIR}/$PROJECT/Clean_image
    else
         echo ""
         echo -e "${BLUE}WARNING: Images taken from $date_update under the ${INFO} do not existed${NC}"
         echo ""
    fi
done

### Define the start and end time stamp of experiments
### remove images taken during night (dark images)
echo ""
echo ""
echo "Images during night from $END_TIME to $START_TIME will be removed "
for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f4,5 | cut -d "-" -f2 | sort | uniq | awk -v a=$START_TIME -v b=$END_TIME '$1< a || $1> b {print $0}');
do
	rm ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}.????.??.??-$i.??.jpg
done

echo ""
echo "One random image per day from $START_YEAR.$START_MONTH.$START_DATE to $END_YEAR.$END_MONTH.$END_DATE will be selected to validate parameter information...... "
for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f3,4 | cut -d "-" -f1 | sort | uniq);
do
    SELECT=$(ls ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}.????.$i-??.??.??.jpg | shuf -n 1)
    cp $SELECT ${OUTPUT_DIR}/${PROJECT}/Test_image
done


### Extract parameter in database for analyis
if [[ $ANSWER1 == "No" ]]
then 
    grep $CAMERA $CODE_DIR/MULTI_database | grep $RIG_ID > ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter 
    echo ""
    echo ""
    echo "The paramters for $RIG_ID under the $CAMERA were loaded" 
else
    echo ""
    echo ""
    echo "The paramters of $BATCH_NAME for $RIG_ID under the $CAMERA were loaded" 
    grep $CAMERA $CODE_DIR/MULTI_database | grep $RIG_ID | grep $BATCH_NAME > ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter
fi

ROW_NUMBER=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | wc -l)
if [[ $ROW_NUMBER == 0 ]]
then
    echo ""
    echo -e "${RED}ERROR: No record of parameter found from SIDEVIEW_parameter! Please check if $BATCH_NAME for $RIG_ID under the $CAMERA matched the SIDEVIEW_parameter......${NC}"
else
    COLUMN_NUMBER=$(awk '{print NF}' ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | sort -nu | tail -n 1)
    if [[ $COLUMN_NUMBER -ne 20 ]]
    then
        echo ""
        echo -e "${RED}ERROR: Incorrect column(s) numbers from SIDEVIEW_parameter! Please check the format and re-launch analysis......${NC}"
    else

        ### Loading parameters for image processing
        echo ""
        echo ""
        #read parameter for white balance
        white_X=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $3 }')
        white_Y=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $4 }')
        white_W=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $5 }')
        white_H=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $6 }')
        #read parameter for moving image
        deg=$(cat $PROJECT/Configure/MULTI_parameter | awk '{ print $7 }')
        shift1_size=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $8 }')
        shift1_dir=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $9 }')
        shift2_size=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $10 }')
        shift2_dir=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $11 }')
        #read parameter for cutoff
        threshold=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $12 }')
        #read parameter for ROI
        ROIx=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $13 }')
        ROIy=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $14 }')
        ROIw=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $15 }')
        ROIh=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $16 }')
        #read paramter for reference plant
        plantx=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $17 }')
        planty=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $18 }')
        radius=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/MULTI_parameter | awk '{ print $19 }')

        #ASSIGN PARAMETERS
        white_balance="$white_X, $white_Y, $white_W, $white_H"
        rotations="rotation_deg=$deg"
        shift1="img=img1, number=$shift1_size, side='$shift1_dir'"
        shift2="img=imgs, number=$shift2_size, side='$shift2_dir'"
        ROI="x=$ROIx, y=$ROIy, w=$ROIw, h=$ROIh"

        echo ""
        echo ""
        #ECHO ALL PARAMETERS FOR CHECK
        echo "${BLUE}The following parameter will be applied for image analysis${NC}"
        echo ""
        echo -e "${BLUE}Range for white balance calibration is:${NC} x=$white_X, y=$white_Y, w=$white_W, h=$white_H"
        echo -e "${BLUE}rotation degree is:${NC} $deg" 
        echo -e "${BLUE}threshold for masking is:${NC} $threshold"
        echo -e "${BLUE}pixels to be shifted $shift1_dir is:${NC} $shift1_size"
        echo -e "${BLUE}pixels to be shifted $shift2_dir is:${NC} $shift2_size"
        echo -e "${BLUE}region of interest (ROI) is:${NC} $ROI"
        echo -e "${BLUE}coordinate of the the first plant to be analyzed is:${NC} x=$plantx, y=$planty"
        echo -e "${BLUE}radius for each plant is:${NC} $radius"
        echo ""
        echo ""

        echo -e "${GREEN}*** STEP 2 Generating python scripts and json configuration file for selected rig based on metadata......***${NC}"

        #replace python scripts
        sed "s/white_Xwhite_Ywhite_Wwhite_H/$white_balance/g" $CODE_DIR/multi_plant.py | \
            sed "s/rotation_deg=/$rotations/g" | \
            sed "s/cut_off/$threshold/g" | \
            sed "s/img=img1, number=shift1, side=dir1/$shift1/g" | \
            sed "s/img=imgs, number=shift2, side=dir2/$shift2/g" | \
            sed "s/ROIxROIyROIwROIh/$ROI/g" | \
            sed "s/plantx/$plantx/g" | \
            sed "s/planty/$planty/g" | \
            sed "s/VALUE/$radius/g" > ${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.multi.py

        #repalce json scripts
        sed "s@INPUT@${OUTPUT_DIR}/$PROJECT/Test_image@g" $CODE_DIR/multi_plant.json | \
            sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json@g" | \
            sed "s@WORKFLOW@${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.multi.py@g" | \
            sed "s@OUTDIR@${OUTPUT_DIR}/$PROJECT/Results_images@g" > ${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.multi.json

        echo ""
        echo ""
        echo -e "${GREEN}*** STEP 3 Batch analysis will be launched for one image per day to test parameter ......***${NC}"
        echo ""
        ### Use image per day image as examples to check if parameter works well for samples
        python $CODE_DIR/plantcv-workflow.py \
            --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.multi.json

        echo ""
        echo ""
        echo -e "${GREEN}***STEP 4 Check if parameters works well with selected images ......***${NC}"
        read -p "Do you want to check images by pop-up window under: ${OUTPUT_DIR}/${PROJECT}/Results_images ? (Type in "Yes" or "No") " ANSWER2
        if [[ $ANSWER2 == "Yes" ]]
        then
            for i in $(ls ${OUTPUT_DIR}/${PROJECT}/Results_images); 
            do
                display ${OUTPUT_DIR}/${PROJECT}/Results_images/$i && read -p "Press [Enter] key to continue..."; 
            done
        else
            echo ""
            echo ""
            echo -e "${BLUE}***PLEASE check images under : ${OUTPUT_DIR}/${PROJECT}/Results_images ......***${NC}"
        fi

        ### Check if parameters works well with selected images
        echo ""
        echo ""
        read -p "Are parameters been used fit images under: ${OUTPUT_DIR}/${PROJECT}/Results_images ? (Type in "Yes" or "No") " ANSWER3

        if [[ $ANSWER3 == "Yes" ]]
        then
            echo ""
            echo ""
            echo -e "${GREEN}*** STEP 5 Batch analysis will be launched for selected images based on paramter sets from last step ***${NC}"  
            echo ""
            echo ""
            ### update the json configure file 
            sed "s@INPUT@${OUTPUT_DIR}/$PROJECT/Clean_image@g" $CODE_DIR/multi_plant.json | \
                sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json@g" | \
                sed "s@WORKFLOW@${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.multi.py@g" | \
                sed "s@OUTDIR@${OUTPUT_DIR}/$PROJECT/Results_images@g" > ${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.multi-all.json

            ### Perform analysis for all images
            python $CODE_DIR/plantcv-workflow.py \
                --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.multi-all.json

            python $CODE_DIR/plantcv-utils.py json2csv \
                --json ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json \
                --csv ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.csv
            echo ""
            echo "${GREEN}*** Image analysis finished ! Please check results under the ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.csv..... ***${NC}"
            echo ""
            echo -e "${GREEN}*************************************** Thanks for using MULTI_PLANTS PIPELINES ***************************************${NC}"
            echo ""
        else 
            echo ""
            echo -e "${GREEN}****************Please optimize the parameters for using jupyter notebook and relauch this pipeline.....******************${NC}" 
            echo ""
        fi
    fi
fi