#!/bin/bash

PATH="$HOME/bin:$PATH"
export PATH

TARGET=~/in/
PROCESSED=~/out/

inotifywait -m -e create -e moved_to --format "%f" $TARGET \
        | while read FILENAME
                do
                        echo Detected $FILENAME, running av1an
                        av1an -i "$TARGET/$FILENAME" -o "$PROCESSED/" --temp ~/tmp/ $1
                done