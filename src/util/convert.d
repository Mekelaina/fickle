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

ubyte[] toBytes(ushort toCon)
{
    //bool t = isSigned!(toCon);
    //writefln(format("%s, %s: %s", toCon.stringof, toCon, t));
    return [cast(ubyte) (cast(short) (toCon >> 8)), cast(ubyte) toCon];
}

ubyte[] toBytes(short toCon, int a)
{
    return [cast(ubyte) (cast(short) (toCon >> 8)), cast(ubyte) toCon];
}

ubyte[] toBytes(double toCon)
{
    DoubleConv test = DoubleConv(toCon);
    ubyte[8] t = test.b;
    
    return t.dup;
}

double toDouble(ubyte[] toCon)
{
    //ubyte[8] x = r[0..$-1];
    double rtn = *cast(double*)toCon.ptr;
    return rtn;
}

ushort toShort(ubyte[] toCon)
{
    ushort ret = toCon[0];
    ret = cast(ushort) toCon[1];
    //writeln(ret);
    ret = cast(ushort) (ret << 8);

    return ret;
}

pragma(inline):
bool XOR(bool a, bool b) @nogc @safe pure nothrow
{
    return ((a || b) && !(a && b));
}
