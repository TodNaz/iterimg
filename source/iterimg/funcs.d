module iterimg.funcs;

import std.traits;
import iterimg.iface;
import imagefmt;

auto imageFile(string path)
{
    auto image = read_image(path, 4);

    static struct IterateImageFile
    {
        IFImage image;

        auto width() { return image.w; }
        auto height() { return image.h; }
        auto opIter(int x, int y)
        {
            immutable pos = (width * y) + x;
            return cast(ubyte[4]) image.buf8[pos * 4 .. (pos + 1) * 4][0 .. 4];
        }
    }

    return IterateImageFile(image);
}

void saveIter(alias iterFunc, II)(II iterobj, string path)
if (isIterableImage!II)
{
    auto image = iterFunc!(II)(iterobj);
    ubyte[] bytes = (cast(ubyte*) &image.colors[0])[
        0 .. image.colors.length * 4
    ];
    
    write_image(path, image.width, image.height, bytes);
}

auto filledImage(T)(
    T color,
    int width,
    int height
)
{
    static struct FilledIterImage
    {
        Color color;
        int width,
            height;

        auto opIter(int x, int y) { return color; }
    }

    return FilledIterImage(
        extractColor!(T)(color),
        width,
        height
    );
}

auto randomFilledImage(
    int width,
    int height
)
{
    static struct RandFillIterImage
    {
        int width, height;
        Color!ubyte opIter(int x, int y)
        {
            import std.random;
            
            float[4] _rnd =[
                uniform(0.0f, 1.0f),
                uniform(0.0f, 1.0f),
                uniform(0.0f, 1.0f),
                1.0f
            ];

            return extractColor!(float[4])(_rnd);
        }
    }

    return RandFillIterImage(width, height);
}

auto flipX(II)(II iterobj)
if (isIterableImage!II)
{
    static struct FlipIterImage
    {
        II iter;

        auto width() { return iter.width; }
        auto height() { return iter.height; }
        
        auto opIter(int x, int y)
        {
            return extractColor
                !(ReturnType!(iter.opIter))
                (
                    iter.opIter((iter.width - 1) - x, y)
                );
        }
    }

    return FlipIterImage(iterobj);
}

auto flipY(II)(II iterobj)
if (isIterableImage!II)
{
    static struct FlipIterImage
    {
        II iter;

        auto width() { return iter.width; }
        auto height() { return iter.height; }
        
        auto opIter(int x, int y)
        {
            return extractColor
                !(ReturnType!(iter.opIter))
                (
                    iter.opIter(x, (iterobj.height - 1) - y)
                );
        }
    }

    return FlipIterImage(iterobj);
}

auto blur(II)(II iterobj, float[][] kernel)
if (isIterableImage!II)
{
    static struct BlurInputIterate
    {
        II iterobj;
        float[][] kernel;
        size_t kernelWidth;
        size_t kernelHeight;

        this(II iterate, float[][] kernel)
        {
            this.iterobj = iterate;
            this.kernel = kernel;

            kernelWidth = kernel.length;
            kernelHeight = kernel[0].length;
        }

        Color!ubyte opIter(uint x, uint y)
        {
            Color!ubyte color;

            foreach (iy; 0 .. kernelHeight)
            {
                foreach (ix; 0 .. kernelWidth)
                {
                    immutable xPos = cast(int) (x - kernelWidth / 2 + ix);
                    immutable yPos = cast(int) (y - kernelHeight / 2 + iy);

                    if (xPos < 0 || yPos < 0 ||
                        xPos >= width || yPos >= height)
                        continue;
                    
                    color = color +
                            extractColor!(ReturnType!(iterobj.opIter))
                            (iterobj.opIter(xPos, yPos) * kernel[ix][iy]);
                }
            }

            return color;
        }

        uint width() { return iterobj.width; }

        uint height() { return iterobj.height; }
    }

    return BlurInputIterate(iterobj, kernel);
}

