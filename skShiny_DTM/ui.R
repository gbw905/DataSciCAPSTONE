library(shiny)
require(markdown)
library(wordcloud)

shinyUI(
    navbarPage("Select a tab -->", inverse = FALSE, collapsable = FALSE, 
               tabPanel("Prediction",
                        fluidRow(align="top",
                            sidebarPanel(width=4,style = "background-color: #cfcfcf;",
                                         h4("1- START HERE", style="color:#F80606"),
                                         p("Remember to press the ",code("Go!"), " button.", style="color:#F80606"),
                                         textInput(inputId="entry", 
                                                   label="The app will suggest the next word you may want to type, following the words you type here.",
                                                   value="merry christmas and happy new"),
                                         actionButton(inputId="getMore",label="Go!", icon=icon("ok-sign", lib = "glyphicon")),
                                         br(),
                                         hr(),
                                         h6("The output will be shown to your right... WAIT FOR IT:"),
                                         h6("1. Type text in the input field, click 'Go!'", style="color:#428ee8"),
                                         h6("2. Suggested text appears to the right", style="color:#428ee8"),
                                         h6("3. To view more, click 'Go!' again", style="color:#428ee8"),
                                         hr(),
                                         helpText("Did I remember to tell you to click the ", code("Go!"), "button?"),
                                         hr(),
                                         h6("This App is built for:"),
                                         a("Data Science Capstone (SwiftKey)", href="https://class.coursera.org/dsscapstone-004"),
                                         p("class started on 7-6-2015"),
                                         hr(),
                                         h6("See my LinkedIn profile for more about me..."),
                                         a(img(src = "LinkedIn.png", height = 20, width = 73),href="https://www.linkedin.com/in/gregbwatson"),
                                         br()
                                         ),
                            mainPanel(
                                column(6,
                                       br(),
                                       h4("2- LOOK HERE", style="color:#F80606"),
                                       h5('The text you entered:'),                             
                                       wellPanel(span(h4(textOutput('sent')),style = "color:#428ee8")),
                                       hr(),
                                       h5('The featured next-word:'),
                                       wellPanel(span(h4(textOutput('top1')),style = "color:#e86042")),
                                       hr(),
                                       h5('The next four suggested words:'),
                                       wellPanel(span(h5(textOutput('top2')),style = "color:#2b8c1b"),
                                                 span(h5(textOutput('top3')),style = "color:#2b8c1b"),
                                                 span(h5(textOutput('top4')),style = "color:#2b8c1b"),
                                                 span(h5(textOutput('top5')),style = "color:#2b8c1b")),
                                       hr(),
                                       
                                       p("This app is developed in using shiny. The word prediction model was created in R using text mining tools.")
                                 ),
                                 column(4,style = "background-color: #cfcfcf;",
                                        br(),
                                        h4("3- MORE", style="color:#F80606"),
                                       #img(src="myWordCloud.png"),
                                       plotOutput("plot"),
                                       br(),
                                       p("The above plot is a 'word cloud' built from the words that tend to occur with the 'featured next word'."), 
                                       p("This provides some context as to how the featured-next-word relates to the text you typed."),
                                       br()
                                )
                            )
                        )
               ),
               tabPanel("About this Model",
                        sidebarLayout(
                            sidebarPanel(width=3,style = "background-color: #cfcfcf;",
                                         helpText("At a glance..."),
                                         p(code("MODEL"),": Logic for suggesting a 'next-word'", style="color:#428ee8"),
                                         p(code("STEPS"),": How it works", style="color:#428ee8"),
                                         p(code("CONCEPTS"), ": Definitions", style="color:#428ee8"),
                                         hr(),
                                         helpText("HINT: Read the explanation of 'Probability' on the ", code("Concepts"), " tab."),
                                         helpText("The concept of probability  
                                                  is key to underanding why we are able to predict a next-word, and the next-steps to making 
                                                  predictions better."),
                                         hr(),
                                         h6("This App is built for:"),
                                         a("Data Science Capstone (SwiftKey)", href="https://class.coursera.org/dsscapstone-004"),
                                         p("class started on 7-6-2015"),
                                         hr(),
                                         h6("See my LinkedIn profile for more about me..."),
                                         a(img(src = "LinkedIn.png", height = 20, width = 73),href="https://www.linkedin.com/in/gregbwatson"),
                                         br()
                                         ),
                            mainPanel(
                                tabsetPanel(type="tabs",
                                            tabPanel("MODEL",                                                      
                                                     h3("Principle"),
                                                     p("This app uses two document-term-matrices (see 'concepts' tab for definition). These matrices contain the frequency with which words in the sampled text 
                                                       appear together. One matrix contains the correlations between single words and the other correlation between pairs of
                                                       words. The words selected for presentation appear in the same document as the input words 95+% of the time. There are 
                                                       often more than five words that appear together with the input words. Click 'Go!' for the same string 
                                                       multiple times to see more of the candidate next-words."),
                                                     h4("Choosing datasets from which to build document-term-matrices"),
                                                     p("The population of blog, news feed, and twitter text is both very large and continuously growing. Thus the first step 
                                                       is to develop a method with which to take a sample from a snapshot of the population of blogs, news, and tweets."),
                                                     p("The second step is to partition the selected sample into 'training' and 'test' datasets. I use the 'training' data 
                                                       to develop the model and the 'test' data to estimate the frequency with which the model will predict the word a 
                                                       human being actually wants to use next."),
                                                     h4("Clean the dataset"),
                                                     p("Text taken from the internet contains many characters that are not relevant to predicting the next word that a user 
                                                       wants to type, such as HTML tags, punctuation, and whitespace. Internet text also contains words that have no 
                                                       predictive value, such as common works (e.g. 'I'), jargon specific to one profession, and profanity. I remove these 
                                                       elements from the training and test data sets."),
                                                     h4("Build the model"),
                                                     p("Using the R and the R text mining packages, I developed the two document-term-matrices."),                                                         
                                                     h4("How accurate is the prediction?"),
                                                     p("To test the model, I took the test dataset (data partitioned from the source data and not used to build the model),
                                                       read each line, cleaned the line as I had for the training data, and then checked to see if the model could predict 
                                                       the fourth word in each line from the second and third word."),
                                                     p("More than 80% of the time, the model conatined the search terms. Each time the model contained the search term, the 
                                                       the list of words with a 95+% correlation to the search terms conatined the fourth word from the input test line."),
                                                     p("If the model is so accurate, why are the results when I click 'Go!' so weird?"),
                                                     p("The model is very accurate (returns the correct word), but it is not very precise (returns many words along with 
                                                       the correct word)."),
                                                     p("Three reasons: "),
                                                     p("(1) We are predicting the next word to type, not search terms. We type a sentence 
                                                       like, 'Barack Obama looks older', more often than we search for it. May appear wonky to suggest 'looks' as a word to 
                                                       follow 'Barack Obama', but it is close to what you would actually type."),
                                                     p("(2) I am using the 'sample' function to select five 
                                                       words for display as a placeholder for additional tools such as cluster and sentiment analysis that would be useful 
                                                       in a context that includes all your typing, not with the little input box we have here. "),
                                                     p("(3) This app is a test 
                                                       to confirm that R can process text data in reasonable time, the time to process 
                                                       double the amount of data consumes less than double the amount of processing power (i.e. it scales), and the model 
                                                       produced is reasonably fast and accurate."),
                                                     h4("Will this work in the 'real world'?"),
                                                     p("I ran the model-building R-script with 2%, 4%, 6%, 8%, and 10% of the test data. Processing time increased by about 
                                                       the same amount as data volume (see report for details), and the accuracy of prediction increased as 
                                                       the volume of records increased."),
                                                     p("Conclusion: R will be able to handle the volume of text data I am likely to have 
                                                       going forward, and produce useful results."),
                                                     p("Although I don't recommend anyone use this particular app for predicting the next-word to be typed. I am excited by 
                                                       the ability of R to identify words that occur together. I would like to look further into the R capability for assessing 
                                                       clusters to identify meaning and sentiment."),
                                                     br(),
                                                     br()
                                                     ),
                                            tabPanel("STEPS",                                                       
                                                     h3("Shiny App Prediction Algorithm"),
                                                     p("Here is what the app is doing..."),
                                                     h4("Before applying the DTM model..."),
                                                     p("1. Read the text from the ", code("input box.")),
                                                     p("2. Remove numbers, punctuation, extra spaces, profanity, and stopwords, then convert to lowercase and stem."),
                                                     p("3. Split the cleaned string into an array of words, with each word being a ", code("token.")),
                                                     h4("Search for 'next-word'"),
                                                     p("4. As described in the 'Model' tab, we use a 'backoff' approach, looking first for a matching ", 
                                                       code("Bigram")," then a ", code("single word")," until we have a match and then select a sample of five words to present
                                                       from the list of words with 95+% correlation to the search term.")
                                                     ),
                                            
                                            tabPanel("CONCEPTS",                                                      
                                                     h3("Key Concepts/Terminology"),hr(),
                                                     h4("1. Token"),
                                                     p("A ", code("Token"), " is the smallest unit of text we select for analysis. In the specific case of this app, the smallest
                                                       unit is a 'word'. But in text mining the choice of token depends on the goal of the analysis, and the language, and so is not always a 
                                                       word as it is here."),
                                                     h4("2. Bigram"),
                                                     p(code("Bi")," means 'two'. A 'bigram' is two tokens occuring together. A bigram model lists every pair of tokens that occur together 
                                                       and the frequency with which each pair occurs in the text analyzed."),
                                                     h4("3. Document-Term-Matrix"),
                                                     p("A ", code("Document-term-matrix"), " lists every token as a column-name, and row-name; the cells contain the frequency with which the 
                                                       header and row terms occur together in the same document."),
                                                     h4("5. Frequency"),
                                                     p("The ", code("frequency")," counts the number of times a particular event occurs. In this case, we count the number of times two single tokens, or two pairs 
                                                       of tokens, appear together in the same document."),
                                                     h4("6. Probability"),
                                                     p("A ",a("Markov chain", href="http://en.wikipedia.org/wiki/Markov_chain")," is a sequence of random variables X1, X2, X3,
                                                       ... with the Markov property, namely that, given the present state, the future and past states are independent."),
                                                     p("Once text has been cleaned (stopwords, profanity, punctuation, whitespace, etc., removed, and the words stemmed) words in natural language show the Markov 
                                                       property: one word does not predict the next word -- EXCEPT the writer is trying to express the same idea or sentiment as other writers."),
                                                     p("Thus, we can examine text for exceptions to the Markov property (words the show a higher than random frequency of occuring together) 
                                                       and view each such exception as a representation of an idea or sentiment."),
                                                     p("That is as far as we have taken the Markov concept in this app. Specifically, I have not tried to categorize clusters of related words by the idea or 
                                                       sentiment they represent."),
                                                     p("However, if we assess the context of all of the text a particular user 
                                                       has written, we can weight the prediction set to favour the cluster of ideas that the particular user writes about often. For 
                                                       example, a medical doctor will frequently chose words that express medical diagnoses. We can better predict the doctor's next-word by 
                                                       ranking terms related to medical diagnoses higher in our document-term-matrix."),
                                                     h4("7. Stem"),
                                                     p("The ", code("stem"), " is the root form ('stem') of a word that is independent of its grammatical use. For example the words, 'come', 'coming', 'came' 
                                                       could be represented by the stem 'com'. The intent, together with removing 'stop words' is to separate relationships based on the rules of grammar from groups 
                                                       of words that express a common idea or sentiment."),
                                                     p("Our expectation is that rules of grammar can be applied algorithmically to identify a 'next-word' where the language requires a specific word."),
                                                     h4("8. Stopwords"),
                                                     p("A ", code("stopword"), " is a word so common that it has no value in predicting the next word. Many stop words (such as, 'a', 'an', 'the') can be predicted 
                                                       algorithmically by rules of grammar."),
                                                     p("As a general rule, we do not want to apply statistical methods to predict words that can be predicted by the rules of grammar, because that would cause our 
                                                       model to recommend grammatical errors with about the same frequency as the general population makes grammatical errors (for example, omitting 'a' or 'the')."),
                                                     br(),hr()
                                                     )
                                                     )
                                                     )
                                                     )
                                                     ),
               tabPanel("Bibliography",
                          fluidRow(align="top",
                                       sidebarPanel(width=3,style = "background-color: #cfcfcf;",
                                                    helpText(h6("Geek Alert")),
                                                    p("I have made these notes for my own reference so I can find them at a later date."),
                                                    p("If you feel any of these references will help you, feel free to copy them."),
                                                    hr(),
                                                    h6("This App is built for:"),
                                                    a("Data Science Capstone (SwiftKey)", href="https://class.coursera.org/dsscapstone-004"),
                                                    p("class started on 7-6-2015"),
                                                    hr(),
                                                    h6("See my LinkedIn profile for more about me..."),
                                                    a(img(src = "LinkedIn.png", height = 20, width = 73),href="https://www.linkedin.com/in/gregbwatson"),
                                                    br()
                                                    ),
                                       mainPanel(width=9,
                                                 column(8,
                                                        p("Title: ", a("My Final Report for this Captsone Project",href="http://rpubs.com/gbw905/skReport_FINAL"),", Author: Greg Watson"),
                                                        p("Title: ", a("Basic Test Mining in R", href="http://www.evernote.com/l/ACiUM3394vNETZDV1j6h-6Ghss__kVXh1hE/"),", Author: Anonymous"),
                                                        p("Title: ", a("Text Categorization using N-grams and Hidden-Markov-Models", href="https://www.evernote.com/shard/s40/nl/4447579/86e8d33f-8323-45ed-bcec-571e532b0fcd"), ", Author: Thomas Mathew"),
                                                        p("Title: ", a("N-Gram Language Models", href="https://www.evernote.com/shard/s40/nl/4447579/637fdd0f-dd32-4041-a73c-db13741e219f"), ", Author: Jimmy Lin, The iSchool, University of Maryland"),
                                                        p("Title: ", a("Faster and Smaller N-Gram Language Models", href="https://www.evernote.com/shard/s40/nl/4447579/1713e875-f4a2-42c7-ae1f-7f38b58a4513"), ", Author: Adam Pauls, Dan Klein"),
                                                        p("Title: ", a("Quantifying Memory: Mapping significant textual differences", href="https://www.evernote.com/shard/s40/nl/4447579/d3d0101b-8aa2-463d-aff0-9f17053589c1"), ", Author: Rolf Fredheim"),
                                                        p("Title: ", a("CRAN Task View: Natuarl Language Processing", href="https://www.evernote.com/shard/s40/nl/4447579/add1881f-8d1b-43cd-8b2d-792ed4e9389b"), ", Author: Fridolin Wild, Knowledge Media Institute (KMi), The Open University, UK"),
                                                        p("Title: ", a("Text Mining Infrastructure in R", href="https://www.evernote.com/shard/s40/nl/4447579/5ab95b42-68e4-4b48-a063-80a34d37a77c"), ", Author: Ingo Feiner, Kurt Hornik, David Meyer"),
                                                        p("Title: ", a("Memory usage - Advanced R", href="https://www.evernote.com/shard/s40/nl/4447579/0a3bf961-3e61-4125-a5b6-ac69206aaaa4"), ", Author: Hadley Wickham"),
                                                        p("Title: ", a("DS Capstone Survival Guide", href="https://www.evernote.com/shard/s40/nl/4447579/7d1376c4-e661-429c-97fd-7ac7c610c1ea"), ", Copied from GitHub for class forum"),
                                                        p("Title: ", a("Fig Data: 11 Tips on How to Hangle Big Data in R (and 1 Bad Pun)", href="https://www.evernote.com/shard/s40/nl/4447579/6a4043e6-8521-4a94-8897-344c57ba8a04"), ", Author: Ulrich Atz")
                                                 ),
                                                 column(4,
                                                        h6("Note about Evernote..."),
                                                        p("If you have gone back one of your own bibliographies, you will have noticed that many links that worked when you first submitted your work, return a 404-page-not-found error 
                                                          a year latter."),
                                                        p("For this reason, I have stored all of my reference material in Evernote, and have listed here links to the Evernote notes."),
                                                        p("GitHub can also be used for this purpose. I chose Evernote because I use Evernote to capture my notes as I browse.")
                                                 )
                                       )
                                   )
                          )
               )
               
)
