# chess-analysis
##### *A collection of code and queries used to analyze my online chess games*

With this project I set out to achieve four goals:
1) Discover how to efficiently pull the data from all of my online chess games (more than 900 total) using R coding
2) Use Google Sheets to process, clean, and organize the data
3) Use SQL to discover insights about my chess games
4) Use Tableau Public to create a visualization of the data and insights

## Pulling the data efficiently using R
The initial challenge was that chess game data is stored in plaintext .pgn files which have to be manually downloaded per game from chess.com. However, chess.com offers a developer API to access information about players and games on the platform including a list of a player's monthly archived games, and consolidated monthly .pgn files with every game included.

The chess.com API overview can be found here: https://www.chess.com/news/view/published-data-api

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

The next step was to figure out how to get the entire archive of my games into a useable format. To start, I used a JSON request to pull the available monthly archives from my chess.com profile and parse it out:

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

The link returns a large plaintext file containing all the .pgn data for that month. The next step was to pull the entirety of all my monthly archives into a single list to then extract the .pgn plaintext. The following code accomplishes that:

    # create the list of all pgns using JSON requests
    # uses the character string URLs from archive_list above
    all_pgn_list <- list(0)
    for(i in 1:length(archive_list)){all_pgn_list[i] <- (jsonlite::fromJSON(as.character(archive_list[i])))}

The resulting data in all_pgn_list was a list of length 39, each item in the list containing three dataframes - one unnamed dataframe containing most of the game info (including the .pgn plaintext) as well as one dataframe each for the white and black player:

<img width="762" alt="dataframe" src="https://user-images.githubusercontent.com/109003416/178760048-e6eca49c-260f-411e-b5fb-08d0452b308c.png">

To ensure the subsequent code would pull the right list/dataframe item, I ran a few checks:

    all_pgn_list[[1]][[2]] # pulls pgn list from first list item (2018 December games)
    all_pgn_list[[39]][[2]]  # pulls pgn list from last list item (2022 June games)
    write_csv(as.data.frame(all_pgn_list[[1]][[2]]), "write_csv_from_list_test.csv")

I then imported the .csv into Google Sheets and using "split text to columns" on the delimeter "]" I had one game per row:

<img width="852" alt="Google Sheets" src="https://user-images.githubusercontent.com/109003416/178762427-4899b746-5141-4f1a-a513-87dc7d274a4d.png">

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

## Use Google Sheets to process, clean, and initially analyze the data

I did the initial data cleaning with a series of Find & Replace actions, replacing unneeded information with blank spaces. I then deleted several columns that weren't relevant such as Round, Timezone, and the URL of the individual game.

I soon realized I would need to create several new columns. For instance, the data for the 10th move of a game looked like this:

    10. Nd2 {[%clk 0:15:20]} 10... h6 {[%clk 0:13:27.1]}

Parsed out, the information contained is:
    
    10. = indicates start of the 10th move
    Nd2 = white's move
    {[clk 0:15:20]} = white's remaining time on the clock
    10... indicates black's turn on move 10
    h6 = black's move
    {[clk 0:13:27.1]} = black's remaining time on the clock, note that tenths of a second are included
    
My time management in games is one area I specifically wanted to look at, so I created columns extracting the time data for each player using formulas:

    =IFERROR(IF(AA2>10, RIGHT(AW2, 7)-RIGHT(AX2, 7), "Game Ended"), "Game Ended")

Generically:

    =IFERROR(IF(game_number_of_moves>10, RIGHT(white_move_10, 7)-RIGHT(black_move_10, 7), "Game Ended"), "Game Ended")    
    
This allowed me to format the result as a 'Duration' with an easy indicator of how the game was going - a positive duration indicates white has more time remaining, a negative duration indicates black has more.

Other new columns I created included the game length by number of moves, the day of the week of the game, and a result reason (i.e. 1-0 indicates white won, but was it through checkmate, resignation, time expiring, abandonment, or disconnect?).

Of particular interest was the sequence of the first four moves of the game, which I thought might provide insight on how I perform with various openings. I used regular expressions to extract only the first four moves in a simple format:

    =IFERROR(CONCATENATE(REGEXEXTRACT(white_move_1,".+? (.+?) ")," ",REGEXEXTRACT(black_move_1,".+? (.+?) ")," ",REGEXEXTRACT(white_move_2,".+? (.+?) ")," ",REGEXEXTRACT(black_move_2,".+? (.+?) ")),)
    # this returns:
    e4 e5 Nf3 Nf6

At this point I had enough actionable data to query and aggregate with SQL.

## Use SQL to discover insights about my chess games

