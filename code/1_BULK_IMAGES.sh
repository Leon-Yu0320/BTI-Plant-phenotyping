#!/bin/bash
### define color of the output
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

echo ""
echo ""
echo -e "${GREEN}*************************************** WELCOME TO USE BULK ANALYSIS FOR IMAGES ***************************************${NC}"
echo ""
echo -e "${GREEN}use -help argument to show usage information${NC}"

usage() {
      echo ""
      echo -e "${BLUE}Usage : sh $0 -d DESIGN_TABLE -t EXPERIMENT_TYPE -m MODE${NC}"
      echo ""

cat <<'EOF'

  -d [Table] < /path/to/experimental design table stored, refer manual for details of each type of experiments> 

  -t [String] < type in one of the two experiment types: "TOP_VIEW","SIDE_VIEW">

  -m [String] < type in one of the two modes: "SAMPLE","ALL" DEFAULT: "ALL">

  -h Show this usage information

EOF
    exit 0
}

while getopts ":d:t:m:h:" opt; do
  case $opt in
    d)
     DESIGN_TABLE=$OPTARG
      ;;
    t)
     EXPERIMENT_TYPE=$OPTARG
      ;;
    m)
     MODE=$OPTARG
      ;;
    h)
     usage
     exit 1
      ;;      
    \?)
     echo "Invalid option: -$OPTARG" >&2
     exit 1
      ;;
    :)
     echo "Option -$OPTARG requires an argument." >&2
     exit 1
      ;;
  esac
done


