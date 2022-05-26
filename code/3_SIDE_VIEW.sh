#!/bin/bash

GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

echo ""
echo ""
echo -e "${GREEN}**************************************************WELCOME TO USE SIDE-VIEW IMAGE PHENOTYPING SYSTEM ***************************************************${NC}"
echo -e "${GREEN}********************************************Please answer the following questions to launch analysis**************************************************${NC}"
echo ""
echo ""
read -p "Please provide the directory where source codes were saved: " CODE_DIR
read -p "Please provide the directory where images for analysis were saved: " IMAGE_DIR
read -p "Which rotation frame is for those images been saved ? (Example: RaspiA): " FRAME_ID
read -p "Are different parameters been used for plants under ${FRAME_ID} across different batches ? (Type in "Yes" or "No") " ANSWER1
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
read -p "Please provide the directory where results to be saved after analysis: " OUTPUT_DIR
echo ""
echo ""

### Define the name of projects
if [[ $ANSWER1 == "No" ]]
then 
    ### Define project name
    PROJECT=$(echo ${FRAME_ID})
else
    PROJECT=$(echo ${FRAME_ID}_${BATCH_NAME})
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

### Define the start and end data of experiments based on input and output
startdate=$START_YEAR$START_MONTH$START_DATE
enddate=$END_YEAR$END_MONTH$END_DATE
dates=()
for (( date="$startdate"; date != enddate; )); do
    dates+=( "$date" )
    date="$(date --date="$date + 1 days" +'%Y%m%d')"

    ### extract the specific timestamp based on start-end date interval
    date_update=$(date -d $date +'%Y.%m.%d')
    # redefine the INFO for extracting images 

    INFO=$(echo ${FRAME_ID})

    ### copy images with specific date from intervals
    PATTERN=${IMAGE_DIR}/${INFO}_side?_$date_update-??.??.??.jpg

    if ls $PATTERN 1> /dev/null 2>&1
    then
        cp ${IMAGE_DIR}/${INFO}_side?_$date_update-??.??.??.jpg ${OUTPUT_DIR}/$PROJECT/Clean_image
    else
         echo ""
         echo -e "${BLUE}WARNING: Images taken from $date_update under the ${INFO} do not existed${NC}"
         echo ""
    fi
done

echo ""
echo ""
echo "One random image per day from $START_YEAR.$START_MONTH.$START_DATE to $END_YEAR.$END_MONTH.$END_DATE will be selected to validate parameter information...... "
for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f2,3 | cut -d "-" -f1 | sort | uniq);
do
    SELECT=$(ls ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}_side?_????.$i-??.??.??.jpg | shuf -n 1)
    cp $SELECT ${OUTPUT_DIR}/${PROJECT}/Test_image
done

echo "The paramter for $FRAME_ID from database will be loaded for analysis" 
### Extract parameter in database for analyis
if [[ $ANSWER1 == "No" ]]
then 
    grep $FRAME_ID $CODE_DIR/SIDEVIEW_database > ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter 
    echo ""
    echo ""
    echo "The paramters for $FRAME_ID were loaded" 
else
    echo ""
    echo ""
    echo "The paramters of $FRAME_ID for $BATCH_NAME were loaded" 
    grep $FRAME_ID $CODE_DIR/SIDEVIEW_database | grep $BATCH_NAME > ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter
fi

ROW_NUMBER=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | wc -l)
if [[ $ROW_NUMBER == 0 ]]
then
    echo ""
    echo -e "${RED}ERROR: No record of parameter found from SIDEVIEW_parameter! Please check if $BATCH_NAME for $RIG_ID under the $CAMERA matched the SIDEVIEW_parameter......${NC}"
