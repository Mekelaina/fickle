module parsing.tokenizer;

import std.algorithm;
import std.uni;
import std.stdio;
import std.conv;
import std.stdint;

import parsing.tokentype;
import parsing.parser;

const string MAIN_START = "fic";
const string MAIN_END = "kle";
const string SUBR_DEF = "def";
const string INC_BUILTIN = "inc";
const string[] BUILTINS = 
[   "mov","prt","inp","add","sub","mul","div","mod","lsl","lsr","asl",
    "asr","lcl","lcr","acl","acr","and","or","xor","not","neg","psh","pop",
    "dup","swp","drp","cyl","pek","flp","siz","if","jmp","ret","clr","cmp"
];

const string[] REGISTERS = 
[
    "s0", "s1", "b0", "b1", "w0", "w1", "f0", "f1", "a0", "a1", "x", "y", "c", "i", "o"
];

struct Token
{
    Location loc;
    TokenTypes type;
    string value;

    /*
    * this constructor is only here to solve a bug wihen trying to get the start loc
    * of a token bc the length of an array is stored as a ulong not an int.
    * we sould probably convert the value when creating the token, but i didnt
    * want to chnge all that atm, so adding this niche contructor that converts
    * the troublesome value is a dirty but quick fix.
    */
    this(int line, ulong startLoc, int endLoc, TokenTypes type, string value)
    {
        this(Location(line, cast(int) startLoc, endLoc), type, value);
    }

    this(int line, int startLoc, int endLoc, TokenTypes type, string value)
    {
        this(Location(line, startLoc, endLoc), type, value);
    }
    
    this(Location loc, TokenTypes type, string value)
    {
        this.loc = loc;
        this.type = type;
        this.value = value;
    }
}

bool isWordLiteral(string s) 
{
    try
    {
        s.parse!int16_t();
        return true;
    } 
    catch (ConvException e)
    {
        return false;
    }
}

int isRegister(string s)
{
    int rtn = -1;
    if(canFind(REGISTERS, s))
    {
        switch(s)
        {
            case "b0", "b1":
                rtn = 1;
                break;
            case "w0", "w1":
                rtn = 2;
                break;
            case "f0", "f1":
                rtn = 3;
                break;
            case "a0", "a1":
                rtn = 4;
            case "s0", "s1":
                rtn = 5;
                break;
            case "x", "y", "c":
                rtn = 6;
                break;
            case "i", "o":
                rtn = 7;
                break;
            default:
                rtn = 0;
                break;
        }
    }
    return rtn;
    
}

bool isStringLiteral(string s)
{
    if(s[0] == '\"' && s[$-1] == '\"')
    {
        return true;
    }
    else if((s[0] != '\"' && s[$-1] == '\"') || (s[0] == '\"' && s[$-1] != '\"'))
    {
        writefln("ERROR: unclosed string literal `%s`", s);
        return false;
    }
    else 
    {
        return false;
    }
}

struct Location
{
    int line;
    int startLoc;
    int endLoc;
    

    this(int line, int startLoc, int endLoc)
    {
        this.line = line;
        this.startLoc = startLoc;
        this.endLoc = endLoc;
    }
}

public Token[] tokenizeScript(Script script)
{
    Token[] tokens;
    string[] knownSubroutines;
    
    for(int line = 0; line < script.lines; line++)
    {
       auto currentline = script.fileContent[line];
       currentline ~= " "; 
        /* append a space to the end of the line. this 
           is a dirty patch for a a bug we have here. 
           as we go through the characters in a line, we
           only collect multi-character tokens after finding
           whitespace. if a multi-character token is not
           followed by whitespace (is the case at the 
           end of the line, because \n is removed somewhere
           in the process of getting `fileContent`.)
          
           BUG: collecting multichar tokens fails at EOL
        */
        string current = "";

        for(int cha = 0; cha < currentline.length; cha++)
        {
            char c = currentline[cha];
            if(!isWhite(c))
            {
                switch(c)
                {
                    case ';':
                        tokens ~= Token(line, cha, cha, TokenTypes.COMMENT_MARK, [c]);
                        break;
                    case '%':
                        tokens ~= Token(line, cha, cha, TokenTypes.DEC_MARK, [c]);
                        break;
                    case '$':
                        tokens ~= Token(line, cha, cha, TokenTypes.HEX_MARK, [c]);
                        break;
                    case '&':
                        tokens ~= Token(line, cha, cha, TokenTypes.BIN_MARK, [c]);
                        break;
                    case '!':
                        tokens ~= Token(line, cha, cha, TokenTypes.REGISTER_MARK, [c]);
                        break;
                    case '#':
                        tokens ~= Token(line, cha, cha, TokenTypes.NUM_FLAG, [c]);
                        break;
                    case '?':
                        tokens ~= Token(line, cha, cha, TokenTypes.ARG_FLAG, [c]);
                        break;
                    case '@':
                        tokens ~= Token(line, cha, cha, TokenTypes.LABEL, [c]);
                        break;
                    case '[':
                        tokens ~= Token(line, cha, cha, TokenTypes.LBRACE, [c]);
                        break;
                    case ']':
                        tokens ~= Token(line, cha, cha, TokenTypes.RBRACE, [c]);
                        break;
                    case ',':
                        tokens = secondCheck(line, cha, current, currentline, knownSubroutines, tokens);
                        current = "";
                        tokens ~= Token(line, cha, cha, TokenTypes.COMMA, [c]);
                        
                        break;
                    case ':':
                        tokens ~= Token(line, cha, cha, TokenTypes.COLON, [c]);
                        break;
                    default:
                        current ~= c;
                        break;
                } 
            }
            else
            {
                tokens = secondCheck(line, cha, current, currentline, knownSubroutines, tokens);
                current = "";
            }
        }
    
    }
    return tokens;
}

