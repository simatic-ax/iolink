// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.iolink
FUNCTION SerializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : BlockDefinition;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeBig := offset;
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.BlockNoDefinition, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.Channel, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.BlockType, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.Version, buffer := buffer);
    SerializeBig := System.Serialization.SerializeBig(offset := SerializeBig, value := value.ByteLength, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeBig : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : BlockDefinition;
    END_VAR
    DeserializeBig := offset;
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.BlockNoDefinition, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.Channel, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.BlockType, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.Version, buffer := buffer);
    DeserializeBig := System.Serialization.DeserializeBig(offset := DeserializeBig, value := value.ByteLength, buffer := buffer);
END_FUNCTION
END_NAMESPACE
