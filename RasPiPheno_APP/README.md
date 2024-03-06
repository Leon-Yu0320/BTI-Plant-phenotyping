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

![ShinyApp-Page2](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/3708e7a3-85d6-4f3e-a7a5-20e8740ef937)

![ShinyApp-Page3](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/3b1be0fb-c428-49a6-9f96-f61ab4498a98)


### Calculate the growth rate (GR)
We provided two options to calculate the GR, including calculating the rate over the entire experiment, as well as customized step-wise selection and window size selection to estimate the rate over certain intervals. 
![ShinyApp-Page4](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/7aac7162-1c24-4572-92d6-ff3e72006145)


### Perform statistical analysis of leaf area and GR data
Different statistical methods can be applied to perform a statistical comparison of plant leaf area at different time points. It includes the one-factor comparison (T-test, Wilcox test, Kruskal Wallis, and One-way ANOVA), also the two-factor comparison by two-way ANOVA. 

![ShinyApp-Page5](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/444c11ef-16bd-4c71-880c-95839d63f23b)

We can also compare the differences of growth rate using the similar approaches as did for leaf area comparison. 

![ShinyApp-Page6](https://github.com/Leon-Yu0320/BTI-Plant-phenotyping/assets/69836931/295562e0-8181-461f-b5df-ff2bf989e68d)

