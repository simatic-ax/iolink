NAMESPACE Simatic.Ax.IOLink
TYPE

    HW_IO  : Word (default := WORD#0);
    HW_ANY : Word (default := WORD#0);
END_TYPE

FUNCTION Chars_TO_Strg
    USING Simatic.Ax.Conversion.Arrays;
    VAR_INPUT
        Chars : ARRAY[*] OF BYTE;
        pChars : INT;
        Cnt : UINT;
    END_VAR
    VAR_OUTPUT
        Strg : STRING;
    END_VAR
    VAR_TEMP
        start : DINT;
        end : DINT;
        loop : DINT;
        chararray : ARRAY[0..255] OF CHAR;
    END_VAR

    start := LOWER_BOUND(Chars, 1);
    end := UPPER_BOUND(Chars, 1);

    FOR loop := start TO end DO
        chararray[loop] := TO_CHAR(Chars[loop]);
    END_FOR;
        Strg := ToString(arr := chararray, startIdx := pChars, endIdx := pChars + TO_INT(Cnt));

END_FUNCTION

FUNCTION Strg_TO_Chars
    USING Simatic.Ax.Conversion.Strings.ToArray;
    VAR_INPUT
        Strg : STRING;
        pChars : INT;
    END_VAR
    VAR_IN_OUT
        Chars : ARRAY[*] OF BYTE;
    END_VAR
    VAR_OUTPUT
        Cnt : UINT;
    END_VAR
    VAR_TEMP
        arraystart : DINT;
        arrayend : DINT;
        min_len : DINT;
        max_len : DINT;
        loop : DINT;
    END_VAR

        arraystart := LOWER_BOUND(Chars, 1);

        IF pChars < arraystart THEN
            min_len := arraystart;
        ELSE
            min_len := pChars;
        END_IF;

        //TODO: Add block content here
        ;
    END_FUNCTION

END_NAMESPACE
