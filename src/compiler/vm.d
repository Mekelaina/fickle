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

    ubyte[] getRange(ushort start, ushort end)
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

    RegisterValue peak()
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
        RegisterValue buffer = stack[(stackPointer-elements)..(stackPointer)];
        RegisterValue temp = cycle(buffer).take(elements*2);
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
    
    /*
    uint8_t* b0, b1;
    int16_t* w0, w1;
    double*  f0, f1;
    dchar*   c0, c1;
    bool*     x,  y;
    */
    uintptr_t[AMT_REGISTERS] ptrs; 
    Registers underlying; 
    Ram ram = Ram();
    Stack stack = Stack();

    static Scope create() {
       auto res = Scope();
       res.underlying = Registers();
       this.ptrs[R.b0] = &res.underlying.b0; 
       this.ptrs[R.b1] = &res.underlying.b1; 
       this.ptrs[R.w0] = &res.underlying.w0; 
       this.ptrs[R.w1] = &res.underlying.w1; 
       this.ptrs[R.f0] = &res.underlying.f0; 
       this.ptrs[R.f1] = &res.underlying.f1; 
       this.ptrs[R.c0] = &res.underlying.c0; 
       this.ptrs[R.c1] = &res.underlying.c1; 
       this.ptrs[R.x ] = &res.underlying.x;    
       this.ptrs[R.y ] = &res.underlying.y;    
       return res;
    }
    void mov(R register, RegisterValue val)
    {
        final switch (register) 
        {
            case R.b0:
            case R.b1:
                val.match!(
                    (uint8_t b) => { *this.ptrs[register] = b; },
                    _ => { writeln("Error: invalid mov"); exit(1); }
                );
                break;
            case R.w0:
            case R.w1:
                val.match!(
                    (int16_t w) => { *this.ptrs[register] = w; },
                    _ => { writeln("Error: invalid mov"); exit(1); }
                );
                break;
            case R.f0:
            case R.f1:
                val.match!(
                    (double f) => { *this.ptrs[register] = f; },
                    _ => { writeln("Error: invalid mov"); exit(1); }
                );
                break;
            case R.c0:
            case R.c1:
                val.match!(
                    (dchar c) => { *this.ptrs[register] = c; },
                    _ => { writeln("Error: invalid mov"); exit(1); }
                );
                break;
            case R.x:
            case R.y:
                val.match!(
                    (bool x) => { *this.ptrs[register] = x; },
                    _ => { writeln("Error: invalid mov"); exit(1); }
                );
                break;
 
       } 
    }
    
}


void test() {

    auto mainScope = Scope.create();
    mainScope.mov(R.w0, 420);
    writeln(mainScope);


}
