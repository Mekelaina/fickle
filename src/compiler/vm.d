module compiler.vm;

import std.stdio;
import std.stdint;
import std.sumtype;
import std.conv;
import std.array;
import std.range : cycle, take;

const AMT_REGISTERS = 10;
const FFFF = 65_535;

alias RegisterValue = SumType!(
   uint8_t,
   int16_t,
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
    
    private ubyte[FFFF] ram;

    void clearRam()
    {
        ram[0..$] = 0;
    }

    void insertAt(ushort loc, ubyte value)
    {
        mapToRange(loc, loc, RegisterValue(value));
    }

    void mapToRange(ushort start, ushort end, RegisterValue value)
    in {
        assert((end-start) % value.sizeof == 0);
    } do {
            ram[start..end] = (cast(ubyte*) &value)[0..value.sizeof];
    }

    ubyte[] getRange(ushort start, ushort end) return
    {
        return ram[start..end];
    }
}

struct Stack {
    
    private RegisterValue[1024] stack;
    private ushort stackPointer = 0;

    void clearStack()
    {
        stack[0..stackPointer] = RegisterValue(0);
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
       auto rtn = stack[stackPointer];
       stack[stackPointer] = 0;
       stackPointer--;
       return rtn;
    }

    RegisterValue peek()
    {
        return stack[stackPointer];
    }

    void drop()
    {
        stack[stackPointer] = 0;
        stackPointer--;
    }

    void duplicate()
    {
        if(stackPointer < 1024)
        {
            auto top = stack[stackPointer];
            stackPointer++;
            stack[stackPointer] = top;
        }
    }

    void swap()
    {
        auto top = stack[stackPointer];
        stackPointer--;
        auto second = stack[stackPointer];
        stack[stackPointer] = top;
        stackPointer++;
        stack[stackPointer] = second;
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
        int count = 0;
        for(int i = stackPointer; i > 0; i--)
        {
            buffer[count] = stack[i];
            count++;
        }
        stack[0..stackPointer] = buffer[0..stackPointer];
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
            case R.b0:
            case R.b1:
                alias movb = (uint8_t b) { *(cast(uint8_t*) this.ptrs[register]) = b; };
                val.tryMatch!(movb); 
                break;
            case R.w0:
            case R.w1:
                alias movw = (int16_t w) { *(cast(int16_t*) this.ptrs[register]) = w; };
                val.tryMatch!(movw);
                break;
            case R.f0:
            case R.f1:
                alias movf = (double f) { *(cast(double*) this.ptrs[register]) = f; };
                val.tryMatch!(movf);
                break;
            case R.c0:
            case R.c1:
                alias movc = (dchar c) { *(cast(dchar*) this.ptrs[register]) = c; };
                val.tryMatch!(movc);
                break;
            case R.x:
            case R.y:
                alias movx = (bool x) { *(cast(bool*) this.ptrs[register]) = x; };
                val.tryMatch!(movx);
                break;
 
        } 
    }
    
}


void test() {

    auto mainScope = Scope.create();
    RegisterValue fourtwenty = cast(short) 420; 
    mainScope.mov(R.w0, fourtwenty);
    writeln(mainScope);


}
