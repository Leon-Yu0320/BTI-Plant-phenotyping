server <- function(input, output) {
  
  ### TAB 1.1 Reshape the phenotypic data sheet ###
  Raspi <- reactive({
    rbindlist(lapply(input$csv.raspi$datapath, fread),
              use.names = TRUE, fill = TRUE)})
  
  Raspi_clean <-  reactive(if(is.null(input$csv.raspi)) {
    return(NULL)}
    else{
      if(input$expType == "PhenoCage"){
        Raspi <- Raspi() %>% separate(roi, c("Year", "Month", "Day","Hour","Min", "Sec","Raspi","Side","Camera"))
        Raspi$timestamp <- paste0(Raspi$Year, ".", Raspi$Month,".", Raspi$Day, "-", Raspi$Hour, ".", Raspi$Min, ".", Raspi$Sec)
        Raspi$TS2 <- paste0(Raspi$Year, "-", Raspi$Month,"-", Raspi$Day)
        Raspi_clean <- Raspi[,c("area","Year", "Month", "Day","Hour","Min", "Sec","timestamp", "Raspi", "TS2")]
      }
      if(input$expType == "PhenoRig"){
        Raspi <- Raspi() %>% separate(plantID, c("RasPi","Camera", "Year", "Month", "Day","Hour","Min", "Sec", "position"))
        Raspi$timestamp <- paste0(Raspi$Year, ".", Raspi$Month,".", Raspi$Day, "-", Raspi$Hour, ".", Raspi$Min, ".", Raspi$Sec)
        Raspi$TS2 <- paste0(Raspi$Year, "-", Raspi$Month,"-", Raspi$Day, " ", Raspi$Hour, ":", Raspi$Min) 
        Raspi_clean <- Raspi[,c("area","Year", "Month", "Day","Hour","Min", "Sec","timestamp", "RasPi", "Camera", "position", "TS2")]
        Raspi_clean$position <- as.numeric(as.character(Raspi_clean$position))
      }
      return(Raspi_clean)
    })
  
  
  output$Data_tabl1 <- renderDataTable({
    Raspi_clean()
  })
  
  ItemList = reactive(if (is.null(input$csv.meta)) {
    return()
  } else {
    d2 = read.csv(input$csv.meta$datapath)
    return(colnames(d2))
  })
  
  output$FWColumn <- renderUI({
    if ((is.null(ItemList())) | (input$FWCheck == FALSE)) {
      return ()
    } else{
      tagList(
        selectizeInput(
          inputId = "FWCol",
          label = "Select column containing Fresh Weight",
          choices = ItemList(),
          multiple = F
        )
      )}
  })
  
  timepointList = reactive(if(is.null(Raspi_clean())){
    return()} else {
      temp <- Raspi_clean()
      return(str_sort(unique(temp$TS2)))
      
    })
  
  output$timeSTART <- renderUI({
    if(is.null(input$csv.raspi)){return() | is.null(timepointList())} else {
      tagList(
        selectizeInput(
          inputId = "StartTimeExp",
          label = "Select experiment start timepoint",
          choices = timepointList(),
          multiple = F
        )
      )
    }
  })
  
  decoding <- reactive(if (input$MergeData == F) {
    return()
  } else {
    decoding <- read.csv(input$csv.meta$datapath)
    if(input$FWCheck == TRUE){
      FW <- input$FWCol
      decoding <- decoding[ , -which(names(decoding) %in% c(FW))]
    }
    decoding
  })
  
  output$uploaded_RasPi_data_report <- renderText({
    if(is.null(input$csv.raspi)) {
      return(NULL)}
    else{
      data <- Raspi_clean()
      no_PIs <- length(unique(data$RasPi))
      no_Month <- length(unique(data$Month))
      no_Day <- length(unique(data$Day))
      no_H <- length(unique(data$Hour))
      sentence <- paste("Your Raspberry Pi uploaded data contains images collected over ",no_PIs, " Raspberry Pi devices, 
                              collected over the period of ", no_Month, " months, ", no_Day, " days, and ", no_H, " hours.")
      return(sentence)
    }
  })
  
  output$uploaded_metadata_report <- renderText({
    if(is.null(input$csv.meta)) {
      return(NULL)}
    else{
      meta <- decoding()
      no_Pot <- length(unique(meta$POT))
      no_Geno <- length(unique(meta$Genotype))
      no_Cond <- length(unique(meta$Condition))
      meta_sentence <- paste("Your uploaded Meta-data contains ", no_Pot, " unique Pots, ", no_Geno, "unique genotypes, and ", no_Cond, " unique conditions.")
    }
    
  })
  
  
  ### TAB 1.2 quick glance of the decoding file ###
  output$Data_tabl2 <- renderDataTable({decoding()})
  
  
  ### TAB 1.3 Merge decoding and phenotypic data sheets ###
  
  ########################################################## merge decoding files and phenotype data ########################################################## 
  Raspi_unique <-  reactive(if(input$MergeData == F){
    return()} else{
      if(input$expType == "PhenoCage"){
        Raspi_clean <- Raspi_clean()
        Raspi_clean <- Raspi_clean %>% group_by(timestamp) %>% mutate(side.counts = n())
        Raspi_clean <- Raspi_clean %>% group_by(timestamp) %>% mutate(area.total = sum(area))
        meta <- decoding()
        pots <- meta$POT
        times <- length(unique(Raspi_clean$timestamp)) / length(pots)
        decoded_list <- rep(pots, times)
        # calculate time_of_experiment based on # Yr.Month.Day format of input$StartTimeExp
        Raspi_clean$start <- input$StartTimeExp
        Raspi_clean$time.days <- as.numeric(difftime(Raspi_clean$TS2, Raspi_clean$start, units = "days"))
        
        Raspi_unique <- unique(Raspi_clean[,c("Raspi", "Month", "Day", "timestamp", "time.days", "side.counts","area.total")])
        Raspi_unique$POT <- decoded_list
        Raspi_decoded <- merge(Raspi_unique, meta, by="POT", all = TRUE) 
      }
      if(input$expType == "PhenoRig"){
        Raspi_clean <- Raspi_clean()
        Raspi_clean$Plant.ID <- paste(Raspi_clean$RasPi, Raspi_clean$Camera, Raspi_clean$position, sep="_")
        # calculate time_of_experiment based on # Yr.Month.Day-Hr.Min format of input$StartTimeExp
        Raspi_clean$start <- input$StartTimeExp
        Raspi_clean$time.min <- as.numeric(difftime(Raspi_clean$TS2, Raspi_clean$start, units = "mins"))
        
        Raspi_unique <- unique(Raspi_clean[,c("RasPi", "Camera","Plant.ID", "position", "Month", "Day", "Hour","Min", "Sec", "timestamp", "time.min", "area")])
        meta <- decoding()
        meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
        Raspi_decoded <- merge(Raspi_unique, meta, by=c("Plant.ID", "position", "RasPi", "Camera"), all = TRUE, allow.cartesian = TRUE)
      }
      Raspi_decoded <- na.omit(Raspi_decoded)
      Raspi_decoded
    }) 
  
  output$merged_data_report <- renderText({
    if(is.null(input$csv.meta)) {
      return(NULL)}
    else{
      if(input$expType == "PhenoCage"){
        data <- Raspi_unique()
        index <- length(unique(data$timestamp))
        sides <- unique(data$side.counts)
        meta <- decoding()
        pot_no <- length(unique(meta$POT))
        timepoint <- index / pot_no
        
        meta_sentence <- paste("Your data contains ", index, " unique observations, that were derived from  summarizing ", sides, " side views. \n The observations were decoded using the order of timestamp for each day for ", pot_no, " plant identifiers uploaded in your metadata. \n The number of timepoints in your data, derived by timestamp / plant identifiers is ", timepoint, " timepoints")    
      }
      if(input$expType == "PhenoRig"){
        data <- Raspi_unique()
        timepoints <- length(unique(data$timestamp))
        plant.id <- length(unique(data$Plant.ID))
        meta_sentence <- paste("Your data was collected over ", timepoints, " unique timepoints, for ", plant.id, " unique plants.")
      }
      return(meta_sentence)
      
    }
    
  })
  
  output$Data_tabl3 <- renderDataTable({
    Raspi_unique()
  })
  
  output$mergedtable_button <- renderUI({
    if (is.null(ItemList())) {
      return()
    }
    else{
      downloadButton("mergedtable_download_button", label = "Download table")
    }
  })
  
  ########################################################## download merged file ########################################################## 
  
  output$mergedtable_download_button <- downloadHandler(
    filename = paste("Merged_data.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- Raspi_unique()
      write.csv(result, file, row.names = FALSE)
      
    }
  )
  
  
  ### TAB 1.4 Overall of plant growth ###
  
  ########################################################## define UI variables ########################################################## 
  metaList = reactive(if(is.null(Raspi_unique())){
    return(NULL)} else {
      temp <- decoding()
      return(colnames(temp))
      
    })
  
  
  output$color_original <- renderUI({
    if(is.null(Raspi_unique())){return()} else {
      tagList(
        selectizeInput(
          inputId = "ColorAreaGG",
          label = "Color individual lines per:",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  output$Choose_alpha <- renderUI(
    sliderInput(inputId = "alpha",
                label = "Transparency of data point to be displayed:",
                min = 0.0,
                max = 1,
                step = 0.1,
                value = 0.2)
  )
  
  
  output$facet_wrap1 <- renderUI({
    if(input$facet1_check == FALSE){return()} else {
      if(is.null(Raspi_unique())){return()} else {
        tagList(
          selectizeInput("facet_item1", 
                         label="Facet group per:", 
                         choices = metaList(),
                         multiple = F))}
    }
  })
  
  
  output$X_tickUI1 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minX_tickUI1", label="Which ticks would you like to use for time (minutes)?", 
                  min = 1000, max=5000, step = 1000, value = 2000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayX_tickUI1", label="Which ticks would you like to use for time (days)?", 
                  min = 1, max=5, step = 1, value = 2)
    }
  })
  
  
  output$Y_tickUI1 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minY_tickUI1", label="Which ticks would you like to use for leaf area?", 
                  min = 1000, max=10000, step = 1000, value = 5000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayY_tickUI1", label="Which ticks would you like to use for total leaf area?", 
                  min = 100000, max=500000, step = 100000, value = 200000)
    }
  })
  
  
  ########################################################## plot the area graph ########################################################## 
  

  TimeGraph <- reactive(if(is.null(Raspi_unique())){return(NULL)}else{  
    my_data <- Raspi_unique()
    
    if(input$expType == "PhenoRig"){
      my_data$col.sorting <-  as.factor(my_data[,input$ColorAreaGG])
      my_data$time.min <- as.numeric(my_data$time.min)
      my_data$area <- as.numeric(my_data$area)
      
      if(input$facet1_check == T){
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item1])
        
        Area_graph <- ggplot(data=my_data, aes(x= time.min, y=area, group = Plant.ID, color = col.sorting)) +
          geom_line(alpha = input$alpha) +
          theme_classic() +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          facet_wrap(vars(facet.sorting), ncol=(length(unique(my_data$facet.sorting)))) +
          ylab("Rosette Area (pixels)") + xlab("Time (minutes)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI1)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area),by=input$minY_tickUI1))
        
      } else {
        
        Area_graph <- ggplot(data=my_data, aes(x= time.min, y=area, group = Plant.ID, color = col.sorting)) +
          geom_line(alpha = input$alpha) +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          theme_classic() +
          ylab("Rosette Area (pixels)") + xlab("Time (minutes)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI1)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area),by=input$minY_tickUI1))
      }
    }
    
    if(input$expType == "PhenoCage"){
      my_data$col.sorting <- as.factor(my_data[,input$ColorAreaGG])
      my_data$time.days <- as.numeric(my_data$time.days)
      my_data$area.total <- as.numeric(my_data$area.total)
      
      if(input$facet1_check == T){
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item1])
        
        Area_graph <- ggplot(data=my_data, aes(x= time.days, y=area.total, group = POT, color = col.sorting)) +
          geom_line(alpha = input$alpha) +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          facet_wrap(vars(facet.sorting), ncol=(length(unique(my_data$facet.sorting)))) +
          theme_classic() +
          ylab("Cummulative Shoot Area (pixels)") + xlab("Time (days)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI1)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total),by=input$dayY_tickUI1))
      } else {
        
        Area_graph <- ggplot(data=my_data, aes(x= time.days, y=area.total, group = POT, color = col.sorting)) +
          geom_line(alpha = input$alpha) +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          theme_classic() +
          ylab("Cummulative Shoot Area (pixels)") + xlab("Time (days)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI1)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total),by=input$dayY_tickUI1))
        
      }
    }
    return(Area_graph)
  })
  
  output$graph_over_time <- renderPlotly(
    ggplotly(TimeGraph())
  )
  
  
  
  
  ### TAB 2.1  Design the smooth and cleaning process ###
  
  ########################################################## define UI variables ##########################################################
  output$SmoothGo <- renderUI({
    if(input$expType == "PhenoRig"){
      actionButton("SmoothGo", icon("file-import"),label = "Smooth and clean all samples")
      
    }else if (input$expType == "PhenoCage") {
      actionButton("SmoothGo", icon("file-import"),label = "Smooth and clean all samples")
    }
  })
  
  # Select samples to display smoothing
  output$Choose_smooth_sample <- renderUI({
    if(is.null(Raspi_unique())){return(NULL)
    }else{tagList(
      selectizeInput(
        inputId = "sample_smooth",
        label = "Select sample to display smoothing",
        choices = smooth_sample(),
        multiple=F))}
  })
  
  # Select samples to be dropped
  output$Drop_smooth_sample <- renderUI({
    if (is.null(Raspi_unique())) {
      return (NULL)
    } else {
      selectizeInput(
        inputId = "SelectDrop",
        label = "Manual selection of plants not included in clean data",
        choices = smooth_sample(),
        multiple = T,
        selected = NULL
      )}
  })
  
  
  smooth_sample <- reactive(if(is.null(Raspi_unique())){return(NULL)
  }else{  
    temp <- Raspi_unique()
    
    if(input$expType == "PhenoRig"){
      sample.id <- unique(temp$Plant.ID)
    }
    if(input$expType == "PhenoCage"){
      sample.id <- unique(temp$POT)
    }
    return(sample.id)
    
  })
  
  Raspi_unique_drop <- reactive(if(is.null(Raspi_unique())) {
    return(NULL)
  } else {
    if(is.null(input$SelectDrop)){
      sub_Raspi <- Raspi_unique()
      return(sub_Raspi)
    } else {
      if(input$expType == "PhenoRig"){
        Raspi_unique <- Raspi_unique()
        list_of_no <- input$SelectDrop
        sub_Raspi <- subset(Raspi_unique, !(Raspi_unique$Plant.ID %in% list_of_no))
      } 
      if(input$expType == "PhenoCage"){
        Raspi_unique <- Raspi_unique()
        list_of_no <- as.list(input$SelectDrop)
        sub_Raspi <- subset(Raspi_unique, !(Raspi_unique$POT %in% list_of_no))
        
      }
      return(sub_Raspi)
    }
  })
  
  
  output$Drop_data_report <- renderText({
    if(is.null(input$SelectDrop)) {
      return(NULL)} else {
        test_sentence <- paste("A total of", length(input$SelectDrop),"individual(s) were manually removed!")
        return(test_sentence)
      }
  })
  
  output$nknotsUI <- renderUI({if(input$smoothType == "Smooth Spline Fit"){
    sliderInput("nknots", label="Which nknots would you like to use?", min = 2, max=30, step = 1, value = 2)
  }else{return(NULL)}})
  
  output$spanUI <- renderUI({if(input$smoothType != "Loess Fit"){return(NULL)}else{
    sliderInput("span", label="Which span would you like to use?", min = 0, max=1, step = 0.1, value = 0.75)
  }})
  
  output$degreeUI <- renderUI({if(input$smoothType != "Polynomial Regression Fit"){return(NULL)}else{
    sliderInput("degree", label="Which degree would you like to use?", min = 2, max=20, step = 1, value = 5)
  }})
  
  
  output$X_tickUI2 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minX_tickUI2", label="Which ticks would you like to use for time (minutes)?", 
                  min = 1000, max=5000, step = 1000, value = 2000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayX_tickUI2", label="Which ticks would you like to use for time (days)?", 
                  min = 1, max=5, step = 1, value = 2)
    }
  })
  
  output$Y_tickUI2 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minY_tickUI2", label="Which ticks would you like to use for leaf area?", 
                  min = 1000, max=10000, step = 1000, value = 5000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayY_tickUI2", label="Which ticks would you like to use for total leaf area?", 
                  min = 100000, max=500000, step = 100000, value = 200000)
    }
  })
  
  ########################################################## Plot the Individual plant ########################################################## 
  Smooth_plot_one <- reactive(
    if(is.null(smooth_sample())){return(NULL)}
    else{
      if(input$smoothType == "Smooth Spline Fit"){
        temp <- Raspi_unique()
        if(input$expType == "PhenoRig"){
          temp2 <- subset(temp, temp$Plant.ID == input$sample_smooth)
          temp2$time.min <- as.numeric(temp2$time.min)
          temp2$area <- as.numeric(temp2$area)
          time.min <- unique(temp2$time.min)
          
          mod.ss <- with(temp2, ss(time.min, area, df = as.numeric(input$nknots)))
          mod.ss.sum <- summary(mod.ss)
          temp2$sigma <-  as.numeric(input$outlier) * mod.ss.sum$sigma
          temp2$residuals <- abs(mod.ss.sum$residuals)
          pred_temp <- predict(mod.ss, temp2$time.min)
          
          Fit_graph <- ggplot(temp2, aes(x=time.min, y=area) ) + 
            geom_point(aes(y = area), size=input$size, shape = 21) +
            geom_spline(aes(x=time.min, y=area), nknots = as.numeric(input$nknots), size=1, color = "blue") +
            geom_ribbon(aes(ymin = pred_temp$y - unique(temp2$sigma), 
                            ymax = pred_temp$y + unique(temp2$sigma)), alpha = 0.2, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Leaf area of Individual") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.min),by=input$minX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area),by=input$minY_tickUI2))
          
          
        }
        if(input$expType == "PhenoCage"){
          temp2 <- subset(temp, temp$POT == input$sample_smooth)
          temp2$time.days <- as.numeric(temp2$time.days)
          time.days <- unique(temp2$time.days)
          
          mod.ss <- with(temp2, ss(time.days, area.total, df = as.numeric(input$nknots)))
          mod.ss.sum <- summary(mod.ss)
          temp2$sigma <-  as.numeric(input$outlier) * mod.ss.sum$sigma
          temp2$residuals <- abs(mod.ss.sum$residuals)
          pred_temp <- predict(mod.ss, temp2$time.days)
          
          Fit_graph <- ggplot(temp2, aes(x=time.days, y=area.total) ) + 
            geom_point(aes(y = area.total), size=input$size, shape = 21) +
            geom_smooth(method = "lm", formula = y ~ splines::bs(x, as.numeric(input$nknots)), se = F)+
            geom_ribbon(aes(ymin = pred_temp$y - unique(temp2$sigma), 
                            ymax = pred_temp$y + unique(temp2$sigma)), alpha = 0.2, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Leaf area of Individual") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.days),by=input$dayX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area.total),by=input$dayY_tickUI2))
        }
        Fit_graph
        
      } else if (input$smoothType == "Loess Fit"){
        temp <- Raspi_unique_drop()
        if(input$expType == "PhenoRig"){
          temp2 <- subset(temp, temp$Plant.ID == input$sample_smooth)
          temp2$time.min <- as.numeric(temp2$time.min)
          time.min <- unique(temp2$time.min)
          
          mod.loess <- loess(temp2$area ~ temp2$time.min, data = temp2, span = as.numeric(input$span))
          mod.sum <- summary(mod.loess)
          temp2$sigma <- as.numeric(input$outlier) * mod.sum$s
          temp2$residual <- abs(mod.sum$residuals)
          Predict_matrix1 <- predict(mod.loess, temp2$time.min)
          
          Fit_graph <- ggplot(temp2, aes(x=time.min, y=area) ) + 
            geom_point(aes(y = area), size=input$size, shape = 21) +
            geom_spline(aes(x = time.min, y = area), span = as.numeric(input$span), size=1, color = "blue") +
            geom_ribbon(aes(ymin = Predict_matrix1 - unique(temp2$sigma), 
                            ymax = Predict_matrix1 + unique(temp2$sigma)), alpha = 0.5, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Leaf area of Individual") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.min),by=input$minX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area),by=input$minY_tickUI2))
        }
        if(input$expType == "PhenoCage"){
          temp2 <- subset(temp, temp$POT == input$sample_smooth)
          temp2$time.days <- as.numeric(temp2$time.days)
          time.days <- unique(temp2$time.days)
          
          mod.loess <- loess(temp2$area.total ~ temp2$time.days, data = temp2, span = as.numeric(input$span))
          mod.sum <- summary(mod.loess)
          temp2$sigma <- as.numeric(input$outlier) * mod.sum$s
          temp2$residual <- abs(mod.sum$residuals)
          Predict_matrix1 <- predict(mod.loess, temp2$time.days)
          
          Fit_graph <- ggplot(temp2, aes(x=time.days, y=area.total) ) + 
            geom_point(aes(y = area.total), size=input$size, shape = 21) +
            geom_smooth(method = 'loess', span = as.numeric(input$span), se = F) +
            geom_ribbon(aes(ymin = Predict_matrix1 - unique(temp2$sigma), 
                            ymax = Predict_matrix1 + unique(temp2$sigma)), alpha = 0.5, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Total Leaf area of Individual from multiple sides") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.days),by=input$dayX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area.total),by=input$dayY_tickUI2))
        }
        Fit_graph
        
      } else if (input$smoothType == "Polynomial Regression Fit"){
        
        temp <- Raspi_unique_drop()
        if(input$expType == "PhenoRig"){
          temp2 <- subset(temp, temp$Plant.ID == input$sample_smooth)
          temp2$time.min <- as.numeric(temp2$time.min)
          time.min <- unique(temp2$time.min)
          
          poly.model <- lm(area ~ poly(time.min, as.numeric(input$degree), raw = TRUE), data = temp2)
          pred_temp <- predict(poly.model)
          mod.sum <- summary(poly.model)
          temp2$sigma <- as.numeric(input$outlier) * mod.sum$sigma
          temp2$residual <- abs(mod.sum$residuals)
          
          ### Plot graph
          Fit_graph <- ggplot(temp2, aes(time.min, area) ) + 
            geom_point(aes(y = area), size=input$size, shape = 21) +
            #stat_smooth(method = 'lm', level = as.numeric(input$level), formula = y ~ poly(x, as.numeric(input$degree), raw = TRUE)) +
            geom_spline(aes(x = time.min, y = area), degree = as.numeric(input$degree), size=1, color = "blue") +
            geom_ribbon(aes(ymin = pred_temp - unique(temp2$sigma), 
                            ymax = pred_temp + unique(temp2$sigma)), alpha = 0.5, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Leaf area of Individual") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.min),by=input$minX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area),by=input$minY_tickUI2))
          
        }
        if(input$expType == "PhenoCage"){
          temp2 <- subset(temp, temp$POT == input$sample_smooth)
          temp2$time.days <- as.numeric(temp2$time.days)
          time.days <- unique(temp2$time.days)
          
          poly.model <- lm(area.total ~ poly(time.days, as.numeric(input$degree), raw = TRUE), data = temp2)
          pred_temp <- predict(poly.model)
          mod.sum <- summary(poly.model)
          temp2$sigma <- as.numeric(input$outlier) * mod.sum$sigma
          temp2$residual <- abs(mod.sum$residuals)
          
          ### Plot graph
          Fit_graph <- ggplot(temp2, aes(time.days, area.total) ) + 
            geom_point(aes(y = area.total), size=input$size, shape = 21) +
            stat_smooth(method = 'lm', formula = y ~ poly(x, as.numeric(input$degree), se = F)) +
            geom_ribbon(aes(ymin = pred_temp - unique(temp2$sigma), 
                            ymax = pred_temp + unique(temp2$sigma)), alpha = 0.5, fill = "grey40") +
            theme_classic() +
            xlab("Total Time (minutes)") +
            ylab("Total Leaf area of Individual from multiple sides") +
            scale_x_continuous(breaks=seq(0,max(temp2$time.days),by=input$dayX_tickUI2)) +
            scale_y_continuous(breaks=seq(0,max(temp2$area.total),by=input$dayY_tickUI2))
        }
        Fit_graph
      }
    })
  
  # # # smooth display per sample completed
  output$Smoothed_graph_one_sample <- renderPlot({
    Smooth_plot_one()}
  )
  
  
  
  ### TAB 2.2 Smooth calculations for all individual plants ###
  
  ########################################################## perform the data smoothing ########################################################## 
  smooth_all <- reactive(if(input$SmoothGo == FALSE){return(NULL)}else{
    my_data <- unique(Raspi_unique_drop())
    if(input$smoothType== "Smooth Spline Fit"){
      if(input$expType == "PhenoRig"){
        names <- c(text="Plant.ID", "time.min", "area.smooth","residuals","sigma")
        spline_data <- data.frame()
        for (k in names) spline_data[[k]] <- as.character()
        i=1
        temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
        temp$time.min <- as.numeric(as.character(temp$time.min))
        day <- unique(temp$time.min)
        max_day <- length(day)
        spl.model <- with(temp, ss(time.min, area, df = as.numeric(input$nknots)))
        
        spl.model.sum <- summary(spl.model)
        temp$sigma <-  as.numeric(input$outlier) * spl.model.sum$sigma
        temp$residuals <- abs(spl.model.sum$residuals)
        
        pred_temp <- predict(spl.model, day)
        spline_data[1:max_day,2] <- pred_temp$x
        spline_data[1:max_day,3] <- pred_temp$y
        spline_data[1:max_day,1] <- temp$Plant.ID[1]
        spline_data[1:max_day,4] <- temp$residuals
        spline_data[1:max_day,5] <- temp$sigma
        spline_data_clean <- spline_data[spline_data$residuals < spline_data$sigma,]
        
        final_spline <- spline_data
        
        for(i in 1:length(unique(my_data$Plant.ID))){
          temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
          temp$time.min <- as.numeric(as.character(temp$time.min))
          day <- unique(temp$time.min)
          max_day <- length(day)
          spl.model <- with(temp, ss(time.min, area, df = as.numeric(input$nknots)))
          
          spl.model.sum <- summary(spl.model)
          temp$sigma <-  as.numeric(input$outlier) * spl.model.sum$sigma
          temp$residuals <- abs(spl.model.sum$residuals)
          
          pred_temp <- predict(spl.model, day)
          spline_data[1:max_day,2] <- pred_temp$x
          spline_data[1:max_day,3] <- pred_temp$y
          spline_data[1:max_day,1] <- temp$Plant.ID[1]
          spline_data[1:max_day,4] <- temp$residuals
          spline_data[1:max_day,5] <- temp$sigma
          
          spline_data_clean <- spline_data[spline_data$residuals < spline_data$sigma,]
          final_spline <- rbind(final_spline, spline_data)
          
        }
        meta <- decoding()
        meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
        Raspi_decoded <- merge(final_spline, meta, by="Plant.ID", all = TRUE) 
        Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
      } 
      if(input$expType == "PhenoCage"){
        names <- c(text="POT", "time.days", "area.total.smooth")
        spline_data <- data.frame()
        for (k in names) spline_data[[k]] <- as.character()
        i=1
        temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
        temp$time.day <- as.numeric(as.character(temp$time.day))
        day <- unique(temp$time.day)
        max_day <- length(day)
        plot.spl <- with(temp, smooth.spline(time.day, area.total, df = as.numeric(input$nknots)))
        pred_temp <- predict(plot.spl, day)
        spline_data[1:max_day,2] <- pred_temp$x
        spline_data[1:max_day,3] <- pred_temp$y
        spline_data[1:max_day,1] <- temp$POT[1]
        final_spline <- spline_data
        
        for(i in 1:length(unique(my_data$POT))){
          temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
          temp$time.day <- as.numeric(as.character(temp$time.day))
          day <- unique(temp$time.day)
          max_day <- length(day)
          plot.spl <- with(temp, smooth.spline(time.day, area.total, df = as.numeric(input$nknots)))
          pred_temp <- predict(plot.spl, day)
          spline_data[1:max_day,2] <- pred_temp$x
          spline_data[1:max_day,3] <- pred_temp$y
          spline_data[1:max_day,1] <- temp$POT[1]
          final_spline <- rbind(final_spline, spline_data)
        }
        meta <- decoding()
        Raspi_decoded <- merge(final_spline, meta, by="POT", all = TRUE) 
        Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
        
      }} else if(input$smoothType== "Loess Fit"){
        
        if(input$expType == "PhenoRig"){
          names <- c(text="Plant.ID", "time.min", "area.smooth","residuals","sigma")
          loess_data <- data.frame()
          for (k in names) loess_data[[k]] <- as.character()
          i=1
          temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
          temp$time.min <- as.numeric(as.character(temp$time.min))
          day <- unique(temp$time.min)
          max_day <- length(day)
          loess.model <- with(temp, loess(area ~ time.min, span = as.numeric(input$span)))
          loess.model.sum <- summary(loess.model)
          
          temp$sigma <-  as.numeric(input$outlier) *loess.model.sum$s
          temp$residuals <- abs(loess.model.sum$residuals)
          
          pred_temp <- predict(loess.model, day)
          loess_data[1:max_day,2] <- day
          loess_data[1:max_day,3] <- pred_temp
          loess_data[1:max_day,1] <- temp$Plant.ID[1]
          loess_data[1:max_day,4] <- temp$residuals
          loess_data[1:max_day,5] <- temp$sigma
          loess_data_clean <- loess_data[loess_data$residuals < loess_data$sigma,]
          
          final_loess <- loess_data
          
          for(i in 1:length(unique(my_data$Plant.ID))){
            temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
            temp$time.min <- as.numeric(as.character(temp$time.min))
            day <- unique(temp$time.min)
            max_day <- length(day)
            loess.model <- with(temp, loess(area ~ time.min, span = as.numeric(input$span)))
            loess.model.sum <- summary(loess.model)
            temp$sigma <-  as.numeric(input$outlier) *loess.model.sum$s
            temp$residuals <- abs(loess.model.sum$residuals)
            
            pred_temp <- predict(loess.model, day)
            loess_data[1:max_day,2] <- day
            loess_data[1:max_day,3] <- pred_temp
            loess_data[1:max_day,1] <- temp$Plant.ID[1]
            loess_data[1:max_day,4] <- temp$residuals
            loess_data[1:max_day,5] <- temp$sigma
            
            loess_data_clean <- loess_data[loess_data$residuals < loess_data$sigma,]
            final_loess <- rbind(final_loess, loess_data)
            
          }
          meta <- decoding()
          meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
          Raspi_decoded <- merge(final_loess, meta, by="Plant.ID", all = TRUE) 
          Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          
        } 
        if(input$expType == "PhenoCage"){
          names <- c(text="POT", "time.days", "area.total.smooth")
          loess_data <- data.frame()
          for (k in names) loess_data[[k]] <- as.character()
          i=1
          temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
          temp$time.day <- as.numeric(as.character(temp$time.day))
          day <- unique(temp$time.day)
          max_day <- length(day)
          loess.model <- with(temp, loess(area.total ~ time.day, span = as.numeric(input$span)))
          pred_temp <- predict(loess.model, day)
          loess_data[1:max_day,2] <- day
          loess_data[1:max_day,3] <- pred_temp
          loess_data[1:max_day,1] <- temp$POT[1]
          final_loess <- loess_data
          
          for(i in 1:length(unique(my_data$POT))){
            temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
            temp$time.day <- as.numeric(as.character(temp$time.day))
            day <- unique(temp$time.day)
            max_day <- length(day)
            loess.model <- with(temp, loess(area.total ~ time.day, span = as.numeric(input$span)))
            pred_temp <- predict(loess.model, day)
            loess_data[1:max_day,2] <- day
            loess_data[1:max_day,3] <- pred_temp
            loess_data[1:max_day,1] <- temp$POT[1]
            final_loess <- rbind(final_loess, loess_data)
          }
          meta <- decoding()
          Raspi_decoded <- merge(final_loess, meta, by="POT", all = TRUE) 
          Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          
        }} else if (input$smoothType== "Polynomial Regression Fit"){
          
          if(input$expType == "PhenoRig"){
            names <- c(text="Plant.ID", "time.min", "area.smooth","residuals","sigma")
            polynomial_data <- data.frame()
            for (k in names) polynomial_data[[k]] <- as.character()
            i=1
            temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
            temp$time.min <- as.numeric(as.character(temp$time.min))
            day <- unique(temp$time.min)
            max_day <- length(day)
            poly.model <- lm(temp$area ~ poly(temp$time.min, as.numeric(input$degree), raw = TRUE))
            pred_temp <- predict(poly.model)
            
            poly.model.sum <- summary(poly.model)
            temp$sigma <-  as.numeric(input$outlier)*poly.model.sum$sigma
            temp$residuals <- abs(poly.model.sum$residuals)
            
            polynomial_data[1:max_day,2] <- day
            polynomial_data[1:max_day,3] <- pred_temp
            polynomial_data[1:max_day,1] <- temp$Plant.ID[1]
            polynomial_data[1:max_day,4] <- temp$residuals
            polynomial_data[1:max_day,5] <- temp$sigma
            
            final_polynomial <- polynomial_data
            
            for(i in 1:length(unique(my_data$Plant.ID))){
              temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
              temp$time.min <- as.numeric(as.character(temp$time.min))
              day <- unique(temp$time.min)
              max_day <- length(day)
              poly.model <- lm(temp$area ~ poly(temp$time.min, as.numeric(input$degree), raw = TRUE))
              poly.model.sum <- summary(poly.model)
              temp$sigma <-  as.numeric(input$outlier) * poly.model.sum$sigma
              temp$residuals <- abs(poly.model.sum$residuals)
              
              pred_temp <- predict(poly.model)
              polynomial_data[1:max_day,2] <- day
              polynomial_data[1:max_day,3] <- pred_temp
              polynomial_data[1:max_day,1] <- temp$Plant.ID[1]
              polynomial_data[1:max_day,4] <- temp$residuals
              polynomial_data[1:max_day,5] <- temp$sigma
              
              final_polynomial <- rbind(final_polynomial, polynomial_data)
            }
            meta <- decoding()
            meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
            Raspi_decoded <- merge(final_polynomial, meta, by="Plant.ID", all = TRUE) 
            Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          }
          if(input$expType == "PhenoCage"){
            names <- c(text="POT", "time.days", "area.total.smooth")
            polynomial_data <- data.frame()
            for (k in names) polynomial_data[[k]] <- as.character()
            i=1
            temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
            temp$time.day <- as.numeric(as.character(temp$time.day))
            day <- unique(temp$time.day)
            max_day <- length(day)
            poly.model <- lm(temp$area.total ~ poly(temp$time.day, as.numeric(input$degree), raw = TRUE))
            pred_temp <- predict(poly.model)
            
            polynomial_data[1:max_day,2] <- day
            polynomial_data[1:max_day,3] <- pred_temp
            polynomial_data[1:max_day,1] <- temp$POT[1]
            final_polynomial <- polynomial_data
            
            for(i in 1:length(unique(my_data$POT))){
              temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
              temp$time.day <- as.numeric(as.character(temp$time.day))
              day <- unique(temp$time.day)
              max_day <- length(day)
              poly.model <- lm(temp$area.total ~ poly(temp$time.day, as.numeric(input$degree), raw = TRUE))
              pred_temp <- predict(poly.model)
              polynomial_data[1:max_day,2] <- day
              polynomial_data[1:max_day,3] <- pred_temp
              polynomial_data[1:max_day,1] <- temp$POT[1]
              final_polynomial <- rbind(final_polynomial, polynomial_data)
            }
            meta <- decoding()
            Raspi_decoded <- merge(final_polynomial, meta, by="POT", all = TRUE) 
            Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          }}
    
    return(Raspi_decoded2)
  })
  
  output$Smooth_table <- renderDataTable({
    smooth_all()
  })    
  
  output$Smooth_table_button <- renderUI({
    if (is.null(smooth_all())) {
      return()
    }
    else{
      downloadButton("smooth_table_download_button", label = "Download the smooth table")
    }
  })
  
  output$smooth_table_data_report <- renderText({
    if(is.null(smooth_all())) {
      return(NULL)}
    else{
      data <- smooth_all()
      
      if(input$expType == "PhenoRig"){
        no_Plants <- length(unique(data$Plant.ID))
      } else if (input$expType == "PhenoCage") {
        no_Plants <- length(unique(data$POT))
      }
      sentence_smooth <- paste("Your Raspberry Pi smoothed data contains images collected  among ",no_Plants, "individual(s)")
      return(sentence_smooth)
    }
  })
  
  ########################################################## download smoothed file ##########################################################  
  
  output$smooth_table_download_button <- downloadHandler(
    filename = paste("Smoothed_data.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- smooth_all()
      write.csv(result, file, row.names = FALSE)
      
    }
  )
  
  
  ### TAB2.3  smooth graph for all plants### 
  
  ########################################################## define UI variables ########################################################## 
  output$color_smooth <- renderUI({
    if(is.null(smooth_all())){return()} else {
      tagList(
        selectizeInput(
          inputId = "ColorSmoothGG",
          label = "Color individual lines per:",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  output$facet_wrap2 <- renderUI({
    if(input$facet2_check == FALSE){return()} else {
      if(is.null(smooth_all())){return()} else {
        tagList(
          selectizeInput("facet_item2", 
                         label="Facet group per:", 
                         choices = metaList(),
                         multiple = F))}
    }
  })
  
  output$X_tickUI3 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minX_tickUI3", label="Which ticks would you like to use for time (minutes)?", 
                  min = 1000, max=5000, step = 1000, value = 2000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayX_tickUI3", label="Which ticks would you like to use for time (days)?", 
                  min = 1, max=5, step = 1, value = 2)
    }
  })
  
  output$Y_tickUI3 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minY_tickUI3", label="Which ticks would you like to use for leaf area?", 
                  min = 1000, max=10000, step = 1000, value = 5000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayY_tickUI3", label="Which ticks would you like to use for total leaf area?", 
                  min = 100000, max=500000, step = 100000, value = 200000)
    }
  })
  
  ########################################################## Plot the smooth graph ##########################################################
  
  smooth_graph_all <- reactive(if(is.null(smooth_all())){return(NULL)}else{
    my_data <- unique(smooth_all())
    my_data$col.sorting <- as.factor(my_data[,input$ColorSmoothGG])
    
    if(input$expType == "PhenoRig"){
      my_data$time.min <- as.numeric(my_data$time.min)
      my_data$area.smooth <- as.numeric(my_data$area.smooth)
      
      if(input$facet2_check == T){
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item2])
        
        Area_graph <- ggplot(data=my_data,aes(x= time.min, y=area.smooth, color = col.sorting)) +
          geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          theme_classic() +
          facet_wrap(~ facet.sorting, ncol=(length(unique(my_data$facet.sorting)))) +
          geom_point(alpha = 0.3, size = 0.2) +
          theme_classic() +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          ylab("Rosette Area (Smooth data)") + 
          xlab("Time (minutes)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI3)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.smooth),by=input$minY_tickUI3))
        
      } else {
        
        Area_graph <- ggplot(data=my_data,aes(x= time.min, y=area.smooth, color = col.sorting)) +
          geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          theme_classic() +
          geom_point(alpha = 0.3, size = 0.2) +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          ylab("Rosette Area (Smooth data)") + 
          xlab("Time (minutes)") +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI3)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.smooth),by=input$minY_tickUI3))
      }
    }
    
    if(input$expType == "PhenoCage"){
      my_data$time.days <- as.numeric(my_data$time.days)
      my_data$area.total.smooth <- as.numeric(my_data$area.total.smooth)
      
      if(input$facet2_check == T){
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item2])
        
        Area_graph <- ggplot(data = my_data, aes(x= time.days, y=area.total.smooth, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          theme_classic() +
          facet_wrap(~ facet.sorting, ncol=(length(unique(my_data$facet.sorting)))) +
          ylab("Cummulative Shoot Area (Smooth data)") +
          xlab("Time (days)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI3)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total.smooth),by=input$dayY_tickUI3))
        
      } else {
        Area_graph <- ggplot(data = my_data, aes(x= time.days, y=area.total.smooth, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          theme_classic() +
          ylab("Cummulative Shoot Area (Smooth data)") +
          xlab("Time (days)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI3)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total.smooth),by=input$dayY_tickUI3))
      }  
    }
    Area_graph
  })
  
  output$all_smooth_graph <- renderPlotly(
    ggplotly(smooth_graph_all())
  )
  
  ########################################################## download smooth graph ##########################################################  
  
  output$Smooth_graph_button <- renderUI({
    if (is.null(smooth_graph_all())) {
      return()
    }
    else{
      downloadButton("smoothgraph_download_button", label = "Download the smooth plot")
    }
  })
  
  
  output$smoothgraph_download_button <- downloadHandler(
    filename = paste("Smoothed_data_graph.RasPiPhenoApp.pdf"),
    content <- function(file) {
      pdf(file, width = 8, height =6)
      plot(smooth_graph_all())
      dev.off()
      
    }
  )
  
  
  ### TAB 2.4 Clean data point which are outliers of model  ###
  
  ##########################################################  Generate the smooth table ##########################################################
  clean_all <- reactive(if(input$SmoothGo == FALSE){return(NULL)}else{
    my_data <- unique(Raspi_unique_drop())
    if(input$smoothType== "Smooth Spline Fit"){
      if(input$expType == "PhenoRig"){
        names <- c(text="Plant.ID", "time.min", "area","residuals","sigma")
        spline_data <- data.frame()
        for (k in names) spline_data[[k]] <- as.character()
        i=1
        temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
        temp$time.min <- as.numeric(as.character(temp$time.min))
        day <- unique(temp$time.min)
        max_day <- length(day)
        spl.model <- with(temp, ss(time.min, area, df = as.numeric(input$nknots)))
        
        spl.model.sum <- summary(spl.model)
        temp$sigma <-  as.numeric(input$outlier) * spl.model.sum$sigma
        temp$residuals <- abs(spl.model.sum$residuals)
        
        pred_temp <- predict(spl.model, day)
        spline_data[1:max_day,2] <- pred_temp$x
        spline_data[1:max_day,3] <- temp$area
        spline_data[1:max_day,1] <- temp$Plant.ID[1]
        spline_data[1:max_day,4] <- temp$residuals
        spline_data[1:max_day,5] <- temp$sigma
        spline_data_clean <- spline_data[spline_data$residuals < spline_data$sigma,]
        
        final_spline <-  spline_data_clean
        
        for(i in 1:length(unique(my_data$Plant.ID))){
          temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
          temp$time.min <- as.numeric(as.character(temp$time.min))
          day <- unique(temp$time.min)
          max_day <- length(day)
          spl.model <- with(temp, ss(time.min, area, df = as.numeric(input$nknots)))
          
          spl.model.sum <- summary(spl.model)
          temp$sigma <-  as.numeric(input$outlier) * spl.model.sum$sigma
          temp$residuals <- abs(spl.model.sum$residuals)
          
          pred_temp <- predict(spl.model, day)
          spline_data[1:max_day,2] <- pred_temp$x
          spline_data[1:max_day,3] <- temp$area
          spline_data[1:max_day,1] <- temp$Plant.ID[1]
          spline_data[1:max_day,4] <- temp$residuals
          spline_data[1:max_day,5] <- temp$sigma
          
          spline_data_clean <- spline_data[spline_data$residuals < spline_data$sigma,]
          final_spline <- rbind(final_spline, spline_data_clean)
        }
        meta <- decoding()
        meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
        Raspi_decoded <- merge(final_spline, meta, by="Plant.ID", all = TRUE) 
        Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
      } 
      if(input$expType == "PhenoCage"){
        names <- c(text="POT", "time.days", "area.total")
        spline_data <- data.frame()
        for (k in names) spline_data[[k]] <- as.character()
        i=1
        temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
        temp$time.day <- as.numeric(as.character(temp$time.day))
        day <- unique(temp$time.day)
        max_day <- length(day)
        plot.spl <- with(temp, smooth.spline(time.day, area.total, df = as.numeric(input$nknots)))
        pred_temp <- predict(plot.spl, day)
        spline_data[1:max_day,2] <- pred_temp$x
        spline_data[1:max_day,3] <- temp$area.total
        spline_data[1:max_day,1] <- temp$POT[1]
        final_spline <- spline_data
        
        for(i in 1:length(unique(my_data$POT))){
          temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
          temp$time.day <- as.numeric(as.character(temp$time.day))
          day <- unique(temp$time.day)
          max_day <- length(day)
          plot.spl <- with(temp, smooth.spline(time.day, area.total, df = as.numeric(input$nknots)))
          pred_temp <- predict(plot.spl, day)
          spline_data[1:max_day,2] <- pred_temp$x
          spline_data[1:max_day,3] <- temp$area.total
          spline_data[1:max_day,1] <- temp$POT[1]
          final_spline <- rbind(final_spline, spline_data)
        }
        meta <- decoding()
        Raspi_decoded <- merge(final_spline, meta, by="POT", all = TRUE) 
        Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
        
      }} else if(input$smoothType== "Loess Fit"){
        
        if(input$expType == "PhenoRig"){
          names <- c(text="Plant.ID", "time.min", "area","residuals","sigma")
          loess_data <- data.frame()
          for (k in names) loess_data[[k]] <- as.character()
          i=1
          temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
          temp$time.min <- as.numeric(as.character(temp$time.min))
          day <- unique(temp$time.min)
          max_day <- length(day)
          loess.model <- with(temp, loess(area ~ time.min, span = as.numeric(input$span)))
          loess.model.sum <- summary(loess.model)
          
          temp$sigma <-  as.numeric(input$outlier) *loess.model.sum$s
          temp$residuals <- abs(loess.model.sum$residuals)
          
          pred_temp <- predict(loess.model, day)
          loess_data[1:max_day,2] <- day
          loess_data[1:max_day,3] <- temp$area
          loess_data[1:max_day,1] <- temp$Plant.ID[1]
          loess_data[1:max_day,4] <- temp$residuals
          loess_data[1:max_day,5] <- temp$sigma
          loess_data_clean <- loess_data[loess_data$residuals < loess_data$sigma,]
          
          final_loess <- loess_data_clean
          
          for(i in 1:length(unique(my_data$Plant.ID))){
            temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
            temp$time.min <- as.numeric(as.character(temp$time.min))
            day <- unique(temp$time.min)
            max_day <- length(day)
            loess.model <- with(temp, loess(area ~ time.min, span = as.numeric(input$span)))
            loess.model.sum <- summary(loess.model)
            temp$sigma <-  as.numeric(input$outlier) * loess.model.sum$s
            temp$residuals <- abs(loess.model.sum$residuals)
            
            pred_temp <- predict(loess.model, day)
            loess_data[1:max_day,2] <- day
            loess_data[1:max_day,3] <- temp$area
            loess_data[1:max_day,1] <- temp$Plant.ID[1]
            loess_data[1:max_day,4] <- temp$residuals
            loess_data[1:max_day,5] <- temp$sigma
            
            loess_data_clean <- loess_data[loess_data$residuals < loess_data$sigma,]
            
            final_loess <- rbind(final_loess, loess_data_clean)
            
          }
          meta <- decoding()
          meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
          Raspi_decoded <- merge(final_loess, meta, by="Plant.ID", all = TRUE) 
          Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          
        } 
        if(input$expType == "PhenoCage"){
          names <- c(text="POT", "time.days", "area.total")
          loess_data <- data.frame()
          for (k in names) loess_data[[k]] <- as.character()
          i=1
          temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
          temp$time.day <- as.numeric(as.character(temp$time.day))
          day <- unique(temp$time.day)
          max_day <- length(day)
          loess.model <- with(temp, loess(area.total~ time.day, span = as.numeric(input$span)))
          pred_temp <- predict(loess.model, day)
          loess_data[1:max_day,2] <- day
          loess_data[1:max_day,3] <- temp$area.total
          loess_data[1:max_day,1] <- temp$POT[1]
          final_loess <- loess_data
          
          for(i in 1:length(unique(my_data$POT))){
            temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
            temp$time.day <- as.numeric(as.character(temp$time.day))
            day <- unique(temp$time.day)
            max_day <- length(day)
            loess.model <- with(temp, loess(area.total ~ time.day, span = as.numeric(input$span)))
            pred_temp <- predict(loess.model, day)
            loess_data[1:max_day,2] <- day
            loess_data[1:max_day,3] <- temp$area.total
            loess_data[1:max_day,1] <- temp$POT[1]
            final_loess <- rbind(final_loess, loess_data)
          }
          meta <- decoding()
          Raspi_decoded <- merge(final_loess, meta, by="POT", all = TRUE) 
          Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          
        }} else if (input$smoothType== "Polynomial Regression Fit"){
          
          if(input$expType == "PhenoRig"){
            names <- c(text="Plant.ID", "time.min", "area","residuals","sigma")
            polynomial_data <- data.frame()
            for (k in names) polynomial_data[[k]] <- as.character()
            i=1
            
            temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[1])
            temp$time.min <- as.numeric(as.character(temp$time.min))
            day <- unique(temp$time.min)
            max_day <- length(day)
            poly.model <- lm(temp$area ~ poly(temp$time.min, as.numeric(input$degree), raw = TRUE))
            pred_temp <- predict(poly.model)
            
            poly.model.sum <- summary(poly.model)
            temp$sigma <-  as.numeric(input$outlier) * poly.model.sum$sigma
            temp$residuals <- abs(poly.model.sum$residuals)
            
            polynomial_data[1:max_day,2] <- day
            polynomial_data[1:max_day,3] <- temp$area
            polynomial_data[1:max_day,1] <- temp$Plant.ID[1]
            polynomial_data[1:max_day,4] <- temp$residuals
            polynomial_data[1:max_day,5] <- temp$sigma
            
            polynomial_data_clean <- polynomial_data[polynomial_data$residuals < polynomial_data$sigma,]
            final_polynomial <- polynomial_data_clean
            
            for(i in 1:length(unique(my_data$Plant.ID))){
              temp <- subset(my_data, my_data$Plant.ID == unique(my_data$Plant.ID)[i])
              temp$time.min <- as.numeric(as.character(temp$time.min))
              day <- unique(temp$time.min)
              max_day <- length(day)
              poly.model <- lm(temp$area ~ poly(temp$time.min, as.numeric(input$degree), raw = TRUE))
              poly.model.sum <- summary(poly.model)
              temp$sigma <-  as.numeric(input$outlier)*poly.model.sum$sigma
              temp$residuals <- abs(poly.model.sum$residuals)
              
              pred_temp <- predict(poly.model)
              polynomial_data[1:max_day,2] <- day
              polynomial_data[1:max_day,3] <- temp$area
              polynomial_data[1:max_day,1] <- temp$Plant.ID[1]
              polynomial_data[1:max_day,4] <- temp$residuals
              polynomial_data[1:max_day,5] <- temp$sigma
              
              polynomial_data_clean <- polynomial_data[polynomial_data$residuals < polynomial_data$sigma,]
              
              final_polynomial <- rbind(final_polynomial, polynomial_data_clean)
            }
            meta <- decoding()
            meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
            Raspi_decoded <- merge(final_polynomial, meta, by="Plant.ID", all = TRUE) 
            Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          }
          if(input$expType == "PhenoCage"){
            names <- c(text="POT", "time.days", "area.total")
            polynomial_data <- data.frame()
            for (k in names) polynomial_data[[k]] <- as.character()
            i=1
            temp <- subset(my_data, my_data$POT == unique(my_data$POT)[1])
            temp$time.day <- as.numeric(as.character(temp$time.day))
            day <- unique(temp$time.day)
            max_day <- length(day)
            poly.model <- with(temp, polynomial(area.total ~ time.day,degree = as.numeric(input$degree)))
            pred_temp <- predict(poly.model)
            
            polynomial_data[1:max_day,2] <- day
            polynomial_data[1:max_day,3] <- temp$area.total
            polynomial_data[1:max_day,1] <- temp$POT[1]
            final_polynomial <- polynomial_data
            
            for(i in 1:length(unique(my_data$POT))){
              temp <- subset(my_data, my_data$POT == unique(my_data$POT)[i])
              temp$time.day <- as.numeric(as.character(temp$time.day))
              day <- unique(temp$time.day)
              max_day <- length(day)
              poly.model <- with(temp, polynomial(area.total ~ time.day,degree = as.numeric(input$degree)))
              pred_temp <- predict(poly.model)
              polynomial_data[1:max_day,2] <- day
              polynomial_data[1:max_day,3] <- temp$area.total
              polynomial_data[1:max_day,1] <- temp$POT[1]
              final_polynomial <- rbind(final_polynomial, polynomial_data)
            }
            meta <- decoding()
            Raspi_decoded <- merge(final_polynomial, meta, by="POT", all = TRUE) 
            Raspi_decoded2 <- unique(na.omit(Raspi_decoded))
          }}
    
    return(Raspi_decoded2)
  })
  
  
  output$Clean_table <- renderDataTable({
    clean_all()
  })    
  
  output$Clean_table_button <- renderUI({
    if (is.null(clean_all())) {
      return()
    }
    else{
      downloadButton("Clean_table_download_button", label = "Download the clean table")
    }
  })
  
  
  output$Clean_table_data_report <- renderText({
    if(is.null(clean_all())) {
      return(NULL)}
    else{
      clean_all <- clean_all()
      
      if(input$expType == "PhenoRig"){
        no_Plants <- length(unique(clean_all$Plant.ID))
      } else if (input$expType == "PhenoRig") {
        no_Plants <- length(unique(clean_all$POT))
      }
      sentence_clean <- paste("Your Raspberry Pi cleaned data contains images collected among",no_Plants, "individual(s)")
      return(sentence_clean)
    }
  })
  
  ########################################################## download Cleaned file ########################################################## 
  
  output$Clean_table_download_button <- downloadHandler(
    filename = paste("Cleaned_data.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- clean_all()
      write.csv(result, file, row.names = FALSE)
      
    }
  )
  
  ### TAB 3.5 Plot the clean data for plants ###
  
  ########################################################## define UI of vatriables ##########################################################
  output$color_clean <- renderUI({
    if(is.null(clean_all())){return()} else {
      tagList(
        selectizeInput(
          inputId = "ColorcleanGG",
          label = "Color individual lines per:",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  
  output$facet_wrap3 <- renderUI({
    if(input$facet3_check == FALSE){return()} else {
      if(is.null(smooth_all())){return()} else {
        tagList(
          selectizeInput("facet_item3", 
                         label="Facet group per:", 
                         choices = metaList(),
                         multiple = F))}
    }
  })
  
  ### define the ticks of plots
  output$X_tickUI4 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minX_tickUI4", label="Which ticks would you like to use for time (minutes)?", 
                  min = 1000, max=5000, step = 1000, value = 2000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayX_tickUI4", label="Which ticks would you like to use for time (days)?", 
                  min = 1, max=5, step = 1, value = 2)
    }
  })
  
  output$Y_tickUI4 <- renderUI({
    if(input$expType == "PhenoRig"){
      sliderInput("minY_tickUI4", label="Which ticks would you like to use for leaf area?", 
                  min = 1000, max=10000, step = 1000, value = 5000)
    } else if (input$expType == "PhenoCage"){
      sliderInput("dayY_tickUI4", label="Which ticks would you like to use for total leaf area?", 
                  min = 100000, max=500000, step = 100000, value = 200000)
    }
  })
  
  ########################################################## Generate the clean graph ##########################################################
  
  clean_graph_all <- reactive(if(is.null(clean_all())){return(NULL)}else{
    my_data <- unique(clean_all())
    my_data$col.sorting <- as.factor(my_data[,input$ColorcleanGG])
    
    if(input$expType == "PhenoRig"){
      my_data$time.min <- as.numeric(my_data$time.min)
      my_data$area <- as.numeric(my_data$area)
      
      if(input$facet3_check == T){
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item3])
        
        Area_graph <- ggplot(data = my_data, aes(x= time.min, y=area, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          geom_point(alpha = 0.3, size = 0.2,aes(group= Plant.ID)) +
          theme_classic() +
          facet_wrap(~ facet.sorting, ncol=(length(unique(my_data$facet.sorting)))) +
          ylab("Rosette Area (Cleaned data)") +
          xlab("Time (minutes)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI4)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area),by=input$minY_tickUI4))
        
      } else {
        Area_graph <- ggplot(data = my_data, aes(x= time.min, y=area, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          geom_point(alpha = 0.3, size = 0.2,aes(group= Plant.ID)) +
          theme_classic() +
          ylab("Rosette Area (Cleaned data)") +
          xlab("Time (minutes)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          scale_x_continuous(breaks=seq(0,max(my_data$time.min),by=input$minX_tickUI4)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area),by=input$minY_tickUI4))
      }
      
    }
    
    if(input$expType == "PhenoCage"){
      
      my_data$time.days <- as.numeric(my_data$time.days)
      my_data$area.total <- as.numeric(my_data$area.total)
      
      if(input$facet3_check == T){ 
        
        my_data$facet.sorting <- as.factor(my_data[,input$facet_item3])
        Area_graph <- ggplot(data = my_data, aes(x= time.days, y=area.total, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          geom_point(alpha = 0.3,size = 0.2, aes(group= POT)) +
          theme_classic() +
          facet_wrap(~ facet.sorting, ncol=(length(unique(my_data$facet.sorting)))) +
          ylab("Cummulative Shoot Area (cleaned data)") +
          xlab("Time (days)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI4)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total),by=input$dayY_tickUI4))
        
      } else {
        
        Area_graph <- ggplot(data = my_data, aes(x= time.days, y=area.total, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          geom_point(alpha = 0.3,size = 0.2, aes(group= POT)) +
          theme_classic() +
          ylab("Cummulative Shoot Area (cleaned data)") +
          xlab("Time (days)") +
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group=col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "anova", hide.ns = T) +
          
          scale_x_continuous(breaks=seq(0,max(my_data$time.days),by=input$dayX_tickUI4)) +
          scale_y_continuous(breaks=seq(0,max(my_data$area.total),by=input$dayY_tickUI4))
      }
      
    }
    Area_graph
  })
  
  output$all_clean_graph <- renderPlotly(
    ggplotly(clean_graph_all())
  )
  
  ########################################################## download clean graph ######################################################### 
  
  output$clean_graph_button <- renderUI({
    if (is.null(clean_graph_all())) {
      return()
    }
    else{
      downloadButton("cleangraph_download_button", label = "Download the clean plot")
    }
  })
  
  
  output$cleangraph_download_button <- downloadHandler(
    filename = paste("cleaned_data_graph.RasPiPhenoApp.pdf"),
    content <- function(file) {
      pdf(file, width = 8, height =6)
      plot(clean_graph_all())
      dev.off()
      
    }
  )
  
  ### TAB 3.1 Calculating growth rate (GR) inputs ###
  
  ########################################################## Define UI vatiables ########################################################## 
  interval_choices <- reactive(if(is.null(Raspi_unique())){return(NULL)}else{
    if(input$expType == "PhenoRig"){
      interval_list <- c("3 hours", "6 hours", "day", "2 days")
    }
    if(input$expType == "PhenoCage"){
      interval_list <- c("6 days", "8 days", "10 days")
    }
    return(interval_list)
  })
  
  output$interval <- renderUI({
    if(is.null(Raspi_unique()) | input$GrowthType == "Over whole experiment"){return(NULL)}else{
      tagList(selectizeInput(
        inputId = "GrowthInterval",
        label = "Calculate growth rate for every:",
        choices = interval_choices(),
        multiple=F
      ))
      
    }
  })
  
  step_choices <- reactive(if(is.null(Raspi_unique())){return(NULL)}else{
    if(input$expType == "PhenoRig"){
      interval_list <- c("1 h", "6 h", "12 h", "24 h")
    }
    if(input$expType == "PhenoCage"){
      interval_list <- c("2 days", "4 days", "6 days")
    }
    return(interval_list)
  })
  
  
  output$step <- renderUI({
    if(is.null(Raspi_unique()) | input$GrowthType == "Over whole experiment"){return(NULL)}else{
      tagList(selectizeInput(
        inputId = "step_size",
        label = "Calculate growth rate with step size every:",
        choices = step_choices(),
        multiple=F
      ))
    }
  })
  
  ########################################################## generate the GR table ########################################################## 
  Growth_rate_table <- reactive(if(input$GoGrowth == FALSE){return(NULL)}else{
    if(input$GrowthType == "Step-wise"){
      if(input$dataGrowth == "Original data"){
        my_data <- Raspi_unique()
        if(input$expType == "PhenoRig"){
          # isolate 1st plant 
          all_plants <- unique(my_data$Plant.ID)
          my_data$time.min <- as.numeric(as.character(my_data$time.min))
          temp <- subset(my_data, my_data$Plant.ID == all_plants[1])
          # isolate first time interval
          min_time <- min(my_data$time.min)
          max_time <- max(my_data$time.min)
          if(input$step_size == "1 h"){step_time <- 60}
          if(input$step_size == "6 h"){step_time <- 60*6}
          if(input$step_size == "12 h"){step_time <- 60*12}
          if(input$step_size == "24 h"){step_time <- 60*24}
          growth_timeline <- seq(min_time, max_time, by=step_time)
          growth_timeline <- growth_timeline[-length(growth_timeline)]
          if(input$GrowthInterval == "3 hours"){
            temp_now <- subset(temp, temp$time.min < 180)
            temp_now$area.smooth <- as.numeric(temp_now$area.smooth)
            temp_now$time.min <- as.numeric(temp_now$time.min)
            model_now <- lm(temp_now$area ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 180
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              temp_now$area.smooth <- as.numeric(temp_now$area.smooth)
              temp_now$time.min <- as.numeric(temp_now$time.min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = t + 1
            for(r in 2:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 180
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "6 hours"){
            temp_now <- subset(temp, temp$time.min < 360)
            model_now <- lm(temp_now$area ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 360
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 360
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "day"){
            temp_now <- subset(temp, temp$time.min < 1440)
            model_now <- lm(temp_now$area ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 1440
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 1440
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "2 days"){
            temp_now <- subset(temp, temp$time.min < 2880)
            model_now <- lm(temp_now$area ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 2880
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 2880
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
        }
        if(input$expType == "PhenoCage"){
          # isolate 1st plant 
          all_plants <- unique(my_data$POT)
          my_data$time.days <- as.numeric(as.character(my_data$time.days))
          temp <- subset(my_data, my_data$POT == all_plants[1])
          # isolate first time interval
          min_time <- min(my_data$time.days)
          max_time <- max(my_data$time.days)
          if(input$step_size == "2 days"){step_time <- 2}
          if(input$step_size == "4 days"){step_time <- 4}
          if(input$step_size == "6 days"){step_time <- 6}
          growth_timeline <- seq(min_time, max_time, by=step_time)
          growth_timeline <- growth_timeline[-length(growth_timeline)]
          if(input$GrowthInterval == "6 days"){
            temp_now <- subset(temp, temp$time.days < 6)
            model_now <- lm(temp_now$area.total ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 6
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 6
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "8 days"){
            temp_now <- subset(temp, temp$time.days < 8)
            model_now <- lm(temp_now$area.total ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 8
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 8
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "10 days"){
            temp_now <- subset(temp, temp$time.days < 10)
            model_now <- lm(temp_now$area.total ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 10
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 10
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
        }
      }
      if(input$dataGrowth == "Smooth data"){
        my_data <- smooth_all()   
        if(input$expType == "PhenoRig"){
          # isolate 1st plant 
          all_plants <- unique(my_data$Plant.ID)
          my_data$time.min <- as.numeric(as.character(my_data$time.min))
          temp <- subset(my_data, my_data$Plant.ID == all_plants[1])
          # isolate first time interval
          min_time <- min(my_data$time.min)
          max_time <- max(my_data$time.min)
          if(input$step_size == "1 h"){step_time <- 60}
          if(input$step_size == "6 h"){step_time <- 60*6}
          if(input$step_size == "24 h"){step_time <- 60*24}
          growth_timeline <- seq(min_time, max_time, by=step_time)
          growth_timeline <- growth_timeline[-length(growth_timeline)]
          if(input$GrowthInterval == "3 hours"){
            temp_now <- subset(temp, temp$time.min < 180)
            temp_now$area.smooth <- as.numeric(temp_now$area.smooth)
            temp_now$time.min <- as.numeric(temp_now$time.min)
            model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 180
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                temp_now$area.smooth <- as.numeric(temp_now$area.smooth)
                temp_now$time.min <- as.numeric(temp_now$time.min)
                model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = t + 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 180
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "6 hours"){
            temp_now <- subset(temp, temp$time.min < 360)
            model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 360
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 360
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "day"){
            temp_now <- subset(temp, temp$time.min < 1440)
            model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 1440
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 1440
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "2 days"){
            temp_now <- subset(temp, temp$time.min < 2880)
            model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="Plant.ID", "min", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$Plant.ID[1]
            growth_data[1,2] <- min(temp_now$time.min)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 2880
              temp_now <- subset(temp, temp$time.min < max)
              temp_now <- subset(temp_now, temp_now$time.min >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                growth_data[t,1] <- temp_now$Plant.ID[1]
                growth_data[t,2] <- min(temp_now$time.min)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$Plant.ID == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 2880
                  temp_now <- subset(temp, temp$time.min < max)
                  temp_now <- subset(temp_now, temp_now$time.min >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.smooth ~ temp_now$time.min)
                    growth_data[counter,1] <- temp_now$Plant.ID[1]
                    growth_data[counter,2] <- min(temp_now$time.min)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
        }
        if(input$expType == "PhenoCage"){
          # isolate 1st plant 
          all_plants <- unique(my_data$POT)
          my_data$time.days <- as.numeric(as.character(my_data$time.days))
          temp <- subset(my_data, my_data$POT == all_plants[1])
          # isolate first time interval
          min_time <- min(my_data$time.days)
          max_time <- max(my_data$time.days)
          if(input$step_size == "2 days"){step_time <- 2}
          if(input$step_size == "4 days"){step_time <- 4}
          if(input$step_size == "6 days"){step_time <- 6}
          growth_timeline <- seq(min_time, max_time, by=step_time)
          growth_timeline <- growth_timeline[-length(growth_timeline)]
          if(input$GrowthInterval == "6 days"){
            temp_now <- subset(temp, temp$time.days < 6)
            model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 6
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 6
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "8 days"){
            temp_now <- subset(temp, temp$time.days < 8)
            model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 8
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 8
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
          if(input$GrowthInterval == "10 days"){
            temp_now <- subset(temp, temp$time.days < 10)
            model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            names <- c(text="POT", "day", "GR", "R2")
            growth_data <- data.frame()
            for (k in names) growth_data[[k]] <- as.character()
            growth_data
            growth_data[1,1] <- temp_now$POT[1]
            growth_data[1,2] <- min(temp_now$time.days)
            growth_data[1,3] <- GR
            growth_data[1,4] <- R2
            for(t in 2:length(growth_timeline)){
              min = growth_timeline[t]
              max = min + 10
              temp_now <- subset(temp, temp$time.days < max)
              temp_now <- subset(temp_now, temp_now$time.days >= min)
              if(dim(temp_now)[1]>3){
                model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                growth_data[t,1] <- temp_now$POT[1]
                growth_data[t,2] <- min(temp_now$time.days)
                growth_data[t,3] <- GR
                growth_data[t,4] <- R2}}
            counter = 1
            for(r in 1:length(all_plants)){
              temp <- subset(my_data, my_data$POT == all_plants[r])
              if(dim(temp)[1]>0){
                for(t in 1:length(growth_timeline)){
                  min = growth_timeline[t]
                  max = min + 10
                  temp_now <- subset(temp, temp$time.days < max)
                  temp_now <- subset(temp_now, temp_now$time.days >= min)
                  if(dim(temp_now)[1]>3){
                    model_now <- lm(temp_now$area.total.smooth ~ temp_now$time.days)
                    growth_data[counter,1] <- temp_now$POT[1]
                    growth_data[counter,2] <- min(temp_now$time.days)
                    growth_data[counter,3] <- model_now$coefficients[2]
                    growth_data[counter,4] <- summary(model_now)$r.squared
                    counter <- counter + 1}
                }}}
          }
        }
      }}
    if(input$GrowthType == "Over whole experiment"){
      if(input$dataGrowth == "Original data"){
        my_data <- Raspi_unique()
        if(input$expType == "PhenoRig"){
          all_plants <- unique(my_data$Plant.ID)
          my_data$time.min <- as.numeric(as.character(my_data$time.min))
          temp <- subset(my_data, my_data$Plant.ID == all_plants[1])
          names <- c(text="Plant.ID", "GR", "R2")
          growth_data <- data.frame()
          for (k in names) growth_data[[k]] <- as.character()
          growth_data
          model_now <- lm(temp$area ~ temp$time.min)
          GR <- model_now$coefficients[2]
          R2 <- summary(model_now)$r.squared
          growth_data[1,1] <- temp$Plant.ID[1]
          growth_data[1,2] <- GR
          growth_data[1,3] <- R2
          for(i in 2:length(all_plants)){
            temp <- subset(my_data, my_data$Plant.ID == all_plants[i])
            names <- c(text="Plant.ID", "GR", "R2")
            model_now <- lm(temp$area ~ temp$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            growth_data[i,1] <- temp$Plant.ID[1]
            growth_data[i,2] <- GR
            growth_data[i,3] <- R2
          }}
        if(input$expType == "PhenoCage"){
          all_plants <- unique(my_data$POT)
          my_data$time.days <- as.numeric(as.character(my_data$time.days))
          temp <- subset(my_data, my_data$POT == all_plants[1])
          names <- c(text="POT", "GR", "R2")
          growth_data <- data.frame()
          for (k in names) growth_data[[k]] <- as.character()
          growth_data
          model_now <- lm(temp$area.total ~ temp$time.days)
          GR <- model_now$coefficients[2]
          R2 <- summary(model_now)$r.squared
          growth_data[1,1] <- temp$POT[1]
          growth_data[1,2] <- GR
          growth_data[1,3] <- R2
          for(i in 2:length(all_plants)){
            temp <- subset(my_data, my_data$POT == all_plants[i])
            names <- c(text="POT", "GR", "R2")
            model_now <- lm(temp$area.total ~ temp$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            growth_data[i,1] <- temp$POT[1]
            growth_data[i,2] <- GR
            growth_data[i,3] <- R2
          }}}
      if(input$dataGrowth == "Smooth data"){
        my_data <- smooth_all()   
        if(input$expType == "PhenoRig"){
          all_plants <- unique(my_data$Plant.ID)
          my_data$time.min <- as.numeric(as.character(my_data$time.min))
          temp <- subset(my_data, my_data$Plant.ID == all_plants[1])
          names <- c(text="Plant.ID", "GR", "R2")
          growth_data <- data.frame()
          for (k in names) growth_data[[k]] <- as.character()
          growth_data
          model_now <- lm(temp$area.smooth ~ temp$time.min)
          GR <- model_now$coefficients[2]
          R2 <- summary(model_now)$r.squared
          growth_data[1,1] <- temp$Plant.ID[1]
          growth_data[1,2] <- GR
          growth_data[1,3] <- R2
          for(i in 2:length(all_plants)){
            temp <- subset(my_data, my_data$Plant.ID == all_plants[i])
            names <- c(text="Plant.ID", "GR", "R2")
            model_now <- lm(temp$area.smooth ~ temp$time.min)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            growth_data[i,1] <- temp$Plant.ID[1]
            growth_data[i,2] <- GR
            growth_data[i,3] <- R2
          }}
        if(input$expType == "PhenoCage"){
          all_plants <- unique(my_data$POT)
          my_data$time.days <- as.numeric(as.character(my_data$time.days))
          temp <- subset(my_data, my_data$POT == all_plants[1])
          names <- c(text="POT", "GR", "R2")
          growth_data <- data.frame()
          for (k in names) growth_data[[k]] <- as.character()
          growth_data
          model_now <- lm(temp$area.total.smooth ~ temp$time.days)
          GR <- model_now$coefficients[2]
          R2 <- summary(model_now)$r.squared
          growth_data[1,1] <- temp$POT[1]
          growth_data[1,2] <- GR
          growth_data[1,3] <- R2
          for(i in 2:length(all_plants)){
            temp <- subset(my_data, my_data$POT == all_plants[i])
            names <- c(text="POT", "GR", "R2")
            model_now <- lm(temp$area.total.smooth ~ temp$time.days)
            GR <- model_now$coefficients[2]
            R2 <- summary(model_now)$r.squared
            growth_data[i,1] <- temp$POT[1]
            growth_data[i,2] <- GR
            growth_data[i,3] <- R2
          }}}
    }
    meta <- decoding()
    if(input$expType == "PhenoCage"){
      growth_data <- merge(growth_data, meta, by="POT", all = TRUE, allow.cartesian = TRUE)
    }
    if(input$expType == "PhenoRig"){
      meta$Plant.ID <- paste(meta$RasPi, meta$Camera, meta$position, sep="_")
      growth_data <- merge(growth_data, meta, by=c("Plant.ID"), all = TRUE, allow.cartesian = TRUE)
    }
    growth_data <- na.omit(growth_data)
    return(growth_data)
  })
  
  
  
  
  output$Growth_table <- renderDataTable(
    Growth_rate_table()
  )
  
  # Growth rate table button
  
  output$Growth_table_button <- renderUI({
    if (is.null(Growth_rate_table())) {
      return()
    }
    else{
      downloadButton("growthtable_download_button", label = "Download table")
    }
  })
  
  
  ##########################################################  download growth rate file ########################################################## 
  
  
  output$growthtable_download_button <- downloadHandler(
    filename = paste("GrowthRate_data.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- Growth_rate_table()
      write.csv(result, file, row.names = FALSE)
      
    }
  )
  ### TAB 3.1 ended
  ### TAB 3.2 Generate the GR plot
  
  ##########################################################  Define UI variables ########################################################## 
  
  output$Growth_Color_button <- renderUI({
    if(is.null(Growth_rate_table())){return()} else {
      tagList(
        selectizeInput(
          inputId = "ColorGrowth",
          label = "Color graph per:",
          choices = metaList(),
          multiple = F
        ))}
  })
  
  output$Growth_Xaxis <- renderUI({
    if(input$GrowthType == "Step-wise"){return()} else {
      tagList(
        selectizeInput(
          inputId = "XGrowth",
          label = "X-axis:",
          choices = metaList(),
          multiple = F
        ))}
  })
  
  output$Growth_facet_check <- renderUI({
    if(is.null(Growth_rate_table())){return()} else {
      tagList(
        checkboxInput(
          inputId = "GrowthFacet",
          label = "Split the graph"
        ))}
  })
  
  output$Growth_facet <- renderUI({
    if(input$GrowthFacet == FALSE){return()} else {
      tagList(
        selectizeInput(
          inputId = "FacetGrowth",
          label = "Facet graph per:",
          choices = metaList(),
          multiple = F
        ))}
  })
  
  output$Rhowlowui <- renderUI({
    if(input$Rtoolow == FALSE){return()} else {
      sliderInput("Rhowlow", label="Select R2 threshold", min = 0, max = 1, step = 0.05, value = 0.5)}
  })
  
  
  ########################################################## Growth rate graph  ##########################################################
  
  Growth_rate_graph <- reactive(if(input$GoGrowth==FALSE){return(NULL)}else{
    my_data <- Growth_rate_table()
    my_data$GR <- as.numeric(as.character(my_data$GR))
    my_data$fill <- my_data[,input$ColorGrowth]
    if(input$Rtoolow == TRUE){
      my_data <- subset(my_data, my_data$R2 > as.numeric(input$Rhowlow))
    }
    
    if(input$GrowthType == "Over whole experiment"){
      my_data$Xaxis <- my_data[,input$XGrowth]
      if(input$expType == "PhenoRig"){
        my_plot <- ggerrorplot(my_data, y="GR", x="Xaxis", fill="fill", color="fill",
                               desc_stat = "mean_sd", add="jitter", add.params = list(color = "darkgray"),
                               ylab="Growth Rate (pix / min)", xlab=input$XGrowth)
      }
      if(input$expType == "PhenoCage"){
        my_plot <- ggerrorplot(my_data, y="GR", x="Xaxis", fill="fill", color="fill",
                               desc_stat = "mean_sd", add="jitter", add.params = list(color = "darkgray"),
                               ylab="Growth Rate (pix / day)", xlab=input$XGrowth)
      }}
    if(input$GrowthType == "Step-wise"){
      if(input$expType == "PhenoRig"){
        my_data$min <- as.numeric(as.character(my_data$min))
        my_plot <- ggplot(data=my_data, aes(x= min, y=GR, group = Plant.ID, color = fill)) 
        my_plot <- my_plot + geom_line(alpha = 0.3) 
        my_plot <- my_plot + theme_classic()
        #my_plot <- my_plot + stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group= fill), alpha=0.3)
        #my_plot <- my_plot + stat_summary(fun=mean, aes(group= fill),  size=0.7, geom="line", linetype = "dashed")
        my_plot <- my_plot + ylab("Growth Rate (pix / min)") + xlab("time (min)")
      }
      if(input$expType == "PhenoCage"){
        my_data$day <- as.numeric(as.character(my_data$day))
        my_plot <- ggplot(data=my_data, aes(x= day, y=GR, group = POT, color = fill)) 
        my_plot <- my_plot + geom_line(alpha = 0.3) 
        my_plot <- my_plot + theme_classic()
        #my_plot <- my_plot + stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group= fill), alpha=0.3)
        #my_plot <- my_plot + stat_summary(fun=mean, aes(group= fill),  size=0.7, geom="line", linetype = "dashed")
        my_plot <- my_plot + ylab("Growth Rate (pix / day)") + xlab("time (days)")
      }
    }
    #my_plot <- my_plot + scale_color_jco()
    return(my_plot)
  })
  
  output$Growth_Graph <- renderPlot({
    Growth_rate_graph()
  })
  
  
  ########################################################## download growth rate graph ##########################################################  
  
  output$Growth_graph_button <- renderUI({
    if (is.null(Growth_rate_graph())) {
      return()
    }
    else{
      downloadButton("growthgraph_download_button", label = "Download plot")
    }
  })
  
  
  output$growthgraph_download_button <- downloadHandler(
    filename = paste("GrowthRate_graph.RasPiPhenoApp.pdf"),
    content <- function(file) {
      pdf(file)
      plot(Growth_rate_graph())
      dev.off()
      
    }
  )
  
  ### TAB 4.1 Perform the stats for raw data ###
  ########################################################## Define the side bar ########################################################## 
  
  output$SelectPrimaryFactor <- renderUI({
    if(is.null(smooth_all())){return()} else {
      tagList(
        selectizeInput(
          inputId = "PrimaryFactor",
          label = "Select the experimental independent variable",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  output$SelectOtherFactor <- renderUI({
    if(input$FactorCheck == FALSE){return()} else {
      tagList(
        selectizeInput(
          inputId = "OtherFactor",
          label = "Select the additional experimental independent variable(s)",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  output$SelectMethod <- renderUI({
    if(input$FactorCheck == FALSE){
      selectizeInput("StatsMethod", label = "What statistical methods used for comparison ?", 
                     choices = c(
                       "T-test", 
                       "Wilcox test",
                       "Kruskal-Wallis",
                       "One-way ANOVA"
                     ), multiple = F)
      
    } else {
      selectizeInput("StatsMethod", label = "What statistical methods used for comparison ?", 
                     choices = c("Two-way ANOVA"), multiple = F)
      
    }
  })
  
  ########################################################## Define the UI varibles for smooth data ########################################################## 
  FactorLength <-  reactive(if(is.null(smooth_all())){
    return(NULL)} else {
      temp <- smooth_all()
      return(length(unique(temp[,input$PrimaryFactor])))
      
    })
  
  output$smooth_stats_button <- renderUI({
    if (is.null(smooth_all())) {
      return()
    }
    else{
      downloadButton("smooth_stats_download_button", label = "Download the statistics of smooth data")
    }
  })
  
  ########################################################## Send the report information ########################################################## 
  
  output$Smooth_data_stats_report <- renderText({
    if(input$FactorCheck == FALSE){
      if(is.null(smooth_all())){
        return(NULL)}
      else{
        data <- smooth_all()
        data_var <- input$PrimaryFactor
        no_var <- length(unique(data[,input$PrimaryFactor]))
        
        sentence_stats1 <- paste("Your selected independent variable is", data_var,
                                 "and the level of the this variable is",no_var)
        return(sentence_stats1)
      }
    } else {
      if(is.null(smooth_all())){
        return(NULL)}
      else{
        data <- smooth_all()
        data_var1 <- input$PrimaryFactor
        data_var2 <- input$OtherFactor
        
        sentence_stats2 <- paste("Your selected two independent variables are", data_var1,
                                 "and ",data_var2)
        return(sentence_stats2)
      }
      
    }
  })
  
  GroupList <-  reactive(if(is.null(smooth_all())){
    return(NULL)} else {
      data <- smooth_all()
      return(unique(data[,input$PrimaryFactor]))
    })
  
  
  ########################################################## Define each of the stats comparison ########################################################## 
  
  output$SelectsmoothSet1 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength() >= 2){
        selectizeInput("Compset1", label = "Which group of data used as refenrece?", 
                       choices = GroupList(), multiple = F)} 
      else if (FactorLength() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels")
        return(Warning_sentence)
        }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength() >= 2){
        selectizeInput("Compset1", label = "Which group of data used as refenrece?", 
                       choices = GroupList(), multiple = F)}
      else if (FactorLength() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels.")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  GroupList2 <-  reactive(if(is.null(smooth_all())){
    return(NULL)} else {
      data <- smooth_all()
      list_of_things <- unique(data[,input$PrimaryFactor])
      list_of_comparisons <- subset(list_of_things, !(list_of_things %in% input$Compset1))
      return(list_of_comparisons)
    })
  
  output$SelectsmoothSet2 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength() >= 2){
        selectizeInput("Compset2", label = "Which group of data used as comparison?", 
                       choices = GroupList2(), multiple = F)}
      else if (FactorLength() < 2) {
        Warning_sentence <- paste("See instructions for more details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength() >= 2){
        selectizeInput("Compset2", label = "Which group of data used as comparison?", 
                       choices = GroupList2(), multiple = F)}
      else if (FactorLength() < 2) {
        Warning_sentence <- paste("See instructions for more details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  ### define selected groups
  list_of_comp <-  reactive(if(is.null(smooth_all())){
    return(NULL)} else {
      if(input$StatsMethod == "T-test"){
        list_of_comp <- c(input$Compset1,input$Compset2)
      } else if (input$StatsMethod == "Wilcox test"){
        list_of_comp <- c(input$Compset1,input$Compset2)
      } else if (input$StatsMethod == "Kruskal-Wallis"){
        list_of_comp <- GroupList()
      } else if (input$StatsMethod == "One-way ANOVA"){
        list_of_comp <- GroupList()
      } else if (input$StatsMethod == "Two-way ANOVA"){
        list_of_comp <- GroupList()
      }
      return(list_of_comp)
    })
  
  ########################################################## Plot the stats graph ########################################################## 
  
  smooth_comp_graph <- reactive(if(input$GoStats==FALSE){
    Plot_sentence <- paste0("Please Click the Launch statistical analysis button in the sidebar")
    return(Plot_sentence)}else{
    
    ### For PhenoRig
    if(input$expType == "PhenoRig"){
    
    my_data <- unique(smooth_all())
    my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp()))
    my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
    my_data$area.smooth <- as.numeric(as.character(my_data$area.smooth))
    my_data$time.min <- as.numeric(as.character(my_data$time.min))
    
    smooth_stats_plot <- 
      ggplot(data = my_data, aes(x= time.min, y=area.smooth, color = col.sorting)) + 
      geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
      geom_point(alpha = 0.3,size = 0.2, aes(group= Plant.ID)) + 
      theme_classic() +
      ylab("Cummulative Shoot Area (Smooth data)") +
      xlab("Time (minutes)") + 
      stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
      stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
      if(input$StatsMethod == "T-test"){
        stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
      } else if (input$StatsMethod == "Wilcox test"){
        stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
      } else if (input$StatsMethod == "Kruskal-Wallis"){
        stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
      } else if (input$StatsMethod == "One-way ANOVA"){
        stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
      } else if (input$StatsMethod == "Two-way ANOVA"){
        stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
      }
    
    } else if (input$expType == "PhenoCage"){
      
      my_data <- unique(smooth_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area.total.smooth <- as.numeric(as.character(my_data$area.total.smooth))
      my_data$time.days <- as.numeric(as.character(my_data$time.days))
      
      smooth_stats_plot <- 
        ggplot(data = my_data, aes(x= time.days, y=area.total.smooth, color = col.sorting)) + 
        geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
        geom_point(alpha = 0.3,size = 0.2, aes(group= POT)) + 
        theme_classic() +
        ylab("Cummulative Shoot Area (Smooth data)") +
        xlab("Time (days)") + 
        stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
        stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
        
        if(input$StatsMethod == "T-test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
        } else if (input$StatsMethod == "Wilcox test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
        } else if (input$StatsMethod == "Kruskal-Wallis"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
        } else if (input$StatsMethod == "One-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
        } else if (input$StatsMethod == "Two-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
        }
    }
    
    return(smooth_stats_plot)
    #
  })
  
  output$smooth_graph_comp <- renderPlotly({
    if(input$GoStats == FALSE){
      Plot_sentence <- paste0("Please Click the Launch statistical analysis button in the sidebar")
      return(Plot_sentence)
    } else {ggplotly(smooth_comp_graph())}
  })
  
  
  ########################################################## Generate the stats comparison table ########################################################## 
  
  output$Comp_table1 <- renderDataTable(if(input$GoStats==FALSE){return(NULL)}else{
    
    ### For PhenoRig
    if(input$expType == "PhenoRig"){
      
      my_data <- unique(smooth_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area.smooth <- as.numeric(my_data$area.smooth)
      time.vector <- my_data$time.min %>% sort() %>% unique() 
      test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
      colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
      test_table$Timepoint <- time.vector
      select_name <- input$PrimaryFactor

      if(input$StatsMethod == "T-test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset1),"area.smooth"]
          if (length(y1) == 0) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset2),"area.smooth"]
            if (length(y2) == 0) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- t.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Wilcox test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset1),"area.smooth"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset2),"area.smooth"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- wilcox.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Kruskal-Wallis") {
        time.vector <- my_data$time.min %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        attach(my_data)
        for (i in (1:length(time.vector))){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- kruskal.test(area.smooth ~ col.sorting, data = sub_data)
          test_table[i,2] <- test.result$p.value
        }
        
      } else if (input$StatsMethod == "One-way ANOVA") {
        attach(my_data)
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- aov(area.smooth ~ col.sorting, data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
        }
        
      } else if (input$StatsMethod == "Two-way ANOVA") {

        my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
        test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
        test_table$Timepoint <- time.vector
        attach(my_data)
        
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- aov(area.smooth ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
        }
      }
      
      ### For PhenoCage
    } else if (input$expType == "PhenoCage"){
      
      my_data <- unique(smooth_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area.total.smooth <- as.numeric(my_data$area.total.smooth)
      time.vector <- my_data$time.days %>% sort() %>% unique() 
      test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
      colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
      test_table$Timepoint <- time.vector
      select_name <- input$PrimaryFactor
      
      if(input$StatsMethod == "T-test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset1),"area.total.smooth"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset2),"area.total.smooth"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- t.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Wilcox test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset1),"area.total.smooth"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset2),"area.total.smooth"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- wilcox.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Kruskal-Wallis") {
        time.vector <- my_data$time.days %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        attach(my_data)
        for (i in (1:length(time.vector))){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- kruskal.test(area.total.smooth ~ col.sorting, data = sub_data)
          test_table[i,2] <- test.result$p.value
        }
        
      } else if (input$StatsMethod == "One-way ANOVA") {
        attach(my_data)
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- aov(area.total.smooth ~ col.sorting, data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
        }
        
      } else if (input$StatsMethod == "Two-way ANOVA") {
        
        my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
        test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
        test_table$Timepoint <- time.vector
        attach(my_data)
        
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- aov(area.total.smooth ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
        }
      }
    }
    
    return(test_table)
  })
  
  ########################################################## download stats table for smooth data ########################################################## 
  
  output$smooth_stats_download_button <- downloadHandler(
    filename = paste("Smooth_data-statistics.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- Comp_table1()
      write.csv(result, file, row.names = FALSE)
      
    }
  )
  
  ### TAB 4.2 Perform the stats for clean data ###
  ########################################################## Define UI variables ########################################################## 
  output$SelectPrimaryFactor <- renderUI({
    if(is.null(clean_all())){return()} else {
      tagList(
        selectizeInput(
          inputId = "PrimaryFactor",
          label = "Select the experimental independent variable",
          choices = metaList(),
          multiple = F
        )
      )
    }
  })
  
  FactorLength2 <-  reactive(if(is.null(clean_all())){
    return(NULL)} else {
      temp <- clean_all()
      return(length(unique(temp[,input$PrimaryFactor])))
    })
  
  
  output$clean_stats_button <- renderUI({
    if (is.null(clean_all())) {
      return()
    }
    else{
      downloadButton("clean_stats_download_button", label = "Download the statistics of clean data")
    }
  })
  
  
  ########################################################## Send the report information ########################################################## 
  
  output$Clean_data_stats_report <- renderText({
    if(input$FactorCheck == FALSE){
      if(is.null(clean_all())){
        return(NULL)}
      else{
        data <- clean_all()
        data_var <- input$PrimaryFactor
        no_var <- length(unique(data[,input$PrimaryFactor]))
        
        sentence_stats1 <- paste("Your selected independent variable is", data_var,
                                 "and the level of the this variable is",no_var)
        return(sentence_stats1)
      }
    } else {
      if(is.null(clean_all())){
        return(NULL)}
      else{
        data <- clean_all()
        data_var1 <- input$PrimaryFactor
        data_var2 <- input$OtherFactor
        
        sentence_stats2 <- paste("Your selected two independent variables are", data_var1,
                                 "and ",data_var2)
        return(sentence_stats2)
      }
      
    }
  })
  
  
  ########################################################## Define each of the stats comparison ########################################################## 
  GroupList3 <-  reactive(if(is.null(clean_all())){
    return(NULL)} else {
      data <- clean_all()
      return(unique(data[,input$PrimaryFactor]))
    })
  
  output$SelectCleanSet1 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength2() >= 2){
        selectizeInput("Compset1_clean", label = "Which group of data used as refenrece?", 
                       choices = GroupList3(), multiple = F)}
      else if (FactorLength2() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength2() >= 2){
        selectizeInput("Compset1_clean", label = "Which group of data used as refenrece?", 
                       choices = GroupList3(), multiple = F)}
      else if (FactorLength2() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  GroupList4 <-  reactive(if(is.null(clean_all())){
    return(NULL)} else {
      data <- clean_all()
      list_of_things <- unique(data[,input$PrimaryFactor])
      list_of_comparisons <- subset(list_of_things, !(list_of_things %in% input$Compset1_clean))
      return(list_of_comparisons)
    })
  
  output$SelectCleanSet2 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength2() >= 2){
        selectizeInput("Compset2_clean", label = "Which group of data used as comparison?", 
                       choices = GroupList4(), multiple = F)}
      else if (FactorLength2() < 2) {
        Warning_sentence <- paste("See instructions for details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength2() >= 2){
        selectizeInput("Compset2_clean", label = "Which group of data used as comparison?", 
                       choices = GroupList4(), multiple = F)}
      else if (FactorLength2() < 2) {
        Warning_sentence <- paste("See instructions for details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  ### define selected groups
  list_of_comp2 <-  reactive(if(is.null(clean_all())){
    return(NULL)} else {
      if(input$StatsMethod == "T-test"){
        list_of_comp2 <- c(input$Compset1_clean,input$Compset2_clean)
      } else if (input$StatsMethod == "Wilcox test"){
        list_of_comp2 <- c(input$Compset1_clean,input$Compset2_clean)
      } else if (input$StatsMethod == "Kruskal-Wallis"){
        list_of_comp2 <- GroupList()
      } else if (input$StatsMethod == "One-way ANOVA"){
        list_of_comp2 <- GroupList()
      } else if (input$StatsMethod == "Two-way ANOVA"){
        list_of_comp2 <- GroupList()
      }
      return(list_of_comp2)
    })
  
  ########################################################## Plot the clean stats graph ########################################################## 
  
  clean_stats_plot <- reactive(if(input$GoStats==FALSE){return(NULL)}else{
    
    ### For PhenoRig
    if(input$expType == "PhenoRig"){
      
      my_data <- unique(clean_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp2()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area <- as.numeric(as.character(my_data$area))
      my_data$time.min <- as.numeric(as.character(my_data$time.min))
      
      clean_stats_plot <- 
        ggplot(data = my_data, aes(x= time.min, y=area, color = col.sorting)) + 
        geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
        geom_point(alpha = 0.3,size = 0.2, aes(group= Plant.ID)) + 
        theme_classic() +
        ylab("Cummulative Shoot Area (Clean data)") +
        xlab("Time (minutes)") + 
        stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
        stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
        if(input$StatsMethod == "T-test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = T)
        } else if (input$StatsMethod == "Wilcox test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = T)
        } else if (input$StatsMethod == "Kruskal-Wallis"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = T)
        } else if (input$StatsMethod == "One-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = T)
        } else if (input$StatsMethod == "Two-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = T)
        }
      
    } else if (input$expType == "PhenoCage"){
      
      my_data <- unique(clean_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp2()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area.total <- as.numeric(as.character(my_data$area.total))
      my_data$time.days <- as.numeric(as.character(my_data$time.days))
      
      clean_stats_plot <- 
        ggplot(data = my_data, aes(x= time.days, y=area.total, color = col.sorting)) + 
        geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
        geom_point(alpha = 0.3,size = 0.2, aes(group= POT)) + 
        theme_classic() +
        ylab("Cummulative Shoot Area (Clean data)") +
        xlab("Time (days)") + 
        stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
        stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
        
        if(input$StatsMethod == "T-test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
        } else if (input$StatsMethod == "Wilcox test"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
        } else if (input$StatsMethod == "Kruskal-Wallis"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
        } else if (input$StatsMethod == "One-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
        } else if (input$StatsMethod == "Two-way ANOVA"){
          stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
        }
    }
    
    return(clean_stats_plot)
    #
  })
  
  output$clean_graph_comp <- renderPlotly({
    if(input$GoStats == FALSE){
      Plot_sentence <- paste0("Please Click the Launch statistical analysis button in the sidebar")
      return(Plot_sentence)
    } else {ggplotly(clean_stats_plot())}
  })
  
  ########################################################## Generate the stats comparison table ########################################################## 
  
  output$Clean_stats_table <- renderDataTable(if(input$GoStats==FALSE){return(NULL)}else{
    
    ### For PhenoRig
    if(input$expType == "PhenoRig"){
      
      my_data <- unique(clean_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp2()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area <- as.numeric(my_data$area)
      time.vector <- my_data$time.min %>% sort() %>% unique() 
      test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
      colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
      test_table$Timepoint <- time.vector
      select_name <- input$PrimaryFactor
      
      if(input$StatsMethod == "T-test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset1_clean),"area"]
          if (length(y1) == 0) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset2_clean),"area"]
            if (length(y2) == 0) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- t.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Wilcox test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset1_clean),"area"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.min==time.vector[i] & get(select_name)== input$Compset2_clean),"area"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- wilcox.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Kruskal-Wallis") {
        time.vector <- my_data$time.min %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        attach(my_data)
        for (i in (1:length(time.vector))){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- kruskal.test(area ~ col.sorting, data = sub_data)
          test_table[i,2] <- test.result$p.value
        }
        
      } else if (input$StatsMethod == "One-way ANOVA") {
        attach(my_data)
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- aov(area ~ col.sorting, data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
        }
        
      } else if (input$StatsMethod == "Two-way ANOVA") {
        
        my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
        test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
        test_table$Timepoint <- time.vector
        attach(my_data)
        
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.min == time.vector[i],]
          test.result <- aov(area ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
        }
      }
      
      ### For PhenoCage
    } else if (input$expType == "PhenoCage"){
      
      my_data <- unique(clean_all())
      my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp2()))
      my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
      my_data$area.total <- as.numeric(my_data$area.total)
      time.vector <- my_data$time.days %>% sort() %>% unique() 
      test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
      colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
      test_table$Timepoint <- time.vector
      select_name <- input$PrimaryFactor
      
      if(input$StatsMethod == "T-test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset1_clean),"area.total"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset2_clean),"area.total"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- t.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Wilcox test"){
        attach(my_data)
        for (i in (1:length(time.vector))){
          y1 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset1_clean),"area.total"]
          if (length(y1) <= 1) {
            test_table[i,2] <- "NA"
          } else {
            y2 <- my_data[ which(time.days==time.vector[i] & get(select_name)== input$Compset2_clean),"area.total"]
            if (length(y2) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              test.result <- wilcox.test(y1, y2)
              test_table[i,2] <- test.result$p.value
            }
          }
        }
        
      } else if (input$StatsMethod == "Kruskal-Wallis") {
        time.vector <- my_data$time.days %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        attach(my_data)
        for (i in (1:length(time.vector))){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- kruskal.test(area.total ~ col.sorting, data = sub_data)
          test_table[i,2] <- test.result$p.value
        }
        
      } else if (input$StatsMethod == "One-way ANOVA") {
        attach(my_data)
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- aov(area.total ~ col.sorting, data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
        }
        
      } else if (input$StatsMethod == "Two-way ANOVA") {
        
        my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
        test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
        test_table$Timepoint <- time.vector
        attach(my_data)
        
        for (i in 1:length(time.vector)){
          sub_data <- my_data[my_data$time.days == time.vector[i],]
          test.result <- aov(area.total ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
          aov_result <- summary(test.result)
          test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
        }
      }
    }
    
    return(test_table)
  })
  
  ########################################################## download stats table for clean data ########################################################## 
  
  output$clean_stats_download_button <- downloadHandler(
    filename = paste("clean_data-statistics.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- Clean_stats_table()
      write.csv(result, file, row.names = FALSE)
    }
  )
  
  
  ### TAB 4.3 Perform the stats for GR data ###
  ########################################################## Define UI variables ########################################################## 
  
  FactorLength3 <-  reactive(if(is.null(Growth_rate_table())){
    return(NULL)} else {
      temp <- Growth_rate_table()
      return(length(unique(temp[,input$PrimaryFactor])))
      
    })
  
  
  output$GR_stats_button <- renderUI({
    if (is.null(Growth_rate_table())) {
      return()
    }
    else{
      downloadButton("GR_stats_download_button", label = "Download the statistics of GR data")
    }
  })
  
  ########################################################## Send the report information ########################################################## 
  
  output$GR_data_stats_report <- renderText({
    if(input$FactorCheck == FALSE){
      if(is.null(Growth_rate_table())){
        return(NULL)}
      else{
        data <- Growth_rate_table()
        data_var <- input$PrimaryFactor
        no_var <- length(unique(data[,input$PrimaryFactor]))
        
        sentence_stats1 <- paste("Your selected independent variable is", data_var,
                                 "and the level of the this variable is",no_var)
        return(sentence_stats1)
      }
    } else {
      if(is.null(Growth_rate_table())){
        return(NULL)}
      else{
        data <- Growth_rate_table()
        data_var1 <- input$PrimaryFactor
        data_var2 <- input$OtherFactor
        
        sentence_stats2 <- paste("Your selected two independent variables are", data_var1,
                                 "and ",data_var2)
        return(sentence_stats2)
      }
      
    }
  })
  
  ########################################################## Define each of the stats comparison ########################################################## 
  GroupList5 <-  reactive(if(is.null(Growth_rate_table())){
    return(NULL)} else {
      data <- Growth_rate_table()
      return(unique(data[,input$PrimaryFactor]))
    })
  
  output$SelectGRSet1 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength3() >= 2){
        selectizeInput("Compset1_GR", label = "Which group of data used as refenrece?", 
                       choices = GroupList5(), multiple = F)}
      else if (FactorLength3() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength3() >= 2){
        selectizeInput("Compset1_GR", label = "Which group of data used as refenrece?", 
                       choices = GroupList5(), multiple = F)}
      else if (FactorLength3() < 2) {
        Warning_sentence <- paste("Please select the variable with at least 2 levels")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  GroupList6 <-  reactive(if(is.null(Growth_rate_table())){
    return(NULL)} else {
      data <- Growth_rate_table()
      list_of_things <- unique(data[,input$PrimaryFactor])
      list_of_comparisons <- subset(list_of_things, !(list_of_things %in% input$Compset1_GR))
      return(list_of_comparisons)
    })
  
  output$SelectGRSet2 <- renderUI({
    if(input$StatsMethod == "T-test"){
      if(FactorLength3() >= 2){
        selectizeInput("Compset2_GR", label = "Which group of data used as comparison?", 
                       choices = GroupList6(), multiple = F)}
      else if (FactorLength3() < 2) {
        Warning_sentence <- paste("See instructions for details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Wilcox test"){
      if(FactorLength3() >= 2){
        selectizeInput("Compset2_GR", label = "Which group of data used as comparison?", 
                       choices = GroupList6(), multiple = F)}
      else if (FactorLength3() < 2) {
        Warning_sentence <- paste("See instructions for details")
        return(Warning_sentence)
      }
    } else if (input$StatsMethod == "Kruskal-Wallis"){
      return(NULL)
    } else if (input$StatsMethod == "One-way ANOVA"){
      return(NULL)
    }
  })
  
  ### define selected groups
  list_of_comp3 <-  reactive(if(is.null(Growth_rate_table())){
    return(NULL)} else {
      if(input$StatsMethod == "T-test"){
        list_of_comp3 <- c(input$Compset1_GR,input$Compset2_GR)
      } else if (input$StatsMethod == "Wilcox test"){
        list_of_comp3 <- c(input$Compset1_GR,input$Compset2_GR)
      } else if (input$StatsMethod == "Kruskal-Wallis"){
        list_of_comp3 <- GroupList()
      } else if (input$StatsMethod == "One-way ANOVA"){
        list_of_comp3 <- GroupList()
      } else if (input$StatsMethod == "Two-way ANOVA"){
        list_of_comp3 <- GroupList()
      }
      return(list_of_comp3)
    })
  
  
  ########################################################## Plot the stats graph ########################################################## 
  
  GR_comp_plot <- reactive(if(input$GoStats==FALSE){return(NULL)}else{
    
    if(input$GrowthType == "Over whole experiment"){
      my_data <- unique(Growth_rate_table())
      sub_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
      sub_data$col.sorting <- as.factor(sub_data[,input$PrimaryFactor])
      sub_data$GR <- as.numeric(as.character(sub_data$GR))
    
      if(input$expType == "PhenoRig"){

        GR_stats_plot <- ggplot(data = sub_data, aes(x= col.sorting, y=GR, color = col.sorting)) + 
          geom_boxplot(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          theme_classic() +
          ylab("Growth Rate (GR)") +
          if(input$StatsMethod == "T-test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
          } else if (input$StatsMethod == "Wilcox test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
          } else if (input$StatsMethod == "Kruskal-Wallis"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
          } else if (input$StatsMethod == "One-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          } else if (input$StatsMethod == "Two-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          }
        
      } else if (input$expType == "PhenoCage"){
        
        GR_stats_plot <- ggplot(data = sub_data, aes(x= col.sorting, y=GR, color = col.sorting)) + 
          geom_boxplot(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          theme_classic() +
          ylab("Growth Rate (GR)") +
          if(input$StatsMethod == "T-test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
          } else if (input$StatsMethod == "Wilcox test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
          } else if (input$StatsMethod == "Kruskal-Wallis"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
          } else if (input$StatsMethod == "One-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          } else if (input$StatsMethod == "Two-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          }
        
      }
    } else if(input$GrowthType == "Step-wise"){
      ### For PhenoRig
      if(input$expType == "PhenoRig"){
        
        my_data <- unique(Growth_rate_table())
        my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
        my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
        my_data$GR <- as.numeric(as.character(my_data$GR))
        my_data$min <- as.numeric(as.character(my_data$min))
        
        GR_stats_plot <- 
          ggplot(data = my_data, aes(x= min, y=GR, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= Plant.ID)) +  
          geom_point(alpha = 0.3,size = 0.2, aes(group= Plant.ID)) + 
          theme_classic() +
          ylab("Growth Rate (GR)") +
          xlab("Time (minutes)") + 
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          if(input$StatsMethod == "T-test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
          } else if (input$StatsMethod == "Wilcox test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
          } else if (input$StatsMethod == "Kruskal-Wallis"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
          } else if (input$StatsMethod == "One-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          } else if (input$StatsMethod == "Two-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          }
        
      } else if (input$expType == "PhenoCage"){
        
        my_data <- unique(Growth_rate_table())
        my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
        my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
        my_data$GR <- as.numeric(as.character(my_data$GR))
        my_data$day <- as.numeric(as.character(my_data$day))
        
        GR_stats_plot <- 
          ggplot(data = my_data, aes(x= day, y=GR, color = col.sorting)) + 
          geom_line(alpha = 0.3,size = 0.4, aes(group= POT)) +  
          geom_point(alpha = 0.3,size = 0.2, aes(group= POT)) + 
          theme_classic() +
          ylab("Growth Rate (GR)") +
          xlab("Time (days)") + 
          stat_summary(fun.data = mean_se, geom="ribbon", linetype=0, aes(group=col.sorting), alpha=0.3) +
          stat_summary(fun=mean, aes(group= col.sorting),  size=0.7, geom="line", linetype = "dashed") +
          
          if(input$StatsMethod == "T-test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "t.test", hide.ns = F)
          } else if (input$StatsMethod == "Wilcox test"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "wilcox.test", hide.ns = F)
          } else if (input$StatsMethod == "Kruskal-Wallis"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "kruskal.test", hide.ns = F)
          } else if (input$StatsMethod == "One-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          } else if (input$StatsMethod == "Two-way ANOVA"){
            stat_compare_means(aes(group = col.sorting), label = "p.signif", method = "aov", hide.ns = F)
          }
      }
    }

    return(GR_stats_plot)
    #
  })
  
  output$GR_comp_graph <- renderPlotly({
    if(input$GoStats == FALSE){
      Plot_sentence <- paste0("Please Click the Launch statistical analysis button in the sidebar")
      return(Plot_sentence)
    } else {ggplotly(GR_comp_plot())}
  })
  
  
  ########################################################## Generate the stats comparison table ########################################################## 
  
  output$GR_stats_table <- renderDataTable(if(input$GoStats==FALSE){return(NULL)}else{
    
    if(input$GrowthType == "Over whole experiment"){
  
        my_data <- unique(Growth_rate_table())
        my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
        my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
        my_data$GR <- as.numeric(as.character(my_data$GR))
        select_name <- input$PrimaryFactor
        
        test_table <- data.frame(matrix(ncol = 2 , nrow = 1))
        colnames(test_table) <- c("Variable", "P_value")
        test_table$Variable <- select_name
        
        if(input$StatsMethod == "T-test"){
          attach(my_data)
            y1 <- my_data[ which(get(select_name)== input$Compset1_GR),"GR"]
            y2 <- my_data[ which(get(select_name)== input$Compset2_GR),"GR"]
            test.result <- t.test(y1, y2)
            test_table$P_value <- test.result$p.value

        } else if (input$StatsMethod == "Wilcox test"){
          attach(my_data)
          y1 <- my_data[ which(get(select_name)== input$Compset1_GR),"GR"]
          y2 <- my_data[ which(get(select_name)== input$Compset2_GR),"GR"]
          test.result <- wilcox.test(y1, y2)
          test_table$P_value <- test.result$p.value
          
        } else if (input$StatsMethod == "Kruskal-Wallis") {
          attach(my_data)
          test.result <- kruskal.test(GR ~ col.sorting, data = my_data)
          test_table$P_value <- test.result$p.value

          
        } else if (input$StatsMethod == "One-way ANOVA") {
          attach(my_data)
          test.result <- aov(GR ~ col.sorting, data = my_data)
          aov_result <- summary(test.result)
          test_table$P_value <- aov_result[[1]]$`Pr(>F)`[1]
          
        } else if (input$StatsMethod == "Two-way ANOVA") {
          
          my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
          test_table <- data.frame(matrix(ncol = 4 , nrow = 1))
          colnames(test_table) <- c("Variable",input$PrimaryFactor,input$OtherFactor,"interaction")
          test_table$Variable <- select_name
          attach(my_data)
          test.result <- aov(GR ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = my_data)
          aov_result <- summary(test.result)
          test_table[,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
        }


    } else if(input$GrowthType == "Step-wise"){
      
      if(input$expType == "PhenoRig"){
        
        my_data <- unique(Growth_rate_table())
        my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
        my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
        my_data$GR <- as.numeric(as.character(my_data$GR))
        time.vector <- my_data$min %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        
        if(input$StatsMethod == "T-test"){
          attach(my_data)
          for (i in (1:length(time.vector))){
            y1 <- my_data[ which(min==time.vector[i] & get(select_name)== input$Compset1_GR),"GR"]
            if (length(y1) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              y2 <- my_data[ which(min==time.vector[i] & get(select_name)== input$Compset2_GR),"GR"]
              if (length(y2) <= 1) {
                test_table[i,2] <- "NA"
              } else {
                test.result <- t.test(y1, y2)
                test_table[i,2] <- test.result$p.value
              }
            }
          }
          
        } else if (input$StatsMethod == "Wilcox test"){
          attach(my_data)
          for (i in (1:length(time.vector))){
            y1 <- my_data[ which(min==time.vector[i] & get(select_name)== input$Compset1_GR),"GR"]
            if (length(y1) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              y2 <- my_data[ which(min==time.vector[i] & get(select_name)== input$Compset2_GR),"GR"]
              if (length(y2) <=1) {
                test_table[i,2] <- "NA"
              } else {
                test.result <- wilcox.test(y1, y2)
                test_table[i,2] <- test.result$p.value
              }
            }
          }
          
        } else if (input$StatsMethod == "Kruskal-Wallis") {
          attach(my_data)
          for (i in (1:length(time.vector))){
            sub_data <- my_data[my_data$min == time.vector[i],]
            if(nrow(sub_data) < 2 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2] <- "NA"
            } else {
              test.result <- kruskal.test(GR ~ col.sorting, data = sub_data)
              test_table[i,2] <- test.result$p.value
            }
          }
          
        } else if (input$StatsMethod == "One-way ANOVA") {
          attach(my_data)
          for (i in 1:length(time.vector)){
            sub_data <- my_data[my_data$min == time.vector[i],]
            
            if(nrow(sub_data) < 4 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2] <- "NA"
            } else {
              test.result <- aov(GR ~ col.sorting, data = sub_data)
              aov_result <- summary(test.result)
              test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
            }
          }
          
        } else if (input$StatsMethod == "Two-way ANOVA") {
          
          my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
          test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
          colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
          test_table$Timepoint <- time.vector
          attach(my_data)
          
          for (i in 1:length(time.vector)){
            sub_data <- my_data[my_data$min == time.vector[i],]
            if(nrow(sub_data) < 4 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2:4] <- c("NA", "NA", "NA")
            } else {
              test.result <- aov(GR ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
              aov_result <- summary(test.result)
              test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
            }
          }
        }
        
        ### For PhenoCage
      } else if (input$expType == "PhenoCage"){
        
        my_data <- unique(Growth_rate_table())
        my_data <- subset(my_data, (my_data[,input$PrimaryFactor] %in% list_of_comp3()))
        my_data$col.sorting <- as.factor(my_data[,input$PrimaryFactor])
        my_data$GR <- as.numeric(my_data$GR)
        time.vector <- my_data$day %>% sort() %>% unique() 
        test_table <- data.frame(matrix(ncol = 2 , nrow = length(time.vector)))
        colnames(test_table) <- c("Timepoint",input$PrimaryFactor)
        test_table$Timepoint <- time.vector
        select_name <- input$PrimaryFactor
        
        if(input$StatsMethod == "T-test"){
          attach(my_data)
          for (i in (1:length(time.vector))){
            y1 <- my_data[ which(day==time.vector[i] & get(select_name)== input$Compset1_GR),"GR"]
            if (length(y1) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              y2 <- my_data[ which(day==time.vector[i] & get(select_name)== input$Compset2_GR),"GR"]
              if (length(y2) <= 1) {
                test_table[i,2] <- "NA"
              } else {
                test.result <- t.test(y1, y2)
                test_table[i,2] <- test.result$p.value
              }
            }
          }
          
        } else if (input$StatsMethod == "Wilcox test"){
          attach(my_data)
          for (i in (1:length(time.vector))){
            y1 <- my_data[ which(day==time.vector[i] & get(select_name)== input$Compset1_GR),"GR"]
            if (length(y1) <= 1) {
              test_table[i,2] <- "NA"
            } else {
              y2 <- my_data[ which(day==time.vector[i] & get(select_name)== input$Compset2_GR),"GR"]
              if (length(y2) <= 1) {
                test_table[i,2] <- "NA"
              } else {
                test.result <- wilcox.test(y1, y2)
                test_table[i,2] <- test.result$p.value
              }
            }
          }
          
        } else if (input$StatsMethod == "Kruskal-Wallis") {
          
          attach(my_data)
          for (i in (1:length(time.vector))){
            sub_data <- my_data[my_data$day == time.vector[i],]
            if(nrow(sub_data) < 4 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2] <- "NA"
            } else {
              test.result <- kruskal.test(GR ~ col.sorting, data = sub_data)
              test_table[i,2] <- test.result$p.value
            }
          }
          
        } else if (input$StatsMethod == "One-way ANOVA") {
          attach(my_data)
          for (i in 1:length(time.vector)){
            sub_data <- my_data[my_data$day == time.vector[i],]
            if(nrow(sub_data) < 4 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2] <- "NA"
            } else {
              test.result <- aov(GR ~ col.sorting, data = sub_data)
              aov_result <- summary(test.result)
              test_table[i,2] <- aov_result[[1]]$`Pr(>F)`[1]
            }
          }
          
        } else if (input$StatsMethod == "Two-way ANOVA") {
          
          my_data$col.sorting2 <- as.factor(my_data[,input$OtherFactor])
          test_table <- data.frame(matrix(ncol = 4 , nrow = length(time.vector)))
          colnames(test_table) <- c("Timepoint",input$PrimaryFactor,input$OtherFactor,"interaction")
          test_table$Timepoint <- time.vector
          attach(my_data)
          
          for (i in 1:length(time.vector)){
            sub_data <- my_data[my_data$day == time.vector[i],]
            if(nrow(sub_data) < 4 | unique(sub_data$col.sorting) %>% length() < 2){
              test_table[i,2:4] <- c("NA", "NA", "NA")
            } else {
              test.result <- aov(GR ~ get(input$PrimaryFactor) * get(input$OtherFactor), data = sub_data)
              aov_result <- summary(test.result)
              test_table[i,2:4] <- aov_result[[1]]$`Pr(>F)`[1:3]
            }
          }
        }
      }
    }
     
    return(test_table)
  })
  
  ########################################################## download stats table for GR data ########################################################## 
  
  output$GR_stats_download_button <- downloadHandler(
    filename = paste("GR_data-statistics.RasPiPhenoApp.csv"),
    content <- function(file) {
      result <- GR_stats_table()
      write.csv(result, file, row.names = FALSE)
      
    }
  )

  
  
  
  # Cant touch this! 
}
