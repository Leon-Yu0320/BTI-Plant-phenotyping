#!/bin/bash
### Set colors
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

echo ""
echo ""
echo -e "${GREEN}*********************************** WELCOME TO USE phenoRig IMAGES SETUP PIPELINE ***********************************${NC}"
echo ""
echo -e "${GREEN}use -help argument to show usage information${NC}"
echo ""

### Set date tag ###
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

echo "The Current Time is: $current_time"

usage() {
      echo ""
      echo -e "${BLUE}Usage : sh $0 -m MODE -f FACILITY -i INTERVAL -t DURATION -d DIRECTORY -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST -ISO ISO -W WIDTH -H HEIGHT${NC}"
      echo ""

cat <<'EOF'
  Image capture parameters
  -m [String] < type in one of the two modes:"collection","calibration" DEFAULT: "collection"> 
  -f [String] < type in the name of facility used for photo collection eg: raspiZ DEFAULT: "raspi"> 
  -i [Integer] < the minutes interval while taking pictures eg: 30 DEFAULT: "30"> 
  -t [Integer] < Number of days (duration) for images collections DEFAULT: "15" >
  -d [String] < /path/to/images to be saved after collection DEFAULT: "." (The current directory)>

  Image quality parameters
  -ss [Integer] < Set shutter speed DEFAULT: 500 (1/500s second) >
  -sh [Integer] < Set image sharpness (-100 to 100) DEFAULT: 50 >
  -sa [Integer] < Set image saturation (-100 to 100) DEFAULT: 50 >
  -br [Integer] < Set image brightness (0 to 100) DEFAULT: 60 > 
  -co [Integer] < Set image contrast (-100 to 100) DEFAULT: 50 >
  -ISO [Integer] < Set image ISO DEFAULT: 300 >

  Image size parameters
  -W [Integer] < Set the width of image DEFAULT: 2000 >
  -H [Integer] < Set the height of image DEFAULT: 2000 >

  -h Show this usage information

EOF
    exit 0
}

while getopts ":m:f:i:t:d:ss:sh:sa:br:co:ISO:W:H:h:" opt; do
  case $opt in
    m)
     MODE=$OPTARG
      ;;
    f)
     FACILITY=$OPTARG
      ;;
    i)
     INTERVAL=$OPTARG
      ;;
    t)
     DURATION=$OPTARG
      ;;
    d)
     DIRECTORY=$OPTARG
      ;;
    ss)
     SHUTTERSPEED=$OPTARG
      ;;
    sh)
     SHARPNESS=$OPTARG
      ;;
    sa)
     SATURATION=$OPTARG
      ;;
    br)
     BRIGHTNESS=$OPTARG
      ;;
    co)
     CONTRAST=$OPTARG
      ;;
    ISO)
     ISO=$OPTARG
      ;;
    W)
     WIDTH=$OPTARG
      ;;
    H)
     HEIGHT=$OPTARG
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

### Parse directory, identifier and interval information
### for directory 
if [[ $DIRECTORY -eq 0 ]]
then
    DIRECTORY=$(pwd)
    echo -e "${BLUE}No directory for saving images provided, use ${NC} $DIRECTORY "
    
else
    echo -e "${BLUE}Images will be saved under $DIRECTORY ${NC}"
fi
### for identifier
if [[ $FACILITY -eq 0 ]]
then
    echo -e "${BLUE}No facility name provided, use default facility name instead ${NC} <DEAFULT:raspi> "
    FACILITY=raspi
else
    echo -e "${BLUE}The facility name for experiment is${NC} $FACILITY "
fi

### for time interval
if [[ $INTERVAL -eq 0 ]]
then
    echo -e "${BLUE}No interval provided, use default interavl instead ${NC} <DEAFULT:30 (unit: minutes)> "
    INTERVAL=30
else
    echo -e "${BLUE}The interval for experiment is${NC} $INTERVAL minutes"
fi
echo ""
echo -e "${Green}Load image parameters${NC}"

### forexperiment duration
if [[ $DURATION -eq 0 ]]
then
    echo -e "${BLUE}No duration of experiments provided, use default interavl instead ${NC} <DEAFULT:15 (unit: days)> "
    DURATION=15
else
    echo -e "${BLUE}The duration time for experiment is${NC} $INTERVAL days"
fi
echo ""
echo -e "${Green}Load image parameters${NC}"

### Parse image parameter commands
### for shutterspeed
if [[ $SHUTTERSPEED -eq 0 ]]
then
    echo -e "${BLUE}No shutterspeed provided, use default shutterspeed instead ${NC} <DEAFULT:500>"
    SHUTTERSPEED=500
else
    echo -e "${BLUE}The shutterspeed parameter used for imaging is ${NC} $SHUTTERSPEED"
fi

### for sharpness
if [[ $SHARPNESS -eq 0 ]]
then
    echo -e "${BLUE}No sharpness parameter provided, use default sharpness instead ${NC}<DEAFULT:50>"
    SHARPNESS=50
else
    echo -e "${BLUE}The sharpness parameter used for imaging is ${NC}$SHARPNESS"
fi

### for saturation
if [[ $SATURATION -eq 0 ]]
then
    echo -e "${BLUE}No saturation parameter provided, use default saturation instead ${NC}<DEAFULT:50> "
    SATURATION=50
else
    echo -e "${BLUE}The saturation parameter used for imaging is: ${NC} $SATURATION "
fi

