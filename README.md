# love\_snippets
LÖVE-oriented snippets that don't warrant their own repositories.

**VERSION:** 1.0.3


## 9slice
Draws a 9-Slice image (a 3x3 tiled graphic, where the edges and center stretch while the corners remain the same size).


## coloredtext\_to\_string
Some basic functions for converting `coloredtext` sequences to plain strings, and writing them to the terminal for debugging purposes. (They do not, unfortunately, print to terminal with the colors intact.)


## line\_stipple
A function that draws stippled lines.


## text\_incremental
Incremental text printing, implemented with `love.graphics.printf()` and LÖVE's `coloredtext` tables. The text can be re-wrapped arbitrarily while still maintaining its progression state.

