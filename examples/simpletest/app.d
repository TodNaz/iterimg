import std.stdio;

import iterimg;
import imagefmt;
import std.math : PI;
import std.stdio;
import std.datetime;
import std.file : exists;

int main(string[] args)
{
    if (args.length == 1)
        return -1;

    string input = args[1];
    if (!exists(input))
        return -2;
    
    auto ii = imageFile(input);
     
    auto time = MonoTime.currTime;

    ii
        .flipX
        .blur(2)
        .process!("a * 0.5")
        .rotateImage(PI / 4.0f, 760 / 4, 760 / 4)
        .scaleImage(4)
        .cut(128, 128, 1024, 720)
        .blit(ii, 256, 256)
        .saveIter!iterate("output.png");

    writeln(MonoTime.currTime - time);
    time = MonoTime.currTime;

    ii
        .flipX
        .blur(2)
        .process!("a * 0.5")
        .rotateImage(PI / 4.0f, 760 / 4, 760 / 4)
        .scaleImage(4)
        .cut(128, 128, 1024, 720)
        .blit(ii, 256, 256)
        .saveIter!parallelIterate("output2.png");

    writeln(MonoTime.currTime - time);

    return 0;
}
