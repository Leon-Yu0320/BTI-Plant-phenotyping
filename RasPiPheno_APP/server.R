server <- function(input, output) {
    
    Raspi <- reactive({
        rbindlist(lapply(input$csv.raspi$datapath, fread),
                  use.names = TRUE, fill = TRUE)})
    
    Raspi_clean <- reactive({
        Raspi <- Raspi() %>% separate(roi, c("Year", "Month", "Day","Hour","Min", "Sec","Raspi","Side","Camera"))
        Raspi$index <- paste0(Raspi$Year, ".", Raspi$Month,".", Raspi$Day, "-", Raspi$Hour, ".", Raspi$Min, ".", Raspi$Sec)
        Raspi_clean <- Raspi[,c("area","Year", "Month", "Day","Hour","Min", "Sec","index")]
        Raspi_clean
    })
    
    decoding <- reactive(if (is.null(input$csv.meta$datapath)) {
        return()
    } else {
        decoding <- read.csv(input$csv.meta$datapath)
        decoding
    })
    
    
    # Start calculating data table uncoded
    output$Data_tabl1 <- renderDataTable({
        if (is.null(input$csv.raspi)) {
            return(NULL)
        } 
        else{
            Raspi_clean()
        }
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
        } else
            tagList(
                selectizeInput(
                    inputId = "FWCol",
                    label = "Select column containing Fresh Weight",
                    choices = ItemList(),
                    multiple = F
                )
            )
    })
    
    output$SVNumber <- renderUI({
        if ((is.null(input$csv.raspi)) | (input$SVCheck == FALSE)) {
            return ()
        } else
            tagList(
                numericInput("NoSV", 
                             label = "Number of side-views per plant:",
                             value = 7)
            )
    })

    output$uploaded_RasPi_data_report <- renderText({
        if(is.null(input$csv.raspi)) {
            return(NULL)}
        else{
            data <- Raspi_clean()
            no_PIs <- length(unique(data$Raspi))
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
    
    
    # quick glance of the decoding file
    output$Data_tabl2 <- renderDataTable({decoding()})
    
    
    ### merge seven images each day 
    Raspi_unique <- reactive({
        Raspi_clean <- Raspi_clean()
        Raspi_clean <- Raspi_clean %>% group_by(index) %>% mutate(side.counts = n())
        Raspi_clean <- Raspi_clean %>% group_by(index) %>% mutate(area.mean = ave(area))
        Raspi_clean <- Raspi_clean %>% group_by(index) %>% mutate(area.total = sum(area))
        
        Raspi_unique <- unique(Raspi_clean[,c("Month", "Day", "index","side.counts","area.mean","area.total")])
        Raspi_unique
    }) 
    
    
    output$Data_tabl3 <- renderDataTable({
        if (is.null(input$csvs)) {
            return(NULL)
        } 
        if (is.null(input$csv)) {
            return(NULL)
        } 
        else{
            Raspi_unique()
            
        }
    })
}
