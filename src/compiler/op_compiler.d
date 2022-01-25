module compiler.op_compiler;

import std.stdio;
import std.array;
import std.format;
import std.conv;
import std.algorithm.searching;
import std.bitmanip;
import std.utf;
import std.string;

import parsing.tokenizer;
import parsing.tokentype;
import machine.vm;
import util.convert;
import compiler;

enum Intrinsics : string
{
    NULL = "",
    MOV = "mov",
    PRT = "prt",
    INP = "inp",
    ADD = "add",
    SUB = "sub",
    MUL = "mul",
    DIV = "div",
    MOD = "mod",
    LSL = "lsl",
    LSR = "lsr",
    ASL = "asl",
    ASR = "asr",
    LCL = "lcl",
    LCR = "lcr",
    ACL = "acl",
    ACR = "acr",
    AND = "and",
    OR  =  "or",
    XOR = "xor",
    NOT = "not",
    NEG = "neg",
    PSH = "psh",
    POP = "pop",
    DUP = "dup",
    SWP = "swp",
    DRP = "drp",
    CYL = "cyl",
    PEK = "pek",
    FLP = "flp",
    SIZ = "siz",
    IF  =  "if",
    JMP = "jmp",
    RET = "ret",
    CLR = "clr",
    BND = "bnd",
    INC = "inc"
}

enum Register {
    NULL,
    b0, b1,
    w0, w1,
    p0, p1,
    f0, f1,
    c0, c1,
    s0, s1,
     x,  y
}

enum Literal {
    NULL,
    BYTE,
    WORD,
    //POINTER,
    DOUBLE,
    CHAR,
    STRING,
    BOOL
}

struct Compiler
{
    alias Script = Token[];

    ubyte[] program;
    Script[] scripts;

    void addScript(Script _script)
    {
        scripts ~= _script;
    }

    void test()
    {
        double d = 65.43;
        auto b = uShortToBytes(d);
        double nd = bytesToDouble(b);
        writeln(nd);
        //writefln(format("%(%02X%)", uShortToBytes(d)));
    }

