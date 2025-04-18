// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : LIOLINK_typeIOHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.control, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.indexHighByte, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.indexLowByte, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.subindex, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : LIOLINK_typeIOHeader;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.control, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.indexHighByte, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.indexLowByte, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.subindex, buffer := buffer);
END_FUNCTION
END_NAMESPACE
