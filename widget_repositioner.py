"""
A small helper script that accepts NetLogo Widget code and prints the code back,
with the location modified/offsetted by the given amounts.
"""

import sys

def errinput(prompt):
    print(prompt, end="", file=sys.stderr)
    return input()

x_align = None
y_align = None
x_offset = 0
y_offset = 0

tmp = errinput("Align x to (leave blank to ignore axis): ")
if tmp:
    x_align = int(tmp)
tmp = errinput("Align y to (leave blank to ignore axis): ")
if tmp:
    y_align = int(tmp)
x_offset = int(errinput("Offset x by: "))
y_offset = int(errinput("Offset y by: "))

lines = iter(list(map(str.strip, sys.stdin)))
previous_blank = True
expect_coordinates = False
for line in lines:
    if expect_coordinates:
        sx = int(line)
        sy = int(next(lines))
        ex = int(next(lines))
        ey = int(next(lines))

        if x_align is not None:
            width = ex - sx
            sx = x_align
            ex = sx + width
        if y_align is not None:
            height = ey- sy
            sy = y_align
            ey = sy + height
        sx += x_offset
        ex += x_offset
        sy += y_offset
        ey += y_offset

        print(sx)
        print(sy)
        print(ex)
        print(ey)
        expect_coordinates = False
    else:
        if line and previous_blank:
            previous_blank = False
            expect_coordinates = True
        if not line:
            previous_blank = True
        print(line)
