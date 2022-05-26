# BTI Plant-phenotyping
Computational pipeline for phenotyping data analysis

## Introduction
Image-based phenotyping provides a powerful avenue to characterize plant growth from different genetic background in responses to biotic and abiotic stresses. We developed a high-throughput streamlined phenotyping workflow based on [**PlantCV**](https://plantcv.readthedocs.io/en/stable/), as well as three sets of facilities for plant growth and phenotyping data collections. This workflow covers step-by-step photo collection, data pre-processing, image processing, and downstream analysis. The integrated streamline effectively paired with the light-weight phenotyping facilities and largely reduce the gap between phenotypic data collections and interpretation of biological questions based on phenotypic data. Operation of this pipeline along with facilities can be applied to screen mutants, teaching, and etc with high-throughput manner and low cost. 

## General overview of pipeline
To realize the high-throughput manner of data processing, advantages of parallel data processing function from the PlantCV was adopted in pipeline and four major steps from plant growth to final downstream analysis will be performed. Detailed steps were described as follow:

### 1. Experimental setup and photo collections
All photos will be collected by Raspberry Pi camera along with light-weight facilities developed for 
plant leaf rosettes phenotyping, plant side-view phenotyping, and tomato root phenotyping. See details about the facilities (LINK to protocol IO).  
To ensure the correct metadata fetching including camera ID, plant ID, year, date, month, hour, minute and experiments related information from name of each photo in subsequent of data processing. The data collections will be initiated by three individual shell scripts with respective fixed naming criteria. Photo name examples from per experiment setup were listed as follow:

**plant leaf rosettes:**\
**format:** RASPI_cameraID.YYYY.MM.DD-HH.MM.SS.jpg\
**example:** raspiU_cameraA.2021.09.07-09.00.01.jpg\
**plant sideview:**\
**format:** RASPI_side.NO_YYYY.MM.DD-HH.MM.SS.jpg\
**example:** RaspiZ_side1_2022.04.17-11.07.01.jpg\

### 2. Image parameter preprocessing
Phenotypic data extraction from images will be processed by PlantCV software with minor modifications and optimizations. Basically, one sample image will be selected to define parameters used for data extraction and the optimized parameter will be used to extract data among rest images which derived from the same batch of experiment. Examples of parameter settings can be referred from house-hold [protocols](dx.doi.org/10.17504/protocols.io.eq2lynp7pvx9/v2). 

### 3. Analysis of images
After initial selection of parameters, users will save these data into databases corresponded to different experimental sets. The format of databases for each type of experiments were shown as follow:

