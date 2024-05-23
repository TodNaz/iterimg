module iterimg.iface;

import std.traits;

enum CannotDetectAuto =
    "The format cannot be detected automatically!";

/// Pixel representation format.
enum PixelFormat : int
{
    None, /// None format
    Auto, /// Automatic detection
    RGB, /// Red-Green-Blue
    RGBA, /// Red-Green-Blue-Alpha
    ARGB, /// Alpha-Red-Green-Blue
    BGRA, /// Blue-Green-Red-Alpha
    BGR /// Blur-Green-Red
}

/++
Whether the pixel format is valid for the job.
+/
template isValidFormat(int pixelformat)
{
    enum isValidFormat = pixelformat != PixelFormat.None &&
        pixelformat != PixelFormat.Auto &&
        pixelformat <= PixelFormat.max;
}

unittest
{
    assert(isValidFormat!(PixelFormat.BGRA));
    assert(!isValidFormat!(30));
}

/++
Shows how many bytes are contained in a color unit.
+/
template bytesPerColor(int pixelformat, T = ubyte)
{
    static assert(isValidFormat!pixelformat, "Invalid or unknown pixel format!");

    static if (pixelformat == PixelFormat.RGBA ||
        pixelformat == PixelFormat.ARGB ||
        pixelformat == PixelFormat.BGRA)
    {
        enum bytesPerColor = 4 * T.sizeof;
    }
    else
    {
        enum bytesPerColor = 3 * T.sizeof;
    }
}

unittest
{
    assert(bytesPerColor!(PixelFormat.RGBA) == 4);
    assert(bytesPerColor!(PixelFormat.RGBA, int) == 4 * int.sizeof);
    assert(bytesPerColor!(PixelFormat.BGR, int) == 3 * int.sizeof);
    assert(bytesPerColor!(PixelFormat.ARGB, long) == 4 * long.sizeof);
    assert(bytesPerColor!(PixelFormat.RGB, float) == 3 * float.sizeof);
}