### for brightness
if [[ $BRIGHTNESS -eq 0 ]]
then
    echo -e "${BLUE}No brightness parameter provided, use default brightness instead ${NC} <DEAFULT:50> "
    BRIGHTNESS=50
else
    echo -e "${BLUE}The brightness parameter used for imaging is: ${NC} $BRIGHTNESS "
fi

### for contrast
if [[ $CONTRAST -eq 0 ]]
then
    echo -e "${BLUE}No contrast parameter provided, use default contrast instead ${NC} <DEAFULT:50> "
    CONTRAST=50
else
    echo -e "${BLUE}The contrast parameter used for imaging is: ${NC} $CONTRAST "
fi

### for ISO
if [[ $ISO -eq 0 ]]
then
    echo -e "${BLUE}No ISO parameter provided, use default ISO instead ${NC} <DEAFULT:300>"
    ISO=300
else
    echo -e "${BLUE}The ISO parameter used for imaging is: ${NC} $ISO "
fi

echo ""
echo -e "${Green}Load image size information${NC}"
### Parse image size information
### for width of image
if [[ $WIDTH -eq 0 ]]
then
    echo -e "${BLUE}No width of image was provided, use default width instead ${NC} <DEAFULT:2000> "
    WIDTH=2000
else
    echo -e "${BLUE}The width of image used for imaging is: ${NC} $WIDTH "
fi
### for height of image
if [[ $HEIGHT -eq 0 ]]
then
    echo -e "${BLUE}No height parameter provided, use default height instead ${NC} <DEAFULT:2000> "
    HEIGHT=2000
else
    echo -e "${BLUE}The height of image used for imaging is: ${NC} $HEIGHT "
fi

### Check and build the folder to store images
if [ -d "${DIRECTORY}/$FACILITY" ]
    then
    echo ""
    echo ""
    echo -e "${BLUE}Directory ${DIRECTORY}/$FACILITY exists. ${NC}"
else
    mkdir ${DIRECTORY}/$FACILITY
fi

if [[ $MODE == "calibration" ]]
then 
    raspistill -ss $SHUTTERSPEED -sh $SHARPNESS -sa $SATURATION -br $BRIGHTNESS -co $CONTRAST --ISO $ISO -w $WIDTH -h $HEIGHT -dt -o ${DIRECTORY}/${FACILITY}_CALIBRATOIN.jpg
    echo -e "${BLUE}Please check calibration images taken under : $HEIGHT ${NC}"
else
    ### check the remaning disk space
    LEFT_SPACE=$(df -a /home | cut -f1)
    TIMES=$((60/$INTERVAL))
    ESTIMATED_SIZE=$((5000*2*12*$TIMES*$DURATION))

    if [ "$ESTIMATED_SIZE" > "$LEFT_SPACE" ];
    then 
        echo -e "${RED}WARNING: The space on this device is not enough for a $DURATION days experiment with $INTERVAL minutes interval settings"
        echo -e "${RED}Please clean the space on this device and re-launch the setup process"
    else
        echo "Setting up crontab for $FACILITY with $DURATION days and  $INTERVAL minutes interval"
	### Define the current directory to save the crontab
        CURRENT_DIR=$(pwd)

        echo '#!/bin/sh
        current_time=$(date "+%Y.%m.%d-%H.%M.%S")
        ###Initiate cameras###
        i2cset -y 1 0x70 0x00 0x01
        gpio -g mode 17 out
        gpio -g mode 4  out
        gpio -g write 17 0 #set the gpio17 low
        gpio -g write 4 0 #set the gpio4   low

        ###Taking a picture with Camera A
        raspistill -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST --ISO ISO_SETTING -w WIDTH -h HEIGHT -dt -o DIRECTORY/FACILITY_cameraA.${current_time}.jpg

        i2cset -y 1 0x70 0x00 0x02
        gpio -g write 4 1 #set the gpio4 high

        ###Taking a picture with Camera B
        raspistill -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST --ISO ISO_SETTING -w WIDTH -h HEIGHT -dt -o DIRECTORY/FACILITY_cameraA.${current_time}.jpg' > $CURRENT_DIR/image_capture_${FACILITY}.sh

        ### Replace character with vairables
        sed -i "s/SHUTTERSPEED/${SHUTTERSPEED}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh
        sed -i "s/SHARPNESS/${SHARPNESS}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/SATURATION/${SATURATION}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/BRIGHTNESS/${SATURATION}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/CONTRAST/${CONTRAST}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/ISO_SETTING/${ISO_SETTING}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh
        sed -i "s/WIDTH/${WIDTH}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/HEIGHT/${HEIGHT}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh
        sed -i "s@DIRECTORY@${DIRECTORY}@g" $CURRENT_DIR/image_capture_${FACILITY}.sh 
        sed -i "s/FACILITY/${FACILITY}/g" $CURRENT_DIR/image_capture_${FACILITY}.sh

        #echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$INTERVAL * * * * bash $CURRENT_DIR/image_capture_${FACILITY}.sh" > ${CURRENT_DIR}/${FACILITY}_newcrontab
        #echo -e " 0 0 */$DURATION * *   sed -i 's~\*~#\*~g' ${CURRENT_DIR}/${FACILITY}_newcrontab"

        echo "Crontab setting finished!"
    fi
fi
echo ""
echo -e "${GREEN}*********************************** Thanks for using phenoRig IMAGES SETUP PIPELINE ***********************************${NC}"