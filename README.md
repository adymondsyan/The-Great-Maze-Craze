# The-Great-Maze-Craze - Verilog Maze Game
# Background Information
The purpose of this project is to demonstrate the integration of hardware and software in game design. It provides an opportunity to explore key concepts such as VGA signal generation, memory management, and user input handling, all while developing a functional and engaging application. The game utilizes a VGA driver for visual output, a double-buffering system for efficient rendering, and a Finite State Machine (FSM) for seamless game logic control. User input is managed through the DE0-SoC board's keys, and the game's visual elements are designed using precise hexadecimal color coding.
Design Description
For this project, we used a VGA Driver to upload an image of a maze to a computer screen and coded the controls for the player to move through the maze with the DE0-SoC board. The keys for movements are:
Key 0 = Down
Key 1 - Up
Key 2 = Right
Key 3 = Left
By using these keys on the DE0-SoC board, the player can move the red square wherever within the maze to reach the end goal represented by a green square. Once the end of the maze is reached and the squares collide, the red square restarts back to the middle space of the board for the next player. 
Technical Description
The VGA driver is used to output the maze image onto a computer screen. This driver is implemented in the vga_driver module, which generates the necessary signals for display output. The game uses a double-buffering technique to store and display the maze. Two frame buffers (vga_memory) are used to store the maze image, and the system alternates between reading from one buffer while writing to the other to update the display as instructed by the code.
A Finite State Machine (FSM) is implemented to ensure smooth visual transitions when switching between buffers for reading and writing operations. Additionally, debouncing is included in the code to prevent false inputs during switch operations. For player movement, the keys on the DE0-SoC board are programmed, and colors for the maze and player are set using hex codes to display red and green squares
# Results
In our project proposal, we outlined plans to create a maze game, The Great Maze Craze, that generates random mazes with varying difficulty levels, offering a unique maze for each stage. Our vision included multiple levels with distinctive maze layouts, where the player navigates to reach the end of each maze. However, due to the challenges of getting the player's movements, we were unable to implement the various levels for the final version. Despite this, we successfully developed a baseline version of the game, where the player can navigate and solve a single maze. 
If we were to do this project again, we would start sooner on the baseline of the project to ensure that everything works for the movement of the squares and perfect those movements first. Once those movements had been perfected, we would have tried to implement the idea of having different maze designs that players could try out once the player reached the end of the maze.
# Video
Linked below is a demo video of The Great Maze Game in action. In the game, the player, represented by the red square, navigates the maze to reach the green square, which marks the end. After completing the maze, the player returns to the center to start again! 
https://youtu.be/8Ym3ZgYao_c
# Conclusion
Overall, we believe this project provided an excellent foundation for understanding how to code a maze game. While we faced significant challenges, particularly in displaying the maze code on a computer screen, our efforts ultimately led to success. Reflecting on our results, starting the project earlier would have allowed us to achieve better quality, especially in addressing crash control within the maze. We hope our experience serves as a helpful resource for anyone playing our game or considering creating their own maze game.
# Citations
A design element that we used throughout our project was the VGA Driver code folder (vga_driver_memory_double_buf) that Dr. Jamieson provided for us through our Canvas page for ECE 287. This code allowed us to display images that we programmed in our code to go to the board, and then back to a computer screen that was connected through the board. This code enabled our game to be functional and display our game for players to enjoy! 
