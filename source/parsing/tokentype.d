module parsing.tokentype;


private struct TokenType
{
    immutable ubyte id;
    //immutable string name;
    

    this(string name, ubyte id)
    {
        //this.name = name;
        this.id = id;
    }

    this(ubyte id)
    {
        this.id = id;
    }

}

enum TokenTypes: ubyte
{
    /* NULL = TokenType("NULL", 0),
    INCLUDE = TokenType("INCLUDE", 1),
    MAIN_START = TokenType("MAIN_START", 2),
    MAIN_END = TokenType("MAIN_END", 3),
    SUBR_DEF = TokenType("SUBR_DEF", 4),
    SUBR_START = TokenType("SUBR_START", 5),
    SUBR_END = TokenType("SUBR_END", 6),
    SUBR_NAME = TokenType("SUBR_NAME", 7),
    SUBR_ARG = TokenType("SUBR_ARG", 8),
    SUBR_RETURN = TokenType("SUBR_RETURN", 9),
    SUBR_CALL = TokenType("SUBR_CALL", 10),
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
    REGISTER_MARK = TokenType("!", 27),
    COMMENT_MARK = TokenType(";", 28),
    ARG_FLAG = TokenType("?", 29),
    CHAR_FLAG = TokenType("\'", 30),
    STRING_FLAG = TokenType("\"", 31),
    NUM_FLAG = TokenType("#", 32),
    COLON = TokenType(":", 33),
    LBRACE = TokenType("[", 34),
    RBRACE = TokenType("]", 35),
    COMMA = TokenType(",", 36) */

    NULL = 0,
    INCLUDE = 1,
    MAIN_START = 2,
    MAIN_END = 3,
    SUBR_DEF = 4,
    SUBR_START = 5,
    SUBR_END = 6,
    SUBR_NAME = 7,
    SUBR_ARG = 8,
    SUBR_RETURN = 9,
    SUBR_CALL = 10,
    RET_CALL = 11,
    INTRINSIC_CALL = 12,
    BYTE_REGISTER = 13,
    WORD_REGISTER = 14,
    CHAR_REGISTER = 15,
    STRING_REGISTER = 16,
    FILE_REGISTER = 17,
    FLAG_REGISTER = 18,
    BYTE_LITERAL = 19,
    WORD_LITERAL = 20,
    CHAR_LITERAL = 21,
    STRING_LITERAL = 22,
    LABEL = 23,
    DEC_MARK = 24,
    HEX_MARK = 25,
    BIN_MARK = 26,
    REGISTER_MARK = 27,
    COMMENT_MARK = 28,
    ARG_FLAG = 29,
    CHAR_FLAG = 30,
    STRING_FLAG = 31,
    NUM_FLAG = 32,
    COLON = 33,
    LBRACE = 34,
    RBRACE = 35,
    COMMA = 36,
    COMMENT_TEXT = 37
}