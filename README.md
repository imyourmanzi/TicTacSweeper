# Tic Tac Sweeper
_"I don’t believe anyone may ever desire to play a game of Tic Tac Sweeper written in assembly"_

## What??

Here is a 2-player game of Tic Tac Toe (with Minesweeper bombs) written in x86 assembly.

Two users can sit down to play Tic Tac Toe on the command line, but with a couple twists.  First, the board may be a traditional 3x3 grid, or users can opt for a 4x4 or 5x5 grid instead.  Second, each player may (secretly) place a single bomb on the board to potentially catch their opponent and win the game early.

## Wanna Play?

You'll have to assemble and link the program yourself on an x86_64 system, so if that sounds like your cup of tea, here are the commands I've used successfully on my Debian box:

```sh
# assemble
nasm -f elf64 -l tic_tac_sweeper.lst tic_tac_sweeper.asm
# link
gcc -nostdlib -m64 -no-pie -o TicTacSweeper tic_tac_sweeper.o
# run
./TicTacSweeper
```

## Background

This was a project I completed in sophomore year of college for my assembly/low-level-programming-focused course.  I've removed any direct mentions of the course and its professor at the time, who no longer teaches there due to an overwhelming number of student complaints after his first and only semester.  Let this project serve as a relic of those horrid times that taught us so much.
