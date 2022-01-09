module parsing.tokens;


private struct TokenType
{
    immutable ubyte id;
    immutable string name;
    

    this(string name, ubyte id)
    {
        this.name = name;
        this.id = id;
    }

}

enum TokenTypes
{
    NULL = TokenType("NULL", 0),
    INCLUDE = TokenType("INCLUDE", 1),
    MAIN_START = TokenType("MAIN_START", 2),
    MAIN_END = TokenType("MAIN_END", 3),
    SUB_DEF = TokenType("SUB_DEF", 4),
    SUB_START = TokenType("MAIN_END", 5),
    SUB_END = TokenType("MAIN_END", 6),
    SUB_NAME = TokenType("SUB_NAME", 7),
    SUB_ARG = TokenType("SUB_ARG", 8),
    SUB_RETURN = TokenType("SUB_RETURN", 9),
    SUB_CALL = TokenType("SUB_CALL", 10),
    RET_CALL = TokenType("RET_CALL", 11),
    INTRINSIC_CALL = TokenType("INTRINSIC_CALL", 12),
    BYTE_REGISTER = TokenType("BYTE_REGISTER", 13),
    WORD_REGISTER = TokenType("WORD_REGISTER", 14),
    CHAR_REGISTER = TokenType("CHAR_REGISTER", 15),
    STRING_REGISTER = TokenType("STRING_REGISTER", 16),
    FILE_REGISTER = TokenType("FILE_REGISTER", 17),
    FLAG_REGISTER = TokenType("FLAG_REGISTER", 18),
    BYTE_LITERAL = TokenType("BYTE_LITERAL", 19),
    WORD_LITERAL = TokenType("WORD_LITERAL", 20),
    CHAR_LITERAL = TokenType("CHAR_LITERAL", 21),
    STRING_LITERAL = TokenType("STRING_LITERAL", 22),
    LABEL = TokenType("LABEL", 23),
    DEC_MARK = TokenType("%", 24),
    HEX_MARK = TokenType("$", 25),
    BIN_MARK = TokenType("&", 26),
    COMMENT_MARK = TokenType(";", 27),
    ARG_FLAG = TokenType("?", 28),
    CHAR_FLAG = TokenType("\'", 29),
    STRING_FLAG = TokenType("\"", 30),
    NUM_FLAG = TokenType("#", 31),
    COLON = TokenType(":", 32),
    LBRACE = TokenType("[", 33),
    RBRACE = TokenType("]", 34)
}