// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeJob;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_TEMP
        i : DINT;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.ExtendedFunctionNum, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.Options, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.SequenceNo, buffer := buffer);
    FOR i := DINT#0 TO DINT#233 DO
        SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.payload[i], buffer := buffer);
    END_FOR;
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLink_typeJob;
    END_VAR
    VAR_TEMP
        i : DINT;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.ExtendedFunctionNum, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.Options, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.SequenceNo, buffer := buffer);
    FOR i := DINT#0 TO DINT#233 DO
        DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.payload[i], buffer := buffer);
    END_FOR;
END_FUNCTION
END_NAMESPACE
