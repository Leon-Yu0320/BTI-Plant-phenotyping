# BTI Plant-phenotyping
Computational pipeline for phenotyping data analysis

## Introduction
Image-based phenotyping provides a powerful avenue to characterize plant growth from different genetic background in responses to biotic and abiotic stresses. We developed a high-throughput streamlined phenotyping workflow based on [**PlantCV**](https://plantcv.readthedocs.io/en/stable/), as well as three sets of facilities for plant growth and phenotyping data collections. This workflow covers step-by-step photo collection, data pre-processing, image processing, and downstream analysis. The integrated streamline effectively paired with the light-weight phenotyping facilities and largely reduce the gap between phenotypic data collections and interpretation of biological questions based on phenotypic data. Operation of this pipeline along with facilities can be applied to screen mutants, teaching, and etc with high-throughput manner and low cost. 

## General overview of pipeline
To realize the high-throughput manner of data processing, advantages of parallel data processing function from the PlantCV was adopted in pipeline and four major steps from plant growth to final downstream analysis will be performed. Detailed steps were described as follow:

### 1. Experimental setup and photo collections
All photos will be collected by Raspberry Pi camera along with light-weight facilities developed for 
plant leaf rosettes phenotyping, plant side-view phenotyping, and tomato root phenotyping. See details about the [**facilities**](https://www.protocols.io/file-manager/092FD0D9DB1A426CA4106CB9D482C7FA).  
To ensure the correct metadata fetching including camera ID, plant ID, year, date, month, hour, minute and experiments related information from name of each photo in subsequent of data processing. The data collections will be initiated by three individual shell scripts with respective fixed naming criteria. Photo name examples from per experiment setup were listed as follow:

**plant leaf rosettes:**\
```
**format:** RASPI_cameraID.YYYY.MM.DD-HH.MM.SS.jpg
**example:** raspiU_cameraA.2021.09.07-09.00.01.jpg
```
**plant sideview:**\
```
**format:** RASPI_side.NO_YYYY.MM.DD-HH.MM.SS.jpg\
**example:** RaspiZ_side1_2022.04.17-11.07.01.jpg\
```

### 2. Image-processing parameter selection
Phenotypic data extraction from images will be processed by PlantCV software with minor modifications and optimizations. Basically, one sample image will be selected to define parameters used for data extraction and the optimized parameter will be used to extract data among rest images which derived from the same batch of experiment. Examples of parameter settings can be referred from house-hold [**protocols**](https://www.protocols.io/file-manager/092FD0D9DB1A426CA4106CB9D482C7FA). 

### 3.Image batch processes
After initial selection of parameters, users will save these data into databases corresponded to different experimental sets. The format of databases for each type of experiments were shown as follow:

#### Example database of MULTI_PLANT pipeline
| raspiID | cameraID | WX | WY | WW | WH | degree | s1_size | s1_dir| s2_size | s2_dir| Cutoff | RX | RY | RW | RH | PX | PY | Radius | BATCH |
| ------- | -------- | -- | -- | -- | -- | ------ | ------- | ----- | ------- |------| ------ | -- | -- | -- | -- | -- | -- | ------ | ----- |
| raspiN | cameraA | 950 | 950 | 100 | 100 | 0 | 1 | Right | 1 |Bottom| 108 | 150 | 150 | 1870 | 1930 | 350 | 350 | 100 | NA |
| raspiK | cameraB | 950 | 850 | 100 | 90 | 5 | 20 | Left | 1 |Bottom| 108 | 150 | 150 | 1870 | 1220| 350 | 450 | 100 | Mike |
| raspiU | cameraB | 100 | 500 | 100 | 90 | 0 | 1 | Left | 1 |Bottom| 134 | 150 | 150 | 1870 | 1220| 350 | 450 | 100 | Nick |

#### Database format of MULTI_PLANT pipeline (20 columns)
| Column Numbers | Description |
| --------------------- | ----------- |
|Column (1)| The identifier of planting trays for plants|
|Column (2)| The camera ID (camera A and camera B) under the dual camera mode of raspberry Pi computer|
|Column (3)| The horizontal coordinate of white balance box used for white balance corrections|
|Column (4)| The vertical coordinate of white balance box used for white balance corrections|
|Column (5)| The width of white balance box used for white balance corrections|
|Column (6)| The height of white balance box used for white balance corrections|
|Column (7)| The rotation degree of image|
|Column (8)| Pixel numbers of image to be shifted on left (right) direction|
|Column (9)| Direction of image shift (left or right)|
|Column (10) | Pixel numbers of image to be shifted on up (down) direction|
|Column (11) | Direction of image shift (Top or Bottom)|
|Column (12) | Cutoff used for image masking from RGB into binary image (See part I for details)|
|Column (13) | The horizontal coordinate of cropping regions of interests (ROIs) used for mapping|
|Column (14) | The vertical coordinate of cropping regions of interests (ROIs) used for mapping|
|Column (15) | The width of cropping regions of interests (ROIs) used for mapping|
|Column (16) | The height of cropping regions of interests (ROIs) used for mapping|
|Column (17) | The horizontal coordinate of the first plant fell into ROIs|
|Column (18) | The vertical coordinate of the first plant fell into ROIs|
|Column (19) | Radius numbers (pixel) used for cropping individual plant|
|Column (20) | The batch name used for experiments, used as an identifier to distinguish different experiments under the same camera and planting trays|

#### Example database of SIDE_VIEW pipeline
| Frame |Degree | WX | WY | WW | WH | cutoff1 | cutoff2 | RX | RY | RW | RH | RX | BATCH |
| ----- | ----- | -- | -- | -- | -- | ------- | ------- | -- | -- | -- | -- | -- | ----- | 
| raspiX | 0 | 450 | 1250 | 100 | 100 | 95 | 113 | 350 | 200 | 1300 | 1300 | DEMO |
| raspiY | 0 | 350 | 1300 | 100 | 90 | 180 | 135 | 500 | 400 | 1000 | 1120 | Round2 |
| raspiZ | 5 | 400 | 1350 | 100 | 90 | 220 | 105 | 450 | 400 | 1000 | 1120 | Round1 |

#### Database format of MULTI_PLANT pipeline (13 columns)
| Column Numbers | Description |
| -------------- | ----------- |
|Column (1)| The identifier of facility for image capturing|
|Column (2)| The rotation degree of image|
|Column (3)| The horizontal coordinate of white balance box used for color corrections|
|Column (4)| The vertical coordinate of white balance box used for color corrections|
|Column (5)| The width of white balance box used for color corrections|
|Column (6)| The height of white balance box used for color corrections|
|Column (7)| Cutoff used for image masking from RGB into LAB channel (L channel)|
|Column (8)| Cutoff used for image masking from RGB into HAV channel (V channel)|
|Column (9)| The horizontal coordinate of cropping regions of interests (ROIs) used for mapping|
|Column (10)| The vertical coordinate of cropping regions of interests (ROIs) used for mapping|
|Column (11)| The width of cropping regions of interests (ROIs) used for mapping|
|Column (12)| The height of cropping regions of interests (ROIs) used for mapping|
|Column (13)| The batch name used for experiments, used as an identifier to distinguish different experiments under the same camera and planting trays|

After the copy of parameters to databases with one of the three experimental types, users will be able to launch the analysis of images based on parameters applied to single test image. Please place all files under the **code** directory into the **same folder** when during configuration. There are two options provided to process images as details from following descriptions:

#### OPTION 1: single experiment analysis
In this option, pipelines for multiple-plants, side-view images, and root phenotyping pipelines will be executed by users respectively to launch analysis. Here, few settings can be specified by users while typing into questions from programs based on their experimental design, such as the start-end time period of experiment, the lights-on and lights-off schedule of plant growth, the camera ID, and raspberry ID for experiments. To launch the analysis, type in the following commend and see outputs screeshot as below.

```
bash 2_MULTI_PLANT.sh
```
```
bash 3_SIDE_VIEW.sh
```

Based on selected time period of experiment, one image per day will be randomly selected to validate parameters from image pre-processing steps (parameters selected will be printed in log file), warning message will be sent if images were missed from desired time period specified under certain folders. After parsing parameters from database, these sample images will be processed by batch processing function from [**PlantCV**](https://plantcv.readthedocs.io/en/stable/). 


Users are able to check quality of images either using pop-in window (Xming or similar software is required) or local image viewers. Please check more details regarding quality judgement of images [**protocols**](https://www.protocols.io/file-manager/092FD0D9DB1A426CA4106CB9D482C7FA). 
