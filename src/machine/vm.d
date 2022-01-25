module machine.vm;

import std.stdio;
import std.stdint;
import std.sumtype;
import std.conv;
import std.array;
import std.range.primitives;
import std.range : cycle, take;
import std.format;
import std.traits;

import compiler.opcode;
import util.convert;


const AMT_REGISTERS = 14;
const FFFF = 0xFFFF;

const RegisterValue emptyByte   = RegisterValue(cast(ubyte) 0);
const RegisterValue emptyWord   = RegisterValue(cast(short) 0);
const RegisterValue emptyPtr    = RegisterValue(cast(ushort) 0);
const RegisterValue emptyDouble = RegisterValue(double.nan);
const RegisterValue emptyChar   = RegisterValue(cast(dchar) '\uFFFF');
const RegisterValue emptyString = RegisterValue(cast(string) "");
const RegisterValue emptyBool   = RegisterValue(false);

alias RegisterValue = SumType!(
   uint8_t,
   int16_t,
   uint16_t,
   double,
   dchar,
   string,
   bool
);

enum R {
    b0, b1,
    w0, w1,
    p0, p1,
    f0, f1,
    c0, c1,
    s0, s1,
     x,  y
}

struct Registers {
    uint8_t  b0, b1;
    int16_t  w0, w1;
    uint16_t p0, p1;
    double   f0, f1;
    dchar    c0, c1;
    string   s0, s1;
    bool      x,  y;

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
        insertAt(cast(ushort) loc, cast(ubyte) value);
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
        /* writefln(format("%s, %s, %s, %s, %s, %s", stackPointer-elements, stackPointer, 
            cycles-1, elements, temp, temp[1..4])); */
        stack[(stackPointer-elements)..stackPointer] = temp[cycles-1..elements+1];
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
       res.ptrs[R.p0] = cast(uintptr_t) &res.underlying.p0;
       res.ptrs[R.p1] = cast(uintptr_t) &res.underlying.p1; 
       res.ptrs[R.f0] = cast(uintptr_t) &res.underlying.f0; 
       res.ptrs[R.f1] = cast(uintptr_t) &res.underlying.f1; 
       res.ptrs[R.c0] = cast(uintptr_t) &res.underlying.c0; 
       res.ptrs[R.c1] = cast(uintptr_t) &res.underlying.c1;
       res.ptrs[R.s0] = cast(uintptr_t) &res.underlying.s0;
       res.ptrs[R.s1] = cast(uintptr_t) &res.underlying.s1; 
       res.ptrs[R.x ] = cast(uintptr_t) &res.underlying.x;    
       res.ptrs[R.y ] = cast(uintptr_t) &res.underlying.y;    
       return res;
    }

    //======= mov methods ========\\
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
            case R.p0, R.p1:
                alias movp = (uint16_t p) {*(cast(uint16_t*) this.ptrs[register]) = p; };
                val.tryMatch!(movp);
                break;
            case R.f0, R.f1:
                alias movf = (double f) { *(cast(double*) this.ptrs[register]) = f; };
                val.tryMatch!(movf);
                break;
            case R.c0, R.c1:
                alias movc = (dchar c) { *(cast(dchar*) this.ptrs[register]) = c; };
                val.tryMatch!(movc);
                break;
            case R.s0, R.s1:
                alias movs = (string s) { *(cast(string*) this.ptrs[register]) = s; };
                val.tryMatch!(movs);
                break;
            case R.x, R.y:
                alias movx = (bool x) { *(cast(bool*) this.ptrs[register]) = x; };
                val.tryMatch!(movx);
                break;
 
        } 
    }

    void mov(R registerTo, R registerFrom)
    {
        final switch(registerFrom)
        {
            case R.b0, R.b1:
                uint8_t b = *(cast(uint8_t*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(b));
                break;
            case R.w0, R.w1:
                int16_t w = *(cast(int16_t*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(w));
                break;
            case R.p0, R.p1:
                uint16_t p = *(cast(uint16_t*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(p));
                break;
            case R.f0, R.f1:
                double d = *(cast(double*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(d));
                break;
            case R.c0, R.c1:
                dchar c = *(cast(dchar*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(c));
                break;
            case R.s0, R.s1:
                string s = *(cast(string*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(s));
                break;
            case R.x, R.y:
                bool l = *(cast(bool*) this.ptrs[registerFrom]);
                mov(registerTo, RegisterValue(l));
                break;

        }
    }

    void mov(R register, int address, Ram ram)
    in {
        assert(address <= FFFF);
    } do {
        mov(register, cast(ushort) address, ram);
    }

    void mov(R register, ushort address, Ram ram)
    {
        auto val = ram.ram[address];
        mov(register, RegisterValue(val));
    } 
    
    //======= prt methods =======\\

    void prt(R register)
    {
        //writeln(register);
        writeln(*(cast(string*) this.ptrs[register]));
    }

    void prt(string s)
    {
        write(s);
    }

    void prt(ubyte b)
    {
        write(b);
    }

    //====== bnd methods =======\\

    void bnd(R register, uint8_t* ptr)
    {
        if (register == R.b0 || register == R.b1)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;     
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-byte register to byte ptr"); 
        }

    }

    void bnd(R register, int16_t* ptr)
    {
        if (register == R.w0 || register == R.w1)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;     
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-word register to word ptr"); 
        }

    }
   
    void bnd(R register, double* ptr)
    {
        if (register == R.f0 || register == R.f1)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;     
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-float register to float ptr"); 
        }

    }

    void bnd(R register, dchar* ptr)
    {
        if (register == R.c0 || register == R.c1)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;     
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-char register to char ptr"); 
        }

    }

    void bnd(R register, string* ptr)
    {
        if (register == R.s0 || register == R.s1)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-string register to string ptr"); 
        }
    }

    void bnd(R register, bool* ptr)
    {
        if (register == R.x || register == R.y)
        {
            this.ptrs[register] = cast(uintptr_t) ptr;     
        }
        else {
            throw new Exception("invalid bnd, cannot bind non-bool register to bool ptr"); 
        }

    }

    //======= clr methods =======\\

    void clr(R register)
    {
        final switch(register)
        {
            case R.b0:
                mov(R.b0, emptyByte);
                break;
            case R.b1:
                mov(R.b1, emptyByte);
                break;
            case R.w0:
                mov(R.w0, emptyWord);
                break;
            case R.w1:
                mov(R.w1, emptyWord);
                break;
            case R.p0:
                mov(R.p0, emptyPtr);
                break;
            case R.p1:
                mov(R.p1, emptyPtr);
                break;
            case R.f0:
                mov(R.f0, emptyDouble);
                break;
            case R.f1:
                mov(R.f1, emptyDouble);
                break;
            case R.c0:
                mov(R.c0, emptyChar);
                break;
            case R.c1:
                mov(R.c1, emptyChar);
                break;
            case R.s0:
                mov(R.s0, emptyString);
                break;
            case R.s1:
                mov(R.s1, emptyString);
                break;
            case R.x:
                mov(R.x, emptyBool);
                break;
            case R.y:
                mov(R.y, emptyBool);
                break;
        }
    }
 
    void clr()
    {
        foreach (register; EnumMembers!R)
        {
            clr(register);
        }
    }
}

