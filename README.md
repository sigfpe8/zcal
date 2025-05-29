## Simple calendar program in Zig

This is just a stripped down version of the Unix/Linux `cal` utility, written in Zig
for my own practice.

In addition to the calendar itself, there's a module called `astrodate` which handles
the calendrical calculations. I'm planning to expand it with more functions related
to astronomy (such as coordinate transformations) so that it can be used in other
projects. Its main data structure, `AstroDate`, keeps track of date and time but with
the limited accuracy of only 1 sec. In the future it may be necessary to add fractions
of a second (milli or microseconds) but for now it is enough. Its is quite compact now,
occupying only 8 bytes (i.e. it fits in a 64-bit register).

```
zcal % zig build run        

----- May 2025 -----
Su Mo Tu We Th Fr Sa 
             1  2  3 
 4  5  6  7  8  9 10 
11 12 13 14 15 16 17 
18 19 20 21 22 23 24 
25 26 27 28 29 30 31 
                     

zcal % ./zig-out/bin/zcal -h

Usage: zcal [options]            ; Print current month
       zcal [options] year       ; Print given year
       zcal [options] month year ; Print given month/year
options: -h                      ; Show this help message
         -c                      ; Print year in 4 columns
         -s                      ; Start week on Monday
```

Built with Zig 0.14.1
