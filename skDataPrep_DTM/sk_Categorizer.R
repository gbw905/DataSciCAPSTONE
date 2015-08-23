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
    mnCnt <- 250000                               # count of records to categorize
    sampSz <- 0.02                                # % of source data to use 
    curDir <- "skDataPrep_DTM"                    # the folder containing this script
    manDir <- "en_US_man"                         # docs to manually classify
    appDir <- "skShiny_DTM"                       # data to be used with the shiny app
    rptDir <- "skReport"                          # data to be used with the RPres reports
    curDir <- "skDataPrep_DTM"                    # the folder containing this script
    trnDir <- "en_US_trn"                         # data to be used for model development
    tstDir <- "en_US_tst"                         # data with which to test the model
    logDir <- "log"                               # data to be used with the shiny app
    
    ## create the folders specified above if they don't already exist
    dir.create(file.path(paste(".", manDir,sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste(".", logDir, sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste(".", srcDir, sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste("..", appDir,sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste("..", rptDir,sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste(".", trnDir, sep="/")), showWarnings=FALSE)
    dir.create(file.path(paste(".", tstDir, sep="/")), showWarnings=FALSE)
    
    #######################
    ### Set Environment ###
    #######################
    
    connLog <- paste('.', logDir, 
                     paste("log_", gsub(" |:", "", Sys.time()), 
                           ".txt", sep=""),sep="/")
    putLog(paste("Run started ", Sys.time(), sep=" "),
           file=connLog, append=FALSE, sep = "\n")
    
    #~~~ get source data
    
    if(!file.exists(paste(srcDir, "en_US.twitter.txt", sep="/")))
    {
        step0_GetData(srcDir, connLog)
        unlink(dir(path=paste(".",manDir,sep="/"), pattern=".txt"))
        unlink(paste('.', trnDir, 'corpusTrn.RData', sep="/"))
        unlink(paste('.', tstDir, 'corpusTst.RData', sep="/"))
    }
    
    #~~~ prepare source data
    
    if(!file.exists(paste(".", manDir, "wrkCorp.RData", sep="/"))
       | !file.exists(paste('.', trnDir, 'corpusTrn.RData', sep="/"))
       | !file.exists(paste('.', tstDir, 'corpusTst.RData', sep="/"))
       | !file.exists(paste(".", trnDir, "unstemDoc.RData", sep="/")))
    {
        step1_partitionData(srcDir, manDir, trnDir, tstDir, mnCnt, sampSz, connLog)
        unlink(paste("..", appDir, "categoryDF.RData", sep="/"))
        unlink(paste("..", appDir, "unstemDict.RData", sep="/"))
        unlink(dir(path=paste("..", appDir,sep="/"), 
                   pattern="dtm_[0-9]*_[a-z]*.RData", full.names=T))
    } 
    
    #~~~ generate category predictor
    
    if(!file.exists(file=paste("..", appDir, "categoryDF.RData", sep="/")))
    { 
        step2_mkCategoryPredictor(manDir, appDir, connLog)
    }
    
    #~~~ generate next-word-predictor
    
    if(length(dir(path=paste("..",appDir,sep="/"), pattern="dtm_[0-9]*_[a-z]*.RData"))<1)
    {
        step3_mkNextwordPredictor(trnDir, appDir, connLog)
    }
    
    #~~~ generate unstem dictionary
    
    if(!file.exists(file=paste("..", appDir, "unstemDict.RData",sep="/")))
    {
        step4_mkUnstemDict(trnDir, appDir, curDir, connLog)
    }
    
    putLog(paste("\nRun Ended ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
}

#~~ functions called from MAIN (start with 'step') ~~

step0_GetData <- function(srcDir, connLog){
    
    putLog(paste("\nskGetData start ", Sys.time()), file=connLog, append=TRUE, sep = "\n")
    
    ## Download the source files and unzip 
    if(!file.exists(paste(srcDir, "en_US.twitter.txt", sep="/")))
    {    
        srcUrl <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset"
        srcFile <- "Coursera-SwiftKey.zip"
        if(!file.exists(paste('.', srcFile, sep="/")))
        {
            download.file(paste(srcUrl, srcFile, sep="/"), 
                          paste('.', srcFile, sep="/"))
        }        
        unzip(paste(getwd(), srcFile, sep="/"), exdir=getwd(), overwrite=TRUE)
    }
    
    putLog(paste("skGetData end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
}    


step1_partitionData <- function(srcDir, manDir, trnDir, tstDir, mnCnt, sampSz, connLog){
    
    putLog(paste("\nstep-1 start ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
    #~~ read source data ~~
    connTwit <- file(paste(srcDir, "en_US.twitter.txt", sep="/"), 
                     open="r", blocking=TRUE, raw=FALSE)
    connBlog <- file(paste(srcDir, "en_US.blogs.txt", sep="/"), 
                     open="r", blocking=TRUE, raw=FALSE)
    connNews <- file(paste(srcDir, "en_US.news.txt", sep="/"), 
                     open="r", blocking=TRUE, raw=FALSE)
    inTwit <- readLines(con=connTwit, encoding="UTF-8")
    inBlog <- readLines(con=connBlog, encoding="UTF-8")
    inNews <- readLines(con=connNews, encoding="UTF-8")
    close(connTwit); close(connBlog); close(connNews)
    
    inAll <- c(unlist(inNews), unlist(inBlog), unlist(inTwit))
    
    #~~ write categorizer data ~~
    set.seed(42)
    inSampAll <- sample(c(1:length(inAll)),mnCnt)
    wrkTxt <- cleanTxt(as.character(inAll[inSampAll]),connLog)
    wrkCorp <- cleanCorpus(VCorpus(VectorSource(wrkTxt)), connLog)
    saveRDS(wrkCorp, file=paste(".", manDir, "wrkCorp.RData", sep="/"))
    
    restAll <- as.character(inAll[-inSampAll])
    rm(inAll, inSampAll, wrkTxt, wrkCorp)
    
    #~~ select data for rest of work ~~
    inSampAll <- createDataPartition(y=c(1:length(restAll)),
                                     times=1, p=sampSz, list=FALSE)
    work <- cleanTxt(as.character(restAll[inSampAll]), connLog)
    rm(inSampAll, restAll)
    saveRDS(VCorpus(VectorSource(work)), 
            file=paste(".", trnDir, "unstemDoc.RData", sep="/") )
    
    inTrn <- createDataPartition(y=c(1:length(work)), 
                                    times=1, p=0.05, list=FALSE)
    corpusTrn <- cleanCorpus(VCorpus(VectorSource(work[-inTrn])), connLog)
    saveRDS(corpusTrn, file=paste('.', trnDir, 'corpusTrn.RData', sep="/"))
    
    corpusTst <- cleanCorpus(VCorpus(VectorSource(work[inTrn])), connLog)
    saveRDS(corpusTst, file=paste('.', tstDir, 'corpusTst.RData', sep="/"))
    rm(work, inTrn, corpusTrn, corpusTst)
    
    putLog(paste("step-1 end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
}  

step2_mkCategoryPredictor <- function(manDir, appDir, connLog){
    
    putLog(paste("\nstep-2 start ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
    if(!file.exists(paste(".", manDir, "wrkTdm.RData",sep="/"))){
        putLog(paste("--> build wrkTdm.RData ", Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        wrkCorp <- readRDS(paste(".", manDir, "wrkCorp.RData", sep="/"))
        wrkTdm <- TermDocumentMatrix(wrkCorp, control=list(weighting=weightTf,
                                                           minWordLength=3,
                                                           minDocFreq=1))
        wrkTdm <- removeSparseTerms(wrkTdm, 0.99)
        #         wrkTdm <- rollup(wrkTdm, 2, na.rm=T, FUN=sum)
        saveRDS(wrkTdm, file=paste(".", manDir, "wrkTdm.RData",sep="/"))
        rm(wrkCorp, wrkTdm)
    }
    
    if(!file.exists(paste(".", manDir, "wrkClst.RData",sep="/"))
       |!file.exists(paste(".", manDir, "wrkDf.RData", sep="/"))){
        putLog(paste("--> build wrkClst.RData ", Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        wrkTdm <- readRDS(paste(".", manDir, "wrkTdm.RData",sep="/"))
        wrkDf <- as.data.frame(inspect(wrkTdm), stringsAsFactors=F)
        wrkDf[is.na(wrkDf)]<-0
        hc<-hclust(dist(wrkDf))
        wrkClst <- cclust(as.matrix(wrkTdm), centers=length(hc$labels))
        saveRDS(wrkClst, file=paste(".", manDir, "wrkClst.RData",sep="/"))
        saveRDS(wrkDf, file=paste(".", manDir, "wrkDf.RData", sep="/"))
        rm(wrkTdm, wrkClst, hc)
    }
    
    if(!file.exists(paste("..", appDir, "categoryDF.RData", sep="/"))){
        putLog(paste("--> build categoryDF.RData ", Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        wrkClst <- readRDS(paste(".", manDir, "wrkClst.RData",sep="/"))
        wrkDf <- readRDS(paste(".", manDir, "wrkDf.RData", sep="/"))
        wrk.centers <- as.matrix(wrkClst$centers)
        wrk.centers.names <- row.names(wrk.centers)
        wrk.clusters <- data.frame(
            terms=character(0),
            prob=double(0),
            category=character(0), 
            stringsAsFactors=F)
        names(wrk.clusters) <- c("terms","prob","category")
        for(r in 1:nrow(wrkClst$centers)){
            work.tmp <- wrkDf[,as.numeric(
                row.names(as.data.frame(
                    wrk.centers[r,wrk.centers[r,1:length(wrk.centers.names)]>0]))
                )]
            work.prob <- unlist(
                apply(work.tmp, 1, function(x) sum(x[1:ncol(work.tmp)])))
            work.end <- data.frame(
                terms=row.names(work.tmp), 
                prob=as.numeric(work.prob), 
                category=rep(wrk.centers.names[r], nrow(work.tmp)))
            names(work.end) <- c("terms","prob","category")
            wrk.clusters <- rbind(wrk.clusters, work.end)
        }
        wrk.clusters[is.na(wrk.clusters)] <- 0
        wrk.clusters <- wrk.clusters[wrk.clusters$prob!=0,]
        saveRDS(wrk.clusters, file=paste("..", appDir, "categoryDF.RData", sep="/"))
        rm(wrkClst, wrkDf, wrk.centers, wrk.centers.names, wrk.clusters, 
           work.tmp, work.prob,work.end)
    }
    
    putLog(paste("step-2 end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
}

step3_mkNextwordPredictor <- function(trnDir, appDir, connLog){
    
    putLog(paste("\nstep-3 start ", Sys.time()),
           file=connLog, append=TRUE, sep = "\n")
    
    putLog(paste('--> a. Load files ', Sys.time()),
           file=connLog, append=TRUE, sep = "\n")

    docs <- readRDS(paste('.', trnDir, 'corpusTrn.RData', sep="/"))
    docsArr <- unlist(
        lapply(docs$content, function(x) if(nchar(x$content)>0) x$content), 
        use.names=F)
    
    putLog(paste('--> b. apply categories to training data ', Sys.time()),
           file=connLog, append=TRUE, sep = "\n")
    docs2CatMap <- unlist(
        lapply(docsArr, 
               function(x) getCat(unlist(strsplit(as.character(x), " ")))), 
        use.names=F)
    catLst <- sort(unique(docs2CatMap))
    rm(docs)

    putLog(paste('--> c. Remove any existing dtm files ', Sys.time()),
       file=connLog, append=TRUE, sep = "\n")
    unlink(dir(path=trnDir, 
               pattern=paste("dtm_[0-9]*_[a-z]*.RData",sep=""), 
               full.name=T))

    putLog(paste('--> d. dtm file creation ', Sys.time()),
           file=connLog, append=TRUE, sep = "\n")
    dtmCnt <- 0
    for(c in catLst){
        
        putLog(paste('----> d.1 extract text for ',c, Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        docsCat <- docsArr[unlist(grep(c, docs2CatMap))]
        
        putLog(paste('----> d.2 create dtm for ',c, Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        dtmDocs <- DocumentTermMatrix(VCorpus(VectorSource(docsCat)), 
                                      control=list(weighting=weightTf, 
                                                   minWordLength=3,
                                                   minDocFreq=1))
        dtmDocs <- removeSparseTerms(dtmDocs, 0.99) 
        rm(docsCat)
        
        putLog(paste('----> d.3 save dtm_',c, Sys.time()),
               file=connLog, append=TRUE, sep = "\n")
        
        dtmCnt <- dtmCnt + 1
        
        saveRDS(dtmDocs, 
                file=paste('..',appDir,
                           paste('dtm_', dtmCnt, '_', c, '.RData',sep=""),sep="/"))        
    }
    rm(catLst, docsArr, docs2CatMap)
    putLog(paste('--> e. dtm file creation complete ', Sys.time()),
       file=connLog, append=TRUE, sep = "\n")
    
    putLog(paste("step3 end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
}

step4_mkUnstemDict <- function(inDir, outDir, curDir, connLog){
    
    putLog(paste("\nstep-4 start ", Sys.time()),
           file=connLog, append=TRUE, sep = "\n")

    require(RWeka); require(tm)
    
    docs <- readRDS(paste(".", inDir, "unstemDoc.RData", sep="/"))
    docsArr <- unlist(
        lapply(docs$content, function(x) if(nchar(x$content)>0) x$content), 
        use.names=F)
    work<-unlist(lapply(docsArr, function(x) unlist(strsplit(x," "))))
    work.freq<-table(work)
    outDF <- data.frame(terms=gsub("[^a-z]","",row.names(work.freq)), 
                             freq=as.data.frame(work.freq, 
                                                stringsAsFactors = F)[,2], 
                             stringsAsFactors = F)
    outDF<-outDF[outDF$terms!="",]
    outDF<-arrange(outDF, desc(freq))
    
    saveRDS(outDF, paste("..", outDir, "unstemDict.RData",sep="/"))
        
    putLog(paste("step-4 end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
}

##~~ functions called by steps ~~

# Remove characters that cause problems when processing the file
# the input, docs, is a charcter vector
cleanTxt<-function(docs, connLog) {
    
    lang <- 'english'
    
    putLog(paste("\ncleanTxt start ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
    # Formulaic Transformation
    putLog(paste('--> a. Convert problem characters to whitespace ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    for (i in c('/','\\|','0x0','<[^>]*>',"@","'s","'nt","'ll","'re","'t","[^[:alpha:][:space:]']")){
        docs <- gsub(i, " ", docs)
    }
    
    # Lowercase
    putLog(paste('--> b. Convert to lowercase ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tolower(docs)
    
    # Strip Whitespace
    putLog(paste('--> c. Strip Whitespace ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    while(any(grepl("  ", docs))){
        docs <- gsub("  "," ", docs)
    }
    docs <- gsub("^ *|(?<= ) | *$", "", docs, perl=T)
    
    # Complete messages
    putLog(paste("cleanTxt end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    
    return(docs)
    
}

# Remove terms that have no benefit to processing a corpus
# the input, docs, is a corpus, output is a corpus
cleanCorpus<-function(docs, connLog) {
    
    lang <- 'english'
    
    require(tm); require(SnowballC)
    putLog(paste("\ncleanCorpus start ", Sys.time()),file=connLog, append=TRUE, sep = "\n")    
    
    # Remove Common Stop Words - handled by tdm 
    putLog(paste('--> a. Remove Common Stop Words ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, removeWords, stopwords(lang))
    
    # Profanity filtering
    if(!exists("profanity")){profanity <<- as.data.frame(read.csv(paste('.',"profanity.txt",sep="/")), stringsAsFactors=F)}
    putLog(paste('--> b. Remove Profanity/Jargon ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, removeWords, as.character(profanity))
    
    # stem words (if required) - handled by tdm
    putLog(paste('--> c. stem words= ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, stemDocument, lang)
    
    # Remove Punctuation
    putLog(paste('--> d. Remove punctuation ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, removePunctuation)
    
    # Remove Numbers - handled by tdm
    putLog(paste('--> e. Remove Numbers ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, removeNumbers)
    
    # Strip Whitespace
    putLog(paste('--> f. Strip Whitespace ', Sys.time()),file=connLog, append=TRUE, sep = "\n")
    docs <- tm_map(docs, stripWhitespace)
    docs <- tm_map(docs, content_transformer(trim))
    
    # Complete messages
    putLog(paste("cleanCorpus end ", Sys.time()),file=connLog, append=TRUE, sep = "\n")
    return(docs)
}

getCat <- function(inStr){
    
    if(length(inStr)<1 | 
       (length(inStr)==1 & nchar(inStr[1])<1) | 
       is.na(inStr)){return("other")}
    
    if(!exists("categoryDF")){    
        categoryDF <<- readRDS(paste("../skShiny_DTM/categoryDF.RData", sep="/"))
    }
    
    outCat <- as.character(
        arrange(
            ddply(
                categoryDF[
                    unique(
                        unlist(
                            lapply(inStr, 
                                   function(x) 
                                       if(nchar(as.character(x))>0 & !is.na(x)) 
                                           grep(as.character(x), categoryDF[, 1]))
                        )
                        ,use.names=F),
                    ], 
                .(category), summarise, prob=sum(prob)), 
            desc(prob))
        [1,1])
    
    if(nchar(outCat)<1 | is.na(outCat)){outCat <- "other"}
    
    return(outCat)
}

# define helper functions
trim <- function(x) return(gsub("^ *|(?<= ) | *$", "", x, perl=T))

putLog<-function(input, file, append, sep){
    unlink("./temp.log", force=T)
    if(!append){unlink(file, force=T)}
    cat(paste(input,sep,sep=""), file="./temp.log", append=FALSE, sep="")
    file.append(file, "./temp.log")
    unlink("./temp.log", force=T)
}
