module compiler.tokenizer;

import std.algorithm;
import std.utf;
import std.uni;
import std.stdio;
import std.conv;
import std.stdint;

import core.stdc.stdlib; 

import compiler.tokentype;
import compiler.parser;

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

const string[] SUBR_ARGS = 
[

    /* stack expectations. nothing is passed into these functions, just values
       are pushed onto the stack and popped off by these functions */
    "s", "b", "w", "f", "a", "x", "y", "c", "i", "o",
    /* args which push a ptr passed in onto the stack */
    "s!", "b!", "w!", "f!", "a!", "x!", "y!", "c!", "i!", "o!",
    /* args which dereference a ptr passed in and push the value on the stack */
    "s?", "b?", "w?", "f?", "a?", "x?", "y?", "c?", "i?", "o?",
];

immutable struct Quote
{
  string text;
  string file;
  uint linenum;
  uint col;
  /* TODO: end position may be needed. add a lil method for this if so */
}

immutable struct Token
{
  Quote value;
  TokenType type;
}

Quote[] splitByTokenBoundaries(string file, uint linenum, string line)
{
  bool escapeSequence = false;
  bool inStringLiteral = false;
  bool inComment = false;
  bool inCharLiteral;
  Quote[] acc = [];
  string part;
  uint col = 0;
  dstring dline = line.toUTF32;
  foreach (dchar c ; dline) { 
    /* it is a bug to be in an escape sequence and outside of a string literal */
    assert(!(escapeSequence && !inStringLiteral));
    /* it is a bug to be in a comment and in a string literal */
    assert(!(inComment && inStringLiteral));
    /* it is a bug to be in an escape sequence and in a comment */
    assert(!(inComment && escapeSequence));
    /* it is a bug to be in a char literal and in a string literal */
    assert(!(inCharLiteral && inStringLiteral));
    /* it is a bug to be in a char literal and in a comment */
    assert(!(inCharLiteral && inComment));
    /* TODO: remove branchesExecuted. it is for debugging purposes only. */
    int branchesExecuted = 0; 
    if (inStringLiteral)
    { 
      if (escapeSequence)
      {
        if (c == 'n') {
           branchesExecuted++;
           part ~= '\n';
           col++; 
           escapeSequence = false;
           continue;
        } else {
          branchesExecuted++;
          escapeSequence = false;
          /* character is fine, just add it to `part` */
        } 
         
      }
      else if (c == '\\')
      {
        branchesExecuted++;
        escapeSequence = true;
        col++; 
        continue;
      }
      else if (c == '\"')
      {
        branchesExecuted++;
        part ~= c;
        col++; 
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        inStringLiteral = false;
  
        continue;
      }
      else
      {
        branchesExecuted++;
        /* character is fine, just add it to `part` */
      }
    }
    else if (inCharLiteral)
    {
      if (part.length == 1)
      {
        branchesExecuted++;
        /* character is fine, just add it to `part` */
      } 
      else if (part.length == 2 && c == '\'')
      {
        branchesExecuted++;
        part ~= c;
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        inCharLiteral = false;
        col++; 
        continue;
      }
      else
      {
        branchesExecuted++;
        /* TODO: improve error handling: add quote to the error and don't exit */
        writeln("Error: unclosed char literal");
        writeln("Note: char literals do not support escape sequences. There must be");
        writeln("      only 1 utf-8 encoded character between open single quote and");
        writeln("      closing single quote.");
        exit(1); 
      }
    } 
    else if (inComment)
    {
      branchesExecuted++;
      /* character is fine, just add it to `part` */
    }
    else if (c == ';')
    {
      /* inComment never gets set back to false because the comment consumes the entire rest of the line */ 
      branchesExecuted++;
      inComment = true;
    }
    else if (c == '\'')
    {
      branchesExecuted++;
      inCharLiteral = true; 
    }
    else if (c == '\"')
    {
      branchesExecuted++;
      inStringLiteral = true;
    }
    else if (c == ',')
    {
      if (part != "") 
      {
        branchesExecuted++;
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        part ~= c;
        col++; 
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        continue;
      }
      else
      {
        branchesExecuted++;
        /* character is fine, just add it to `part` */ 
      }
    }
    else if (c == ':')
    {
      if (part != "") 
      {
        branchesExecuted++;
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        part ~= c;
        col++; 
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
        part = "";
        continue;
      }
      else
      {
        branchesExecuted++;
        /* character is fine, just add it to `part` */ 
      }
    }
    else if (c.isWhite())
    {
      branchesExecuted++;
      if (part != "")
      {
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
      }
      part = "";
      col++; 
      continue;
    }
    else
    {
      branchesExecuted++;
      /* character is fine, just add it to `part` */
    }
    assert(branchesExecuted == 1);
    part ~= c;
    col++; 
  }
  if (inStringLiteral)
  {
    /* TODO: improve error handling: add quote to the error and don't exit */
    writeln("Error: Unclosed string literal");
    exit(1); 
  }
  if (inCharLiteral)
  {
    /* TODO: improve error handling: add quote to the error and don't exit */
    writeln("Error: unclosed char literal");
    writeln("Note: char literals do not support escape sequences. There must be");
    writeln("      only 1 utf-8 encoded character between open single quote and");
    writeln("      closing single quote.");
    exit(1); 
  }
  if (part != "") 
  {
    acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
  }
  return acc;
}

