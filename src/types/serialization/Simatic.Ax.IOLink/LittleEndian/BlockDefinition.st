// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.iolink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : BlockDefinition;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.BlockNoDefinition, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.Channel, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.BlockType, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.Version, buffer := buffer);
    SerializeLittle := System.Serialization.SerializeLittle(offset := SerializeLittle, value := value.ByteLength, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : BlockDefinition;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.BlockNoDefinition, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.Channel, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.BlockType, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.Version, buffer := buffer);
    DeserializeLittle := System.Serialization.DeserializeLittle(offset := DeserializeLittle, value := value.ByteLength, buffer := buffer);
END_FUNCTION
END_NAMESPACE
