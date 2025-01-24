NAMESPACE Simatic.Ax.iolink
    
    TYPE

        DeviceHeader : STRUCT
            crc32 : DWORD;
            SourceDestAddress : USINT;
            TypeIdent : USINT;
            ByteLength : UDINT;
            NoOfBlocks : USINT;
        END_STRUCT;

        BlockData : STRUCT
            Block1Definition : USINT;
            Channel : USINT; //00: master, 01..0n: Channels
            BlockType : BlockType;
            Version : USINT;
            ByteLength : UDINT;
        END_STRUCT;

    END_TYPE

    TYPE
        
        BlockType : USINT (PortCfg := USINT#1, IOMapping := USINT#2, DataStorage := USINT#3);

    END_TYPE


END_NAMESPACE
