# chess-analaysis-r-code.r
# author: brian carpenter
# last updated: july 2022
# posted on github: july 2022, user 'carpocalypto', repository 'chess-analysis'

# basic setup
install.packages("dplyr")
install.packages("here")
install.packages("jsonlite")
install.packages("lubridate")
install.packages("readr")
install.packages("stringr")

library("dplyr")
library("here")
library("jsonlite")
library("lubridate")
library("readr")
library("stringr")

# simple json data pull example; replace 'supercarp' with any chess.com username
simple_json_df <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp")
View(simple_json_df)

# chess.com published API URL: https://www.chess.com/news/view/published-data-api

# ---------- start here for complete project code ----------

# get entire list of possible archived pgn games
archive_list <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp/games/archives")
## returns a list of 1 that needs to be split
archive_list <- strsplit(archive_list$archives, ",")

# get the length of the list (number of available pgn files)
## in my case it is 39
length(archive_list)

# --- test and view the json data
## use an item in the list to get the pgn file with a json request; this pulls the entire monthly pgn
jsonlite::fromJSON(as.character(archive_list[1]))
# --- end test

# print out the archive list to scope the size
for(i in 1:length(archive_list)){print(archive_list[i])}

# create the list of all pgns, starting with an empty list
all_pgn_list <- list(0)

# quick test before final data pull, ensure the number of iterations is correct
all_pgn_list <- for(i in 1:length(archive_list)){all_pgn_list[1] <- cat("Item entry #", i, "\n")}

# pull all pgns into all_pgn_list with JSON request
## use as.character to prevent automatic conversion of some date/time data
for(i in 1:length(archive_list)){all_pgn_list[i] <- (jsonlite::fromJSON(as.character(archive_list[i])))}

# use for confirmation of good data pull
## the code below views only the pgn, which is the 2nd item, [2], in each entry of the list 'all_pgn_list'
all_pgn_list[[1]][[2]] # pulls pgn plaintext [2] from first list item [1] ----(2018 December games)
all_pgn_list[[39]][[2]] # pulls pgn plaintext [2] from last list item [39] ----(2022 June games)

# write the pgn data from the first month into a csv file as a test
## after import into Google Sheets, split text to columns on the ']' delimeter to create one row per game
## confirm imported/delmited data is sufficient for further processing/cleaning
write_csv(as.data.frame(all_pgn_list[[1]][[2]]), "write_csv_from_list_test.csv")


# ----- put it all together -----

# create empty data frame:
all_pgn_df <- data.frame(list(0))
# create iterative data frame to fill per loop
iterate_pgn_df <- data.frame(list(0))
# name the column to allow rbind in the loop
colnames(all_pgn_df) <- "PGN List"

# add the other PGNs
for(i in 1:length(archive_list)){
  iterate_pgn_df <- as.data.frame(all_pgn_list[[i]][[2]]) # pull the PGN data from each entry in the list
  colnames(iterate_pgn_df) <- "PGN List" # make sure column names match for rbind
  all_pgn_df <- rbind(all_pgn_df, iterate_pgn_df) # stack the new pgn data below the existing
  cat("Added PGN number ", i, "\n") # print the progress in the console window
}

# view the results
View(all_pgn_df)

# write the final results to a .csv file
write_csv(as.data.frame(all_pgn_df), "all_pgn.csv")

# end of code