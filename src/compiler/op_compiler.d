module compiler.op_compiler;

import std.stdio;
import std.array;
import std.format;
import std.conv;

import parsing.tokenizer;
import parsing.tokentype;
import machine.vm;
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
    f0, f1,
    c0, c1,
    s0, s1,
     x,  y
}

enum Literal {
    NULL,
    BYTE,
    WORD,
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

    void compile()
    {
        auto script = scripts[0];
        program ~= toBytes(Opcode.BOUND);
        Intrinsics currentIntrinsic = Intrinsics.NULL;
        Register currentRegister = Register.NULL;
        Literal currentLiteral = Literal.NULL;
        string currentValue;

        foreach (Token token; script)
        {
            switch(token.type)
            {
                case TokenType.MAIN_START:
                    program ~= toBytes(Opcode.MAIN_START);
                break;
                case TokenType.MAIN_END:
                    program ~= toBytes(Opcode.MAIN_END);
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
                case TokenType.COMMA:
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
                            }
                        break;
                        case Register.s0:
                            final switch(currentLiteral)
                            {
                                case Literal.NULL:
                                break;
                                case Literal.STRING:
                                    program ~= toBytes(Opcode.MOV_STRREG_LIT);
                                    program ~= cast(ubyte) 0;
                                    program ~= currentValue;
                                    currentIntrinsic = Intrinsics.NULL;
                                    currentRegister = Register.NULL;
                                    currentLiteral = Literal.NULL;
                                    currentValue = "";
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
                            }
                        break;
                        case Register.s1:
                        break;
                        case Register.b0:
                        break;
                        case Register.b1:
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
                        break;
                        case Register.s0, Register.s1:
                            program ~= toBytes(Opcode.PRT_STRREG);
                            program ~= currentRegister == Register.s0 ? cast(ubyte) 0 : cast(ubyte) 1;
                            currentIntrinsic = Intrinsics.NULL;
                            currentRegister = Register.NULL;
                        break;
                        case Register.b0, Register.b1:
                        break;
                        case Register.w0, Register.w1:
                        break;
                        case Register.f0, Register.f1:
                        break;
                        case Register.c0, Register.c1:
                        break;
                        case Register.x, Register.y:
                        break;
                    }
                break;
                default:
                break;
            }   
        }
        program ~= toBytes(Opcode.BOUND);

        writefln(format("%(%02X%)", program));
    }

    ubyte[] toBytes(ushort toCon)
    {
        return [cast(ubyte) toCon, cast(ubyte) (cast(ushort) (toCon >> 8))];
    }

    ushort toShort(ubyte[] toCon)
    {
        ushort ret = cast(ushort) toCon[1];
        //writeln(ret);
        ret = cast(ushort) (ret << 8);
        ret += toCon[0];
        return ret;
    }
}