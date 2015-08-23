rm(list=ls(all=TRUE)); gc()
require(stringr); require(tm);require(plyr); require(dplyr)

# load the dtm prediction models
loadDtm <- function(){
    dtmNames <- sort(dir(path=".", 
                         pattern="dtm_[0-9]*_[a-z]*.RData", full.names=T))
    ldCat<-function(d) {
        dtmNm <- paste("dtm",gsub("./","",gsub(".RData","",gsub("dtm_[0-9]*_","", d))),sep="")
        assign(dtmNm, value=readRDS(d), envir=.GlobalEnv)
        return(dtmNm)
    }
    dtmLst<<-unlist(lapply(dtmNames, ldCat))
    rm(ldCat, dtmNames)
}
loadDtm()

wrkClstDf <- readRDS(paste(gsub("skDataPrep","skShiny",getwd()),
                           'categoryDF.RData',sep="/"),.GlobalEnv)

# load unstem lookup table
unstemDict <- readRDS(paste(gsub("skDataPrep","skShiny",getwd()),
                            'unstemDict.RData',sep="/"),.GlobalEnv)
unstem <- function(x) {
    
    retcode <- stemCompletion(x, 
                              dictionary=unstemDict$terms, 
                              type=c("prevalent"))
    
    if(!is.na(retcode)) {if(nchar(retcode)>0) {return(retcode)}}
    return(x)
}

# load the hash tables 
profanity <- as.data.frame(read.csv(paste('.',"profanity.txt",sep="/")), 
                           stringsAsFactors=F)

trim <- function(x) return(gsub("^ *|(?<= ) | *$", "", x, perl=T))

# convert a string to an array of words
word2token<-function(inWord){
    
    outLst <- c()
    lang <- "english"
    
    require(tm); require(SnowballC)
    
    # Note: The order matters. The list of stopwords and profanity is lowercase
    # Stopwords and stem include the apostrophe as part of the word - the 
    # removepunctuation function removes singe quotes, which are also ascii 
    # apostrophes. Profane words can include characters
    
    # Lowercase
    outLst <- tolower(inWord)
    
    # Remove Common Stop Words
    for(w in stopwords(lang)){
        outLst <- gsub(paste("^|\\s(", w, ")\\s|$", sep=""), " ", outLst)
    }
    
    # Profanity filtering
    for(w in profanity[,1]){
        outLst <- gsub(paste("^|\\s(", as.character(w), ")\\s|$", sep=""), " ", outLst)
    }
    
    # remove unwanted characters, including punctuation, numerals, and html tags
    for (p in c('/','\\|','0x0','<[^>]*>',"@","'s","'nt","'t","'ll","'re","[^[:alpha:][:space:]']")){
        outLst <- gsub(p, " ", outLst)
    }
    
    # Strip Whitespace
    while(grepl("  ", outLst)){
        outLst <- gsub("  "," ", outLst)
    }
    outLst <- trim(outLst)
    
    # convert to vector
    outLst <- unlist(strsplit(outLst, " "))
    
    # stem words (if required)
    outLst <- stemDocument(outLst, lang)
    
    return(outLst)
    
}

getCat <- function(inStr){
    
    if(length(inStr)<1 | 
       (length(inStr)==1 & nchar(inStr[1])<1) | 
       all(is.na(inStr))){return("other")}

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


shinyNextWord <- function(inStr){
    
    luArr <- word2token(inStr)
    
    if(!exists("unstemWt")){unstemWt <<- sum(unstemDict$freq)}
    outArr <- sample(unstemDict$terms, 5, prob=unstemDict$freq/unstemWt)

    tom <- batchNextWord(luArr)
    
    if(length(tom)>0){
        dick <- as.character(
            stemCompletion(tom, dictionary=unstemDict$terms,type=c("first")))
        harry <- data.frame(term=tom, value=dick, stringsAsFactors=F)
        outArr <- apply(harry,1,function(x) ifelse(nchar(x[2])<1 | is.na(x[2]),x[1],x[2]))
        outArr <- as.character(outArr)
    }
    
    return(outArr)
}

batchNextWord <- function(luArr){

    tom <- c()

    category <- getCat(luArr)
    
    luW <- unlist(luArr[length(luArr)])
    
    dtm <- get(paste("dtm", category, sep=""))
    
    tom <- row.names(as.data.frame(findAssocs(dtm, luW, corlimit=0.015)))
    if(length(tom)<1){
        for(dname in dtmLst){
            dtm <- get(dname)
            tom <- row.names(as.data.frame(findAssocs(dtm, luW, corlimit=0.015)))
            if(length(tom)>0) break
        }
    }
    
    return(tom)
    
}
