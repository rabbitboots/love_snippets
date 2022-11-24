# love\_snippets
LÖVE-oriented snippets that don't warrant their own repositories.

**VERSION:** 1.0.8


## 9slice
*(Obsolete! See: [quadSlice](https://github.com/rabbitboots/quad_slice))*

Draws a 9-Slice image (a 3x3 tiled graphic, where the edges and center stretch while the corners remain the same size).


## coloredtext\_to\_string
Some basic functions for converting `coloredtext` sequences to plain strings, and writing them to the terminal for debugging purposes. (They do not, unfortunately, print to terminal with the colors intact.)


## line\_stipple
A function that draws stippled lines.


## mod\_key\_state
An alternative to using `love.keyboard.isDown()` within `love.keypressed()` to check the state of modifier keys (ctrl, alt, etc.).


## system\_cursor\_test
Gets copies of the system mouse cursors, and sets them as the mouse hovers over widgets (colored rectangles).


## text\_incremental
Incremental text printing, implemented with `love.graphics.printf()` and LÖVE's `coloredtext` tables. The text can be re-wrapped arbitrarily while still maintaining its progression state.