void executeProgram(ubyte[] program)
{
    auto mainScope = Scope.create();
    Ram ram = Ram();
    Stack stack = Stack();
    int pc = 0;
    bool run = true;
    ushort currentOp;
    //writeln(program.length);
    do
    {
        //WTF is this????
        //writeln(program);
        //ushort x = toShort([program[0], program[1]]);
        currentOp = byteToUShort([program[pc], program[++pc]]);
        //writefln(format("pc: %s, op: %x",pc, x));
        pc++;
        //writeln(pc);
        //writefln(format("%x", currentOp));
        switch(currentOp)
        {
            case Opcode.BOUND:
                
                if(pc == (cast(int) program.length - 1))
                {
                    run = false;
                }
                continue;
                break;
            case Opcode.MAIN_START:
                continue;
                break;
            case Opcode.MAIN_END:
                continue;
                break;
            case Opcode.MOV_STRREG_LIT:
                //writeln(currentOp);
                auto reg = program[pc++];
                string value;
                ubyte current;
                do 
                {
                    current = program[pc++];
                    value ~= current;
                } while(current != 0);
                //writeln(reg);
                //writeln("a");
                mainScope.mov(reg == 0 ? R.s0 : R.s1, RegisterValue(value));
                //pc++;
                //writeln(mainScope);
                break;
            case Opcode.MOV_BYTEREG_LIT:
                auto reg = program[pc++];
                auto value = program[pc++];
                mainScope.mov(reg == 0 ? R.b0 : R.b1, RegisterValue(value));
                break;
            case Opcode.MOV_WORDREG_LIT:
                auto reg = program[pc++];
                auto value = [program[pc++], program[pc++]];
                mainScope.mov(reg == 0 ? R.w0 : R.w1, RegisterValue(byteToShort(value)));
                break;
            case Opcode.MOV_DOUBLEREG_LIT:
                auto reg = program[pc++];
                auto value = program[pc..pc+8];
                pc += 8;
                mainScope.mov(reg == 0 ? R.f0 : R.f1, RegisterValue(byteToDouble(value)));
                break;
            case Opcode.MOV_POINTERREG_LIT:
                auto reg = program[pc++];
                auto value = [program[pc++], program[pc++]];
                mainScope.mov(reg == 0 ? R.w0 : R.w1, RegisterValue(byteToUShort(value)));
                break;
            case Opcode.MOV_CHARREG_LIT:
                auto reg = program[pc++];
                break;
            case Opcode.MOV_BOOLREG_LIT:
                break;
            case Opcode.PRT_STRLIT:
                string value;
                ubyte current;
                do 
                {
                    current = program[pc++];
                    value ~= current;
                } while(current != 0);
                mainScope.prt(value);
                break;
            case Opcode.PRT_STRREG:
                auto reg = program[pc++];
                //writefln(format("DEBUG: %s", reg));
                mainScope.prt(reg == 0 ? R.s0 : R.s1);
                break;
            case Opcode.PRT_BYTELIT:
                //writeln("zoop");
                ubyte b = program[pc++];
                //writeln(b);
                mainScope.prt(b);
                break;
            case Opcode.PRT_BYTEREG:
                auto reg = program[pc++];
                mainScope.prt(reg == 0 ? R.b0 : R.b1);
                break;
            case Opcode.PRT_WORDLIT:
                auto w = [program[pc++], program[pc++]];
                mainScope.prt(byteToShort(w));
                break;
            case Opcode.PRT_WORDREG:
                auto reg = program[pc++];
                mainScope.prt(reg == 0 ? R.w0 : R.w1);
                break;
            default:
                break;
        }
        //writeln(pc);
    } while(pc+1 < program.length);
}