T hexTo(T, R)(R hexData) nothrow pure
if (isSomeString!R)
{
    import std.math : pow;

    enum hexNumer = "0123456789";
    enum hexWord = "ABCDEF";
    enum hexSmallWord = "abcdef";

    T result = T.init;
    int index = -1;

    hexDataEach: foreach_reverse (e; hexData)
    {
        index++;
        immutable rindex = (cast(int) hexData.length) - index;
        immutable ai = pow(16, index);

        foreach (el; hexNumer)
        {
            if (e == el)
            {
                result += (e - 48) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }

        foreach (el; hexWord)
        {
            if (e == el)
            {
                result += (e - 55) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }

        foreach (el; hexSmallWord)
        {
            if (e == el)
            {
                result += (e - 87) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }
    }

    return result;
}

unittest
{
    assert(hexTo!long("FF0000") == (0xFF0000));
    assert(hexTo!long("0A0A1F") == (0x0A0A1f));
    assert(hexTo!int("3AF124") == (0x3AF124));
    assert(hexTo!int("f1aB11") == (0xf1aB11));
    assert(hexTo!int("fffff3a") == (0xfffff3a));
}

/++
Creates an RGB color.

Params:
    red = Red.
    green = Green.
    blue = Blue. 

Returns: RGBA
+/
Color!ubyte rgb(ubyte red, ubyte green, ubyte blue) nothrow pure
{
    return Color!ubyte(red, green, blue, ubyte.max);
}

Color!ubyte rgb(ubyte[] data) nothrow pure
{
    return Color!ubyte(data[0], data[1], data[2]);
}

Color!ubyte rgba(ubyte[] data) nothrow pure
{
    return Color!ubyte(data);
}

Color!ubyte grayscale(ubyte value) nothrow pure
{
    return Color!ubyte(value, value, value, Color!ubyte.Max);
}

/++
Creates an RGBA color.

Params:
    red = Red.
    green = Green.
    blue = Blue. 
    alpha = Alpha.

Returns: RGBA
+/
Color!ubyte rgba(ubyte red, ubyte green, ubyte blue, ubyte alpha) nothrow pure
{
    return Color!ubyte(red, green, blue, alpha);
}

/++
Recognizes a hex format string, converting it to RGBA representation as a 
`Color!ubyte` structure.

Params:
    hex = The same performance. The following formats can be used:
          * `0xRRGGBBAA` / `0xRRGGBB`
          * `#RRGGBBAA` / `#RRGGBB`
    format = Pixel format.

Returns: `Color!ubyte`
+/
Color!C parseColor(int format = PixelFormat.Auto, C = ubyte, T)(T hex)
nothrow pure
{
    static if (isSomeString!T)
    {
        import std.conv : to;
        import std.bigint;

        size_t cv = 0;
        if (hex[0] == '#')
            cv++;
        else if (hex[0 .. 2] == "0x")
            cv += 2;

        static if (format == PixelFormat.Auto)
        {
            const alpha = hex[cv .. $].length > 6;

            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                alpha ? hex[cv + 6 .. cv + 8].hexTo!C : Color!C.Max
            );
        }
        else static if (format == PixelFormat.RGB)
        {
            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C
            );
        }
        else static if (format == PixelFormat.RGBA)
        {
            assert(hex[cv .. $].length > 6, "This is not alpha-channel hex color!");

            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C
            );
        }
        else static if (format == PixelFormat.ARGB)
        {
            assert(hex[cv .. $].length > 6, "This is not alpha-channel hex color!");

            return Color!C(
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C,
                hex[cv .. cv + 2].hexTo!C
            );
        }
        else static if (format == PixelFormat.BGRA)
        {
            assert(hex[cv .. $].length > 6, "This is not alpha-channel hex color!");

            return Color!C(
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C
            );
        }
        else static if (format == PixelFormat.BGR)
        {
            return Color!C(
                hex[cv + 6 .. cv + 8].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv .. cv + 2].hexTo!C);
        }
        else
            static assert(null, "Unknown pixel format");
    }
    else static if (isIntegral!T)
    {
        Color!C result;

        static if (format == PixelFormat.RGBA)
        {
            result.r = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.b = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);

            return result;
        }
        else static if (format == PixelFormat.RGB)
        {
            result.r = (hex & 0xFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.b = (hex & 0x0000FF);
            result.a = 255;

            return result;
        }
        else static if (format == PixelFormat.ARGB)
        {
            result.a = (hex & 0xFF000000) >> 24;
            result.r = (hex & 0x00FF0000) >> 16;
            result.g = (hex & 0x0000FF00) >> 8;
            result.b = (hex & 0x000000FF);

            return result;
        }
        else static if (format == PixelFormat.BGRA)
        {
            result.b = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.r = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);

            return result;
        }
        else static if (format == PixelFormat.BGR)
        {
            result.b = (hex & 0XFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.r = (hex & 0x0000FF);
            result.a = Color!C.Max;

            return result;
        }
        else static if (format == PixelFormat.Auto)
        {
            return parseColor!(PixelFormat.RGB, C, T)(hex);
        }
        else
            static assert(null, "Unknown pixel format!");
    }
    else
        static assert(null, "Unknown type hex!");
}

unittest
{
    assert(parseColor(0xFFFFFF) == (Color!ubyte(255, 255, 255)));
    assert(parseColor("#f9004c") == (Color!ubyte(249, 0, 76)));
    assert(parseColor("#f9004cf9") == (Color!ubyte(249, 0, 76, 249)));

    assert(parseColor!(PixelFormat.RGBA)(0xc1f4a1b4) == (Color!ubyte(193, 244, 161, 180)));
    assert(parseColor!(PixelFormat.BGRA)("FF0000FF") == (Color!ubyte(0, 0, 255, 255)));
    assert(parseColor!(PixelFormat.ARGB)("f9ff00ff") == (Color!ubyte(255, 0, 255, 249)));
    assert(parseColor!(PixelFormat.BGR)(0xf900ff) == (Color!ubyte(255, 0, 249, 255)));
}

