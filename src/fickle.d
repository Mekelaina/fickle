module fickle;

import std.stdio: writefln, writeln;
import std.format;
import std.getopt;
import std.array;
import core.stdc.stdlib;
import std.algorithm.searching;
import std.file;

import compiler;
import parsing;
import machine;


struct CLInput
{
    string[] filesIn;    /* no default, required */
    string fileOut;      /* Default "foo.fkl */
    bool runPostCompile; /* Default false */
    bool isBinary;       /* Default false*/

    static CLInput defaults()
    {
        return CLInput([], "", false, false);
    }

    static CLInput parseCommands(string[] args) 
    {    
        CLInput res = CLInput.defaults();
        GetoptResult optRes; 
        arraySep = ",";
        try
        {
            optRes = getopt(
                args,
                config.bundling,
                "run|r", &res.runPostCompile,
                "output|o", &res.fileOut,
                config.required, 
                "files|file|f", &res.filesIn,
            );
        }
        catch (GetOptException e)
        {
            usage(args[0]);
            writeln("Error: ", e.msg);
            exit(1);
        }
        if (optRes.helpWanted)
        {
          usage(args[0]);
          exit(0);
        }
 
        validateInput(res);
        return res;
    }
}

void usage(string programName)
{ 
    writeln(format("USAGE: %s <args>", programName));
    writeln("    where <args> is one or more of the following:");
    writeln("        -r | --run            run the binary generated by");
    writeln("                              compilation to fickle bytecode.");
    writeln("                              /* default: false */");
    writeln("");
    writeln("        -o <output> |         name the binary <output>.");
    writeln("        --out <output>        /* default: foo.fkl */");
    writeln("");
    writeln("        -f <input> |          where <input> is one or");
    writeln("        --file <input> |      more fickle source files.");
    writeln("        --files <input>       /* required */");
    writeln("");
    writeln("        -h | --help           print this help.");
    writeln("");
} 

const string SOURCE_FILE = "fic";
const string BINARY_FILE = "fkl";



void main(string[] args) 
{    
    auto clin = CLInput.parseCommands(args);
    //writeln(clin);
    ubyte[] program;
    //writeln(clin);
    if(clin.isBinary)
    {
        program = cast(ubyte[])read(clin.filesIn[0]);
        //program = (cast(ubyte*) &i)[0..i.sizeof];
    }
    else 
    {
        Script[] scripts = parseFiles(clin.filesIn);
        //writeln(scripts);
        Token[] tokens = tokenize(scripts[0]);
        //writeln(tokens);
        Compiler compiler = Compiler();
        compiler.addScript(tokens);
        program = compiler.compile();
        //writeln("loop zoop");
    }
    
    if(clin.fileOut != "")
    {
        string buf = split(clin.fileOut, "\\")[$-1];
        string ext;
        if(canFind(buf, "."))
        {
            ext = split(buf, ".")[1];
        }
        else
        {
            ext = buf;
        }

        string name = (ext == BINARY_FILE) ? clin.fileOut : (clin.fileOut ~= ".fkl");
        if(exists(name))
        {
            write(name, program);
        }
        else
        {
            append(name, program);
        }
    }
    
    if(clin.runPostCompile)
    {
        writefln(format("%(%02X%)", program));
        machine.executeProgram(program);
    }
    //writefln(format("%(%02X%)",program));
    

    //machine.test();
}


/*
 * TODO: consider removing this function.
 * checking if the file extension is correct
 * may not be a good behavior. for example,
 * if someone were to make a fickle source
 * file with a shebang into an executable, 
 * they would likely remove the extension.
 * generally, extensions should be seen as
 * annotations/suggestions rather than rules. 
 * if a `.txt` file's content is valid
 * fickle source, should we reject to compile it?
 * maybe remove this? maybe add a flag to disable it?
 */
void validateInput(ref CLInput clin)
in {
     /* there is a bug in CLInput.parseCommands
        if clin.filesIn is empty. */
     assert(clin.filesIn.length > 0); 
} do { 
    // TODO: consider using map-reduce here to validate
    // rather than manual for loop for cleaner code
    bool invalidInFiles = false;
    foreach (string f; clin.filesIn) 
    {
        string buf = split(f, "\\")[$-1];
        string ext = split(buf, ".")[1];
        //writeln(ext);
        if (ext == BINARY_FILE)
        {
            clin.isBinary = true;
            clin.runPostCompile = true;
            break;
        }
        else if (ext == SOURCE_FILE)
        {
            break;
        }
        else
        {
            invalidInFiles = true;
            break;
        }
    }

    if (invalidInFiles)  
    {
        writeln("Error: Invalid input file(s): please provide a `.fic` fickle source file.");
        exit(1); 
    }
}




