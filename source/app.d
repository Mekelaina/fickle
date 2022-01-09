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
		bool valid = parseCommands(args);
		//writefln(format("%s", args));
		if(valid)
		{
			setFiles(filesIn);
			//printFiles();
			parseFiles();
		}
	}
}

bool parseCommands(string[] args) 
{	
	arraySep = ",";
	auto userIn = 
	getopt(args, config.bundling,
	 config.passThrough,
	 "run|r", &runPostCompile,
	 "output|o", &fileOut,
	 "files|file|f", &filesIn,
	);

	bool validInFiles = false;

	if(filesIn.length == 1) 
	{
		string f = split(filesIn[0], ".")[1];
		//writefln(format("DEBUG: %s", f));
		if(f == SOURCE_FILE) 
		{
			validInFiles = true;
		}
	} 
	else if (filesIn.length > 1) 
	{
		foreach (string f; filesIn) 
		{
			f = split(f, ".")[1];
			//writefln(format("DEBUG: %s", f));
			if(f == SOURCE_FILE) 
			{
				validInFiles = true;
			}
		}
	}
	else
	{
		writefln("Error: Please provide either a .fkl binary or at least one .fic script file.");
	}
	
	writefln(format("Run: %s, Input: %s, Output: %s", runPostCompile, filesIn, fileOut));
	return validInFiles;
}