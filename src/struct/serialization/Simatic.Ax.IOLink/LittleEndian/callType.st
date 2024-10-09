// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWriteDataHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.extFunctionNum, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.port, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.fiIndex, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeReadWriteDataHeader;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.extFunctionNum, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.port, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.fiIndex, buffer := buffer);
END_FUNCTION
END_NAMESPACE
