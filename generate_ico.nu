#!/usr/bin/nu

use std null-device

def main [sizes: list<int> = [16, 32, 48, 64, 96, 128, 256, 512]] {
    rm -f sunfish.ico
    rm -f sunfish.icns
    let temp_dir = mktemp --directory
    $sizes | each {|size|
        print $"Rasterizing ($size)"
        inkscape -w $size -h $size assets/sunfish.svg -o ($temp_dir)/($size).png e+o> (null-device)
    }
    print "Converting to icons"
    magick ($temp_dir)/*.png sunfish.ico
    magick ($temp_dir)/*.png sunfish.icns
    mv ($temp_dir)/($sizes | last).png sunfish.png
    inkscape -w 192 -h 192 sunfish_android.svg -o android.png e+o> (null-device)
    inkscape -w 192 -h 192 sunfish_android.svg -o android.svg e+o> (null-device)
    inkscape -w 108 -h 108 sunfish_android.svg -o android_432dp.png e+o> (null-device)
    print "Done"

    rm -rf $temp_dir
}
