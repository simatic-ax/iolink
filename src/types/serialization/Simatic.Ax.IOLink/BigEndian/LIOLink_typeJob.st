// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeBig : UDINT
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
    SerializeBig := offset;
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.ExtendedFunctionNum, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.Options, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.SequenceNo, buffer := buffer);
    FOR i := DINT#0 TO DINT#233 DO
        SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.payload[i], buffer := buffer);
    END_FOR;
END_FUNCTION

FUNCTION DeserializeBig : UDINT
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
    DeserializeBig := offset;
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.ExtendedFunctionNum, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.Options, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.SequenceNo, buffer := buffer);
    FOR i := DINT#0 TO DINT#233 DO
        DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.payload[i], buffer := buffer);
    END_FOR;
END_FUNCTION
END_NAMESPACE
