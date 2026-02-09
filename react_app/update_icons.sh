#!/bin/bash

SRC_FULL="/Users/j/.gemini/antigravity/brain/8a986d87-e53f-4aa0-a169-31171b310c63/app_icon_full_1765227700610.png"
SRC_FG="/Users/j/Desktop/CardioInsight/app/temp_foreground.png"
RES_DIR="android/app/src/main/res"

# Defines sizes: folder_suffix size
# mdpi: 48
# hdpi: 72
# xhdpi: 96
# xxhdpi: 144
# xxxhdpi: 192

declare -a sizes=("mdpi 48" "hdpi 72" "xhdpi 96" "xxhdpi 144" "xxxhdpi 192")

for i in "${sizes[@]}"
do
    set -- $i
    folder=$1
    size=$2
    
    echo "Processing mipmap-$folder ($size x $size)..."
    
    # Legacy Icon (Full)
    sips -s format png -z $size $size "$SRC_FULL" --out "$RES_DIR/mipmap-$folder/ic_launcher.png"
    sips -s format png -z $size $size "$SRC_FULL" --out "$RES_DIR/mipmap-$folder/ic_launcher_round.png"
    
    # Adaptive Foreground (Transparent)
    # ...
    # ...
    
    fg_size=$(echo "$size * 2.25" | bc | cut -d'.' -f1)
    
    echo "  -> Foreground size: $fg_size x $fg_size"
    sips -s format png -z $fg_size $fg_size "$SRC_FG" --out "$RES_DIR/mipmap-$folder/ic_launcher_foreground.png"
done

echo "Done updating icons."
