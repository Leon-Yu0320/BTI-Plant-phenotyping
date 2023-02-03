#!/bin/bash
read -p "What is your experiment name (no spaces): " experiment
echo "Assigned experiment name is: $experiment"
read -p "What Raspis are you using? This should be in the format of RaspiK RaspiL (Raspi IDs separated by spaces). WARNING, this will stop any current experiment on those Raspis: " -a array
read -p "For how many days will this experiment be run? This helps to determine how long this folder is kept on the Raspi: " trash
echo "This experiment will be kept for slightly longer than $trash days on the Raspi, after which you will only find it on the lab server"
read -p "How many minutes in between each image? (1, 5, 30, 60): " min
echo "You have chosen $min minute intervals"

for Raspis in "${array[@]}"; do
        echo "Turning on $Raspis"
done

if [[ " ${array[@]} " =~ " RaspiK " ]]; then
        echo "Setting up RaspiK"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiK~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
	#Make a new directory
	sshpass -p 'AWM_20624_80C' ssh -p 9004 pi@132.236.156.74 mkdir /home/pi/Documents/raspiK_image_factory/$experiment
	#login info
        echo "Moving files to RaspiK"
        sshpass -p 'AWM_20624_80C' scp -P 9004 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiK"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiK_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9004 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9004 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiL " ]]; then
        echo "Setting up RaspiL"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiL~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9006 pi@132.236.156.74 mkdir /home/pi/Documents/raspiL_image_factory/$experiment
	#login info
        echo "Moving files to RaspiL"
        sshpass -p 'AWM_20624_80C' scp -P 9006 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiL"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiL_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9006 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9006 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiM " ]]; then
        echo "Setting up RaspiM"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiM~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
	#Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9005 pi@132.236.156.74 mkdir /home/pi/Documents/raspiM_image_factory/$experiment
	#login info
        echo "Moving files to RaspiM"
        sshpass -p 'AWM_20624_80C' scp -P 9005 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiM"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiM_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9005 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9005 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiN " ]]; then
        echo "Setting up RaspiN"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiN~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
	#login info
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9000 pi@132.236.156.74 mkdir /home/pi/Documents/raspiN_image_factory/$experiment

        echo "Moving files to RaspiN"
        sshpass -p 'AWM_20624_80C' scp -P 9000 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiN"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiN_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9000 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9000 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiO " ]]; then
        echo "Setting up RaspiO"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiO~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9008 pi@132.236.156.74 mkdir /home/pi/Documents/raspiO_image_factory/$experiment
	#login info
        echo "Moving files to RaspiO"
        sshpass -p 'AWM_20624_80C' scp -P 9008 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiO"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiO_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9008 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9008 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiP " ]]; then
        echo "Setting up RaspiP"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiP~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9001 pi@132.236.156.74 mkdir /home/pi/Documents/raspiP_image_factory/$experiment

	#login info
        echo "Moving files to RaspiP"
        sshpass -p 'AWM_20624_80C' scp -P 9001 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiP"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiP_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9001 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9001 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiQ " ]]; then
        echo "Setting up RaspiQ"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiQ~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9007 pi@132.236.156.74 mkdir /home/pi/Documents/raspiQ_image_factory/$experiment

	#login info
        echo "Moving files to RaspiQ"
        sshpass -p 'AWM_20624_80C' scp -P 9007 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiQ"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiQ_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9007 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9007 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiR " ]]; then
        echo "Setting up RaspiR"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiR~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9013 pi@132.236.156.74 mkdir /home/pi/Documents/raspiR_image_factory/$experiment

	#login info
        echo "Moving files to RaspiR"
        sshpass -p 'AWM_20624_80C' scp -P 9013 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiR"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiR_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9013 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9013 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiS " ]]; then
        echo "Setting up RaspiS"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiS~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9002 pi@132.236.156.74 mkdir /home/pi/Documents/raspiS_image_factory/$experiment

	#login info
        echo "Moving files to RaspiS"
        sshpass -p 'AWM_20624_80C' scp -P 9002 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiS"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiS_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9002 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9002 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiT " ]]; then
        echo "Setting up RaspiT"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiT~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9009 pi@132.236.156.74 mkdir /home/pi/Documents/raspiT_image_factory/$experiment

	#login info
        echo "Moving files to RaspiT"
        sshpass -p 'AWM_20624_80C' scp -P 9009 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiT"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiT_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9009 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9009 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiU " ]]; then
        echo "Setting up RaspiU"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiU~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9010 pi@132.236.156.74 mkdir /home/pi/Documents/raspiU_image_factory/$experiment

	#login info
        echo "Moving files to RaspiU"
        sshpass -p 'AWM_20624_80C' scp -P 9010 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiU"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiU_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9010 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9010 pi@132.236.156.74 crontab newcrontab
fi

if [[ " ${array[@]} " =~ " RaspiV " ]]; then
        echo "Setting up RaspiV"
        #Manipulate image_capture.sh file
        sed "s~imager~raspiV~g" empty_doc.sh >image_capture.sh
        sed -i "s~NEF~$experiment~g" image_capture.sh
        sed -i "s~dump~$trash~g" image_capture.sh
        #Make a new directory
        sshpass -p 'AWM_20624_80C' ssh -p 9011 pi@132.236.156.74 mkdir /home/pi/Documents/raspiV_image_factory/$experiment

	#login info
        echo "Moving files to RaspiV"
        sshpass -p 'AWM_20624_80C' scp -P 9011 image_capture.sh pi@132.236.156.74:Documents/
        echo "Setting up the imaging schedule on RaspiV"
        echo -e "SHELL=/bin/bash\\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\\n*/$min * * * * bash /home/pi/Documents/image_capture.sh | mail -s 'RaspiV_rsyncing' alpharaspi@gmail.com" >newcrontab
        sshpass -p 'AWM_20624_80C' scp -P 9011 newcrontab pi@132.236.156.74:
        sshpass -p 'AWM_20624_80C' ssh -p 9011 pi@132.236.156.74 crontab newcrontab
fi
echo "Your new experiment has been set up. Good luck"
