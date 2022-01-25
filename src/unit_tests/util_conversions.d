module unit_tests.util_conversions;

import std.format;
import std.stdio;

import util.convert;

unittest {
    ushort x = 42069;
    ubyte[] y = ushortToBytes(x);
    assert(y == [164, 85]);
    assert(x == bytesToUShort(y));
}

unittest {
    short x = -23467;
    ubyte[] y = shortToBytes(x);
    assert(y == [164, 85]);
    assert(x == bytesToShort(y));
}

unittest {
    double x = 3.1415926535897932;
    ubyte[] y = doubleToBytes(x);
    //foreach (q; y) writeln(format("%x", q));
    // 64-bit floating point of pi is 0x400921fb54442d18
    assert(y == [0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40]);
    assert(x == bytesToDouble(y));
}

unittest {
    assert(XOR(true, true) == false);
    assert(XOR(true, false) == true);
    assert(XOR(false, true) == true);
    assert(XOR(false, false) == false);
}
