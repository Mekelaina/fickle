module parsing.tokenizer;

import std.algorithm;
import std.ascii;

import parsing.tokentype;
import parsing.parser;

const string MAIN_START = " fic";
const string MAIN_END = "kle";
const string SUBR_DEF = "def";
const string INC_BUILTIN = "inc";
const string[] BUILTINS = ["mov","prt","inp","add","sub","mul","div","mod","lsl","lsr","asl",
    "asr","lcl","lcr","acl","acr","and","or","xor","not","neg","psh","pop",
    "dup","swp","drp","cyl","pek","flp","siz","if","jmp","ret","clr","cmp"
];


struct Token
{
    Location loc;
    TokenTypes type;
    string value;

    this(short line, short startLoc, short endLoc, TokenTypes type, string value)
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

struct Location
{
    short startLoc;
    short endLoc;
    short line;

    this(short line, short startLoc, short endLoc)
    {
        this.line = line;
        this.startLoc = startLoc;
        this.endLoc = endLoc;
    }
}

public Token[] tokenizeScript(Script script)
{
    Token[] tokens;
    //int[] knownLines = getLines(script);
    

    for(int line = 0; line < script.lines; line++)
    {
        auto currentline = script.fileContent[line];
        string current = "";

        for(int cha = 0; cha < currentline.length; cha++)
        {
            char c = currentline[cha];
            if(!isWhite(c))
            {
                switch(c)
                {
                    case ';':
                        tokens ~= Token(line, cha, cha, TokenTypes.COMMENT_MARK, c);
                        break;
                    case '%':
                        tokens ~= Token(line, cha, cha, TokenTypes.DEC_MARK, c);
                        break;
                    case '$':
                        tokens ~= Token(line, cha, cha, TokenTypes.HEX_MARK, c);
                        break;
                    case '&':
                        tokens ~= Token(line, cha, cha, TokenTypes.BIN_MARK, c);
                        break;
                    case '!':
                        tokens ~= Token(line, cha, cha, TokenTypes.REGISTER_MARK, c);
                        break;
                    case '%':
                        tokens ~= Token(line, cha, cha, TokenTypes.DEC_MARK, c);
                        break;
                    case '#':
                        tokens ~= Token(line, cha, cha, TokenTypes.NUM_FLAG, c);
                        break;
                    case '?':
                        tokens ~= Token(line, cha, cha, TokenTypes.ARG_FLAG, c);
                        break;
                    case '@':
                        tokens ~= Token(line, cha, cha, TokenTypes.LABEL, c);
                        break;
                    case '[':
                        tokens ~= Token(line, cha, cha, TokenTypes.LBRACE, c);
                        break;
                    case ']':
                        tokens ~= Token(line, cha, cha, TokenTypes.RBRACE, c);
                        break;
                    case ',':
                        tokens ~= Token(line, cha, cha, TokenTypes.COMMA, c);
                        break;
                    case ':':
                        tokens ~= Token(line, cha, cha, TokenTypes.COLON, c);
                        break;
                    default:
                        current ~= c;
                        break;
                } 
            }
            else
            {
                switch(current)
                {
                    case MAIN_START:
                        tokens ~= Token(
                            line, cha-MAIN_START.length-1, cha-1, 
                            TokenTypes.MAIN_START, current);
                        break;
                    case MAIN_END:
                        tokens ~= Token(
                            line, cha-MAIN_END.length-1, cha-1,
                            TokenTypes.MAIN_END, current);
                        break;
                    case SUBR_DEF:
                        tokens ~= Token(
                            line, cha-SUBR_DEF.length-1, cha-1,
                            TokenTypes.SUBR_DEF, current);
                        break;
                    case INC_BUILTIN:
                        tokens ~= Token(
                            line, cha-INC_BUILTIN.length-1, cha-1,
                            TokenTypes.INCLUDE, current);
                        break;
                    default:
                        if(canFind(BUILTINS, current))
                        {
                            tokens ~= Token(
                                line, cha-current.length-1, cha-1,
                                TokenTypes.INTRINSIC_CALL, current);
                        }
                        break;

                        //TODO: finish tokenizing based on previous token here
                }

                current = "";
            }

        }
    
    }

    return tokens;
}