auto blur(II)(II iterobj, float radius)
if (isIterableImage!II)
{
    static float[][] gausKernel(int width, int height, float sigma) nothrow pure
    {
        import std.math : exp, PI;
    
        float[][] result = new float[][](width, height);
    
        float sum = 0f;
    
        foreach (i; 0 .. height)
        {
            foreach (j; 0 .. width)
            {
                result[j][i] = exp(-(i * i + j * j) / (2 * sigma * sigma) / (2 * PI * sigma * sigma));
                sum += result[j][i];
            }
        }
    
        foreach (i; 0 .. height)
        {
            foreach (j; 0 .. width)
            {
                result[j][i] /= sum;
            }
        }
    
        return result;
    }

    return blur!(II)(iterobj, gausKernel(cast(int)(radius * 2), cast(int)(radius * 2), radius));
}

import std.functional : unaryFun;

// skip all ASCII chars except a .. z, A .. Z, 0 .. 9, '_' and '.'.
private uint _ctfeSkipOp(ref string op)
{
    if (!__ctfe)
        assert(false);
    import std.ascii : isASCII, isAlphaNum;

    immutable oldLength = op.length;
    while (op.length)
    {
        immutable front = op[0];
        if (front.isASCII() && !(front.isAlphaNum() || front == '_' || front == '.'))
            op = op[1 .. $];
        else
            break;
    }
    return oldLength != op.length;
}

// skip all digits
private uint _ctfeSkipInteger(ref string op)
{
    if (!__ctfe)
        assert(false);
    import std.ascii : isDigit;

    immutable oldLength = op.length;
    while (op.length)
    {
        immutable front = op[0];
        if (front.isDigit())
            op = op[1 .. $];
        else
            break;
    }
    return oldLength != op.length;
}

// skip name
private uint _ctfeSkipName(ref string op, string name)
{
    if (!__ctfe)
        assert(false);
    if (op.length >= name.length && op[0 .. name.length] == name)
    {
        op = op[name.length .. $];
        return 1;
    }
    return 0;
}

private uint _ctfeMatchUnary(string fun, string name)
{
    if (!__ctfe)
        assert(false);
    fun._ctfeSkipOp();
    for (;;)
    {
        immutable h = fun._ctfeSkipName(name) + fun._ctfeSkipInteger();
        if (h == 0)
        {
            fun._ctfeSkipOp();
            break;
        }
        else if (h == 1)
        {
            if (!fun._ctfeSkipOp())
                break;
        }
        else
            return 0;
    }
    return fun.length == 0;
}

template processStrFunc(alias fun, string parmName = "a")
{
    static if (is(typeof(fun) : string))
    {
        static if (!fun._ctfeMatchUnary(parmName))
        {
            import std.algorithm, std.conv, std.exception, std.math, std.range, std.string;
            import std.meta, std.traits, std.typecons;
        }

        auto findXY(string str)
        {
            auto p = split(str, ' ');

            foreach (e; p)
            {
                if (e == "x" || e == "y")
                    return true;
            }

            return false;
        }

        static if (findXY(fun))
        {
            auto call(ElementType)(auto ref ElementType __a, uint x, uint y)
            {
                mixin("alias " ~ parmName ~ " = __a ;");
                return mixin(fun);
            }

            enum isSingle = false;
        }
        else
        {
            auto call(ElementType)(auto ref ElementType __a)
            {
                mixin("alias " ~ parmName ~ " = __a ;");
                return mixin(fun);
            }

            enum isSingle = true;
        }
    }
    else
    {
        alias call = fun;
        enum isSingle = Parameters!fun.length == 1;
    }
}

template process(alias pred, II)
if (isIterableImage!II)
{
    alias fun = processStrFunc!pred;

    enum isSingle = fun.isSingle;

    auto process(II iterobj)
    {
        static struct ProcessIterate
        {
            II iterobj;

            auto opIter(int x, int y)
            {
                static if (isSingle)
                {
                    return fun.call(
                        extractColor!(ReturnType!(iterobj.opIter))(iterobj.opIter(x, y))
                    );
                }
                else
                {
                    return fun.call(
                        extractColor!(ReturnType!(iterobj.opIter))(iterobj.opIter(x, y)), x, y
                    );
                }
            }

            auto width()
            {
                return iterobj.width;
            }

            auto height()
            {
                return iterobj.height;
            }
        }

        return ProcessIterate(iterobj);
    }
}

