import std.stdio;
import std.format;
import std.getopt;
import std.array;
import parsing;

string[] filesIn;
string fileOut = "foo.fkl";
bool runPostCompile = false;

const string SOURCE_FILE = "fic";
const string BINARY_FILE = "fkl";

void main(string[] args) 
{
	if(args.length > 1) 
	{
		parseCommands(args);
		bool valid = areFilesInvalid(filesIn);

		if(valid)
		{
			setFiles(filesIn);
			parseFiles();
		}
	}
}

bool areFilesInvalid(string[] files)
{
	bool invalidInFiles = false;
    foreach (string f; filesIn) 
    {
        f = split(f, ".")[1];
        //writefln(format("DEBUG: %s", f));
        if(f != SOURCE_FILE) 
        {
            invalidInFiles = true;
            break;
        }
    }
    if(invalidInFiles || filesIn.length == 0) 
    {
        writefln("Error: Please provide either a .fkl binary or at least one .fic script file.");
        return false;
    }
    writefln(format("Run: %s, Input: %s, Output: %s", runPostCompile, filesIn, fileOut));
    return true;
}

void parseCommands(string[] args) 
{	
	arraySep = ",";
	auto userIn = 
	getopt(args, config.bundling,
	 config.passThrough,
	 "run|r", &runPostCompile,
	 "output|o", &fileOut,
	 "files|file|f", &filesIn,
	);
}