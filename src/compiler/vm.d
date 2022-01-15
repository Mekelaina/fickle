module compiler.vm;

import std.stdio;
import std.stdint;
import std.sumtype;
import std.conv;
import std.array;
import std.range : cycle, take;
import std.format;

const AMT_REGISTERS = 10;
const FFFF = 65_535;


alias RegisterValue = SumType!(
   uint8_t,
   uint16_t,
   double,
   dchar,
   bool
);


enum R {
    b0, b1,
    w0, w1,
    f0, f1,
    c0, c1,
     x,  y
}

struct Registers {
    uint8_t b0, b1;
    int16_t w0, w1;
    double  f0, f1;
    dchar   c0, c1;
    bool     x,  y;

}

struct Ram {
    //NOTE: all the methods that take ints are just convenience wrappers
    //that call their ushort counterparts with the appropriate cast
    //so we dont have to cast each input each time.
    
    //the single value methods wrap the input in an array and pass it
    //to the array input methods. which check for single values and
    //and map it to the given range.
    
    private ubyte[FFFF] ram = 0;

    void clearRam()
    {
        ram[0..$] = 0;
    }

    void insertAt(ushort loc, ubyte value)
    {
        ram[loc] = value;
    }

    void insertAt(int loc, int value)
    in {
        assert(loc <= 0xFFFF && value <= 0xFF);
    } do {
        ram[cast(ushort) loc] = cast(ubyte) value;
    }

    void mapToRange(ushort start, ushort end, RegisterValue value)
    in {
        assert((end-start) % value.sizeof == 0);
    } do {
        mapToRange(cast(ushort) start, cast(ushort) end, [value]);
    } 

    void mapToRange(int start, int end, RegisterValue value)
    in {
        assert(start <= 0xFFFF && end <= 0xFFFF);
    } do {
        mapToRange(cast(ushort) start, cast(ushort) end, value);
    }

    void mapToRange(ushort start, ushort end, RegisterValue[] values)
    in {
        assert((end-start) % values.sizeof == 0);
    } do {
        if(values.length == 1){
            auto t = (cast(ubyte*) &values[0])[0..values[0].sizeof];
            ram[cast(ushort) start..cast(ushort) end] = t[0];
        }
        else {
            ram[cast(ushort) start..cast(ushort) end] = (cast(ubyte*) &values)[0..values.sizeof];
        }
    }

    void mapToRange(int start, int end, RegisterValue[] values)
    in {
        assert(start <= 0xFFFF && end <= 0xFFFF);
    } do {
        mapToRange(cast(ushort) start, cast(ushort) end, values);
    }

    ubyte[] getRange(ushort start, ushort end) return
    {
        return ram[start..end];
    }

    ubyte[] getRange(int start, int end) return
    in {
        assert(start <= 0xFFFF && end <= 0xFFFF);
    } do{
        return getRange(cast(ushort) start, cast(ushort) end);
    }

    ubyte getAt(ushort loc)
    {
        return ram[loc];
    }

    ubyte getAt(int loc)
    in {
        assert(loc <= 0xFFFF);
    } do{
        return ram[cast(ushort) loc];
    }
}

struct Stack {
    
    private RegisterValue[1024] stack;
    private ushort stackPointer = 0;
    private const RegisterValue ZERO = RegisterValue(cast(uint8_t) 0);

    void clearStack()
    {
        stack[0..stackPointer] = ZERO;
        stackPointer = 0;
    }

    void push (RegisterValue value)
    {
        if(stackPointer < 1024)
        {
            stack[stackPointer] = value;
            stackPointer++;
        }
    }

    RegisterValue pop ()
    {
       auto rtn = stack[stackPointer-1];
       stack[stackPointer-1] = ZERO;
       stackPointer--;
       return rtn;
    }

    RegisterValue peek()
    {
        return stack[stackPointer-1];
    }

    void drop()
    {
        stack[stackPointer-1] = ZERO;
        stackPointer--;
    }

    void duplicate()
    {
        if(stackPointer < 1024)
        {
            auto top = stack[stackPointer-1];
            stackPointer++;
            stack[stackPointer-1] = top;
        }
    }

