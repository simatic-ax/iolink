// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLINK_typeIOHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeBig := offset;
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.control, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.indexHighByte, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.indexLowByte, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.subindex, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLINK_typeIOHeader;
    END_VAR
    DeserializeBig := offset;
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.control, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.indexHighByte, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.indexLowByte, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.subindex, buffer := buffer);
END_FUNCTION
END_NAMESPACE
