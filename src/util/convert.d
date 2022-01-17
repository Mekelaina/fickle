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
    return [cast(ubyte) toCon, cast(ubyte) (cast(ushort) (toCon >> 8))];
}

ubyte[] toBytes(short toCon, int a)
{
    return [cast(ubyte) toCon, cast(ubyte) (cast(short) (toCon >> 8))];
}

ubyte[] toBytes(double toCon)
{
    DoubleConv test = DoubleConv(toCon);
    ubyte[8] t = test.b;
    ubyte[] r;
    int c = 0;
    //writefln(format("%(%02X%)", t));
    for(int i = t.length-1; i >= 0; i--)
    {
        r ~= t[i];
        //writeln(r);
    }
    return r;
}

double toDouble(ubyte[] toCon)
{
    ubyte[] r;
    for(size_t i = toCon.length - 1; i >= 0; i--)
    {
        r ~= toCon[i];
        //writeln(r);
    }
    writefln(format("%s", r.length));
    //ubyte[8] x = r[0..$-1];
    double rtn = *cast(double*)r.ptr;
    return rtn;
}

ushort toShort(ubyte[] toCon)
{
    ushort ret = cast(ushort) toCon[1];
    //writeln(ret);
    ret = cast(ushort) (ret << 8);
    ret += toCon[0];
    return ret;
}
