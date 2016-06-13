# Completetris
A Tetris-like game about closing loops

One tile at a time drops down the board.
You can rotate it as it falls, and move it left/right.
You can also instantly drop it.

Each tile (except blank spaces) has a number of 'open' edges.

When a set of tiles has all of of it's open edges matched with those in another
tile (forming a single closed shape), all of those tiles are removed.

(todo: what should I do with the 'x' and 'X' tiles? Easy for the player would be
to turn them into the corresponding `<`, `>`, `u`, `n` tiles. Harder would be
to require that *both sides* of the `x` or `X` are completed. I should change
the graphic to hint at this if it's the case.)
