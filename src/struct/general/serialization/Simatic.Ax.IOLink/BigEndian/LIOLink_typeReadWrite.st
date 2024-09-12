// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeBig : UDINT
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
    SerializeBig := offset;
    SerializeBig := Simatic.Ax.IOLink.SerializeBig(offset := SerializeBig, value := value.header, buffer := buffer);
    FOR i := DINT#0 TO DINT#231 DO
        SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.data[i], buffer := buffer);
    END_FOR;
END_FUNCTION

FUNCTION DeserializeBig : UDINT
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
    DeserializeBig := offset;
    DeserializeBig := Simatic.Ax.IOLink.DeserializeBig(offset := DeserializeBig, value := value.header, buffer := buffer);
    FOR i := DINT#0 TO DINT#231 DO
        DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.data[i], buffer := buffer);
    END_FOR;
END_FUNCTION
END_NAMESPACE
