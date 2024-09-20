NAMESPACE Simatic.Ax.IOLink
    TYPE
        LIOLink_typeJob                : STRUCT                  // structure of data record for restore (NEW)
            ExtendedFunctionNum: Byte;                   // extended function number (01=PUSH, 02=PULL)
            Options            : Byte;                   // options, not used
            SequenceNo         : DWord;                  // sequence number (please see manual)
            payload            : Array[0..233] of Byte;  // payload data (raw data)
        END_STRUCT;

        LIOLink_typeRecStruct: STRUCT        // structured database for different jobs of RDREC/WRREC
            reset            : LIOLink_typeJob;
            backup           : LIOLink_typeJob;
            restore          : LIOLink_typeJob;
        END_STRUCT;

        LIOLINK_typeIOHeader: STRUCT  // header für IO-Link
            control      : Byte;   // RD_WR = 0 = read = Control:=0x03 / / RD_WR = 1 = write = Control:=0x02
            indexHighByte: Byte;   // index of data record 0…32767 (high byte)
            indexLowByte : Byte;   // index of data record 0…32767 (low byte)
            subindex     : Byte;   // subindex for data record 0...255
        END_STRUCT;

        LIOLink_typeReadWriteDataHeader      : STRUCT                 // header for read/write data record
            extFunctionNum: Byte := BYTE#16#08;    // extended function number (fix coded 08h)
            port          : Byte;                  // variable port (user interface) 0...255
            fiIndex       : Word := WORD#16#FE4A;  // FI index (fix coded 65098)
        END_STRUCT;

        headerType: STRUCT          // Header
            call      : LIOLink_typeReadWriteDataHeader;
            iolHeader : LIOLINK_typeIOHeader;
        END_STRUCT;

        LIOLink_typeReadWrite: STRUCT                  // data area for writing/reading data
            header       : headerType;
            data         : Array[0..Lengths#RECORD - 1] of Byte;  // Data
        END_STRUCT;

        LIOLink_typeRecordData : ARRAY[0..Lengths#RECORD - 1] OF BYTE;
        LIOLink_typeRecordDataWithHeader : ARRAY[0..Lengths#RECORD + Lengths#RECORD_HEADER - 1] OF BYTE;
        LIOLink_typeMaster4PortRecordData : ARRAY[0..10240 - 1] OF BYTE;
        LIOLink_typeMaster8PortRecordData : ARRAY[0..17550 - 1] OF BYTE;

    END_TYPE
END_NAMESPACE
