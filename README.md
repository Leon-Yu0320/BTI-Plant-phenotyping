# BTI mobile plant phenotyping system
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Leon-Yu0320/BTI-Plant-phenotyping/HEAD)

Integrated workflow for phenotyping data analysis using images

- [BTI mobile plant phenotyping system](#bti-mobile-plant-phenotyping-system)
  - [Introduction](#introduction)
  - [Required packages](#required-packages)
  - [General overview of the workflow](#general-overview-of-the-workflow)
    - [schematic charts of the RasPiPheno PIPE for single experiemnt](#schematic-charts-of-the-pipeline-for-single-experiemnt)
    - [schematic charts of the RasPiPheno PIPE for multiple experiemnt](#schematic-charts-of-the-pipeline-for-multiple-experiemnt)
  - [Detailed steps for the RasPiPheno PIPE](#detailed-steps-for-the-pipeline)
    - [1. Experimental setup and photo collections](#1-experimental-setup-and-photo-collections)
    - [2. Image-processing parameter selection](#2-image-processing-parameter-selection)
    - [3. Image batch processes](#3-image-batch-processes)
  - [Reference](#reference)
 
## Introduction
Image-based phenotyping provides a powerful avenue to characterize plant growth from different genetic backgrounds in response to biotic and abiotic stresses. We developed a high-throughput streamlined phenotyping workflow based on [**PlantCV**](https://plantcv.readthedocs.io/en/stable/), as well as two sets of facilities for plant growth and phenotyping data collections. This workflow covers step-by-step photo collection, data pre-processing, image processing, and downstream analysis. The integrated streamline effectively pairs with the lightweight phenotyping facilities and largely reduce the gap between phenotypic data collections and interpretation of biological questions based on phenotypic data. Operation of this pipeline along with facilities can be applied with the high-throughput manner and low cost. 

## Required packages
[**Jupyter notebook**](https://jupyter.org/)\
[**Conda**](https://docs.conda.io/en/latest/)\
[**PlantCV**](https://plantcv.readthedocs.io/en/stable/)

## General overview of the workflow
To realize the high-throughput manner of data processing, advantages of [**parallel data processing function**](https://plantcv.readthedocs.io/en/v3.7/pipeline_parallel/) from the PlantCV were adopted in the pipeline and four major steps from plant growth to final downstream analysis of [**MVAPP**](https://mvapp.kaust.edu.sa/) will be performed. Two schematic charts were displayed and detailed steps were described as follow:

### schematic charts of the pipeline for interactive surface experiments
![image](https://user-images.githubusercontent.com/69836931/180051339-15279750-0225-47d5-a792-15512de06372.png)
### schematic charts of the pipeline for BULK analysis
![image](https://user-images.githubusercontent.com/69836931/180051103-e4d2b6a6-e736-4d90-bd6a-17eb0ceff22b.png)

## Detailed steps for the pipeline
Descriptions for each step were shown as follow, with link to our in-house protocols and references. 
### 1. Experimental setup and photo collections
All photos will be collected by Raspberry Pi camera along with light-weight [**facilities**](https://www.protocols.io/view/bti-mobile-plant-phenotyping-system-phenotyping-fa-cavmse46) (**PhenoRig and PhenoCage**) developed for phenotyping.
To ensure the correct metadata fetching including **camera ID, plant ID, year, date, month, hour, minute, and other experiments related information** from the name of each photo in the subsequent data processing. The data collection will be initiated by **two individual shell scripts with respective fixed naming criteria**. Photo name examples from per experiment setup were listed as follows:

**Top-view IMAGES for PhenoRig:**
```
format: RASPI_cameraID.YYYY.MM.DD-HH.MM.SS.jpg
example: raspiU_cameraA.2021.09.07-09.00.01.jpg
```

**Type in the following command to check the help page**
```
bash phenoRig_setup.sh -help 
```
**Help page for top-view image setup pipeline will be displayed as follows:**
```
*********************************** WELCOME TO USE PhenoRig SETUP PIPELINE ***********************************

use -help argument to show usage information
The Current Time is: 2022.06.15-14.31.30

Usage : sh phenoRig_setup.sh -m MODE -f FACILITY -t INTERVAL -d DIRECTORY -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST -ISO ISO -W WIDTH -H HEIGHT

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

```
Please note that most parameters are not required with alternative default parameters to set inputs. The default settings will be displayed while launching pipelines.

**Side-view IMAGES for PhenoCage:**
```
format: RASPI_side.NO_YYYY.MM.DD-HH.MM.SS.jpg
example: RaspiZ_side1_2022.04.17-11.07.01.jpg
```
**Type in the following command to check the help page**
```
bash phenoRig_setup.sh -help 
```
**Help page for side-view image setup pipeline will be displayed as follows:**
```
*********************************** WELCOME TO USE PhenoCage IMAGES SETUP PIPELINE ***********************************

use -help argument to show usage information

The Current Time is: 2022.06.15-16.36.35
Usage : sh phenoCage_setup.sh -m MODE -f FACILITY -d DIRECTORY -ss SHUTTERSPEED -sh SHARPNESS -sa SATURATION -br BRIGHTNESS -co CONTRAST -ISO ISO -W WIDTH -H HEIGHT

  Image capture parameters
  -m [String] < type in one of the two modes:"image","calibration" DEFAULT: "image">
  -f [String] < type in the name of facility used for photo collection eg: raspiZ DEFAULT: "raspi">
  -d [String] < /path/to/images to be saved after collection DEFAULT: "." (The current directory)>

  Image quality parameters
  -ss [Integer] < Set shutterspeed DEFAULT: 500 (1/500s second) >
  -sh [Integer] < Set image sharpness (-100 to 100) DEFAULT: 50 >
  -sa [Integer] < Set image saturation (-100 to 100) DEFAULT: 50 >
  -br [Integer] < Set image brightness (0 to 100) DEFAULT: 60 >
  -co [Integer] < Set image contrast (-100 to 100) DEFAULT: 50 >
  -ISO [Integer] < Set image ISO DEFAULT: 300 >

  Image size parameters
  -W [Integer] < Set the width of image DEFAULT: 2000 >
  -H [Integer] < Set the height of image DEFAULT: 2000 >

  -h Show this usage information

```
Please note that most parameters are not required with alternative default parameters to set inputs. The default settings will be displayed while launching pipelines.

**Image data transfer**\
After collection of images, images from different experiments will be transferd to local server or PC for data processing due to limited computational power of raspiberry computers. Users can use hardware transfer (flash drive, hard disk, and etc). However, the remote transfer by SSH will be recommended. The manual and configureation of IP address of host and raspiberry computers can be found under the [**data transfer tutorial**](https://www.protocols.io/edit/bti-plant-phenotyping-system-image-data-transfer-t-cbudsns6)


### 2. Image-processing parameter selection
Phenotypic data extraction from images will be processed by PlantCV software with minor modifications and optimizations. One sample image will be selected to define parameters used for data extraction and the optimized parameter will be used to extract data among the rest images derived from the same batch of experiments. Examples of parameter settings can be referred from household [**protocols**](https://www.protocols.io/view/bti-mobile-plant-phenotyping-system-jupyter-notebo-car5sd86). 

### 3. Image batch processes
After the initial selection of parameters, users will save these data into databases corresponding to different experimental sets. The format of databases for each type of experiments was shown as follows:

**NOTE: The column names of the database is required and certain characters used for name is customizable**

**Database format of MULTI_PLANT pipeline (20 columns)**
| Column Numbers | Description |
| --------------------- | ----------- |
|RASPIID| The identifier of planting trays for plants|
|CAMERAID| The camera ID (camera A and camera B) under the dual camera mode of raspberry Pi computer|
|WX| The horizontal coordinate of white balance box used for white balance corrections|
|WY| The vertical coordinate of white balance box used for white balance corrections|
|WW| The width of white balance box used for white balance corrections|
|WH| The height of white balance box used for white balance corrections|
|DEGREE| The rotation degree of image|
|S1_SIZE| Pixel numbers of image to be shifted on left (right) direction|
|S1_DIR| Direction of image shift (left or right)|
|S2_SIZE| Pixel numbers of image to be shifted on up (down) direction|
|S2_DIR| Direction of image shift (Top or Bottom)|
|CUTOFF| Cutoff used for image masking from RGB into binary image (See part I for details)|
|RX| The horizontal coordinate of cropping regions of interests (ROIs) used for mapping|
|RY| The vertical coordinate of cropping regions of interests (ROIs) used for mapping|
|RW| The width of cropping regions of interests (ROIs) used for mapping|
|RH| The height of cropping regions of interests (ROIs) used for mapping|
|PX| The horizontal coordinate of the first plant fell into ROIs|
|PY| The vertical coordinate of the first plant fell into ROIs|
|RADIUS| Radius number (pixel) used for cropping individual plant|
|BATCH| The batch name used for experiments, used as an identifier to distinguish different experiments under the same camera and planting trays|

An example is attached:
**Example database of MULTI_PLANT pipeline**
| RASPIID | CAMERAID | WX | WY | WW | WH | DEGREE | S1_SIZE | S1_DIR | S2_SIZE | S2_DIR | CUTOFF | RX | RY | RW | RH | PX | PY | RADIUS | BATCH |
| ------- | -------- | -- | -- | -- | -- | ------ | ------- | ------ | ------- |------- | ------ | -- | -- | -- | -- | -- | -- | ------ | ----- |
| raspiN | cameraA | 950 | 950 | 100 | 100 | 0 | 1 | Right | 1 |Bottom| 108 | 150 | 150 | 1870 | 1930 | 350 | 350 | 100 | NA |
| raspiK | cameraB | 950 | 850 | 100 | 90 | 5 | 20 | Left | 1 |Bottom| 108 | 150 | 150 | 1870 | 1220| 350 | 450 | 100 | Mike |
| raspiU | cameraB | 100 | 500 | 100 | 90 | 0 | 1 | Left | 1 |Bottom| 134 | 150 | 150 | 1870 | 1220| 350 | 450 | 100 | Nick |

**Database format of MULTI_PLANT pipeline (13 columns)**
| Column Numbers | Description |
| -------------- | ----------- |
|FRAME | The identifier of facility for image capturing|
|DEGREE| The rotation degree of image|
|WX| The horizontal coordinate of white balance box used for color corrections|
|WY| The vertical coordinate of white balance box used for color corrections|
|WW| The width of white balance box used for color corrections|
|WH| The height of white balance box used for color corrections|
|CUTOFF1| Cutoff used for image masking from RGB into LAB channel (L channel)|
|CUTOFF2| Cutoff used for image masking from RGB into HAV channel (V channel)|
|RX| The horizontal coordinate of cropping regions of interest (ROI) used for mapping|
|RY| The vertical coordinate of cropping regions of interest (ROI) used for mapping|
|RW| The width of cropping regions of interest (ROI) used for mapping|
|RH| The height of cropping regions of interest (ROI) used for mapping|
|BATCH| The batch name used for experiments, used as an identifier to distinguish different experiments under the same camera and planting trays|

An example is attached:
**Example database of SIDE_VIEW pipeline**
| FRAME |DEGREE | WX | WY | WW | WH | CUTOFF1 | CUTOFF2 | RX | RY | RW | RH | BATCH |
| ----- | ----- | -- | -- | -- | -- | ------- | ------- | -- | -- | -- | -- | ----- | 
| raspiX | 0 | 450 | 1250 | 100 | 100 | 95 | 113 | 350 | 200 | 1300 | 1300 | DEMO |
| raspiY | 0 | 350 | 1300 | 100 | 90 | 180 | 135 | 500 | 400 | 1000 | 1120 | Round2 |
| raspiZ | 5 | 400 | 1350 | 100 | 90 | 220 | 105 | 450 | 400 | 1000 | 1120 | Round1 |

After the copy of parameters to databases with one of the three experimental types, users will be able to launch the analysis of images based on parameters applied to a single test image. Please place all files under the **code** directory into the **same folder** when during configuration. There are two options provided to process images as details from the following descriptions:

**OPTION 1: single experiment analysis**
In this option, pipelines for MULTI_PLANT and SIDE_VIEW pipelines will be executed by users respectively to launch analysis. Here, a few settings can be specified by users while typing into questions from programs based on their experimental design, such as the start-end time period of the experiment, the lights-on and lights-off schedule of plant growth, the camera ID, and raspberry ID for experiments. To launch the analysis, type in the following command line and see output screenshot as below.

```
bash phenoRig_process.sh
```
**Type in the answers for each questions to launch analysis**
![image](https://user-images.githubusercontent.com/69836931/170578689-aa2de6ae-22bd-4b67-bf39-4895de0fab0d.png)

**Parameters used for analysis will be displayed here**
![image](https://user-images.githubusercontent.com/69836931/170578770-a78b1328-097a-4075-a144-d4b00b9007e3.png)

```
bash phenoCage_process.sh
```
**Type in the answers for each questions to launch analysis**
![image](https://user-images.githubusercontent.com/69836931/170578807-0224e5fa-5aa9-4b81-a8c8-26d70e3bdf12.png)

**Parameters used for analysis will be displayed here**
![image](https://user-images.githubusercontent.com/69836931/170578823-b774752e-8328-49e7-a3a5-0e5ce3976e04.png)

Based on these selected periods of the experiment, one image per day will be randomly selected to validate parameters from image pre-processing steps (parameters selected will be printed in a log file), warning message will be sent if images were missed from desired time period under certain folders. After parsing parameters from the database, these sample images will be processed by [**batch processing function from PlantCV**](https://plantcv.readthedocs.io/en/v3.7/pipeline_parallel/) 

![image](https://user-images.githubusercontent.com/69836931/170578867-2eb55c69-735e-4895-88af-78566aa6c167.png)

Users are able to check the quality of images either using a pop-up window (Intallation of [**Xming**](http://www.straightrunning.com/XmingNotes/) or similar software is required) or local laptop image viewers. Please check more details regarding quality judgement of images [**protocols**](https://www.protocols.io/file-manager/092FD0D9DB1A426CA4106CB9D482C7FA).

![image](https://user-images.githubusercontent.com/69836931/170578910-e0f0c643-5a45-4475-a46c-48845053e898.png)

![image](https://user-images.githubusercontent.com/69836931/170578942-9b76ec96-e4b6-46c6-b9e7-58cf320cf13c.png)

After quality control of sample images has been processed, users will be asked if they decide to process rest images or if parameters should be modified for quality improvement. After adjustment of parameter, users should update database and re-launch the analysis
![image](https://user-images.githubusercontent.com/69836931/170578992-be8ded75-37bb-4974-977f-1e80bed060e8.png)

![image](https://user-images.githubusercontent.com/69836931/170579002-1fe36861-fd46-4db6-8273-816c31316700.png)


**OPTION 2: bulk analysis for multiple experiments**
When tackling multiple experiments or large datasets, bulk analysis is recommended by incorporating experimental design metadata into a table (see the below example). In this pipeline, three arguments will be provided by users, including an experimental design table containing metadata, the type of experiments (**options: "MULTI_PLANT", "SIDE_VIEW"**), and the mode of analysis regarding inclusion of one random image per day (**sample images**) or all images (**option: "SAMPLE","ALL" DEFAULT: ALL**) as shown from the attached picture. To start with the program, a tabular design table is required with a restricted format regarding column information. Please note that there are different column numbers from design table for MULTI_PLANT and SIDE_VIEW types of experiments. In addition, without providing the mode option (**-m argument**), all images under the image folder will be used for analysis. 

**Type in the following command to check the help page**
```
bash BULK_IMAGES.sh -help 
```
**Help page will be displayed as follows:**
```
*************************************** WELCOME TO USE BULK ANALYSIS FOR IMAGES ***************************************

use -help argument to show usage information

Usage : sh code/BULK_IMAGES.sh -d DESIGN_TABLE -t EXPERIMENT_TYPE -m MODE

  -d [Table] < /path/to/experimental design table stored, refer manual for details of each type of experiments>
  -t [String] < type in one of the three experiment types: "TOP_VIEW" or "SIDE_VIEW" >
  -m [String] < type in one of the two modes: "SAMPLE","ALL" DEFAULT: "ALL">
  -h Show this usage information
```
**Refer to the following information to prepare an experimental design table for different types of analysis**

**Format of design table when using "MULTI_PLANT" type for bulk analysis (14 columns)**
| Column Numbers | Description |
| -------------- | ----------- |
|CODE|  The directory where code been saved |
|IMAGE| The directory where source images been saved |
|RIF| The identifier of facility used for phenotyping |
|CAMERA| The camera ID which anchors to the facility |
|BATCH| The unique identifier of experiment name |
|START_YEAR| Start **year (YYYY)** of the experiment |
|END_YEAR| End **year (YYYY)** of the experiment |
|START_MONTH| Start **month (MM)** of the experiment |
|END_MONTH| End **month (MM)** of the experiment |
|START_DATE| Start **date (DD)** of the experiment |
|END_DATE| End **date (DD)** of the experiment |
|LIGHTS_ON| Hour **and minute (HH.MM)** of lights-on for experiments |
|LIGHTS_OFF| Hour **and minute (HH.MM)** of lights-off for experiments |
|OUTPUT_DIR| The directory where results to be saved |

**Example design table when using "MULTI_PLANT" type for bulk analysis**
| CODE |IMAGE | RIG | CAMERA |BATCH | START_YEAR | END_YEAR | START_MONTH | END_MONTH | START_DATE | END_DATE | LIGHTS_ON | LIGHTS_OFF | OUTPUT_DIR |
| ---- | ---- | ----| ------ | ---- | ---------- | -------- | ----------- | --------- | ---------- | -------- | --------- | ---------- | ---------- |
| /home/User/code | home/image | raspiU | cameraA | Mike | 2022 | 2022 | 04 | 04 | 02 | 15 | 09.00 | 21.00 | /data/results |
| /home/User/code | home/image | raspiK | cameraA | Nick | 2021 | 2022 | 12 | 01 | 18 | 07 | 12.00 | 18.00 | /data/results |
| /home/User/code | home/image | raspiN | cameraB | Mike | 2022 | 2022 | 02 | 02 | 09 | 27 | 09.00 | 21.00 | /data/results |

**Format of design table when using "SIDE_VIEW" type for bulk analysis (11 columns)**
| Column Numbers | Description |
| -------------- | ----------- |
|CODE| The directory where code been saved |
|IMAGE| The directory where source images been saved |
|FRAME| The identifier of facility used for phenotyping |
|BATCH| The unique identifier of experiment name |
|START_YEAR| Start **year (YYYY)** of the experiment |
|END_YEAR| End **year (YYYY)** of the experiment |
|START_MONTH| Start **month (MM)** of the experiment|
|END_MONTH| End **month (MM)** of the experiment |
|START_DATE| Start **date (DD)** of the experiment |
|END_DATE| End **date (DD)** of the experiment |
|OUTPUT_DIR| The directory where results to be saved |


**Example design table when using "SIDE_VIEW" type for bulk analysis**
| CODE |IMAGE | FRAME | BATCH | START_YEAR | END_YEAR | START_MONTH | END_MONTH | START_DATE | END_DATE | OUTPUT_DIR |
| ---- | ---- | ----- | ----- | ---------- | -------- | ----------- | --------- | ---------- | -------- | ---------- | 
| /home/User/code | home/image | raspiZ | Mike | 2022 | 2022 | 04 | 04 | 02 | 15 | /data/results |
| /home/User/code | home/image | raspiX | Nick | 2021 | 2022 | 12 | 01 | 18 | 07 | /data/results |
| /home/User/code | home/image | raspiX | Mike | 2022 | 2022 | 02 | 02 | 09 | 27 | /data/results |


## Reference
**Citation**
1. Yu, L. A., Sussman, H., Khmelnitsky, O., Rahmati Ishka, M., Srinivasan, A., Nelson, A. D., & Julkowska, M. M. (2024). Development of a mobile, high-throughput, and low-cost image-based plant growth phenotyping system. ***Plant Physiology***, kiae237 (https://doi.org/10.1093/plphys/kiae237)
   
3. Ohlsson, J. A., Leong, J. X., Elander, P. H., Ballhaus, F., Holla, S., Dauphinee, A. N., ... & Minina, E. A. (2024). SPIRO–the automated Petri plate imaging platform designed by biologists, for biologists. ***The Plant Journal***, 118(2), 584-600.(https://doi.org/10.1111/tpj.16587)

**Acknowledgement**

We acknowledge the orginal design of 3-D printer components used for PhenoCage and PhenoRig facilities derived from [**Ohlsson et al., 2024**](https://doi.org/10.1111/tpj.16587) : 
1. The 3D model for camera hold - PhenoCage - modified from original SPIRO [**design**](https://github.com/AlyonaMinina/SPIRO.Hardware)
2. Raspberry Pi holder for PhenoCage - modified from original Raspberry Pi Case for 5 inch HDMI [**touchscreen**](https://www.thingiverse.com/thing:4020018)
3. Raspberry Pi holder for PhenoRig - modified from original raspberry Pi Zero [**case**](https://www.thingiverse.com/thing:1167846)
4. Stackable trellis - modified from the original Modular [**Trellis**](https://www.thingiverse.com/thing:4188355)