void testSplitByTokenBoundaries() {
  string testLine; 
  
  testLine = "  prn \"Hello, world\\\"\" ; Print hello world and stuff ";  
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "mov s0, \"ok;)\"";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "add w0,w1  ";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "sub w0 , w1";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "fic";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "def 🧨🧨🎃";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "; test \"string\" in comment! ";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "; test \'c\' in comment! ";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "    mov c0,'a', 'b'";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  testLine = "  mov s0, \"string";
  writeln("INPUT:  `", testLine, "`");
  writeln("OUTPUT: ", splitByTokenBoundaries("", 0, testLine));
  
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
    else 
    {
        /* it would be a bug if we have an unclosed string literal at this point */
        assert(!((s[0] != '\"' && s[$-1] == '\"') || (s[0] == '\"' && s[$-1] != '\"')));
        return false;
    }
}


public Token[] tokenize(Script script)
{
  Token[] acc = [];

  foreach (uint linenum, string line; script.fileContent)
  {
    Quote[] parts = splitByTokenBoundaries(script.fileName, linenum, line);
    foreach (Quote part; parts)
    {
      if (part.text == MAIN_START)
      {
        acc ~= Token(part, TokenType.MAIN_START);
      }
      else if (part.text == MAIN_END)
      {
        acc ~= Token(part, TokenType.MAIN_END);
      }
      else if (part.text == SUBR_DEF)
      {
        acc ~= Token(part, TokenType.SUBR_DEF);
      }
      else if (BUILTINS.canFind(part.text))
      {
        acc ~= Token(part, TokenType.INTRINSIC_CALL);
      }
      else if (script.subroutines.map!(subroutine => subroutine.name)
                                 .canFind(part.text) 
               && acc[$-1].type != TokenType.SUBR_DEF)
      {
        acc ~= Token(part, TokenType.SUBR_CALL);
      }
      else if (script.subroutines.map!(subroutine => subroutine.name)
                                 .canFind(part.text) 
               && acc[$-1].type == TokenType.SUBR_DEF)
      {
        acc ~= Token(part, TokenType.SUBR_NAME);
      }
      else if (acc[$-1].type == TokenType.SUBR_NAME
               && SUBR_ARGS.canFind(part.text))
      {
        acc ~= Token(part, TokenType.SUBR_ARG);
      }
      else if (part.text[0] == ';')
      {
        acc ~= Token(part, TokenType.COMMENT);
      }
      else if (part.text == ",")
      {
        acc ~= Token(part, TokenType.COMMA);
      }
      else if (part.text == ":")
      {
        acc ~= Token(part, TokenType.COLON);
      }
      else if (isRegister(part.text) > 0)
      {
        final switch(isRegister(part.text))
        {
          case 0:
            break;
          case 1:
            acc ~= Token(part, TokenType.BYTE_REGISTER);
            break;
          case 2:
            acc ~= Token(part, TokenType.WORD_REGISTER); 
            break;
          case 3:
            acc ~= Token(part, TokenType.FLOAT_REGISTER); 
            break;
          case 4: 
            acc ~= Token(part, TokenType.CHAR_REGISTER); 
            break;
          case 5:
            acc ~= Token(part, TokenType.STRING_REGISTER); 
            break;
          case 6:
            acc ~= Token(part, TokenType.FLAG_REGISTER); 
            break;
          case 7:
            acc ~= Token(part, TokenType.FILE_REGISTER);
            break;
      
        }                                             
      
      }
      else if (isStringLiteral(part.text))
      {
        acc ~= Token(part, TokenType.STRING_LITERAL);
      }
      else
      {
        writeln("Error: unrecognized token ", part);
        exit(1);
      }
    }
  }
  return acc;
}