struct Color(T : byte)
if (isIntegral!T || isFloatingPoint!T)
{
    alias Type = T;

    static if (isIntegral!T)
    {
        enum Max = T.max;
        enum Min = 0;
    }
    else static if (isFloatingPoint!T)
    {
        enum Max = 1.0f;
        enum Min = 0.0f;
    }

export:
    T red; /// Red component
    T green; /// Green component
    T blue; /// Blue component
    T alpha = Max; /// Alpha component

    alias r = red;
    alias g = green;
    alias b = blue;
    alias a = alpha;

nothrow pure:
    /++
    Color constructor for four components, the latter which is optional.
    +/
    this(T red, T green, T blue, T alpha = Max)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }

    /++
    Parses a color from the input.
    +/
    this(R)(R value) if (isIntegral!R || isSomeString!R || isArray!R)
    {
        static if (isArray!R && !isSomeString!R)
        {
            this.red = cast(T) value[0];
            this.green = cast(T) value[1];
            this.blue = cast(T) value[2];
            this.alpha = cast(T)(value.length > 3 ? value[3] : Max);
        }
        else
            this = parseColor!(PixelFormat.Auto, T, R)(value);
    }

    void opAssign(R)(R value) if (isIntegral!R || isSomeString!R || isArray!R)
    {
        static if (isArray!R && !isSomeString!R)
        {
            this.red = value[0];
            this.green = value[1];
            this.blue = value[2];
            this.alpha = value.length > 3 ? value[3] : Max;
        }
        else
            this = parseColor!(PixelFormat.Auto, T, R)(value);
    }

    R to(R, int format = PixelFormat.RGBA)() inout
    {
        static if (isIntegral!R && !isFloatingPoint!T)
        {
            static if (format == PixelFormat.RGBA)
                return cast(R)(((r & 0xff) << 24) + ((g & 0xff) << 16) + ((b & 0xff) << 8) + (
                        a & 0xff));
            else static if (format == PixelFormat.RGB)
                return cast(R)((r & 0xff) << 16) + ((g & 0xff) << 8) + ((b & 0xff));
            else static if (format == PixelFormat.ARGB)
                return cast(R)(((a & 0xff) << 24) + ((r & 0xff) << 16) + ((g & 0xff) << 8) + (
                        b & 0xff));
            else static if (format == PixelFormat.BGRA)
                return cast(R)(((b & 0xff) << 24) + ((g & 0xff) << 16) + ((r & 0xff) << 8) + (
                        a & 0xff));
            else static if (format == PixelFormat.BGR)
                return cast(R)(((b & 0xff) << 16) + ((g & 0xff) << 8) + ((r & 0xff)));
            else
                return 0;
        }
        else static if (isSomeString!R)
        {
            static if (isFloatingPoint!T)
                return "";
            else
            {
                import std.digest : toHexString;

                return cast(R) toBytes!(format).toHexString;
            }
        }
    }

    /++
    Returns an array of components.

    Params:
        format = Pixel format.
    +/
    T[] toBytes(int format)() inout
    {
        static assert(isValidFormat!format, CannotDetectAuto);

        static if (format == PixelFormat.RGBA)
            return [r, g, b, a];
        else static if (format == PixelFormat.RGB)
            return [r, g, b];
        else static if (format == PixelFormat.ARGB)
            return [a, r, g, b];
        else static if (format == PixelFormat.BGRA)
            return [b, g, r, a];
        else static if (format == PixelFormat.BGR)
            return [b, g, r];
    }

    Color!T opBinary(string op)(T koe) inout
    {
        import std.conv : to;

        static if (op == "+")
            return Color!T(cast(T)(r + koe),
                cast(T)(g + koe),
                cast(T)(b + koe),
                cast(T)(a + koe));
        else static if (op == "-")
            return Color!T(cast(T)(r - koe),
                cast(T)(g - koe),
                cast(T)(b - koe),
                cast(T)(a - koe));
        else static if (op == "*")
            return Color!T(cast(T)(r * koe),
                cast(T)(g * koe),
                cast(T)(b * koe),
                cast(T)(a * koe));
        else static if (op == "/")
            return Color!T(cast(T)(r / koe),
                cast(T)(g / koe),
                cast(T)(b / koe),
                cast(T)(a / koe));
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    Color!T opBinary(string op)(float koe) inout
    {
        import std.conv : to;

        static if (op == "+")
            return Color!T(cast(T)(r + koe),
                cast(T)(g + koe),
                cast(T)(b + koe),
                cast(T)(a + koe));
        else static if (op == "-")
            return Color!T(cast(T)(r - koe),
                cast(T)(g - koe),
                cast(T)(b - koe),
                cast(T)(a - koe));
        else static if (op == "*")
            return Color!T(cast(T)(r * koe),
                cast(T)(g * koe),
                cast(T)(b * koe),
                cast(T)(a * koe));
        else static if (op == "/")
            return Color!T(cast(T)(r / koe),
                cast(T)(g / koe),
                cast(T)(b / koe),
                cast(T)(a / koe));
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    Color!T opBinary(string op)(Color!T color) inout
    {
        static if (op == "+")
        {
            return Color!T(cast(T)(r + color.r),
                cast(T)(g + color.g),
                cast(T)(b + color.b),
                cast(T)(a + color.a));
        }
        else static if (op == "-")
            return Color!T(cast(T)(r - color.r),
                cast(T)(g - color.g),
                cast(T)(b - color.b),
                cast(T)(a - color.a));
        else static if (op == "*")
            return Color!T(
                cast(T) (r * color.r),
                cast(T) (g * color.g),
                cast(T) (b * color.b),
                cast(T) (a * color.a)
            );
        else static if (op == "/")
            return Color!T(cast(T) r / color.r,
                g / color.g,
                b / color.b,
                a / color.a);
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    /// Converts the color to black and white.
    float toGrayscaleFloat() inout
    {
        return (rf * 0.299 + gf * 0.587 + bf * 0.144);
    }

    /// Whether the color is dark.
    bool isDark() inout
    {
        return toGrayscaleFloat < 0.5f;
    }

    /// Whether the color is light.
    bool isLight() inout
    {
        return toGrayscaleFloat > 0.5f;
    }

    /// Converts the color to black and white.
    T toGrayscaleNumber() inout
    {
        return cast(T)(Max * toGrayscaleFloat());
    }

    /// Converts the color to black and white.
    Color!T toGrayscale() inout
    {
        auto graycolor = toGrayscaleNumber();

        return Color!T(graycolor, graycolor, graycolor, alpha);
    }

    /// Will return the color opposite to itself.
    @property Color!T inverted() inout
    {
        return Color!T(cast(T) (Max - r), cast(T) (Max - g), cast(T) (Max - b), a);
    }

    /// Invert alpha value
    @property T invertAlpha() inout
    {
        return cast(T) (Max - alpha);
    }

    /// Red value in the form of a range from 0 to 1.
    @property float rf() inout
    {
        return cast(float) r / cast(float) Max;
    }

    /// ditto
    @property float rf(float value)
    {
        this.r = cast(T)(Max * value);

        return value;
    }

    /// Green value in the form of a range from 0 to 1.
    @property float gf() inout
    {
        return cast(float) g / cast(float) Max;
    }

    /// ditto
    @property float gf(float value)
    {
        this.g = cast(T)(Max * value);

        return value;
    }

    /// Alpha value in the form of a range from 0 to 1.
    @property float bf() inout
    {
        return cast(float) b / cast(float) Max;
    }

    /// ditto
    @property float bf(float value)
    {
        this.b = cast(T)(Max * value);

        return value;
    }

    /// Returns a alpha value in the form of a range from 0 to 1.
    @property float af() inout
    {
        return cast(float) a / cast(float) Max;
    }
    /// ditto
    @property float af(float value)
    {
        this.a = cast(T)(Max * value);

        return value;
    }
}

template validColorComp(T)
{
    static if (isStaticArray!(T))
    {
        static if (
            (is(ForeachType!(T) == byte) || is(ForeachType!(T) == ubyte)) &&
            T.length == 4
        )
        {
            enum validColorComp = true;
        } else
        static if (
            ForeachType!(T) == float &&
            T.length == 4
        )
        {
            enum validColorComp = true;
        } else
            enum validColorComp = false;
    } else
    static if ( is(T == int) || is(T == uint) ||
                is(T == long) || is(T == ulong))
    {
        enum validColorComp = true;
    } else
    {
        alias rt = typeof((T r) { return r.r; } (T.init));
        alias gt = typeof((T r) { return r.g; } (T.init));
        alias bt = typeof((T r) { return r.b; } (T.init));
        alias at = typeof((T r) { return r.a; } (T.init));
        
        static if (
            (is(rt == byte) || is(rt == ubyte)) &&
            (is(gt == byte) || is(gt == ubyte)) &&
            (is(bt == byte) || is(bt == ubyte)) &&
            (is(at == byte) || is(at == ubyte))
        )
        {
            enum validColorComp = true;
        } else
        static if (
            (is(rt == float)) &&
            (is(gt == float)) &&
            (is(bt == float)) &&
            (is(at == float))
        )
        {
            enum validColorComp = true;
        } else
        {
            enum validColorComp = false;
        }
    }
}

template extractColor(T)
{
    static if (isStaticArray!(T))
    {
        static if (
            (is(ForeachType!(T) == byte) || is(ForeachType!(T) == ubyte)) &&
            T.length == 4
        )
        {
            Color!ubyte extractColor(T color) @nogc nothrow pure
            {
                return Color!ubyte(color[0], color[1], color[2], color[3]);
            }
        } else
        static if (
            is(ForeachType!(T) == float) &&
            T.length == 4
        )
        {
            Color!ubyte extractColor(T color) @nogc nothrow pure
            {
                return Color!ubyte(
                    cast(ubyte) (color[0] * ubyte.max),
                    cast(ubyte) (color[1] * ubyte.max),
                    cast(ubyte) (color[2] * ubyte.max),
                    cast(ubyte) (color[3] * ubyte.max)
                );
            }
        } else
            static assert(null, "The color component cannot be calculated.");
    } else
    static if ( is(T == int) || is(T == uint) ||
                is(T == long) || is(T == ulong))
    {
        Color!ubyte extractColor(T color) @nogc nothrow pure
        {
            Color!ubyte result;
            result.r = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.b = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);

            return result;
        }
    } else
    {
        alias rt = typeof((T r) { return r.r; } (T.init));
        alias gt = typeof((T r) { return r.g; } (T.init));
        alias bt = typeof((T r) { return r.b; } (T.init));
        alias at = typeof((T r) { return r.a; } (T.init));
        
        static if (
            (is(rt == byte) || is(rt == ubyte)) &&
            (is(gt == byte) || is(gt == ubyte)) &&
            (is(bt == byte) || is(bt == ubyte)) &&
            (is(at == byte) || is(at == ubyte))
        )
        {
            Color!ubyte extractColor(T color) @nogc nothrow pure {
                return Color!ubyte(
                    cast(byte) color.r,
                    cast(byte) color.g,
                    cast(byte) color.b,
                    cast(byte) color.a
                );
            };
        } else
        static if (
            (is(rt == float)) &&
            (is(gt == float)) &&
            (is(bt == float)) &&
            (is(at == float))
        )
        {
            Color!ubyte extractColor(T color) @nogc nothrow pure {
                return Color!ubyte(
                    cast(ubyte) (color.r * ubyte.max),
                    cast(ubyte) (color.g * ubyte.max),
                    cast(ubyte) (color.b * ubyte.max),
                    cast(ubyte) (color.a * ubyte.max)
                );
            };
        } else
            static assert(null, "The color component cannot be calculated.");
    }
}

template isIterableImage(T)
{
    alias wt = typeof((T r) { return r.width; } (T.init));
    alias ht = typeof((T r) { return r.height; } (T.init));
    
    enum isIterableImage =
        validColorComp!(
            ReturnType!(T.opIter)
        ) &&
        (is(wt == int) || is(wt == uint)) &&
        (is(ht == int) || is(ht == uint));
}

interface IterateImage
{
    uint width();
    uint height();
    Color!ubyte opIter(int x, int y);
}

struct Image
{
    Color!ubyte[] colors;
    int width;
    int height;

    Color!ubyte opIter(int x, int y)
    in(x < width)
    in(y < height)
    {
        return colors[(width * y) + x];
    }
}

Image iterate(II)(
    II iterobj
)
{
    Image image;
    image.width = iterobj.width;
    image.height = iterobj.height;
    image.colors = new Color!ubyte[](
        image.width * image.height
    );
    
    foreach (y; 0 .. iterobj.height)
    {
        foreach (x; 0 .. iterobj.width)
        {
            image.colors[x + y * image.width] = iterobj.opIter(x, y);
        }
    }

    return image;
}

Image parallelIterate(II)(
    II iterobj
)
{
    import core.thread;
    import core.cpuid;

    static void iterateRange(
        uint x0, uint y0,
        uint x1, uint y1,
        ref Image image,
        ref II iterobj
    )
    {
        foreach (y; y0 .. y1)
        {
            foreach (x; x0 .. x1)
            {
                image.colors[x + y * image.width] = iterobj.opIter(x, y);
            }
        }
    }

    static final class IterateThread : Thread
    {
        Image* pImage;
        II* pIterobj;
        uint x0, y0, x1, y1;
         
        this(uint x0, uint y0,
            uint x1, uint y1,
            ref Image image,
            ref II iterobj
        )
        {
            this.x0 = x0;
            this.y0 = y0;
            this.x1 = x1;
            this.y1 = y1;
            this.pImage = &image;
            this.pIterobj = &iterobj;
            
            super(&run);
        }
        
        void run()
        {
            iterateRange(x0, y0, x1, y1, *pImage, *pIterobj);
        }
    }
    
    Image image;
    image.width = iterobj.width;
    image.height = iterobj.height;
    image.colors = new Color!ubyte[](
        image.width * image.height
    );
    
    immutable   chunkSizeX = cast(uint) (cast(float) iterobj.width / threadsPerCPU),
                chunkSizeY = cast(uint) (cast(float) iterobj.height / threadsPerCPU);

    debug
    {
        import std.stdio;
        writeln("DEBUG: threadsPerCPU() = ", threadsPerCPU);
    }

    IterateThread[] threads;
    
    foreach (x; 0 .. image.width / chunkSizeX)
    {
        foreach (y; 0 .. image.height / chunkSizeY)
        {
            auto th = new IterateThread(
                    x * chunkSizeX, y * chunkSizeY,
                    (x + 1) * chunkSizeX, (y + 1) * chunkSizeY,
                    image,
                    iterobj
            );
            th.start();
            threads ~= th;
        }
    }

    foreach (e; threads)
    {
        e.join();
    }

    return image;
}

auto iterateRange(II)(II iterobj)
{
    static struct IterateRange
    {
        II iterobj;
        int x = 0, y = 0;

        bool empty()
        {
            return ((y * iterate.width) + x) == iterobj.width * iterobj.height;
        }

        void popFront()
        {
            x++;

            if (x == iterate.width)
            {
                x = 0;
                y++;
            }
        }

        Color!ubyte front()
        {
            return extractColor!(ReturnType!(iterobj.opIter))
            (iterobj.opIter(x, y));
        }
    }

    return IterateRange(iterobj);
}