### Load Design table which contains all inforamtion 
if [[ $EXPERIMENT_TYPE == "TOP_VIEW" ]]
then 
    echo ""
    echo -e "${GREEN}*** STEP 1 The Experimental design table for $EXPERIMENT_TYPE will be loaded ***${NC}" 
    ### Load experimental design table 
    IFS=$'\n';

    ### Check the format of desith table 
    COLUMN_NUMBER=$(awk '{print NF}' $DESIGN_TABLE | sort -nu | tail -n 1)
    if (($COLUMN_NUMBER != 14)) 
    then
        echo ""
        echo -e "${RED}ERROR: Missing column(s) from $DESIGN_TABLE! Please check the format and re-launch analysis......${NC}"
    else
        for LINE in $(cat $DESIGN_TABLE | sed '1d');do

            CODE_DIR=$(echo ${LINE} | awk '{ print $1 }')
            IMAGE_DIR=$(echo ${LINE} | awk '{ print $2 }')
            RIG_ID=$(echo ${LINE} | awk '{ print $3 }')
            CAMERA=$(echo ${LINE} | awk '{ print $4 }')
            BATCH_NAME=$(echo ${LINE} | awk '{ print $5 }')

            START_YEAR=$(echo ${LINE} | awk '{ print $6 }')
            END_YEAR=$(echo ${LINE} | awk '{ print $7 }')
            START_MONTH=$(echo ${LINE} | awk '{ print $8 }')
            END_MONTH=$(echo ${LINE} | awk '{ print $9 }')
            START_DATE=$(echo ${LINE} | awk '{ print $10 }')
            END_DATE=$(echo ${LINE} | awk '{ print $11 }')
            START_TIME=$(echo ${LINE} | awk '{ print $12 }')
            END_TIME=$(echo ${LINE} | awk '{ print $13 }')
            OUTPUT_DIR=$(echo ${LINE} | awk '{ print $14 }')

            if [[ $BATCH_NAME == "NA" ]]
            then 
              ### Define project name based on RigID and cameraID
              PROJECT=$(echo ${RIG_ID}_${CAMERA})
            else
              ### Define project name based on RigID, cameraID, and BATCHID
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
            echo ""
            echo -e "${GREEN}*** STEP 2 Images for experiments will be loaded ***${NC}" 

            ### Create a temp datestamp based on unique date from the image directory
            ls $IMAGE_DIR/*.jpg | cut -d "." -f2,3,4 | cut -d "-" -f1 | sort | uniq > ${OUTPUT_DIR}/$PROJECT/date.stamp

            ### filter selected date based on duration of expriments
            if [[ $START_YEAR == $END_YEAR ]];
            then
                if [[ $START_DATE -ge $END_DATE ]];
                then
                    awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                        awk -v a=$START_MONTH -v b=$END_MONTH -F "." '$2>=a && $2<=b {print $0}' |\
                        awk -v a=$START_DATE -v b=$END_DATE -v c=$START_MONTH -v d=$END_MONTH -F "." '$2==c && $3>=a || $2==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
                else
                    awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                        awk -v a=$START_MONTH -v b=$END_MONTH -F "." '$2>=a && $2<=b {print $0}' |\
                        awk -v a=$START_DATE -v b=$END_DATE -v c=$START_MONTH -v d=$END_MONTH -F "." '$2==c && $3>=a && $2==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
                fi
            else
                awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                    awk -v a=$START_MONTH -v b=$END_MONTH -v c=$START_YEAR -v d=$END_YEAR -F "." '$1==c && $2>=a || $1==d && $2<=b {print $0}' |\
                    awk -v a=$START_DATE -v b=$END_DATE -v c=$START_YEAR -v d=$END_YEAR -F "." '$1==c && $3>=a || $1==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
            fi

            ### copy images assocaited with the selected stamp to the Clean image dirctory
            INFO=$(echo ${RIG_ID}_${CAMERA})

            for SELECT_STAMP in $(cat ${OUTPUT_DIR}/$PROJECT/select_date.stamp);
            do
                cp ${IMAGE_DIR}/${INFO}.$SELECT_STAMP-??.??.??.jpg ${OUTPUT_DIR}/$PROJECT/Clean_image
            done

            ### remove images taken during night (dark images)
            echo ""
            echo ""
            echo "Images during night from $END_TIME to $START_TIME will be removed "TOPVIE
            for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f4,5 | cut -d "-" -f2 | sort | uniq | awk -v a=$START_TIME -v b=$END_TIME '$1< a || $1> b {print $0}');
            do
              rm ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}.????.??.??-$i.??.jpg
            done

            ### Pick up one random image per day 
            echo "One random image per day from $START_YEAR.$START_MONTH.$START_DATE to $END_YEAR.$END_MONTH.$END_DATE will be saved under ${OUTPUT_DIR}/${PROJECT}/Test_image......"
            for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f3,4 | cut -d "-" -f1 | sort | uniq);
            do
                SELECT=$(ls ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}.????.$i-??.??.??.jpg | shuf -n 1)
                cp $SELECT ${OUTPUT_DIR}/${PROJECT}/Test_image
            done
            ### Loading parameters for image processing
            echo ""
            echo ""
            echo -e "${GREEN}*** STEP 3 The plantcv paramters from database will be loaded for analysis ***${NC}" 

            ### Extract parameter in database for analyis
            if [[ $BATCH_NAME == "NA" ]]
            then 
                grep $CAMERA $CODE_DIR/TOPVIEW_database | grep $RIG_ID > ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter 
                echo ""
                echo ""
                echo "The paramters for $RIG_ID under the $CAMERA were loaded" 
            else
                echo ""
                echo ""
                echo "The paramters of $BATCH_NAME for $RIG_ID under the $CAMERA were loaded" 
                grep $CAMERA $CODE_DIR/TOPVIEW_database | grep $RIG_ID | grep $BATCH_NAME > ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter
            fi

            COLUMN_NUMBER=$(awk '{print NF}' ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | sort -nu | tail -n 1)
            if [[ $COLUMN_NUMBER -ne 20 ]]
            then
                echo ""
                echo -e "${RED}ERROR: Incorrect column(s) numbers from $CODE_DIR/SIDEVIEW_parameter! Please check the format and re-launch analysis......${NC}"
            else
                ### check the numbers of parameters 
                PARAMETER_COUNT=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | wc -l)
                if (( $PARAMETER_COUNT > 1 ))
                then 
                    echo -e "${RED}ERROR:There are $PARAMETER_COUNT sets parameter under the $CODE_DIR/TOPVIEW_database for $PROJECT, please add the BATCH information to distinguish these parameters${NC}"
                elif (( $PARAMETER_COUNT == 0 ))
                then
                    echo -e "${RED}ERROR:There is $PARAMETER_COUNT parameter found under the $CODE_DIR/TOPVIEW_database, please provide the parameter information for $PROJECT${NC}"
                else
                    ### Loading parameters for image processing
                    echo ""
                    #read parameter for white balance
                    white_X=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $3 }')
                    white_Y=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $4 }')
                    white_W=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $5 }')
                    white_H=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $6 }')
                    #read parameter for moving image
                    deg=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $7 }')
                    shift1_size=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $8 }')
                    shift1_dir=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $9 }')
                    shift2_size=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $10 }')
                    shift2_dir=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $11 }')
                    #read parameter for cutoff
                    threshold=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $12 }')
                    #read parameter for ROI
                    ROIx=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $13 }')
                    ROIy=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $14 }')
                    ROIw=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $15 }')
                    ROIh=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $16 }')
                    #read paramter for reference plant
                    plantx=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $17 }')
                    planty=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $18 }')
                    radius=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/TOPVIEW_parameter | awk '{ print $19 }')

                    #ASSIGN PARAMETERS
                    white_balance="$white_X, $white_Y, $white_W, $white_H"
                    rotations="rotation_deg=$deg"
                    shift1="img=img1, number=$shift1_size, side='$shift1_dir'"
                    shift2="img=imgs, number=$shift2_size, side='$shift2_dir'"
                    ROI="x=$ROIx, y=$ROIy, w=$ROIw, h=$ROIh"

                    echo ""
                    echo ""
                    #ECHO ALL PARAMETERS FOR CHECK
                    echo -e "${BLUE}The following parameter will be applied for image analysis${NC}"
                    echo ""
                    echo -e "${BLUE}Location of white balance calibration is:${NC} x=$white_X, y=$white_Y, w=$white_W, h=$white_H"
                    echo -e "${BLUE}Rotation degree is:${NC} $deg" 
                    echo -e "${BLUE}Threshold for masking is:${NC} $threshold"
                    echo -e "${BLUE}Pixels to be shifted $shift1_dir is:${NC} $shift1_size"
                    echo -e "${BLUE}Pixels to be shifted $shift2_dir is:${NC} $shift2_size"
                    echo -e "${BLUE}Region of interest (ROI) is:${NC} $ROI"
                    echo -e "${BLUE}Coordinate of the the first plant to be analyzed is:${NC} x=$plantx, y=$planty"
                    echo -e "${BLUE}Radius for each plant is:${NC} $radius"
                    echo ""
                    echo ""

                    echo -e "${GREEN}*** STEP 4 Generating python scripts and json configuration file for selected rig based on parameter ***${NC}"
                    #replace python scripts
                    sed "s/white_Xwhite_Ywhite_Wwhite_H/$white_balance/g" $CODE_DIR/top_view.py | \
                        sed "s/rotation_deg=/$rotations/g" | \
                        sed "s/cut_off/$threshold/g" | \
                        sed "s/img=img1, number=shift1, side=dir1/$shift1/g" | \
                        sed "s/img=imgs, number=shift2, side=dir2/$shift2/g" | \
                        sed "s/ROIxROIyROIwROIh/$ROI/g" | \
                        sed "s/plantx/$plantx/g" | \
                        sed "s/planty/$planty/g" | \
                        sed "s/VALUE/$radius/g" > ${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.TOPVIEW.py

                    ### Determine if all images or part images included
                    if [[ $MODE == "SAMPLE" ]]
                    then
                        FINAL_FOLDER="Test_image"
                        echo ""
                    echo "images under ${OUTPUT_DIR}/$PROJECT/Test_image will be loaded for analysis"
                    elif [[ $MODE == "ALL" ]]
                    then
                        FINAL_FOLDER="Clean_image"
                        echo ""
                        echo "images under ${OUTPUT_DIR}/$PROJECT/Clean_image will be loaded for analysis"
                    else
                        FINAL_FOLDER="Clean_image"
                        echo "WARNING: No -m argument provided and  images under ${OUTPUT_DIR}/$PROJECT/Clean_image will be loaded by default"
                    fi

                    ### repalce json scripts
                    sed "s@INPUT@${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER@g" $CODE_DIR/top_view.json | \
                        sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json@g" | \
                        sed "s@WORKFLOW@${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.TOPVIEW.py@g" | \
                        sed "s@OUTDIR@${OUTPUT_DIR}/$PROJECT/Results_images@g" > ${OUTPUT_DIR}/$PROJECT/Configure/$PROJECT.TOPVIEW.json
                
                    echo ""
                    echo ""
                    echo -e "${GREEN}*** STEP 5 Batch analysis will be launched for selected images based on paramter sets from last step ***${NC}" 
                    echo ""
                    
                    PHOTO_COUNT=$(ls ${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER | wc -l)
                    if [[ $PHOTO_COUNT == 0 ]]
                    then 
                        echo -e "${RED}ERROR: No images found under the ${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER, Please check $DESIGN_TABLE ${NC}"
                    else
                        ### Perform analysis for all images
                        python $CODE_DIR/plantcv-workflow.py \
                            --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.TOPVIEW.json

                        python $CODE_DIR/plantcv-utils.py json2csv \
                            --json ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json \
                            --csv ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result
                        echo ""
                        echo -e "${GREEN}*** Image analysis finished ! Please check results under the ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result...... ***${NC}"
                        echo ""
                        echo -e "${GREEN}*************************************** Thanks for using BULK ANALYSIS FOR TOPVIEW_PLANTS ***************************************${NC}"
                        echo ""
                    fi
                fi
            fi
        done
    fi
fi

if [[ $EXPERIMENT_TYPE == "SIDE_VIEW" ]]
then 
    echo ""
    echo -e "${GREEN}*** STEP 1 The Experimental design table for $EXPERIMENT_TYPE will be loaded ***${NC}" 
    ### Load experimental design table 
    IFS=$'\n';

    ### Check the format of design table 
    COLUMN_NUMBER=$(awk '{print NF}' $DESIGN_TABLE | sort -nu | tail -n 1)
    if (($COLUMN_NUMBER != 11)) 
    then
        echo ""
        echo -e "${RED}ERROR: Missing column(s) from $DESIGN_TABLE! Please check the format and re-launch analysis......${NC}"
    else
        for LINE in $(cat $DESIGN_TABLE | sed '1d');
        do
            CODE_DIR=$(echo ${LINE} | awk '{ print $1 }')
            IMAGE_DIR=$(echo ${LINE} | awk '{ print $2 }')
            FRAME_ID=$(echo ${LINE} | awk '{ print $3 }')
            BATCH_NAME=$(echo ${LINE} | awk '{ print $4 }')

            START_YEAR=$(echo ${LINE} | awk '{ print $5 }')
            END_YEAR=$(echo ${LINE} | awk '{ print $6 }')
            START_MONTH=$(echo ${LINE} | awk '{ print $7 }')
            END_MONTH=$(echo ${LINE} | awk '{ print $8 }')
            START_DATE=$(echo ${LINE} | awk '{ print $9 }')
            END_DATE=$(echo ${LINE} | awk '{ print $10 }')
            OUTPUT_DIR=$(echo ${LINE} | awk '{ print $11 }')

            ### Define the name of projects
            if [[ $BATCH_NAME == "NA" ]]
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
            echo ""
            echo -e "${GREEN}*** STEP 2 Images for experiments will be loaded ***${NC}" 

            ### Create a temp datestamp based on unique date from the image directory
            ls $IMAGE_DIR/*.jpg | cut -d "." -f2,3,4 | cut -d "-" -f1 | sort | uniq > ${OUTPUT_DIR}/$PROJECT/date.stamp

            ### filter selected date based on duration of expriments
            if [[ $START_YEAR == $END_YEAR ]];
            then
                if [[ $START_DATE -ge $END_DATE ]];
                then
                    awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                        awk -v a=$START_MONTH -v b=$END_MONTH -F "." '$2>=a && $2<=b {print $0}' |\
                        awk -v a=$START_DATE -v b=$END_DATE -v c=$START_MONTH -v d=$END_MONTH -F "." '$2==c && $3>=a || $2==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
                else
                    awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                        awk -v a=$START_MONTH -v b=$END_MONTH -F "." '$2>=a && $2<=b {print $0}' |\
                        awk -v a=$START_DATE -v b=$END_DATE -v c=$START_MONTH -v d=$END_MONTH -F "." '$2==c && $3>=a && $2==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
                fi
            else
                awk -v a=$START_YEAR -v b=$END_YEAR -F "." '$1>=a && $1<=b {print $0}' ${OUTPUT_DIR}/$PROJECT/date.stamp |\
                    awk -v a=$START_MONTH -v b=$END_MONTH -v c=$START_YEAR -v d=$END_YEAR -F "." '$1==c && $2>=a || $1==d && $2<=b {print $0}' |\
                    awk -v a=$START_DATE -v b=$END_DATE -v c=$START_YEAR -v d=$END_YEAR -F "." '$1==c && $3>=a || $1==d && $3<=b {print $0}' > ${OUTPUT_DIR}/$PROJECT/select_date.stamp
            fi

            ### copy images assocaited with the selected stamp to the Clean image dirctory
            INFO=$(echo ${RIG_ID}_${CAMERA})

            for SELECT_STAMP in $(cat ${OUTPUT_DIR}/$PROJECT/select_date.stamp);
            do
                cp ${IMAGE_DIR}/${INFO}.$SELECT_STAMP-??.??.??.jpg ${OUTPUT_DIR}/$PROJECT/Clean_image
            done

            echo ""
            echo ""
            echo "One random image per day from $START_YEAR.$START_MONTH.$START_DATE to $END_YEAR.$END_MONTH.$END_DATE will be saved under ${OUTPUT_DIR}/$PROJECT/Test_image...... "
            for i in $(ls ${OUTPUT_DIR}/$PROJECT/Clean_image | cut -d "." -f2,3 | cut -d "-" -f1 | sort | uniq);
            do
                SELECT=$(ls ${OUTPUT_DIR}/${PROJECT}/Clean_image/${INFO}_side?_????.$i-??.??.??.jpg | shuf -n 1)
                cp $SELECT ${OUTPUT_DIR}/${PROJECT}/Test_image
            done

            ### Loading parameters for image processing
            echo ""
            echo ""
            echo -e "${GREEN}*** STEP 3 The plantcv paramters from database will be loaded for analysis ***${NC}" 

            ### Extract parameter in database for analyis
            if [[ $BATCH_NAME == "NA" ]]
            then 
                grep $FRAME_ID $CODE_DIR/SIDEVIEW_database > ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter 
                echo ""
                echo ""
                echo "The paramters for $FRAME_ID were loaded" 
            else
                echo ""
                echo ""
                echo "The paramters of $BATCH_NAME for $FRAME_ID were loaded" 
                grep $FRAME_ID $CODE_DIR/SIDEVIEW_database | grep $BATCH_NAME > ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter
            fi


            COLUMN_NUMBER=$(awk '{print NF}' ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | sort -nu | tail -n 1)
            if [[ $COLUMN_NUMBER -ne 13 ]]
            then
                echo ""
                echo -e "${RED}ERROR: Incorrect column(s) numbers from $${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter! Please check the format and re-launch analysis......${NC}"
            else
                PARAMETER_COUNT=$(cat ${OUTPUT_DIR}/$PROJECT/Configure/SIDEVIEW_parameter | wc -l)
                if (( $PARAMETER_COUNT > 1 ))
                then 
                    echo -e "${RED}ERROR: There are $PARAMETER_COUNT parameters found under the $CODE_DIR/SIDEVIEW_database, please add the BATCH information to distinguish these parameters${NC}"
                elif (( $PARAMETER_COUNT == 0 ))
                then
                    echo "${RED}ERROR: There is $PARAMETER_COUNT parameter found under the $CODE_DIR/SIDEVIEW_database, please provide the parameter information ${NC}"
                else

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
                    echo -e "${GREEN}*** STEP 4 Generating python scripts and json configuration file for selected rig based on metadata ***${NC}"
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

                    ### Determine if all images or part images included
                    if [[ $MODE == "SAMPLE" ]]
                    then
                        FINAL_FOLDER="Test_image"
                        echo ""
                    echo "images under ${OUTPUT_DIR}/$PROJECT/Test_image will be loaded for analysis"
                    elif [[ $MODE == "ALL" ]]
                    then
                        FINAL_FOLDER="Clean_image"
                        echo ""
                        echo "images under ${OUTPUT_DIR}/$PROJECT/Clean_image will be loaded for analysis"
                    else
                        FINAL_FOLDER="Clean_image"
                        echo -e "${BLUE}WARNING: No -m argument provided and  images under ${OUTPUT_DIR}/$PROJECT/Clean_image will be loaded by default${NC}"
                    fi
                    
                    #replace json scripts with selected parameter
                    sed "s@INPUT@${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER@g" $CODE_DIR/side_view.json | \
                        sed "s@JSON@${OUTPUT_DIR}/${PROJECT}/Results/${PROJECT}.result.json@g" | \
                        sed "s@WORKFLOW@${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.py@g" | \
                        sed "s@OUTDIR@${OUTPUT_DIR}/${PROJECT}/Results_images@g" > ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.json

                    echo ""
                    echo ""
                    echo -e "${GREEN}*** STEP 5 Batch analysis will be launched for selected images based on paramter sets from last step ***${NC}" 
                    echo ""

                    PHOTO_COUNT=$(ls ${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER | wc -l)
                    if [[ $PHOTO_COUNT == 0 ]]
                    then 
                        echo -e "${RED}ERROR: No images found under the ${OUTPUT_DIR}/${PROJECT}/$FINAL_FOLDER, Please check $DESIGN_TABLE ${NC}"
                    else
                        ### Perform analysis for all images
                        python $CODE_DIR/plantcv-workflow.py \
                            --config ${OUTPUT_DIR}/${PROJECT}/Configure/$PROJECT.side.json

                        python $CODE_DIR/plantcv-utils.py json2csv \
                            --json ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result.json \
                            --csv ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result
                        echo ""
                        echo -e "${GREEN}*** Image analysis finished ! Please check results under the ${OUTPUT_DIR}/${PROJECT}/Results/$PROJECT.result...... ***${NC}"
                        echo ""
                        echo -e "${GREEN}*************************************** Thanks for using BULK ANALYSIS FOR SIDE_VIEW PLANTS ***************************************${NC}"
                        echo ""
                    fi
                fi
            fi
        done
    fi
fi