// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWriteDataHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeBig := offset;
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.extFunctionNum, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.port, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.fiIndex, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWriteDataHeader;
    END_VAR
    DeserializeBig := offset;
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.extFunctionNum, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.port, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.fiIndex, buffer := buffer);
END_FUNCTION
END_NAMESPACE
