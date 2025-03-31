// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeRecStruct;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeBig := offset;
    SerializeBig := Simatic.Ax.IOLink.SerializeBig(offset := SerializeBig, value := value.reset, buffer := buffer);
    SerializeBig := Simatic.Ax.IOLink.SerializeBig(offset := SerializeBig, value := value.backup, buffer := buffer);
    SerializeBig := Simatic.Ax.IOLink.SerializeBig(offset := SerializeBig, value := value.restore, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeRecStruct;
    END_VAR
    DeserializeBig := offset;
    DeserializeBig := Simatic.Ax.IOLink.DeserializeBig(offset := DeserializeBig, value := value.reset, buffer := buffer);
    DeserializeBig := Simatic.Ax.IOLink.DeserializeBig(offset := DeserializeBig, value := value.backup, buffer := buffer);
    DeserializeBig := Simatic.Ax.IOLink.DeserializeBig(offset := DeserializeBig, value := value.restore, buffer := buffer);
END_FUNCTION
END_NAMESPACE
