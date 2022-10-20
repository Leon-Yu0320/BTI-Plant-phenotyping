ui <- fluidPage(
  theme = shinytheme("superhero"),
  navbarPage( title = "RasPiPheno App", 
              
              tabPanel("Data Upload", icon=icon("upload"),
                       sidebarPanel(
                         
                         selectizeInput("expType", label="What system did you use to collect data?",
                                        choices = c("PhenoRig", "PhenoCage"), multiple = F),
                         
                         fileInput("csv.raspi",
                                   label="Upload Raspberry Pi derived CSV files here",
                                   multiple = TRUE),
                         
                         uiOutput("timeSTART"),
                         
                         fileInput("csv.meta",
                                   label="Upload the decoding  Meta-data file here",
                                   accept = c('text / csv', '.csv', 'text/comma-separated-values')),
                         
                         checkboxInput("FWCheck", label = "My Meta-data contains collumn with Fresh Weight informatio", value = F),
                         uiOutput("FWColumn"),
                         
                         actionButton("MergeData",icon("file-import"), label = "Merge Data"),
                         
                         h3(strong("About the APP")),
                         strong("RasPiPheno App"), "is developed by Stress Architecture & RNA Biology Lab at the Boyce Thompson Institute, Cornell University.",br(),br(),
                        "The App is a part of high-throughput phenotypic data processing system and it aimed to streamline the downstream phenotypic data collected by
                        customized phenotypic facilities which include", strong("PhenoRig"), "and",strong("PhenoCage")

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
                         tabPanel("Decoded data", icon = icon("wand-magic-sparkles"),
                                  verbatimTextOutput("merged_data_report"),
                                  uiOutput("mergedtable_button"),
                                  dataTableOutput("Data_tabl3")),
                         
                         tabPanel("Vizual Curation", icon=icon("eye"),
                                  fluidRow(
                                  column(6,uiOutput("Choose_alpha")),
                                  column(6,uiOutput("X_tickUI1")), 
                                  column(6,uiOutput("color_original")),
                                  column(6,uiOutput("Y_tickUI1"))),
                                  hr(),
                                  checkboxInput("facet1_check", "facet variables of overall plot"),
                                  uiOutput("facet_wrap1"),
                                  mainPanel(plotlyOutput("graph_over_time")))
                                  ))
                       # end of Tab1
              ),
              
              # # # # # # # # # # # # # # # # TAB 2 # # # # # # # # # # # # # # # # # # # # # # # # 
              tabPanel("Data Smoothing", icon=icon("blender"),
                       sidebarPanel(
                         selectizeInput("smoothType", label = "What kind of smoothing would you like to use?",
                                        choices = c("Smooth Spline Fit", "Loess Fit", "Polynomial Regression Fit"), multiple=F),
                         sliderInput(inputId = "size",
                                     label = "Dot size of data point:",
                                     min = 0.0,
                                     max = 3.0,
                                     step = 0.5,
                                     value = 1.5),

                         
                         selectizeInput(
                           inputId = "outlier",
                           label = "Select the outlier removal cutoff (n * SD): ",
                           choices = c(1, 1.5, 2, 2.5, 3),
                           selected = 1.5),
                         
                         uiOutput("nknotsUI"),
                         uiOutput("spanUI"),
                         uiOutput("degreeUI"),
                         uiOutput("SmoothGo"),
                  
                         h3(strong("Note")),
                         "This App provides smoothing and cleaning option for data processing:",br(),br(),
                         strong("Data smoothing:"),br(),
                         "Using non-linear model to predict phenotypic data (both PhenoRig and PhenoCage).", br(),br(),
                         strong("Data cleaning:"),br(),
                         "Data cleaning: Removing outliers based on fitted model (PhenoRig only)."
                         # end of sidebar panel
                       ),
                       
                       mainPanel(navbarPage(
                         "Smooth",
                         tabPanel("smoothing and cleaning", icon = icon("snowplow"),
                                  fluidRow(
                                    column(6,uiOutput("X_tickUI2"),uiOutput("Choose_smooth_sample")),
                                    column(6,uiOutput("Y_tickUI2"),uiOutput("Drop_smooth_sample"))),
                                  hr(),
                                  verbatimTextOutput("Drop_data_report"),
                                  plotOutput("Smoothed_graph_one_sample")
                         ),
                         tabPanel("smooth data", icon=icon("calculator"),
                                  uiOutput("Smooth_table_button"),
                                  verbatimTextOutput("smooth_table_data_report"),
                                  dataTableOutput("Smooth_table")
                         ),
                         tabPanel("smoothed data graph", icon=icon("cloud-sun"),
                                  fluidRow(
                                    column(6,uiOutput("color_smooth"),
                                           checkboxInput("facet2_check", "facet variables of smooth graph")
                                           ,uiOutput("facet_wrap2")),
                                    column(6,uiOutput("X_tickUI3")),
                                    column(6,uiOutput("Y_tickUI3"))),
                                  hr(),
                                  plotlyOutput("all_smooth_graph"),
                                  uiOutput("Smooth_graph_button")
                         ),
                         tabPanel("clean data", icon=icon("brush"),
                                  uiOutput("Clean_table_button"),
                                  verbatimTextOutput("Clean_table_data_report"),
                                  dataTableOutput("Clean_table")
                         ),
                         tabPanel("cleaned data graph", icon = icon("palette"),
                                  
                                  fluidRow(
                                    column(6,uiOutput("color_clean"),
                                           checkboxInput("facet3_check", "facet variables of clean graph")
                                           ,uiOutput("facet_wrap3")),
                                    column(6,uiOutput("X_tickUI4")),
                                    column(6,uiOutput("Y_tickUI4"))),
                                  hr(),
                                  plotlyOutput("all_clean_graph"),
                                  uiOutput("clean_graph_button"))
                       ))
                       # end of Tab2
              ),              

              
              # # # # # # # # # # # # # # # # TAB 3 # # # # # # # # # # # # # # # # # # # # # # # # 
              
              tabPanel("Growth Rate", icon=icon("seedling"),
                       sidebarPanel(
                         selectizeInput("dataGrowth", label = "What data to use for growth rate calculations?", 
                                        choices = c("Original data", "Smooth data"), multiple = F),
                         selectizeInput("GrowthType", "Growth rate type to be calculated:",
                                        choices=c("Over whole experiment", "Step-wise")),
                         uiOutput("interval"),
                         uiOutput("step"),
                         actionButton("GoGrowth", icon("file-import"),label = "Calculate Growth Rate")
                         # end of sidebar panel
                         ),
                       
                       mainPanel(navbarPage("Plant Growth",
                                            tabPanel("Growth Table",
                                                     uiOutput("Growth_table_button"),
                                                     dataTableOutput("Growth_table")),
                                            tabPanel("Growth Graph",
                                                     fluidRow(
                                                       column(4,uiOutput("Growth_Color_button")),
                                                       column(4, uiOutput("Growth_Xaxis")),
                                                       column(4, checkboxInput("Rtoolow", "Exclude samples with low R2"),
                                                              uiOutput("Rhowlowui"))),
                                                     hr(),
                                                  
                                                     mainPanel(plotOutput(outputId = "Growth_Graph")),
                                                     uiOutput("Growth_graph_button"))
                       ))
                       # end of Tab3
              )
              
              # end of App - do not move!
  ))
