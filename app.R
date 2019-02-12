#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(here)
library(shiny)
library(shinydashboard)
library(rredlist)
library(dplyr)
library(readr)
library(stringr)
library(purrr)

source(here("config.R"))

header <- dashboardHeader(title="RedListGetter")
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Choose something to do:"),
    menuItem("Get the species details", tabName="details", icon=icon("tree")),
    menuItem("Look up assesment histories", tabName="history", icon=icon("book"))
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(
      tabName="details",
      h3("Species details - ",
         tags$a("get some species details", 
                href="http://apiv3.iucnredlist.org/api/v3/docs#species-individual-name")),
      fluidRow(
        column(
          width=3,
          box(title="List of species to get",
              width=NULL, collapsible=FALSE,
              tags$form(
                tags$textarea(id="species", rows=8, cols=50,
                              "Cola letouzeyana\n")
              ),
              tags$br(),
              submitButton(text="REQUEST SPECIES!"))
        ),
        column(
          width=9,
          box(title="Returned data",
              width=NULL,
              p("results from the IUCN Red List"),
              DT::dataTableOutput(outputId="details"),
              downloadButton("downloadDetails", "DOWNLOAD!"))
        )
      )
    ),
    tabItem(
      tabName="history",
      h3("Assessment histories - ",
         tags$a("look up the assessment history of species", 
                href="http://apiv3.iucnredlist.org/api/v3/docs#species-history-name")),
      fluidRow(
        column(
          width=3,
          box(title="List of species to look up history for",
              width=NULL, collapsible=FALSE,
              tags$form(
                tags$textarea(id="histories", rows=8, cols=50,
                              "Cola letouzeyana\n")
              ),
              tags$br(),
              submitButton(text="REQUEST HISTORY!"))
        ),
        column(
          width=9,
          box(title="Returned assessment histories",
              width=NULL,
              p("results from the IUCN Red List"),
              DT::dataTableOutput(outputId="histories"),
              downloadButton("downloadHistories", "DOWNLOAD!"))
        )
      )
    )
  )
)

ui <- dashboardPage(skin="blue", header, sidebar, body)

# Define server logic required to draw a histogram
server <- function(input, output) {
  redlist_results <- reactive({
    input_species <- str_trim(input$species)
    input_species <- str_split(input_species, "\n")
    input_species <- input_species[[1]][input_species != ""]
  
    species_details <- map_dfr(input_species, ~rl_search(.x, key=TOKEN)$result)
    unfound_species <- input_species[! input_species %in% species_details$scientific_name]
    
    first_columns <- c("taxonid", "scientific_name", "category", "criteria", "assessor", "assessment_date")
    other_columns <- colnames(species_details)
    other_columns <- other_columns[! other_columns %in% first_columns]
    species_details <- select(species_details, one_of(first_columns), one_of(other_columns))
    
    output$downloadCSV <- downloadHandler(
      filename="redlist_results.csv",
      content = function(file=filename) {
        write_csv(species_details, file, na="")
      }
    )
    
    species_details
  })
  
  output$details <- DT::renderDataTable(redlist_results(),
                                         extensions=c("Responsive", "ColReorder"),
                                         options=list(dom="Rlfrtip", deferRender=TRUE),
                                         escape=1)
  
  get_histories <- reactive({
    input_species <- str_trim(input$histories)
    input_species <- str_split(input_species, "\n")
    input_species <- input_species[[1]][input_species != ""]
    
    species_details <- map_dfr(input_species, ~rl_history(.x, key=TOKEN)$result %>% mutate(scientific_name=.x))
    unfound_species <- input_species[! input_species %in% species_details$scientific_name]
    
    first_columns <- c("scientific_name", "year", "code", "category")
    other_columns <- colnames(species_details)
    other_columns <- other_columns[! other_columns %in% first_columns]
    species_details <- select(species_details, one_of(first_columns), one_of(other_columns))
    
    output$downloadHistories <- downloadHandler(
      filename="redlist_assessment_histories.csv",
      content = function(file=filename) {
        write_csv(species_details, file, na="")
      }
    )
    
    species_details
  })
  
  output$histories <- DT::renderDataTable(get_histories(),
                                         extensions=c("Responsive", "ColReorder"),
                                         options=list(dom="Rlfrtip", deferRender=TRUE),
                                         escape=1)
}


# Run the application 
shinyApp(ui = ui, server = server)

