// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.iolink
FUNCTION SerializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : DeviceHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeBig := offset;
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.crc32, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.SourceDestAddress, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.TypeIdent, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.ByteLength, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.NoOfBlocks, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : DeviceHeader;
    END_VAR
    DeserializeBig := offset;
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.crc32, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.SourceDestAddress, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.TypeIdent, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.ByteLength, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.NoOfBlocks, buffer := buffer);
END_FUNCTION
END_NAMESPACE
