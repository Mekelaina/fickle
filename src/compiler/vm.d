module compiler.vm;

import std.stdio;
import std.stdint;
import std.sumtype;

const AMT_REGISTERS = 10;

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

    static Scope create() {
       auto res = Scope();
       res.underlying = Registers();
       ptrs[R.b0] = &res.underlying.b0; 
       ptrs[R.b1] = &res.underlying.b1; 
       ptrs[R.w0] = &res.underlying.w0; 
       ptrs[R.w1] = &res.underlying.w1; 
       ptrs[R.f0] = &res.underlying.f0; 
       ptrs[R.f1] = &res.underlying.f1; 
       ptrs[R.c0] = &res.underlying.c0; 
       ptrs[R.c1] = &res.underlying.c1; 
       ptrs[R.x ] = &res.underlying.x;    
       ptrs[R.y ] = &res.underlying.y;    
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


void main() {

    auto mainScope = Scope.create();
    mainScope.mov(R.w0, 420);
    writeln(mainScope);


}