    void swap()
    {
        auto top = stack[stackPointer-1];
        auto second = stack[stackPointer-2];
        //writefln(format("DEBUG: %s, %s", top, second));
        stack[stackPointer-1] = second;
        stack[stackPointer-2] = top;
    }

    ushort getSize()
    {
        return stackPointer;
    }

    void cycleStack(ushort elements, ushort cycles)
    in {
        assert(cycles < elements);
    } do {
        RegisterValue[] buffer = stack[(stackPointer-elements)..(stackPointer)];
        RegisterValue[] temp = array(cycle(buffer).take(elements*2));
        stack[stackPointer-elements..stackPointer] = temp[cycles..elements];
    }

    void flip()
    {
        RegisterValue[] buffer;
        for(int i = stackPointer; i >= 0; i--)
        {
            buffer ~= stack[i];
            writeln(stack[i]);
        }
        //writefln(format("DEBUG: %s", buffer));
        buffer = buffer[1..$];
        stack[0..stackPointer] = buffer;
    }

    string toString() const @safe pure 
    {
        return to!(string)(stack[0..stackPointer]);
    }
    
}


struct Scope {
    
    /* Layout of ptrs should look something like this: 
        uint8_t* b0, b1
        int16_t* w0, w1
        double*  f0, f1
        dchar*   c0, c1
        bool*     x,  y
    */
    uintptr_t[AMT_REGISTERS] ptrs; 
    Registers underlying; 
    /* NOTE: i removed ram and stack from here because
       ram and stack aren't scoped, they're global */

    static Scope create() {
       auto res = Scope();
       res.underlying = Registers();
       res.ptrs[R.b0] = cast(uintptr_t) &res.underlying.b0; 
       res.ptrs[R.b1] = cast(uintptr_t) &res.underlying.b1; 
       res.ptrs[R.w0] = cast(uintptr_t) &res.underlying.w0; 
       res.ptrs[R.w1] = cast(uintptr_t) &res.underlying.w1; 
       res.ptrs[R.f0] = cast(uintptr_t) &res.underlying.f0; 
       res.ptrs[R.f1] = cast(uintptr_t) &res.underlying.f1; 
       res.ptrs[R.c0] = cast(uintptr_t) &res.underlying.c0; 
       res.ptrs[R.c1] = cast(uintptr_t) &res.underlying.c1; 
       res.ptrs[R.x ] = cast(uintptr_t) &res.underlying.x;    
       res.ptrs[R.y ] = cast(uintptr_t) &res.underlying.y;    
       return res;
    }
    void mov(R register, RegisterValue val)
    {
        /* NOTE: this raises an exception on an invalid mov, 
                 which may not be desired behavior. */
        final switch (register) 
        {
            case R.b0, R.b1:
                alias movb = (uint8_t b) { *(cast(uint8_t*) this.ptrs[register]) = b; };
                val.tryMatch!(movb); 
                break;
            case R.w0, R.w1:
                alias movw = (int16_t w) { *(cast(int16_t*) this.ptrs[register]) = w; };
                val.tryMatch!(movw);
                break;
            case R.f0, R.f1:
                alias movf = (double f) { *(cast(double*) this.ptrs[register]) = f; };
                val.tryMatch!(movf);
                break;
            case R.c0, R.c1:
                alias movc = (dchar c) { *(cast(dchar*) this.ptrs[register]) = c; };
                val.tryMatch!(movc);
                break;
            case R.x, R.y:
                alias movx = (bool x) { *(cast(bool*) this.ptrs[register]) = x; };
                val.tryMatch!(movx);
                break;
 
        } 
    }
    
}


void test() {

    auto mainScope = Scope.create();
    RegisterValue fourtwenty = cast(short) 420; 
    //Stack stack = Stack();
    Ram ram = Ram();
    mainScope.mov(R.w0, fourtwenty);
    //writeln(mainScope);
    writeln(ram.getAt(0x4269));
    ram.insertAt( 0x4269, 0xFF);
    writeln(ram.getAt(0x4269));
    ram.clearRam();
    writeln(ram.getRange(0x4261, 0x4269));
    ram.mapToRange(0x4261, 0x4269, [RegisterValue(0xFF)]);
    writeln(ram.getRange(0x4261, 0x4269));
}
