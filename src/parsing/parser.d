module parsing.parser;

import std.stdio;
import std.conv;
import std.format;
import std.typecons;
import std.algorithm;
import std.array;
import std.ascii;

import parsing.tokentype;

alias CodeBlock = Tuple!(string, "name", int, "startLine", int, "endLine");

Script[] parseFiles(string[] files)
{
    Script[] acc = [];
    acc ~= Script(files[0], true); 
    /* TODO: add to specification and documentation that 
       first file provided is assumed to be main file */
    files.remove(0);
    foreach (string file; files) {
        acc ~= Script(file, false);
    }
    return acc;
    
}

struct Script
{
    string fileName;
    bool mainFile;
    string[] fileContent;
    size_t lines;
    CodeBlock mainRoutine;
    bool hasSubroutines;
    CodeBlock[] subroutines;
    size_t subroutine_count;

    this(string fileName, bool mainFile)
    {
        this.fileName = fileName;
        this.mainFile = mainFile;
        this.fileContent = readFile(fileName);
        this.lines = this.fileContent.length;
        this.mainRoutine = mainFile ? findMainRoutine(fileContent) : CodeBlock("main", -1, -1);
        this.hasSubroutines = mainFile ? checkForSubroutines(fileContent) : true;
        this.hasSubroutines = checkForSubroutines(fileContent);
        this.subroutines = findSubroutines(fileContent);
        this.subroutine_count = this.subroutines.length;
    }

    private CodeBlock[] findSubroutines(string[] fileContent)
    {
        CodeBlock[] sr;
        string name = "";
        int start, end = -1;

        for(int line = 0; line < fileContent.length; line++)
        {
            auto sub = fileContent[line].findSplit("def");
            
            if(name == "")
            {
                if(sub[0].empty && !sub[1].empty)
                {
                    start = line;
                    auto subdef = sub[2].split();
                    name = subdef[0];
                }
            }
            else
            {
                sub = fileContent[line].findSplit(name);
                if(!sub[1].empty)
                {
                    end = line;

                    sr ~= CodeBlock(name, start, end);
                    name = "";
                    start = -1;
                    end = -1;
                }
            }
        }

        return sr;
    } 

    private bool checkForSubroutines(string[] fileContent)
    {
        bool foundSubroutines = false;

        foreach (string line; fileContent)
        {
            auto sub = line.findSplit("def");
            
            if(sub[0].empty && !sub[1].empty)
            {
                foundSubroutines = true;
                break;
            }
        }

        return foundSubroutines;
    }

    private CodeBlock findMainRoutine(string[] fileContent)
    {
        bool validblock = false;
        CodeBlock main = CodeBlock("main", -1, -1);

        for (int line = 0; line < fileContent.length; line++)
        {
            auto start = fileContent[line].findSplit("fic");
            auto end = fileContent[line].findSplit("kle");

            if(!start[1].empty)
            {
                main.startLine = line;
            } else if (!end[1].empty)
            {
                main.endLine = line;
                break;
            }
        }
        if(main.startLine != -1 && main.endLine != -1)
        {
            validblock = true;
        }

        return validblock ? main : CodeBlock("main", -1, -1);
    }

    private string[] readFile(string fileName)
    {
        string[] buffer;

        foreach (line; File(fileName, "r").byLine)
        {
            buffer ~= line.to!string;
        }
        
        return buffer;
    }
}
