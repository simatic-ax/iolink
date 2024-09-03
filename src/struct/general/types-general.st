NAMESPACE Simatic.Ax.IOLink
    TYPE
        jobType                : STRUCT                  // structure of data record for restore (NEW)
            ExtendedFunctionNum: Byte;                   // extended function number (01=PUSH, 02=PULL)
            Options            : Byte;                   // options, not used
            SequenceNo         : DWord;                  // sequence number (please see manual)
            payload            : Array[0..233] of Byte;  // payload data (raw data)
        END_STRUCT;

        statRecStructType: STRUCT        // structured database for different jobs of RDREC/WRREC
            reset            : jobType;
            backup           : jobType;
            restore          : jobType;
        END_STRUCT;

        iolHeaderType: STRUCT  // header für IO-Link
            control      : Byte;   // RD_WR = 0 = read = Control:=0x03 / / RD_WR = 1 = write = Control:=0x02
            indexHighByte: Byte;   // index of data record 0…32767 (high byte)
            indexLowByte : Byte;   // index of data record 0…32767 (low byte)
            subindex     : Byte;   // subindex for data record 0...255
        END_STRUCT;

        callType      : STRUCT                 // header for read/write data record
            extFunctionNum: Byte := BYTE#16#08;    // extended function number (fix coded 08h)
            port          : Byte;                  // variable port (user interface) 0...255
            fiIndex       : Word := WORD#16#FE4A;  // FI index (fix coded 65098)
        END_STRUCT;

        headerType: STRUCT          // Header
            call      : callType;
            iolHeader : iolHeaderType;
        END_STRUCT;

        statReadWriteType: STRUCT                  // data area for writing/reading data
            header       : headerType;
            data         : Array[0..Lengths#RECORD - 1] of Byte;  // Data
        END_STRUCT;

        recordType : STRUCT
            data : ARRAY[0..Lengths#RECORD - 1] OF BYTE;
        END_STRUCT;

    END_TYPE
END_NAMESPACE
