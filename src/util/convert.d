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
    return [cast(ubyte) (toCon >> 8), cast(ubyte) toCon];
}

ubyte[] shortToBytes(short toCon)
{
    return [cast(ubyte) (toCon >> 8), cast(ubyte) toCon];
}

ubyte[] doubleToBytes(double toCon)
{
    return DoubleConv(toCon).b.dup;
}

short bytesToShort(ubyte[] toCon)
{
    ubyte high = toCon[0];
    ubyte low = toCon[1];
    return (high << 8) + low;
}

ushort bytesToUShort(ubyte[] toCon)
{
    ubyte high = toCon[0];
    ubyte low = toCon[1];
    return (high << 8) + low;
}

double bytesToDouble(ubyte[] toCon)
{
    return *cast(double*)toCon.ptr;
}


pragma(inline):
bool XOR(bool a, bool b) @nogc @safe pure nothrow
{
    return (a || b) && !(a && b);
}
