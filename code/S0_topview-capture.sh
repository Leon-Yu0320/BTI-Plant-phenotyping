#!/bin/bash
### Set colors
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

echo ""
echo ""
echo -e "${GREEN}*********************************** WELCOME TO USE TOP-VIEW IMAGES SETUP PIPELINE ***********************************${NC}"
echo ""
echo -e "${GREEN}use -help argument to show usage information${NC}"
echo ""

### Set date tag ###
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

echo "The Current Time is: $current_time"

usage() {
      echo ""
      echo -e "${BLUE}Usage : sh $0 -m MODE -f FACILITY -t INTERVAL -d DIRECTORY -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST -ISO ISO -W WIDTH -H HEIGHT${NC}"
      echo ""

cat <<'EOF'
  Image capture parameters
  -m [String] < type in one of the two modes:"image","calibration" DEFAULT: "image"> 
  -f [String] < type in the name of facility used for photo collection eg: raspiZ DEFAULT: "raspi"> 
  -t [integer] < the minutes interval while taking pictures eg: 30 DEFAULT: "30"> 
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

while getopts ":m:f:t:d:ss:sh:sa:br:co:ISO:W:H:h:" opt; do
  case $opt in
    m)
     MODE=$OPTARG
      ;;
    f)
     FACILITY=$OPTARG
      ;;
    t)
     INTERVAL=$OPTARG
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
    echo -e "${BLUE}The interval name for experiment is${NC} $INTERVAL "
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
    echo -e "${BLUE}WARNING: Directory ${DIRECTORY}/$FACILITY exists. Results will be overwritten${NC}"
    rm -r ${DIRECTORY}/$FACILITY
fi

mkdir ${DIRECTORY}/$FACILITY

if [[ $MODE == "calibration" ]]
then 
    raspistill -ss $SHUTTERSPEED -sh $SHARPNESS -sa $SATURATION -br $BRIGHTNESS -co $CONTRAST --ISO $ISO -w $WIDTH -h $HEIGHT -dt -o ${DIRECTORY}/${FACILITY}_CALIBRATOIN_$current_time.jpg
    echo -e "${BLUE}Please check calibration images taken under : $HEIGHT ${NC}"
else
    ### set the crown
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin

    i2cset -y 1 0x70 0x00 0x01
    gpio -g mode 17 out
    gpio -g mode 4  out
    gpio -g write 17 0 #set the gpio17 low
    gpio -g write 4 0 #set the gpio4   low
    echo -e "${BLUE}Taking a picture with Camera A${NC}"

    */$INTERVAL * * * * raspistill -ss $SHUTTERSPEED -sh $SHARPNESS -sa $SATURATION -br $BRIGHTNESS -co $CONTRAST --ISO $ISO \
         -w $WIDTH -h $HEIGHT \
         -dt -o ${DIRECTORY}/${FACILITY}_cameraA.$current_time.jpg

    i2cset -y 1 0x70 0x00 0x02
    gpio -g write 4 1 #set the gpio4 high

    echo -e "${BLUE}Taking a picture with Camera B${NC}"

    */$INTERVAL * * * * raspistill -ss $SHUTTERSPEED -sh $SHARPNESS -sa $SATURATION -br $BRIGHTNESS -co $CONTRAST --ISO $ISO \
        -w $WIDTH -h $HEIGHT \
        -dt -o ${DIRECTORY}/${FACILITY}_cameraB.$current_time.jpg

    echo -e "${GREEN}Image capture from cameraA and cameraB with $INTERVAL minutes intervals were completed! Check images under ${DIRECTORY}/$FACILITY ${NC}"
fi


