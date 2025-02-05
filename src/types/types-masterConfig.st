NAMESPACE Simatic.Ax.iolink
    
    TYPE

        DeviceHeader : STRUCT
            crc32 : DWORD;
            SourceDestAddress : BYTE;
            TypeIdent : BYTE;
            ByteLength : UDINT;
            NoOfBlocks : BYTE;
        END_STRUCT;

        BlockDefinition : STRUCT
            BlockNoDefinition : BYTE;
            Channel : BYTE; //00: master, 01..0n: Channels
            BlockType : BlockType;
            Version : BYTE;
            ByteLength : UDINT;
        END_STRUCT;

        RecordContent : STRUCT
            Function_Num : BYTE; //16#5E: Read, 16#5F: Write
            Slot_Number : BYTE;
            Index : BYTE;
            LengthOfNetData : BYTE;
        END_STRUCT;

        BlockContent : STRUCT
            Data : ARRAY[0..233] OF BYTE;
        END_STRUCT;

        DecodedConfig : STRUCT
            Header : DeviceHeader;
            BlockDefinition : ARRAY[1..16] OF BlockDefinition;
            BlockData : ARRAY[1..16] OF BlockContent;
        END_STRUCT;

    END_TYPE

    TYPE
        
        BlockType : BYTE (PortCfg := BYTE#1, IOMapping := BYTE#2, DataStorage := BYTE#3);

    END_TYPE


END_NAMESPACE
