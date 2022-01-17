module parsing.tokenizer;

import std.algorithm;
import std.utf;
import std.uni;
import std.stdio;
import std.conv;
import std.stdint;
import std.format;
import std.string;

import core.stdc.stdlib; 

import parsing.tokentype;
import parsing.parser;
import util.convert;

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
  bool inNumLiteral = false;
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
    else if(inNumLiteral)
    {
      if(part.length==1)
      {
        branchesExecuted++;
      }
      else if(part.length > 1)
      {
        branchesExecuted++;
        
      }
      else if(part.length > 1 && isWhite(c))
      {
        branchesExecuted++;
        acc ~= Quote(part, file, linenum, col-part.toUTF32.length);
      }
    } 
    else if (inComment)
    {
      branchesExecuted++;
      /* character is fine, just add it to `part` */
    }
    else if(c == '%' || c == '$' || c == '&')
    {
      branchesExecuted++;
      inNumLiteral = true;
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


bool isNumLiteral(string s) 
{
  //s = s[1..$-2];
  if(s[0] == '%' || s[0] == '$' || s[0] == '&')
  {
    writeln(s);
    auto x = s[1..$-1];
    switch(s[0])
    {
      
      case '%':
        try
        {
            parse!int(x);
            return true;
        } 
        catch (ConvException e)
        {
            return false;
        }
      break;
      case '$':
        try
        {
            parse!int(x, 16);
            return true;
        } 
        catch (ConvException e)
        {
            return false;
        }
      break;
      case '&':
        try
        {
            parse!int(x, 2);
            return true;
        } 
        catch (ConvException e)
        {
            return false;
        }
      break;
      default:
      return false;
      break;
    }
  }
  else
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

int getNumType(string s)
{
  auto x = s[1..$];
  dstring dx = x.toUTF32;
  auto buf = 0;
  if(s[0] == '%')
  {
    try{
      buf = parse!int(dx);
    } catch(ConvException e){

    }
  }
  else if(s[0] == '$')
  {
    try {
      buf = parse!int(dx, 16);
    } catch(ConvException e) {

    }
  }
  else 
  {
    try{
      buf = parse!int(dx, 2);
    } catch(ConvException e){

    }
  }
  bool hasDecimal = canFind(x, '.');
  bool isNegative = canFind(x, '-');
  bool isByteRange = (buf >= ubyte.min && buf <= ubyte.max) ? true : false;
  writeln(x.length);
  bool isPointerRange =  (x.length == 4);
  writefln(format("%s, %s, %s, %s", hasDecimal, isNegative, isByteRange, isPointerRange));
  
  switch(s[0])
  {
    case '%':
      if(hasDecimal)
      {
        try
        {
          parse!double(x);  
          return 3;
        } 
        catch (ConvException e)
        {
            return -3;
        }
      }
      else if(isNegative || (!hasDecimal && !isByteRange))
      {
        try
        {
          parse!short(x);
          return 2;
        }
        catch (ConvException e)
        {
          return -2;
        }
      }
      else
      {
        try
        {
          auto t = parse!ubyte(x);
          return 1;
        }
        catch (ConvException e)
        {
          writeln(e);
          return -1;
        }
      }
    break;
    case '$':
      if(hasDecimal)
      {
        try
        {
          parse!double(x);  
          return 6;
        } 
        catch (ConvException e)
        {
            return -6;
        }
      }
      else if(!hasDecimal && (isNegative || (!isByteRange || isPointerRange)))
      {
        if(isPointerRange)
        {
          try
          {
            parse!ushort(x, 16);
            return 10;
          }
          catch (ConvException e)
          {
            return -10;
          }
        }
        else 
        {
          try
          {
            parse!short(x, 16);
            return 5;
          }
          catch (ConvException e)
          {
            return -5;
          }
        }
      }
      else
      {
        try
        {
          parse!ubyte(x, 16);
          return 4;
        }
        catch (ConvException e)
        {
          return -4;
        }
      }
    break;
    case '&':
      bool siz = (x.length==16 && x[0] == '0');
      if(hasDecimal)
      {
        try
        {
          parse!double(x);  
          return 9;
        } 
        catch (ConvException e)
        {
            return -9;
        }
      }
      else if(!hasDecimal && (isNegative || (!isByteRange || isPointerRange) ))
      {
        if(siz)
        {
          try
          {
            parse!short(x, 2);
            return 8;
          }
          catch (ConvException e)
          {
            return -8;
          }
        }
        else
        {
          try
          {
            parse!ushort(x, 2);
            return 11;
          }
          catch (ConvException e)
          {
            return -11;
          }
        }
      }
      else
      {
        try
        {
          parse!ubyte(x, 2);
          return 7;
        }
        catch (ConvException e)
        {
          return -7;
        }
      }
    break;
    default:
      return 0;
    break;
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
      else if (isNumLiteral(part.text))
      {
        int t = getNumType(part.text);
        final switch(t)
        {
          case -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0:
            writeln("Error: invalid number literal: ", t, " -- ", part.text);
            exit(1);
          break;
          case 1, 4, 7:
            acc ~= Token(part, TokenType.BYTE_LITERAL);
          break;
          case 2, 5, 8:
            acc ~= Token(part, TokenType.WORD_LITERAL);
          break;
          case 3, 6, 9:
            acc ~= Token(part, TokenType.FLOAT_LITERAL);
          break;
          case 10, 11:
            acc ~= Token(part, TokenType.POINTER_LITERAL);
          break;
        }
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
      else if (isNumLiteral(part.text))
      {
        writeln(part);
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


