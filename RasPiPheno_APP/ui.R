ui <- fluidPage(
  theme = shinytheme("superhero"),
  navbarPage( title = "RasPiPheno App", 
              
  tabPanel("Data Upload", icon=icon("upload"),
    sidebarPanel(
      fileInput("csv.raspi",
                label="Upload Raspberry Pi derives CSV files here",
                multiple = TRUE),
      
      fileInput("csv.meta",
                label="Upload the decoding  Meta-data file here",
                accept = c('text / csv', '.csv', 'text/comma-separated-values')),
      
     selectInput(inputId = "EXPType",
          label = "Experimental Type:",
          choices = c("PhenoRig data", "PhenoCage data"),
          selected = "PhenoRig data"),
      uiOutput("Experiment"),
      
      checkboxInput("FWCheck", label = "My Meta-data contains collumn with Fresh Weight information", value = F),
      uiOutput("FWColumn"),
      
      checkboxInput("SVCheck", label = "My RasPi data contains multiple side-view of one plant", value = F),
      uiOutput("SVNumber")
      # end of sidebar panel
    ),
  
    
    
    mainPanel(navbarPage(
      ">> Data <<",
      tabPanel("Raspberry Pi data", icon = icon("flask"),
               verbatimTextOutput("uploaded_RasPi_data_report"),
               dataTableOutput("Data_tabl1")),
      tabPanel("Meta data", icon = icon("ruler"),
               verbatimTextOutput("uploaded_metadata_report"),
               dataTableOutput("Data_tabl2")),
      tabPanel("Decoded data", icon = icon("magic"),
               verbatimTextOutput("merged_data_report"),
               dataTableOutput("merged_data"))
    ))
    # end of Tab1
  ),
  
  tabPanel("Visual Curation", icon=icon("eye"),
    mainPanel(navbarPage(
      ">> Data curation <<",
      tabPanel("Timeseries Graph", icon=icon("chart-line"),
       sidebarPanel(
        selectInput(inputId = "y",
          label = "Source input:",
          choices = c("area", "convex_hull_area", "perimeter", "width", "height", "longest_path"),
          selected = "area"),
        selectInput(inputId = "x",
          label = "Time-series Unit:",
          choices = c("Day", "Totall minutes", "Total Hours"),
          selected = "Totall minutes"),
        selectInput(inputId = "color",
          label = "Group index: ",
          choices = c("Treatment", "Genotype"),
          selected = "Treatment"),
        
        sliderInput(inputId = "alpha",
              label = "Alpha:",
              min = 0.0, max = 1.0,
              value = 0.2),
        sliderInput(inputId = "size",
              label = "Statistics line width:",
              min = 0.0,
              max = 1.0,
              value = 0.8),
        sliderInput(inputId = "X_ticks",
              label = "X-axis ticks:",
              min = 1000,
              max = 10000,
              value = 2500),
        sliderInput(inputId = "Y_ticks",
              label = "Y-axis ticks:",
              min = 1000,
              max = 50000,
              value = 5000)
    # end of sidebar panel
    ),
    plotOutput(outputId = "Line_graph")),
    
    tabPanel("Smooth spline fit", icon=icon("gavel"),
       sidebarPanel(
        selectInput(inputId = "IQR",
          label = "IQR for filtering outliers: ",
          choices = c(0,0.5,1,1.5,2,2.5,3),
          selected = 1),
       
       selectInput(inputId = "fitNight",
          label = "Fit Night Data: ",
          choices = c("Yes", "No"),
          selected = "Yes"),
       
        sliderInput(inputId = "nknots",
          label = "nknots: ",
              min = 5,
              max = 30,
              value = 8),
       
        sliderInput(inputId = "alpha",
              label = "Alpha:",
              min = 0.0,
              max = 1.0,
              value = 0.2),
        sliderInput(inputId = "X_ticks",
              label = "X-axis ticks:",
              min = 1000,
              max = 10000,
              value = 2500),
        sliderInput(inputId = "Y_ticks",
              label = "Y-axis ticks:",
              min = 1000,
              max = 50000,
              value = 5000)
 
    # end of sidebar panel
    ),
    
   plotOutput(outputId = "smooth.spline_graph")),
   
   # end of the tab panel 2
      tabPanel("Loess fit", icon=icon("gavel"),
       sidebarPanel(
        selectInput(inputId = "IQR",
          label = "IQR for filtering outliers: ",
          choices = c(0,0.5,1,1.5,2,2.5,3),
          selected = 1),
       
       selectInput(inputId = "fitNight",
          label = "Fit Night Data: ",
          choices = c("Yes", "No"),
          selected = "Yes"),
       
        sliderInput(inputId = "span",
          label = "span",
              min = 0,
              max = 1,
              value = 0.25),
       
        sliderInput(inputId = "alpha",
              label = "Alpha:",
              min = 0.0,
              max = 1.0,
              value = 0.2),
        sliderInput(inputId = "X_ticks",
              label = "X-axis ticks:",
              min = 1000,
              max = 10000,
              value = 2500),
        sliderInput(inputId = "Y_ticks",
              label = "Y-axis ticks:",
              min = 1000,
              max = 50000,
              value = 5000)    
       #end of slide bar panel
      ),
      
   plotOutput(outputId = "loess_graph")),
   
   tabPanel("Polynomial regression fit", icon=icon("gavel"),
       sidebarPanel(
        selectInput(inputId = "IQR",
          label = "IQR for filtering outliers: ",
          choices = c(0,0.5,1,1.5,2,2.5,3),
          selected = 1),
       
       selectInput(inputId = "fitNight",
          label = "Fit Night Data: ",
          choices = c("Yes", "No"),
          selected = "Yes"),
       
        sliderInput(inputId = "Degree",
          label = "span",
              min = 1,
              max = 20,
              value = 6),
       
        sliderInput(inputId = "alpha",
              label = "Alpha:",
              min = 0.0,
              max = 1.0,
              value = 0.2),
        sliderInput(inputId = "X_ticks",
              label = "X-axis ticks:",
              min = 1000,
              max = 10000,
              value = 2500),
        sliderInput(inputId = "Y_ticks",
              label = "Y-axis ticks:",
              min = 1000,
              max = 50000,
              value = 5000)    
       #end of slide bar panel
      ),
      
   plotOutput(outputId = "Polynomia_graph"))
    )
  )
    # end of Tab2
),

  tabPanel("Data exploration", icon=icon("laptop"),
    mainPanel(navbarPage(
      ">> Summary <<",
      
      tabPanel("Traits comparisons", icon=icon("keyboard"),
      sidebarPanel(
        selectInput(inputId = "Statistical comparison",
          label = "Statistical comparison type: ",
          choices = c("ANOVA", "T-test", "Wilcoxon", "Kruskal-Wallis"),
          selected = "ANOVA")
      ), 
      plotOutput(outputId = "stats_graph")),
      
      
      tabPanel("Growth rate calculation", icon=icon("calculator"),
       sidebarPanel(
        selectInput(inputId = "Growth calculation format",
          label = "GR type: ",
          choices = c("daily growth rate (DGR)", "growth rate by window (GRW)"),
          selected = "growth rate by window (GRW)"),
      sliderInput(inputId = "WindowSize",
          label = "Sliding Window size: ",
          min = 60,
          max = 600,
          value = 150),
      sliderInput(inputId = "StepSize",
          label = "Step size: ",
          min = 30,
          max = 300,
          value = 60)
      ),
      
      plotOutput(outputId = "GR_graph")),
      
      tabPanel("Stress index", icon=icon("chart-area")
               
     ### add slide bar information    
     )
     
    )
  )
    # end of Tab3
)
# end of App - do not move!
))
