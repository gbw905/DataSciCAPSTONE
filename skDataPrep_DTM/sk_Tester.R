# clear variables existing in the global environment
rm(list=ls(all=TRUE)); gc() # initialize memory once, at the start of run

# set any runtime options
options( java.parameters = "-Xmx4g"); options(mc.cores=2)

# confirm required libraries are available
require(tm); require(SnowballC); require(stringr); require(cclust)
require(caret); require(plyr); require(dplyr); require(RWeka); require(cluster)

MAIN <- function(){
    
    # Rprof(filename="./log/Rprof.out", line.profiling=T, interval=0.06)
    
    #########################
    ### Variables You Set ###
    #########################
    
    ## Set the following variables to values appropriate for your environment 
    srcDir <- paste('.', "final","en_US",sep="/") # location of source data
    recLimit <- 600                               # max number of test cases
    curDir <- "skDataPrep_DTM"                    # the folder containing this script
    manDir <- "en_US_man"                         # docs to manually classify
    appDir <- "skShiny_DTM"                       # data to be used with the shiny app
    rptDir <- "skReport"                          # data to be used with the RPres reports
    curDir <- "skDataPrep_DTM"                    # the folder containing this script
    trnDir <- "en_US_trn"                         # data to be used for model development
    tstDir <- "en_US_tst"                         # data with which to test the model
    logDir <- "log"                               # data to be used with the shiny app
    
    #~~ Set Environment ~~

    connLog <- paste('.', logDir, 
                     paste("log_", gsub(" |:", "", Sys.time()), 
                           ".txt", sep=""),sep="/")
    putLog(paste("Run started ", Sys.time(), sep=" "),
           file=connLog, append=FALSE, sep = "\n")
    
    #~~ begin testing ~~    
    
    if(file.exists(file=paste("..", appDir, "categoryDF.RData", sep="/")) &
       length(dir(path=paste("..",appDir,sep="/"), pattern="dtm_[0-9]*_[a-z]*.RData"))<1 &
       file.exists(file=paste("..", appDir, "unstemDict.RData",sep="/")))
    {
        step5_testNext-Word(curDir, tstDir, appDir, rptDir, recLimit=0, connLog)
    }
    
    
    putLog(paste("\nRun Ended ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
}


step5_testNext-Word <- function(curDir, tstDir, appDir, rptDir, recLimit=0, connLog){
    
    putLog(paste("\nskPredictTest start ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
    # instantiate the lookup source code used in the shiny app
    source(paste(gsub(curDir,appDir,getwd()), "skNextWord.R",sep="/"))
    
    # initialize counters
    match.attempted.all <- 0
    match.keyFound.all <- 0
    match.nextWordFound.all <- 0
    
    # get test data
    myFileLst <- dir(tstDir, pattern=".txt")
    if(length(myFileLst) < 1){return(FALSE)}
    
    for(f in myFileLst){
        myLines <- as.data.frame(readLines(paste(tstDir, f, sep="/"), warn=F))
        if(nrow(myLines) < 1){break}
        if(nrow(myLines) > recLimit){myLines <- sample(myLines, recLimit)}
        putLog(paste("--> started file: ", f, ", with ", 
                     nrow(myLines), " records at", Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        endPoint <- nrow(myLines)
        for(j in myLines[1:endPoint,1]){
            str <- word2token(as.character(j))
            if(length(str) > 4){
                tstW <- paste(as.character(str[2]),as.character(str[3]))
                tstChk <- paste("^|\\s(",str[4],")\\s|$",sep="")
                predict <- batchNextWord(tstW)
                match.attempted.all <- match.attempted.all + 1
                match.nextWordFound.tmp <- 0
                match.keyFound.tmp <- 0
                if(length(predict)>0) {
                    match.keyFound.all <- match.keyFound.all + 1
                    match.keyFound.tmp <- 1
                    if(any(grepl(tstChk, predict))){
                        match.nextWordFound.all <- match.nextWordFound.all + 1
                        match.nextWordFound.tmp <- 1
                    }
                }
                
                # log the current test
                putLog(paste("    --> tstW= '", as.character(tstW), 
                             "', tstChk= '",as.character(tstChk), 
                             "', NWF=", match.nextWordFound.tmp,  
                             ", KF=", match.keyFound.tmp, sep=""),
                       file=connLog, append=TRUE, sep = "\n")
            }
        }
    }
    
    c4 <- c(match.attempted.all, match.keyFound.all, match.nextWordFound.all, 
            paste(round((match.nextWordFound.all)/(match.keyFound.all) *100, digits=1),"%",sep=""),
            paste(round((match.keyFound.all)/match.attempted.all*100, digits=1), "%", sep=""),
            paste(round((match.nextWordFound.all)/match.attempted.all*100, digits=1), "%", sep=""))
    
    outNames <- c("Attempted", "Keys Found", "Next-Word Found", "% NWF/Keys", "% Keys/Attempted", "% NWF/Attempted")
    skTestResults <- data.frame(All=c4, row.names=outNames)
    save(skTestResults, file=paste("..", rptDir, "skTestResults.RData", sep="/"))
    
    putLog("\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nTest Results...",file=connLog, append=TRUE, sep = "\n")
    putLog(paste("    match.attempted.all           : ", match.attempted.all),file=connLog, append=TRUE, sep = "\n")
    putLog(paste("    match.keyFound.all            : ", match.keyFound.all),file=connLog, append=TRUE, sep = "\n")
    putLog(paste("    match.nextWordFound.all       : ", match.nextWordFound.all),file=connLog, append=TRUE, sep = "\n")
    putLog("\n",file=connLog, append=TRUE, sep = "\n")
    
    putLog(paste("skPredictTest end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
}

#~~ functions called from other functions ~~


