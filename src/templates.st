NAMESPACE Simatic.Ax.IOLink

FUNCTION PEEK_WORD : WORD
    VAR_INPUT
        area : WORD;
        dbNumber : INT;
        byteOffset : INT;
    END_VAR
    ;
END_FUNCTION

FUNCTION PEEK_DWORD : DWORD
    VAR_INPUT
        area : WORD;
        dbNumber : INT;
        byteOffset : INT;
    END_VAR
    ;
END_FUNCTION

FUNCTION PEEK : BYTE
    VAR_INPUT
        area : WORD;
        dbNumber : INT;
        byteOffset : INT;
    END_VAR
    ;
END_FUNCTION

FUNCTION PEEK_BOOL : BOOL
    VAR_INPUT
        area : WORD;
        dbNumber : INT;
        byteOffset : INT;
        bitOffset : INT;
    END_VAR
    ;
END_FUNCTION

END_NAMESPACE