void testVM() {

    auto mainScope = Scope.create();
    Ram ram = Ram();
    Stack stack = Stack();

    RegisterValue fourtwenty = cast(short) 65;
    RegisterValue haha = cast(ushort) 0xFFFF; 
    mainScope.mov(R.w0, fourtwenty);
    mainScope.mov(R.p0,haha);
    writeln(mainScope);
    mainScope.clr();
    writeln(mainScope);
    /* //writeln(mainScope);
    mainScope.mov(R.p0, haha);    
    auto anotherScope = Scope.create();
    mainScope.mov(R.s0, cast(RegisterValue) cast(string) "hello");
    anotherScope.bnd(R.w1, cast(int16_t*) mainScope.ptrs[R.w1]);
    anotherScope.mov(R.w1, cast(RegisterValue) cast(short) 69);
    
    writeln(mainScope);
    writeln(haha);

    ram.insertAt(0x4269, 0xFF);
    mainScope.mov(R.b0, 0x4269, ram);

    stack.push(cast(RegisterValue) cast(ubyte) 0);
    stack.push(cast(RegisterValue) cast(ubyte) 1);
    stack.push(cast(RegisterValue) cast(ubyte) 2);
    writeln(stack);
    stack.cycleStack(cast(ushort) 3, 2);
    writeln(stack); */
    //writeln(mainScope);

    

}
