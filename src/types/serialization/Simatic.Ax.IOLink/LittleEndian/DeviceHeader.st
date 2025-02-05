// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.iolink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : DeviceHeader;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.crc32, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.SourceDestAddress, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.TypeIdent, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.ByteLength, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.NoOfBlocks, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : DeviceHeader;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.crc32, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.SourceDestAddress, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.TypeIdent, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.ByteLength, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.NoOfBlocks, buffer := buffer);
END_FUNCTION
END_NAMESPACE
