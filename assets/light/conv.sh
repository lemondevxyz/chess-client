#!/bin/sh
for f in ./*; do
	X=$(echo "$filename" | cut -f 1 -d '.')
	inkscape -w 1024 -h 1024 "$f" -o "$X.png"
done
