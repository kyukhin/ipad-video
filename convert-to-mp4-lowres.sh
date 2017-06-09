#!/bin/bash

SRC=$1
DST=$2

find "$SRC" -type f -print0 | while IFS= read -r -d '' file
do
    out=$DST/$(basename "$file")

    echo "$file => ${out%.mkv}.mp4" 
    ./ipad.video.convert.pl -set-resolution="480x360" \
			    -if="$file" \
			    -of="${out%.mkv}.mp4"
done

