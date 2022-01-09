module parsing.tokens;


private struct Token
{
    immutable ubyte id;
    immutable string name;
    

    this(string name, ubyte id)
    {
        this.name = name;
        this.id = id;
    }

}

enum Tokens
{
    NULL = Token("NULL", 0),
    TEST = Token("TEST", 1)
}