auto scaleImage(II)(II iterobj, float factor)
if(isIterableImage!II)
{
    static struct ScaleIteration
    {
        II iterobj;
        float factor;
        float scaleWidth, scaleHeight;

        this(II iterobj, float factor)
        {
            this.iterobj = iterobj;
            this.factor = factor;
            immutable newWidth = iterobj.width * factor;
            immutable newHeight = iterobj.height * factor;
            scaleWidth =  cast(float) iterobj.width / cast(float) newWidth;
            scaleHeight =  cast(float) iterobj.height / cast(float) newHeight;
        }

        auto opIter(uint x, uint y)
        {
            uint nx = cast(uint) (scaleWidth * cast(float) x);
            uint ny = cast(uint) (scaleHeight * cast(float) y);

            return extractColor!(ReturnType!(iterobj.opIter))(iterobj.opIter(
                nx, ny
            ));
        }

        /// The estimated image width.
        @property uint width()
        {
            return cast(uint) (iterobj.width * factor);
        }

        /// The estimated image height.
        @property uint height()
        {
            return cast(uint) (iterobj.height * factor);
        }
    }

    return ScaleIteration(iterobj, factor);
}

auto rotateImage(II)(II iterobj, float angle, int cx = 0, int cy = 0)
if(isIterableImage!II)
{
    static struct RotateInputIterate
    {
        II iterobj;
        float angle;
        float cx, cy;

        Color!ubyte opIter(int x, int y)
        {
            import std.math : cos, sin;

            immutable ca = cos(angle);
            immutable sa = sin(angle);

            immutable   vx = cast(immutable float) (x - cx),
                        vy = cast(immutable float) (y - cy);
            
            immutable   rx = (vx * ca - vy * sa) + cx,
                        ry = (vx * sa + vy * ca) + cy;

            if (rx < 0 || ry < 0 ||
                rx >= width || ry >= height)
                return rgba(0, 0, 0, 0);

            return  extractColor!(ReturnType!(iterobj.opIter))
                    (iterobj.opIter(cast(uint) rx, cast(uint) ry));
        }

        uint width()
        {
            return iterobj.width;
        }

        uint height()
        {
            return iterobj.height;
        }
    }

    return RotateInputIterate(iterobj, angle, cx, cy);
}

auto cut(II)(II iterobj, int x, int y, int w, int h)
{
    static struct CutInputIterate
    {
        II iterobj;
        int x, y, w, h;

        uint width() { return w; }
        uint height() { return h; }
        auto opIter(int x, int y)
        {
            if (x > this.x && x < (this.x + w) &&
                y > this.y && y < (this.y + h))
            {
                return extractColor!(ReturnType!(iterobj.opIter))
                (iterobj.opIter(x, y));
            } else
            {
                return Color!ubyte(0, 0, 0, 0);
            }
        }
    }

    return CutInputIterate(iterobj, x, y, w, h);
}

auto blit(II, II2)(II iterobj, II2 iterobj2, int x, int y)
{
    static struct BlitInputIterate
    {
        II iterobj;
        II2 iterobj2;
        int x;
        int y;

        uint width() { return iterobj.width; }
        uint height() { return iterobj.height; }
        auto opIter(int x, int y)
        {
            if (
                x > this.x &&
                y > this.y &&
                x < (this.x + iterobj2.width) &&
                y < (this.y + iterobj2.height)
            )
            {
                return extractColor!(ReturnType!(iterobj2.opIter))
                (iterobj2.opIter(x - this.x, y - this.y));
            } else
                return extractColor!(ReturnType!(iterobj.opIter))
                (iterobj.opIter(x, y));
        }
    }

    return BlitInputIterate(iterobj, iterobj2, x, y);
} 