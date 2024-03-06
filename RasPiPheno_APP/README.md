# **RaspiPheno APP**

RasPiPheno App is developed by [**Julkowska**](https://btiscience.org/magda-julkowska/) and [**Nelson**](https://btiscience.org/andrew-nelson/) lab at the [**Boyce Thompson Institute, Cornell University**](https://btiscience.org/).

The App is a part of a high-throughput phenotypic data processing system and it aimed to streamline the downstream phenotypic data collected by customized phenotypic facilities which include [**PhenoRig and PhenoCage**](https://www.protocols.io/edit/bti-mobile-plant-phenotyping-system-phenotyping-fa-cavmse46)


## User manual
To use the APP, please download all files under the current repository to execute the program, more details and instructions of APP usage can be reached at [**Shiny R**](https://shiny.rstudio.com/articles/running.html) website. Video instructions of the usage will be available on our Youtube channel in the near future. 

### Load the phenotype worksheet and the metadata table
The phenotype worksheets are derived from the results of the RaspiPheno Pipe. Other metadata information can be customized by creating a metatable. See an [**example**](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/tree/main/Results_example) for the format requirement.

### Merge phenotype data and metadata for visualization
An identifier that includes the phenotyping rig (cage), camera ID, and plant ID is used to match meta-features under the meta table. After this step, Users can customized plot options interactively to grasp the overall data representation. 

![ShinyApp-Page1](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/a066484e-a279-4fd5-93b4-a97b154654f9)

### Curate the data using statistical methods
Three types of data curation methods were provided for data smoothing, including [**smooth spline**](https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/smooth.spline), [**Loess fit**](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/loess.html), and [**Polynomial regression fit**](https://search.r-project.org/CRAN/refmans/polyreg/html/polyFit.html). Users can select parameters to curate individual plants and remove plants with unexpected patterns. 

<img width="1889" alt="image" src="https://user-images.githubusercontent.com/69836931/214946807-923da2ec-d208-402c-b0f2-f133b44344db.png">
<img width="1877" alt="image" src="https://user-images.githubusercontent.com/69836931/214946943-0140848f-33a6-4ae5-945f-c222b3f186b3.png">
<img width="1877" alt="image" src="https://user-images.githubusercontent.com/69836931/214947338-336c2bbc-99eb-4e48-a88f-d3f5dae59702.png">

### Plot the curated and cleaned dataset by selected grouping criteria
<img width="1889" alt="image" src="https://user-images.githubusercontent.com/69836931/214947249-aa872a38-6fbc-4619-a77f-5a751bfc4d54.png">
<img width="1889" alt="image" src="https://user-images.githubusercontent.com/69836931/214947500-04884663-aa0e-44e2-861b-74b6317cc4f6.png">

### Calculate the growth rate (GR)
We provided two options to calculate the GR, including calculating the rate over the entire experiment, as well as customized step-wise selection and window size selection to estimate the rate over certain intervals. 
<img width="1883" alt="image" src="https://user-images.githubusercontent.com/69836931/214947661-ff93f93d-4e83-42c8-85a7-64332d8a10c3.png">
<img width="1879" alt="image" src="https://user-images.githubusercontent.com/69836931/214947782-dc96162c-95d7-4420-8d25-2066db7fd34c.png">

### Perform statistical analysis of leaf area and GR data
<img width="1863" alt="image" src="https://user-images.githubusercontent.com/69836931/214948019-bcc41730-991d-44ad-b826-7033aa3629be.png">
<img width="1895" alt="image" src="https://user-images.githubusercontent.com/69836931/214948229-6c3946c5-8bc8-4dc9-8c2e-d43c4585d3dc.png">



