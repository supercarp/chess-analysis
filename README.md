# chess-analysis
A collection of code and queries used to analyze my online chess games

With this project I set out to achieve four goals:
1) Discover how to efficiently pull the data from all of my online chess games (more than 900 total) using R coding
2) Use Google Sheets to process, clean, and organize the data
3) Use SQL to discover insights about my chess games
4) Use Tableau Public to create a visualization of the data and insights

## Pulling the data efficiently using R
The initial challenge was that chess game data is stored in plaintext .pgn files which have to be manually downloaded per game from chess.com. However, chess.com offers a developer API to access information about players and games on the platform including a list of a player's monthly archived games, and consolidated monthly .pgn files with every game included. Link to the chess.com API overview: https://www.chess.com/news/view/published-data-api

Initially I downloaded a single .pgn file and read it into an R dataframe. I then pulled only relevant data to my analysis from the dataframe. Example:

    # read pgn file into dataframe
    pgn_df_1 <- read.delim("pgn_1.pgn")

    # pull relevant fields from complete dataframe (white player, black player, result, white elo, black elo, move list string)
    game_summary_df_1 <- pgn_df_1[c(4,5,6,8,9,13),]

    # transpose from vertical to horizontal in anticipation of stacking multiple games into a row per game
    # this also creates generic column names "X1", "X2", etc
    game_summary_df_1 <- data.frame(t(game_summary_df_1))
    
    # need to name the columns the same before binding multiple dataframes
    colnames(game_summary_df_3) <- c("white_player", "black_player", "result", "white_elo", "black_elo", "moves")

This worked well for a single .pgn file but was impractical for getting the data from more than 900 games. To test the API and JSON tools further, I did a simple pull of my chess.com profile:

    # simple json data pull
    simple_json_df <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp")

The next step was to figure out how to get the entire archive of my games into a useable format. To start, I used a JSON request to pull the available monthly archives on my profile and parse it out:

    # get entire list of possible archived pgn games
    archive_list <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp/games/archives")
    
    # above returns a list of 1 that needs to be split; split on the comma
    archive_list <- strsplit(archive_list$archives, ",")
    
    # get the length of the list (number of available pgn files)
    length(archive_list)
    
    # print the list to ensure accuracy so far
    for(i in 1:length(archive_list)){print(archive_list[i])}

At this point I had a list of 39 available monthly archives with each archive as a URL with a year/month stamp:

    [[1]]
    [1] "https://api.chess.com/pub/player/supercarp/games/2018/12"

    [[1]]
    [1] "https://api.chess.com/pub/player/supercarp/games/2019/01"

    [[1]]
    [1] "https://api.chess.com/pub/player/supercarp/games/2019/02"

The link returns a large plaintext file containing all the .pgn data for that month. The next step was to pull the entirety of all my monthly archives into a single list or order to then extract the .pgn plaintext. The following code accomplishes that:

    # create the list of all pgns using JSON requests
    # uses the character string URLs from archive_list above
    all_pgn_list <- list(0)
    for(i in 1:length(archive_list)){all_pgn_list[i] <- (jsonlite::fromJSON(as.character(archive_list[i])))}

The resulting data in all_pgn_list was a list of length 39, each item in the list containing three dataframes - one unnamed dataframe containing most of the game info (including the .pgn plaintext) as well as one dataframe each for the white and black player:

<img width="762" alt="Screen Shot 2022-07-13 at 10 34 53 AM" src="https://user-images.githubusercontent.com/109003416/178760048-e6eca49c-260f-411e-b5fb-08d0452b308c.png">

To ensure the subsequent code would pull the right list/dataframe item, I ran a few checks:

    all_pgn_list[[1]][[2]] # pulls pgn list from first list item (2018 December games)
    all_pgn_list[[39]][[2]]  # pulls pgn list from last list item (2022 June games)
    write_csv(as.data.frame(all_pgn_list[[1]][[2]]), "write_csv_from_list_test.csv")

I then imported the .csv into Google Sheets and using "split text to columns" on the delimeter "]" I had one game per row:

<img width="852" alt="Screen Shot 2022-07-13 at 10 45 01 AM" src="https://user-images.githubusercontent.com/109003416/178762427-4899b746-5141-4f1a-a513-87dc7d274a4d.png">

Finally, I put it all together:

    # create empty data frame:
    all_pgn_df <- data.frame(list(0))
    # create iterative data frame to fill per loop
    iterate_pgn_df <- data.frame(list(0))
    # name the column to allow rbind in the loop
    colnames(all_pgn_df) <- "PGN List"

    # add the other PGNs
    for(i in 1:length(archive_list)){
        iterate_pgn_df <- as.data.frame(all_pgn_list[[i]][[2]]) # pull the PGN data from each entry
        colnames(iterate_pgn_df) <- "PGN List" # make sure column names match for rbind
        all_pgn_df <- rbind(all_pgn_df, iterate_pgn_df) # stack the new pgn data below the existing
        cat("Added PGN number ", i, "\n") # print the progress
    }
    
    View(all_pgn_df) # confirm results

    write_csv(as.data.frame(all_pgn_df), "all_pgn.csv")

I then imported the .csv file into Google Sheets to begin work on goal #2.

## Use Google Sheets to process, clean, and organize the data

Find/replace
Delete columns
Create new columns - time difference, result reason, game length moves, first four moves, day of the week
IFERROR statements