/*
* This is a hacky way to solve a bug with the special chars that
* are used for things but are not seperated by a whitespace.
* can thus call the check when one of those chars is encountered to
* enusre the token before it is processed correctly.
* TODO: refactor to make this not needed.
*/
Token[] secondCheck(int line, int cha, string current, 
string currentline, string[] knownSubroutines, Token[] tokens)
{
    switch(current)
    {
        case "":
            /* multiple whitespace in succession
                generates empty `current`, skip
                these cases */
            break;
        case MAIN_START:
            tokens ~= Token(
                line, cha-MAIN_START.length, cha-1, 
                TokenTypes.MAIN_START, current);
            break;
        case MAIN_END:
            tokens ~= Token(
                line, cha-MAIN_END.length, cha-1,
                TokenTypes.MAIN_END, current);
            break;
        case SUBR_DEF:
            tokens ~= Token(
                line, cha-SUBR_DEF.length, cha-1,
                TokenTypes.SUBR_DEF, current);
            break;
        case INC_BUILTIN:
            tokens ~= Token(
                line, cha-INC_BUILTIN.length, cha-1,
                TokenTypes.INCLUDE, current);
            break;
        default:
            if(canFind(BUILTINS, current))
            {
                tokens ~= Token(
                    line, cha-current.length, cha-1,
                    TokenTypes.INTRINSIC_CALL, current);
            }
            else if (isWordLiteral(current))
            {
                tokens ~= Token(
                    line, cha-current.length, cha-1,
                    TokenTypes.WORD_LITERAL, current);
            }
            else if(isRegister(current) > 0)
            {
                final switch(isRegister(current))
                {
                    case 0:
                        break;
                    case 1:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.BYTE_REGISTER, current);
                        break;
                    case 2:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.WORD_REGISTER, current);
                        break;
                    case 3:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.FLOAT_REGISTER, current);
                        break;
                    case 4:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.CHAR_REGISTER, current);
                        break;
                    case 5:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.STRING_REGISTER, current);
                        break;
                    case 6:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.FLAG_REGISTER, current);
                        break;
                    case 7:
                        tokens ~= Token(
                            line, cha-current.length, cha-1,
                            TokenTypes.FILE_REGISTER, current);
                        break;

                }
            }
            else if(isStringLiteral(current))
            {
                tokens ~= Token(
                    line, cha-current.length, cha-1,
                    TokenTypes.STRING_LITERAL, current);
            }
            /* TODO: Add elifs here to handle multi-char tokens. */
            else 
            {
                writefln("Error: unrecognized token %s", current);
                
            }
            //break;

        

            //TODO: finish tokenizing based on previous token here
            Token prevTok = tokens[$-1];
            string currentScope =  "";

            switch(prevTok.type)
            {
                case TokenTypes.SUBR_DEF:
                    tokens ~= Token(
                    line, cha-current.length, cha-1,
                    TokenTypes.SUBR_NAME, current);
                    currentScope = current;
                    break;
                case TokenTypes.SUBR_NAME:
                    if(prevTok.loc.line == line)
                    {
                        tokens ~= Token(
                        line, cha-current.length, cha-1,
                        TokenTypes.SUBR_ARG, current);
                        currentScope = current;
                        knownSubroutines ~= current; 
                    }
                    break;
                case TokenTypes.COMMENT_MARK:
                    tokens ~= Token(
                    line, cha-current.length, cha-1,
                    TokenTypes.COMMENT_TEXT, 
                    currentline[prevTok.loc.startLoc+1..$-1]);
                    break;

                default:
                    break;
            }
            break;
    }

    return tokens;
}
