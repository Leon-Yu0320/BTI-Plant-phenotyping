ui <- fluidPage(
  theme = shinytheme("superhero"),
  navbarPage( title = "RasPiPheno App", 
              
              tabPanel("Data Upload", icon=icon("upload"),
                       mainPanel(navbarPage(
                         ">> Data <<",
                         tabPanel("Raspberry Pi data", icon = icon("flask"),
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
                                    
                                    checkboxInput("FWCheck", label = "My Meta-data contains collumn with Fresh Weight information", value = F),
                                    uiOutput("FWColumn"),
                                    
                                    actionButton("MergeData", icon("file-import"),label = "Merge Data")
                                    # end of sidebar panel
                                  ),
                                  verbatimTextOutput("uploaded_RasPi_data_report"),
                                  column(6,dataTableOutput("Data_tabl1"))),
                         
                         tabPanel("Meta data", icon = icon("ruler"),
                                  verbatimTextOutput("uploaded_metadata_report"),
                                  dataTableOutput("Data_tabl2")),
                         tabPanel("Decoded data", icon = icon("wand-magic-sparkles"),
                                  verbatimTextOutput("merged_data_report"),
                                  uiOutput("mergedtable_button"),
                                  dataTableOutput("Data_tabl3")),
                         
                         tabPanel("Vizual Curation", icon=icon("eye"),
                                  sidebarPanel(
                                    selectizeInput("expType", label="What system did you use to collect data?",
                                                   choices = c("PhenoRig", "PhenoCage"), multiple = F),
                                    sliderInput(inputId = "alpha",
                                                label = "Transparency of data point to be displayed:",
                                                min = 0.0,
                                                max = 1,
                                                step = 0.1,
                                                value = 0.2),
                                    sliderInput(inputId = "alpha_region",
                                                label = "Transparency of statitics summary to be displayed:",
                                                min = 0.0,
                                                max = 1,
                                                step = 0.1,
                                                value = 0.5),
                                    selectInput(inputId = "geom_method",
                                                label = "Displaying standard error:",
                                                choices = c("errorbar", "ribbon", "line", "point"),
                                                selected = "ribbon"),
                                    
                                    uiOutput("minX_tickUI"),
                                    uiOutput("minY_tickUI"),
                                    uiOutput("dayX_tickUI"),
                                    uiOutput("dayY_tickUI"),
                                    uiOutput("color_original")),
                                  mainPanel(plotlyOutput("graph_over_time", width = "100%", height = "500px")))
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
                         selectInput(inputId = "level",
                                     label = "Level of confidence interval to use: ",
                                     choices = c(0.9, 0.95, 0.975),
                                     selected = 0.95),
                         uiOutput("nknotsUI"),
                         uiOutput("spanUI"),
                         uiOutput("degreeUI"),
                         
                         uiOutput("min_X_tickUI"),
                         uiOutput("min_Y_tickUI"),
                         uiOutput("day_X_tickUI"),
                         uiOutput("day_Y_tickUI"),
                         
                         uiOutput("Outlier_removal"),
                         uiOutput("Outlier_range"),

                         actionButton("SmoothGo", icon("file-import"),label = "Smooth all samples")
                       ),
                       mainPanel(navbarPage(
                         "Smooth",
                         tabPanel("smooth design", icon = icon("snowplow"),
                                  uiOutput("Choose_smooth_sample"),
                                  uiOutput("Drop_smooth_sample"),
                                  #uiOutput("Drop_action"),
                                  verbatimTextOutput("Drop_data_report"),
                                  plotOutput("Smoothed_graph_one_sample")),
                         tabPanel("smooth data", icon=icon("calculator"),
                                  uiOutput("Smooth_table_button"),
                                  verbatimTextOutput("smooth_table_data_report"),
                                  dataTableOutput("Smooth_table")),
                         tabPanel("smooth graph", icon=icon("cloud-sun"),
                                  uiOutput("color_smooth"),
                                  plotlyOutput("all_smooth_graph"),
                                  uiOutput("Smooth_graph_button")),
                         mainPanel(plotOutput(outputId = "Smooth_plot_one",width = "100%", height = "500px")))
                       )
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
                         actionButton("GoGrowth", icon("file-import"),label = "Calculate Growth Rate")),
                       
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
                                                  
                                                     mainPanel(plotOutput(outputId = "Growth_Graph",width = "100%", height = "500px")),
                                                     uiOutput("Growth_graph_button"))
                       ))
                       # end of Tab3
              )
              
              # end of App - do not move!
  ))