    ubyte[] compile()
    {
        //writefln(format("prt_bytelit: %x, prt_wordlit: %x, prt_doublelit: %x, prt_charlit: %x",
         //   Opcode.PRT_BYTELIT, Opcode.PRT_WORDLIT, Opcode.PRT_DOUBLELIT, Opcode.PRT_CHARLIT));
        auto script = scripts[0];
        program ~= uShortToBytes(Opcode.BOUND);
        Intrinsics currentIntrinsic = Intrinsics.NULL;
        Register currentRegister = Register.NULL;
        Literal currentLiteral = Literal.NULL;
        string currentValue;

        foreach (Token token; script)
        {
            switch(token.type)
            {
                case TokenType.MAIN_START:
                    program ~= uShortToBytes(Opcode.MAIN_START);
                break;
                case TokenType.MAIN_END:
                    program ~= uShortToBytes(Opcode.MAIN_END);
                break;
                case TokenType.INTRINSIC_CALL:
                    switch(token.value.text)
                    {
                        case Intrinsics.MOV:
                            currentIntrinsic = Intrinsics.MOV;
                        break;
                        case Intrinsics.PRT:
                            currentIntrinsic = Intrinsics.PRT;
                        break;
                        default:
                        break;
                    }
                break;
                case TokenType.STRING_REGISTER:
                    switch(token.value.text)
                    {
                        case "s0":
                            currentRegister = Register.s0;
                        break;
                        case "s1":
                            currentRegister = Register.s1;
                        break;
                        default:
                            //TODO: ERROR for incorrect string register
                        break;
                    }
                break;
                case TokenType.STRING_LITERAL:
                    currentLiteral = Literal.STRING;
                    currentValue = token.value.text[1..$-1];
                break;
                case TokenType.BYTE_LITERAL:
                    currentLiteral = Literal.BYTE;
                    currentValue = token.value.text[0..$];
                break;
                case TokenType.COMMA, TokenType.COMMENT:
                    continue;
                break;
                default:
                    //TODO: sdfg
                break;
            }

            switch(currentIntrinsic) //make final eventually
            {
                case Intrinsics.NULL:
                break;
                case Intrinsics.MOV:
                    final switch(currentRegister)
                    {
                        case Register.NULL:
                            final switch(currentLiteral)
                            {
                                case Literal.NULL:
                                break;
                                case Literal.STRING:
                                break;
                                case Literal.BYTE:
                                break;
                                case Literal.WORD:
                                break;
                                case Literal.DOUBLE:
                                break;
                                case Literal.CHAR:
                                break;
                                case Literal.BOOL:
                                break;
                                //case Literal.POINTER:
                                //break;
                            }
                        break;
                        case Register.s0:
                            final switch(currentLiteral)
                            {
                                case Literal.NULL:
                                break;
                                case Literal.STRING:
                                    program ~= uShortToBytes(Opcode.MOV_STRREG_LIT);
                                    program ~= cast(ubyte) 0;
                                    program ~= currentValue;
                                    program ~= cast(ubyte) 0x00;
                                    currentIntrinsic = Intrinsics.NULL;
                                    currentRegister = Register.NULL;
                                    currentLiteral = Literal.NULL;
                                    currentValue = "";
                                break;
                                case Literal.BYTE:
                                break;
                                case Literal.WORD:
                                break;
                                //case Literal.POINTER:
                                //break;
                                case Literal.DOUBLE:
                                break;
                                case Literal.CHAR:
                                break;
                                case Literal.BOOL:
                                break;
                            }
                        break;
                        case Register.s1:
                        break;
                        case Register.b0:
                        break;
                        case Register.b1:
                        break;
                        case Register.p0:
                        break;
                        case Register.p1:
                        break;
                        case Register.w0:
                        break;
                        case Register.w1:
                        break;
                        case Register.f0:
                        break;
                        case Register.f1:
                        break;
                        case Register.c0:
                        break;
                        case Register.c1:
                        break;
                        case Register.x:
                        break;
                        case Register.y:
                        break;
                    }
                break;
                case Intrinsics.PRT:
                    final switch(currentRegister)
                    {
                        case Register.NULL:
                            if(currentValue != "")
                            {
                                string x = currentValue[1..$];
                                dstring t = x.toUTF32;
                                switch(currentValue[0])
                                {
                                    case '%':
                                        if(canFind(currentValue,"."))
                                        {
                                            program ~= uShortToBytes(Opcode.PRT_DOUBLELIT);
                                            program ~= uShortToBytes(parse!double(t));
                                            currentIntrinsic = Intrinsics.NULL;
                                            currentValue = "";
                                        }
                                        else if (canFind(currentValue, "-") && !canFind(currentValue, "."))
                                        {
                                            int temp = parse!int(t);
                                            if(temp >= short.min && temp <= short.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            //TODO: error report
                                        }
                                        else
                                        {

                                            int temp = parse!int(t);

                                            if(temp >= ubyte.min && temp <= ubyte.max)
                                            {

                                                program ~= uShortToBytes(Opcode.PRT_BYTELIT);
                                                auto a = cast(ubyte) temp;
                                                program ~= a;
                                                //writeln(a);
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else if(temp >= short.min && temp <= short.max)
                                            {
                                                //writeln("eggu");
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else
                                            {
                                                //TODO: error report
                                            }
                                        }
                                    break;
                                    case '$':
                                        if(canFind(currentValue,"."))
                                        {
                                            program ~= uShortToBytes(Opcode.PRT_DOUBLELIT);
                                            int buf = parse!int(t);
                                            program ~= uShortToBytes(to!double(buf));
                                            currentIntrinsic = Intrinsics.NULL;
                                            currentValue = "";
                                        }
                                        else if (canFind(currentValue, "-") && !canFind(currentValue, "."))
                                        {
                                            int temp = parse!int(t, 16);
                                            if(temp >= short.min && temp <= short.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t, 16));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            //TODO: error report
                                        }
                                        else
                                        {
                                            int temp = parse!int(t, 16);
                                            if(temp >= ubyte.min && temp <= ubyte.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_BYTELIT);
                                                program ~= parse!ubyte(t, 16);
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else if(temp >= short.min && temp <= short.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t, 16));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else
                                            {
                                                //TODO: error report
                                            }
                                        }
                                    break;
                                    case '&':
                                        if(canFind(currentValue,"."))
                                        {
                                            program ~= uShortToBytes(Opcode.PRT_DOUBLELIT);
                                            double buf = parse!double(t);
                                            program ~= uShortToBytes(buf);
                                            currentIntrinsic = Intrinsics.NULL;
                                            currentValue = "";
                                        }
                                        else if (canFind(currentValue, "-") && !canFind(currentValue, "."))
                                        {
                                            int temp = parse!int(t);
                                            if(temp >= short.min && temp <= short.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t, 2));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            //TODO: error report
                                        }
                                        else
                                        {
                                            int temp = parse!int(t);
                                            if(temp >= ubyte.min && temp <= ubyte.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_BYTELIT);
                                                program ~= uShortToBytes(parse!byte(t, 2));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else if(temp >= short.min && temp <= short.max)
                                            {
                                                program ~= uShortToBytes(Opcode.PRT_WORDLIT);
                                                program ~= uShortToBytes(parse!short(t, 2));
                                                currentIntrinsic = Intrinsics.NULL;
                                                currentValue = "";
                                            }
                                            else
                                            {
                                                //TODO: error report
                                            }
                                        }
                                    break;
                                    case '\"':

                                    break;
                                    default:
                                        program ~= uShortToBytes(Opcode.PRT_STRLIT);
                                        program ~= currentValue;
                                        program ~= cast(ubyte) 0;
                                        currentValue = "";
                                        currentIntrinsic = Intrinsics.NULL;
                                    break;
                                }
                            }
                        break;
                        case Register.s0, Register.s1:
                            program ~= uShortToBytes(Opcode.PRT_STRREG);
                            program ~= currentRegister == Register.s0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.b0, Register.b1:
                            program ~= uShortToBytes(Opcode.PRT_BYTEREG);
                            program ~= currentRegister == Register.b0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.w0, Register.w1:
                            program ~= uShortToBytes(Opcode.PRT_WORDREG);
                            program ~= currentRegister == Register.w0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.p0, Register.p1:
                            program ~= uShortToBytes(Opcode.PRT_PTRREG);
                            program ~= currentRegister == Register.p0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.f0, Register.f1:
                            program ~= uShortToBytes(Opcode.PRT_DOUBLEREG);
                            program ~= currentRegister == Register.f0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.c0, Register.c1:
                            program ~= uShortToBytes(Opcode.PRT_CHARREG);
                            program ~= currentRegister == Register.c0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.x, Register.y:
                            program ~= uShortToBytes(Opcode.PRT_BOOLREG);
                            program ~= currentRegister == Register.x ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                    }
                break;
                default:
                break;
            }
        }
        program ~= uShortToBytes(Opcode.BOUND);

        return program;
    }


}