I began to query the data, starting with my performance by day of the week:

    SELECT
        game_day_of_week,
        COUNT(*) AS game_count,
        SUM(IF(white_player = "SuperCarp" AND result = "1-0" OR black_player = "SuperCarp" AND result = "0-1", 1, 0)) AS win_count,
        SUM(IF(white_player = "SuperCarp" AND result = "0-1" OR black_player = "SuperCarp" AND result = "1-0", 1, 0)) AS loss_count,
        SUM(IF(result = "draw", 1, 0)) as draw_count,
        ROUND(SUM(IF(white_player = "SuperCarp" AND result = "1-0" OR black_player = "SuperCarp" AND result = "0-1", 1, 0))/COUNT(*)*100,1) AS win_pct,
        ROUND(SUM(IF(white_player = "SuperCarp" AND result = "0-1" OR black_player = "SuperCarp" AND result = "1-0", 1, 0))/COUNT(*)*100,1) AS loss_pct,
        ROUND(SUM(IF(result = "draw", 1, 0))/COUNT(*)*100,1) AS draw_pct,
    FROM `database.chess_dataset.complete_game_data`
        GROUP BY game_day_of_week
    ORDER BY
      (CASE WHEN game_day_of_week = "Monday" THEN 1
      WHEN game_day_of_week = "Tuesday" THEN 2
      WHEN game_day_of_week = "Wednesday" THEN 3
      WHEN game_day_of_week = "Thursday" THEN 4
      WHEN game_day_of_week = "Friday" THEN 5
      WHEN game_day_of_week = "Saturday" THEN 6
      ELSE 7
      END)
 
 And the result:
 
 <img width="730" alt="Day of the Week" src="https://user-images.githubusercontent.com/109003416/178789742-1bf4fede-2e41-4381-82f4-a56dcd7b8391.png">

Without going into too much detail here, from this type of query I was able to gain insights such as strong performances Tuesday - Friday but with a significant drop on Thursday. I expected my weekend performance to be good but Saturday and Sunday had high loss percentages.

The query below proved that time management was a substantial problem in most of my games:

    SELECT
    COUNT(*) as total_games,
    -- time differences for move 10
     SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) = "-", 1, 0)) AS positive_time_diff_move_ten,
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) != "-", 1, 0)) AS negative_time_diff_move_ten,
    -- percentage for move 10
     ROUND(SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) != "-", 1, 0)) / 
    (SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) = "-", 1, 0)) +
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_ten,1) != "-", 1, 0)))*100,1)
    AS move_ten_negative_time_pct,
    --
    -- time differences for move 15
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) = "-", 1, 0)) AS positive_time_diff_move_fifteen,
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) != "-", 1, 0)) AS negative_time_diff_move_fifteen,
    -- percentage for move 15
    ROUND(SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) != "-", 1, 0)) / 
    (SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) = "-", 1, 0)) +
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_fifteen,1) != "-", 1, 0)))*100,1)
    AS move_fifteen_negative_time_pct,  
    --
    -- time differences for move 20
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) = "-", 1, 0)) AS positive_time_diff_move_twenty,
     SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) != "-", 1, 0)) AS negative_time_diff_move_twenty,
    -- percentage for move 20
    ROUND(SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) != "-", 1, 0)) / 
    (SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) = "-", 1, 0)) +
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_twenty,1) != "-", 1, 0)))*100,1)
    AS move_twenty_negative_time_pct,  
    --
    -- time differences for move 30
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) = "-", 1, 0)) AS positive_time_diff_move_thirty,
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) != "-", 1, 0)) AS negative_time_diff_move_thirty,
    -- percentage for move 30
    ROUND(SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) != "-", 1, 0)) / 
    (SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) != "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) = "-", 1, 0)) +
    SUM(IF(white_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) = "-" OR black_player = "SuperCarp" AND LEFT(time_diff_move_thirty,1) != "-", 1, 0)))*100,1)
    AS move_thirty_negative_time_pct,
    --
    FROM `database.chess_dataset.complete_game_data`
    
The results show that I am behind on the clock by move 10 in most of my games and I never recover:

<img width="718" alt="Time Differences" src="https://user-images.githubusercontent.com/109003416/178791006-0bf4e96d-de01-4f53-9bfa-56d13608897c.png">

One final example of my SQL work I would like to show uses the "first four moves" idea and finds my win/loss/draw percentage based on just the first four moves. Here is the query and results:

    SELECT
        first_four_moves,
        COUNT(*) AS game_count,
        SUM(IF(white_player = "SuperCarp" AND result = "1-0" OR black_player = "SuperCarp" AND result = "0-1", 1, 0)) AS win_count,
        SUM(IF(white_player = "SuperCarp" AND result = "0-1" OR black_player = "SuperCarp" AND result = "1-0", 1, 0)) AS loss_count,
        SUM(IF(result = "draw", 1, 0)) AS draw_count,
        ROUND(SUM(IF(white_player = "SuperCarp" AND result = "1-0" OR black_player = "SuperCarp" AND result = "0-1", 1, 0))/COUNT(*)*100,1) AS win_pct,
        ROUND(SUM(IF(white_player = "SuperCarp" AND result = "0-1" OR black_player = "SuperCarp" AND result = "1-0", 1, 0))/COUNT(*)*100,1) AS loss_pct,
        ROUND(SUM(IF(result = "draw", 1, 0))/COUNT(*)*100,1) AS draw_pct,
    FROM `database.chess_dataset.complete_game_data`
    GROUP BY first_four_moves
    ORDER BY game_count DESC
    
<img width="718" alt="Openings" src="https://user-images.githubusercontent.com/109003416/178791612-7cd3501f-b893-4b19-b952-8c5c4c4bd9d0.png">

I have only included the results for those openings that appear at in at least 15 games (of my 900+ total). There are some obvious points of emphasis - a 60 percent loss rate for a few of the openings! The first four sequences listed comprise 30 percent of my total games. I have a 50 percent or better win rate on only three opening sequences.

With a host of insightful queries, my final step was to visualize the data.

## Visualize the data with Tableau Public

I created a visualization appropriately titled "I Suck at Chess," the link is here: https://public.tableau.com/app/profile/brian.carpenter8228/viz/ISuckatChess/Dashboard2#1

I have posted files with the R code and SQL queries into the project. I hope you found this interesting or helpful in some way!

Brian Carpenter
