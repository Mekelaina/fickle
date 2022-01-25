module util.convert;

import std.stdio;
import std.format;
import std.traits;

union DoubleConv
{
    double d;
    short[4] w;
    ubyte[8] b;

}

ubyte[] ushortToBytes(ushort toCon)
{
    //bool t = isSigned!(toCon);
    //writefln(format("%s, %s: %s", toCon.stringof, toCon, t));
    return [cast(ubyte) (cast(short) (toCon >> 8)), cast(ubyte) toCon];
}

ubyte[] shortToBytes(short toCon)
{
    return [cast(ubyte) (cast(short) (toCon >> 8)), cast(ubyte) toCon];
}

ubyte[] uShortToBytes(double toCon)
{
    DoubleConv test = DoubleConv(toCon);
    ubyte[8] t = test.b;
    
    return t.dup;
}

double byteToDouble(ubyte[] toCon)
{
    //ubyte[8] x = r[0..$-1];
    double rtn = *cast(double*)toCon.ptr;
    return rtn;
}

short byteToShort(ubyte[] toCon)
{
    short ret = cast(short) toCon[0];
    ret = cast(short) (ret << 8);
    ret += toCon[1];
    return ret;
}

ushort byteToUShort(ubyte[] toCon)
{
    ushort ret = cast(ushort) toCon[0];
    ret = cast(ushort) (ret << 8);
    ret += toCon[1];
    return ret;
}

pragma(inline):
bool XOR(bool a, bool b) @nogc @safe pure nothrow
{
    return ((a || b) && !(a && b));
}
