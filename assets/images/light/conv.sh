#!/bin/sh
for f in ./*.png; do
	X=$(echo "$filename" | cut -f 1 -d '.')
	convert "$f" -resize 200x200 "$f"
done
