// This is generated code. *** DO NOT MODIFY ***

NAMESPACE Simatic.Ax.IOLink
FUNCTION SerializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
    END_VAR
    VAR_IN_OUT
        value : headerType;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    SerializeLittle := offset;
    SerializeLittle := Simatic.Ax.IOLink.SerializeLittle(offset := SerializeLittle, value := value.call, buffer := buffer);
    SerializeLittle := Simatic.Ax.IOLink.SerializeLittle(offset := SerializeLittle, value := value.iolHeader, buffer := buffer);
END_FUNCTION

FUNCTION DeserializeLittle : UDINT
    VAR_INPUT
        offset : UDINT;
        buffer : ARRAY[*] OF BYTE;
    END_VAR
    VAR_IN_OUT
        value : headerType;
    END_VAR
    DeserializeLittle := offset;
    DeserializeLittle := Simatic.Ax.IOLink.DeserializeLittle(offset := DeserializeLittle, value := value.call, buffer := buffer);
    DeserializeLittle := Simatic.Ax.IOLink.DeserializeLittle(offset := DeserializeLittle, value := value.iolHeader, buffer := buffer);
END_FUNCTION
END_NAMESPACE