else
    COLUMN_NUMBER=$(awk '{print NF}' ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | sort -nu | tail -n 1)
    if [[ $COLUMN_NUMBER -ne 13 ]]
    then
        echo ""
        echo -e "${RED}ERROR: Incorrect column(s) numbers from SIDEVIEW_parameter! Please check the format and re-launch analysis......${NC}"
    else
        ### Loading parameters for image processing
        echo ""
        echo ""
        echo -e "${GREEN}*** STEP 2 Loading parameters for image processing......***${NC}"

        #READ PARAMETER
        degree=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $2 }')
        WBx=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $3 }')
        WBy=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $4 }')
        WBw=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $5 }')
        WBh=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $6 }')
        threshold1=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $7 }')
        threshold2=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $8 }')
        roix=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $9 }')
        roiy=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $10 }')
        roiw=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $11 }')
        roih=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | awk '{ print $12 }')

        echo -e "${BLUE}The following parameter will be applied for image analysis${NC}"
        echo ""
        echo ""
        echo -e "${BLUE}Degree for image rotation is:${NC} $degree"
        if [[ $WBx != "NA" ]]
        then 
            echo -e "${BLUE}Coordinates of white balance correction is: ${NC}x=$WBx y=$WBy w=$WBw h=$WBh"
        else
            echo -e "${BLUE} No white balance correation coordinates specified, will skip this correation step ${NC}"
        fi
        echo -e "${BLUE}Threshold for masking is:${NC} $threshold1 for V channel and $threshold2 and A channel"
        echo -e "${BLUE}Coordinate of ROI is:${NC} x=$roix y=$roiy w=$roiw h=$roih"

        echo ""
        echo ""
        echo -e "${GREEN}*** STEP 2 Generating python scripts and json configuration file for selected rig based on metadata......***${NC}"

        #replace python scripts with selected parameter
        sed "s/DEGREE/$degree/g" $CODE_DIR/side_view.py | \
            sed "s/WBX/$WBx/g" | \
            sed "s/WBY/$WBy/g" | \
            sed "s/WBW/$WBw/g" | \
            sed "s/WBH/$WBh/g" | \
            sed "s/THRESHOLD1/$threshold2/g" | \
            sed "s/THRESHOLD2/$threshold2/g" | \
            sed "s/roix/$roix/g" | \
            sed "s/roiy/$roiy/g" | \
            sed "s/roiw/$roiw/g" | \
            sed "s/roih/$roih/g" > ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.sidetemp.py

        ### generate final python script based on presense or absence of white balance parameter
        if [[ $WBx != "NA" ]]
        then 
            mv ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.sidetemp.py ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.py
        else
            grep -v "pcv.white_balance" ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.sidetemp.py > ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.py
            rm ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.sidetemp.py
        fi  

        #replace json scripts with selected parameter
        sed "s@INPUT@${OUTPUT_DIR}/${PROJECT}/Test_image@g" $CODE_DIR/side_view.json | \
            sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/${PROJECT}.result.json@g" | \
            sed "s@WORKFLOW@${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.py@g" | \
            sed "s@OUTDIR@${OUTPUT_DIR}/${PROJECT}/Results_images@g" > ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.json

        echo ""
        echo ""
        echo -e "${GREEN}*** STEP 3 Batch analysis will be launched for one image per day to test parameter ......***${NC}"
        echo ""
        ### Use image per day image as examples to check if parameter works well for samples
        python $CODE_DIR/plantcv-workflow.py \
            --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.json

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
            
            ### update the json configure file 
            sed "s@INPUT@${OUTPUT_DIR}/${PROJECT}/Clean_image@g" $CODE_DIR/side_view.json | \
                sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/${FRAME_ID}.result.json@g" | \
                sed "s@WORKFLOW@${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.py@g" | \
            sed "s@OUTDIR@${OUTPUT_DIR}/${PROJECT}/Results_images@g" > ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side-all.json

            ### Perform analysis for all images
            python $CODE_DIR/plantcv-workflow.py \
                --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side-all.json

            python $CODE_DIR/plantcv-workflow.py json2csv \
                --json ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json \
                --csv ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result

            echo ""
            echo "${GREEN}*** Image analysis finished ! Please check results under the ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.csv..... ***${NC}"
            echo ""
            echo -e "${GREEN}*************************************** Thanks for using SIDE_VIEW PIPELINES ***************************************${NC}"
            echo ""
        else 
            echo ""
            echo -e "${GREEN}****************Please optimize the parameters for using jupyter notebook and relauch this pipeline.....******************${NC}" 
            echo ""
        fi
    fi
fi