library(shiny)
library(wordcloud)
library(RColorBrewer)
source(paste(getwd(), 'skNextWord.R',sep="/"))

shinyServer(function(input, output) {
    dataInput <- eventReactive(input$getMore, {
        shinyNextWord(input$entry)
    })
    getWord <- eventReactive(input$getMore, {
        if(length(dataInput)>0){
            word <- as.character(dataInput()[1])
        } else {
            word <- "watson"
        }
        return(word)
    })
    
    output$top1 <- renderText({
        paste("Top 1:", input$entry, dataInput()[1])
    })
    output$top2 <- renderText({
        paste("Top 2:", input$entry, dataInput()[2])
    })
    output$top3 <- renderText({
        paste("Top 3:", input$entry, dataInput()[3])
    })
    output$top4 <- renderText({
        paste("Top 4:", input$entry, dataInput()[4])
    })
    output$top5 <- renderText({
        paste("Top 5:", input$entry, dataInput()[5])
    })
    
    output$text <- renderText({
        dataInput()
    })
    output$sent <- renderText({
        input$entry
    })
    output$plot <- renderPlot({
        word <- getWord()
        v <- sort(table(unstemDict$terms), decreasing=T)
        myNames <- names(v)
        k <- which(names(v)==word)
        myNames[k] <- word
        d <- data.frame(word=myNames, freq=v)
        names(d) <- c("word", "freq")
        wordcloud(d[,1], d[,2], scale=c(1.5,1.5),
                  min.freq = 2, max.words=20,rot.per=0.35,
                  colors=brewer.pal(7,"Dark2"), random.color=T)        
    })
    
    
    withProgress(message = 'Loading Data ...', value = NULL, {
        Sys.sleep(0.25)
        dat <- data.frame(x = numeric(0), y = numeric(0))
        withProgress(message = 'App Initializing', detail = "part 0", value = 0, {
            for (i in 1:10) {
                dat <- rbind(dat, data.frame(x = rnorm(1), y = rnorm(1)))
                incProgress(0.1, detail = paste(":", i*10,"%"))
                Sys.sleep(0.5)
            }
        })
        
        # Increment the top-level progress indicator
        incProgress(0.5)
    })
    
})