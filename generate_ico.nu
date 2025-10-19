#!/usr/bin/nu

use std null-device

def main [sizes: list<int> = [16, 32, 48, 64, 96, 128, 256, 512]] {
    rm -f sunfish.ico
    rm -f sunfish.icns
    let temp_dir = mktemp --directory
    $sizes | each {|size|
        print $"Rasterizing ($size)"
        inkscape -w $size -h $size assets/sunfish.svg -o ($temp_dir)/($size).png
    }
    print "Converting to icons"
    rm icons/*
    mkdir icons
    magick ($temp_dir)/*.png icons/sunfish.ico
    magick ($temp_dir)/*.png icons/sunfish.icns
    mv ($temp_dir)/64.png icons/sunfish.png
    inkscape -w 256 -h 256 assets/sunfish_large.svg -o icons/sunfish_hq_svg.svg
    inkscape -w 192 -h 192 assets/sunfish_legacy.svg -o icons/android_legacy.png
    inkscape -w 432 -h 432 assets/sunfish_adaptive_fg.svg -o icons/android_adaptive_fg.png
    inkscape -w 432 -h 432 assets/sunfish_adaptive_bg.svg -o icons/android_adaptive_bg.png
    cp assets/sunfish_adaptive_fg_mono.svg icons/android_adaptive_fg_mono.svg
    print "Done"

    rm -rf $temp_dir
}
