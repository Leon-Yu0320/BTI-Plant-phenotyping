#!/bin/sh
### Set date tag ###
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
echo "Current Time : $current_time"
### End date tag ###
###Initiate cameras###
i2cset -y 1 0x70 0x00 0x01
gpio -g mode 17 out
gpio -g mode 4  out
gpio -g write 17 0 #set the gpio17 low
gpio -g write 4 0 #set the gpio4   low
echo "Taking a picture with Camera A"
raspistill -ss 1000 -ISO 600 -w 2000 -h 2000 -dt -o /home/pi/Documents/imager_image_factory/NEF/imager_cameraA.$current_time.jpg
i2cset -y 1 0x70 0x00 0x02
gpio -g write 4 1 #set the gpio4 high
echo "Taking a picture with Camera B"
raspistill -ss 1000 -ISO 600 -w 2000 -h 2000 -dt -o /home/pi/Documents/imager_image_factory/NEF/imager_cameraB.$current_time.jpg
echo "Pictures captured successfully"
###Upload pictures to server
sshpass -f /home/pi/Documents/file.txt /usr/bin/rsync -e 'ssh -p 14817' -avz /home/pi/Documents/imager_image_factory/ Raspis@132.236.156.106:Raspis/imager_image_factory/NEF
###Remove pictures older than 5 days
find /home/pi/Documents/imager_image_factory/NEF/* -mtime +4 -exec rm {} \;

