// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWrite;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_TEMP
        i : DINT;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := Simatic.Ax.IOLink.SerializeLittle(offset := SerializeLittle, value := value.header, buffer := buffer);
    FOR i := DINT#0 TO DINT#231 DO
        SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.data[i], buffer := buffer);
    END_FOR;
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWrite;
    END_VAR
    VAR_TEMP
        i : DINT;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := Simatic.Ax.IOLink.DeserializeLittle(offset := DeserializeLittle, value := value.header, buffer := buffer);
    FOR i := DINT#0 TO DINT#231 DO
        DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.data[i], buffer := buffer);
    END_FOR;
END_FUNCTION
END_NAMESPACE
