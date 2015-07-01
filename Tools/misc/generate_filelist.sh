#!/bin/bash
# generate_filelist.sh $DIR $FILELIST

# initialize empty file
:> "$2"
# fill with entries
for FILE in "$1"/*; do
    echo $FILE >> "$2"
done
