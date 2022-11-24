# Changelog (love\_snippets)

## 1.0.8 -- 2022-11-23
* mod\_key\_state:
  * Changed the example to use KeyConstants rather than Scancodes. This should be more friendly to users who have remapped keys at the OS level. One can still use Scancodes instead, if that causes other issues.
  * Renamed some variables in mod\_key.lua to be agnostic as to whether KeyConstants or Scancodes are being used. (Use one or the other, but not both.) For the time being, I am leaving scancode-centric code in the other snippets as it is.

## 1.0.7 -- 2022-08-11
* Obsoleted the 9slice example, as I now have a [library](https://github.com/rabbitboots/quad_slice) for drawing 9slice rectangles.

## 1.0.6 -- 2022-07-30
* Added 'mod\_key\_state' example.

## 1.0.5 -- 2022-07-04
* Added system cursor test.
* Deleted 'ticker_text', a WIP that I uploaded by mistake on the 29th. You can find it in [this commit](https://github.com/rabbitboots/love_snippets/commit/4dfa122da4a684a93b5853637e00e4c016d04a31), if you're curious, though it doesn't really do anything besides apply a sine function to some sample text.

## 1.0.4 -- 2022-06-29
* coloredtext\_to\_string:
  * Include the optional alpha channel when printing color tables.
  * Add conf.lua.

## 1.0.3 -- 2022-06-29
* Added some basic coloredtext-to-string functions.

## 1.0.2 -- 2022-06-15
* Added incremental text snippet.

## 1.0.1 -- 2022-05-16
* Added changelog.
* Added 9slice example.
* Removed `console = true` from line`_stipple's conf.lua.

