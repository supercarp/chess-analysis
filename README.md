# chess-analysis
A collection of code and queries used to analyze my online chess games

With this project I set out to achieve four goals:
1) Discover how to efficiently pull the data from all of my online chess games (more than 900 total)
2) Use R coding and Google Sheets to process, clean, and organize the data
3) Use SQL to discover insights about my chess games
4) Use Tableau Public to create a visualization of the data and insights

## Pulling the data efficiently
The initial challenge was that chess game data is stored in plaintext .pgn files, which have to be manually downloaded per game from chess.com. However, chess.com offers a developer API to access information about players and games on the platform including a list of a player's monthly archived games and consolidated monthly .pgn files with every game included.
