# chess-analysis
A collection of code and queries used to analyze my online chess games

With this project I set out to achieve four goals:
1) Discover how to efficiently pull the data from all of my online chess games (more than 900 total)
2) Use R coding and Google Sheets to process, clean, and organize the data
3) Use SQL to discover insights about my chess games
4) Use Tableau Public to create a visualization of the data and insights

## Pulling the data efficiently
The initial challenge was that chess game data is stored in plaintext .pgn files, which have to be manually downloaded per game from chess.com. However, chess.com offers a developer API to access information about players and games on the platform including a list of a player's monthly archived games and consolidated monthly .pgn files with every game included. Link to the chess.com API overview: https://www.chess.com/news/view/published-data-api

Initially I downloaded a single .pgn file and read it into an R dataframe. I then pulled only relevant data to my analysis from the dataframe. Example:

    -- read pgn file into dataframe
    pgn_df_1 <- read.delim("pgn_1.pgn")

    -- pull relevant fields from complete dataframe (white player, black player, result, white elo, black elo, move list string)
    game_summary_df_1 <- pgn_df_1[c(4,5,6,8,9,13),]

    -- transpose from vertical to horizontal in anticipation of stacking multiple games into a row per game
    -- this also creates generic column names "X1", "X2", etc
    game_summary_df_1 <- data.frame(t(game_summary_df_1))
    
    -- need to name the columns the same before binding multiple dataframes
    colnames(game_summary_df_3) <- c("white_player", "black_player", "result", "white_elo", "black_elo", "moves")

This worked well for a single .pgn file but was impractical for getting the data from more than 900 games. To test the API and JSON tools further, I did a simple pull of my chess.com profile:

    -- simple json data pull
    simple_json_df <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp")

The next step was to figure out how to get the entire archive of my games into a useable format. To start, I used a JSON request to pull the available monthly archives on my profile and parse it out:

    -- get entire list of possible archived pgn games
    archive_list <- jsonlite::fromJSON("https://api.chess.com/pub/player/supercarp/games/archives")
    
    -- above returns a list of 1 that needs to be split; split on the comma
    archive_list <- strsplit(archive_list$archives, ",")
    
    -- get the length of the list (number of available pgn files)
    length(archive_list)
    
    -- print the list to ensure accuracy so far
    for(i in 1:length(archive_list)){print(archive_list[i])}

At this point I had a list of 39 available monthly archives in this format, feel free to click the link to see what the request returns:

[[1]]
[1] "https://api.chess.com/pub/player/supercarp/games/2018/12"

[[1]]
[1] "https://api.chess.com/pub/player/supercarp/games/2019/01"

[[1]]
[1] "https://api.chess.com/pub/player/supercarp/games/2019/02"

The link returns a large plaintext file containing all the .pgn data for that month. //read into dataframe

## Using R and Google Sheets to process, clean, and organize the data