// public Token[] tokenizeScript(Script script)
// {
//     Token[] tokens;
//     string[] knownSubroutines;
//     
//     for(uint line = 0; line < script.lines; line++)
//     {
//        auto currentline = script.fileContent[line];
//        currentline ~= " "; 
//         /* append a space to the end of the line. this 
//            is a dirty patch for a a bug we have here. 
//            as we go through the characters in a line, we
//            only collect multi-character tokens after finding
//            whitespace. if a multi-character token is not
//            followed by whitespace (is the case at the 
//            end of the line, because \n is removed somewhere
//            in the process of getting `fileContent`.)
//           
//            BUG: collecting multichar tokens fails at EOL
//         */
//         string current = "";
// 
//         for(int cha = 0; cha < currentline.length; cha++)
//         {
//             char c = currentline[cha];
//             if(!isWhite(c))
//             {
//                 switch(c)
//                 {
//                     case ';':
//                         tokens ~= Token(line, cha, cha, TokenType.COMMENT_MARK, [c]);
//                         break;
//                     case '%':
//                         tokens ~= Token(line, cha, cha, TokenType.DEC_MARK, [c]);
//                         break;
//                     case '$':
//                         tokens ~= Token(line, cha, cha, TokenType.HEX_MARK, [c]);
//                         break;
//                     case '&':
//                         tokens ~= Token(line, cha, cha, TokenType.BIN_MARK, [c]);
//                         break;
//                     case '!':
//                         tokens ~= Token(line, cha, cha, TokenType.REGISTER_MARK, [c]);
//                         break;
//                     case '#':
//                         tokens ~= Token(line, cha, cha, TokenType.NUM_FLAG, [c]);
//                         break;
//                     case '?':
//                         tokens ~= Token(line, cha, cha, TokenType.ARG_FLAG, [c]);
//                         break;
//                     case '@':
//                         tokens ~= Token(line, cha, cha, TokenType.LABEL, [c]);
//                         break;
//                     case '[':
//                         tokens ~= Token(line, cha, cha, TokenType.LBRACE, [c]);
//                         break;
//                     case ']':
//                         tokens ~= Token(line, cha, cha, TokenType.RBRACE, [c]);
//                         break;
//                     case ',':
//                         tokens = secondCheck(line, cha, current, currentline, knownSubroutines, tokens);
//                         current = "";
//                         tokens ~= Token(line, cha, cha, TokenType.COMMA, [c]);
//                         
//                         break;
//                     case ':':
//                         tokens ~= Token(line, cha, cha, TokenType.COLON, [c]);
//                         break;
//                     default:
//                         current ~= c;
//                         break;
//                 } 
//             }
//             else
//             {
//                 tokens = secondCheck(line, cha, current, currentline, knownSubroutines, tokens);
//                 current = "";
//             }
//         }
//     
//     }
//     return tokens;
// }
// 
// /*
// * This is a hacky way to solve a bug with the special chars that
// * are used for things but are not seperated by a whitespace.
// * can thus call the check when one of those chars is encountered to
// * enusre the token before it is processed correctly.
// * TODO: refactor to make this not needed.
// */
// Token[] secondCheck(int line, int cha, string current, 
// string currentline, string[] knownSubroutines, Token[] tokens)
// {
//     switch(current)
//     {
//         case "":
//             /* multiple whitespace in succession
//                 generates empty `current`, skip
//                 these cases */
//             break;
//         case MAIN_START:
//             tokens ~= Token(
//                 line, cha-MAIN_START.length, cha-1, 
//                 TokenType.MAIN_START, current);
//             break;
//         case MAIN_END:
//             tokens ~= Token(
//                 line, cha-MAIN_END.length, cha-1,
//                 TokenType.MAIN_END, current);
//             break;
//         case SUBR_DEF:
//             tokens ~= Token(
//                 line, cha-SUBR_DEF.length, cha-1,
//                 TokenType.SUBR_DEF, current);
//             break;
//         case INC_BUILTIN:
//             tokens ~= Token(
//                 line, cha-INC_BUILTIN.length, cha-1,
//                 TokenType.INCLUDE, current);
//             break;
//         default:
//             if(canFind(BUILTINS, current))
//             {
//                 tokens ~= Token(
//                     line, cha-current.length, cha-1,
//                     TokenType.INTRINSIC_CALL, current);
//             }
//             else if (isWordLiteral(current))
//             {
//                 tokens ~= Token(
//                     line, cha-current.length, cha-1,
//                     TokenType.WORD_LITERAL, current);
//             }
//             else if(isRegister(current) > 0)
//             {
//                 final switch(isRegister(current))
//                 {
//                     case 0:
//                         break;
//                     case 1:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.BYTE_REGISTER, current);
//                         break;
//                     case 2:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.WORD_REGISTER, current);
//                         break;
//                     case 3:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.FLOAT_REGISTER, current);
//                         break;
//                     case 4:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.CHAR_REGISTER, current);
//                         break;
//                     case 5:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.STRING_REGISTER, current);
//                         break;
//                     case 6:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.FLAG_REGISTER, current);
//                         break;
//                     case 7:
//                         tokens ~= Token(
//                             line, cha-current.length, cha-1,
//                             TokenType.FILE_REGISTER, current);
//                         break;
// 
//                 }                                             
//             }
//             else if(isStringLiteral(current))
//             {
//                 tokens ~= Token(
//                     line, cha-current.length, cha-1,
//                     TokenType.STRING_LITERAL, current);
//             }
//             /* TODO: Add elifs here to handle multi-char tokens. */
//             else 
//             {
//                 writefln("Error: unrecognized token %s", current);
//                 
//             }
//             //break;
// 
//         
// 
//             //TODO: finish tokenizing based on previous token here
//             Token prevTok = tokens[$-1];
//             string currentScope =  "";
// 
//             switch(prevTok.type)
//             {
//                 case TokenType.SUBR_DEF:
//                     tokens ~= Token(
//                     line, cha-current.length, cha-1,
//                     TokenType.SUBR_NAME, current);
//                     currentScope = current;
//                     break;
//                 case TokenType.SUBR_NAME:
//                     if(prevTok.loc.line == line)
//                     {
//                         tokens ~= Token(
//                         line, cha-current.length, cha-1,
//                         TokenType.SUBR_ARG, current);
//                         currentScope = current;
//                         knownSubroutines ~= current; 
//                     }
//                     break;
//                 case TokenType.COMMENT_MARK:
//                     tokens ~= Token(
//                     line, cha-current.length, cha-1,
//                     TokenType.COMMENT_TEXT, 
//                     currentline[prevTok.loc.startLoc+1..$-1]);
//                     break;
// 
//                 default:
//                     break;
//             }
//             break;
//     }
// 
//     return tokens;
// }

