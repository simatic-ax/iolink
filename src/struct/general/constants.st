NAMESPACE Simatic.Ax.IOLink

TYPE
    Status : WORD(
        STATUS_EXECUTION_FINISHED := WORD#16#0000,   // Execution finished without errors
        STATUS_NO_CALL            := WORD#16#7000,   // No job being currently processed
        STATUS_FIRST_CALL         := WORD#16#7001,   // First call after incoming new job (rising edge 'execute')
        STATUS_SUBSEQUENT_CALL    := WORD#16#7002,   // Subsequent call during active processing without further details
        STATUS_DONE			      := WORD#16#7003,
        STATUS_OFFSET_BACKUP      := WORD#16#7100,   // Offset for status during backup operation
        STATUS_OFFSET_RESTORE     := WORD#16#7200,   // Offset for status during restore operation
        ERR_EXECUTION_ACTIVE      := WORD#16#8001,   // A command is already being executed
        ERR_HARDWARE_ID_INVALID   := WORD#16#8002,   // Error: The hardware id is not valid
        ERR_UNKNOWN_MODULE        := WORD#16#80B0,   // unknown type of module, check subfunctionStatus
        ERR_UNKNOWN_MODE          := WORD#16#8200,   // Unknown mode
        ERR_ARRAY_UNSUPPORTED     := WORD#16#8201,   // Record array doesn't fit expected limits
        ERR_ARRAY_REFERENCE       := WORD#16#8202,   // Record Array reference is not present
        ERR_WRONG_PORT            := WORD#16#8201,   // Error: wrong port
        ERR_WRONG_INDEX           := WORD#16#8202,   // Error: wrong index
        ERR_WRONG_SUBINDEX        := WORD#16#8203,   // Error: wrong subindex
        ERR_WRONG_LENGTH          := WORD#16#8205,   // Error: wrong length for write data record
        ERR_SEQ_NUMBER            := WORD#16#8401,   // Error: IO-Link master returned a sequence number indicating an error, see "diagnostics"
        ERR_IO_LINK               := WORD#16#8401,   // Error: IO-Link master returned error code, see "diagnostics"
        ERR_INCONSISTENT_DATA     := WORD#16#8402,   // Error: Read data record doesn't match request
        ERR_REQUEST_TIMEOUT       := WORD#16#8403,   // Error: Request timed out
        ERR_UNDEFINED_STATE       := WORD#16#8600,   // Error: due to an undefined state in state machine
        ERR_WRREC                 := WORD#16#8601,   // Error: WRREC encountered an error, see "diagnostics"
        ERR_RDREC                 := WORD#16#8602,   // Error: RDREC encountered an error, see "diagnostics"
        ERR_WRREC_RESTORE         := WORD#16#8603,   // Error: WRREC encountered an error during restore, see "diagnostics"
        ERR_RDREC_VERIFY          := WORD#16#8604    // Error: RDREC encountered an error during verification of restore, see "diagnostics"
    );

    SubFbState : WORD(
        SUB_STATUS_NO_ERROR := WORD#16#0000
    );

        Lengths : INT (
            RECORD := 232,
            RECORD_HEADER := 8,
            RECORD_WITH_HEADER := RECORD + RECORD_HEADER,
            MAX_PORTS := 8,
            PORT_EVENT_CODES := 5,
            PORT_EVENTS := 8,
            MASTER_HEADER := 6,
            MASTER_RECORD_SEGMENT := 234,
            MASTER_RECORD_SEGMENT_WITH_HEADER:= MASTER_RECORD_SEGMENT + MASTER_HEADER,
            MASTER_RECORD_4_PORT := 10240,
            MASTER_RECORD_8_PORT := 17550
            );

        Control : BYTE(
            CONTROL_WRITE               := BYTE#16#02,          // Write data record
			CONTROL_READ                := BYTE#16#03          // Read data record
        );

        Cap : WORD(
            CAP_LEGACY              := WORD#16#00E3,        // Siemens (old) Standard CAP: 227
			CAP_STANDARD            := WORD#16#B400,       // IO-Link Standard CAP: 16#B400
            INDEX_CAP_IOLINK        := WORD#16#B000        // Index of the data record for IOLM_Info. Only IO-Link-Masters with CAP=16#B000 support this call.
        );

        Limit : UINT (
            MAX_PORT                  := USINT#63,           // Max. possible port
			MAX_INDEX                 := UINT#32767,          // Max. possible index
			INDEX_PORT_FUNC           := UINT#65535,          // Index to address port functions
			MAX_SUBINDEX              := USINT#255           // Max. possible subindex
        );

        FunctionType  : BYTE (
            FUNC_PUSH   := BYTE#16#01,          // Extended function number for push
			FUNC_PULL   := BYTE#16#02          // Extended function number for pull
        );

        StateDevice : DINT(
            FB_STATE_NO_PROCESSING     := 0,
            FB_STATE_PREPARE_WRITE     := 10,
            FB_STATE_WRITE             := 1,
            FB_STATE_POLL              := 2,
            FB_STATE_READ_CAP          := 3,
            FB_STATE_ERROR             := 99
        );

        StateMaster : DINT(
			FB_STATE_NO_PROCESSING     := 0,                 // FB state: No processing
			FB_STATE_RESET             := 1,                 // FB state: reset (essential before each backup/restore operation)
			FB_STATE_PREPARE_RESET	   := 10,			
			FB_STATE_BACKUP            := 11,                 // FB state: backup
			FB_STATE_RESTORE           := 21,                 // FB state: restore segment data
			FB_STATE_VERIFY            := 22,                 // FB state: verify restore
            FB_STATE_ERROR             := 99
        );

        StateDiagnose : DINT (
            FB_STATE_NO_PROCESSING     := 0,                   // FB state: No processing
			FB_STATE_READ_CAP          := 1,                   // FB state: Read CAP
			FB_STATE_READ_DIAG         := 2,                   // FB state: Read diagnose
            FB_STATE_ERROR             := 99
        );

        SeqNoMaster : DWORD (
            SEQ_NUM_RESET               := DWORD#16#FFFF_FFFF,  // Sequence number for reset before backup/restore operations
			SEQ_NUM_RESTORE_ONGOING     := DWORD#16#FFFF_FF01,  // Sequence number: restore ongoing
			SEQ_NUM_ACTIVATION_ONGOING  := DWORD#16#FFFF_FF02,  // Sequence number: activation ongoing
			SEQ_NUM_ACTIVATION_DONE     := DWORD#16#FFFF_FF03,  // Sequence number: activation done
			SEQ_NUM_CRC_FAILED          := DWORD#16#FFFF_FF04,  // Sequence number: CRC check failed
			SEQ_NUM_BLOB_INVALID        := DWORD#16#FFFF_FF05,  // Sequence number: blob data invalid
			SEQ_NUM_WRONG_SEQUENCE      := DWORD#16#FFFF_FF06,  // Sequence number: wrong sequence number
			SEQ_NUM_WRONG_SIZE          := DWORD#16#FFFF_FF07  // Sequence number: wrong data record size
        );

        BitmaskByte : BYTE (
			BITMASK_ERR_RDREC_B3   := BYTE#16#DE,          // Status Code of RDREC in case of an error when reading a data record
			BITMASK_ERR_RDREC_B2   := BYTE#16#80,          // Status Code of RDREC in case of an error when reading a data record - Error according to IEC 61158-6
			BITMASK_ERR_RDREC_B1   := BYTE#16#B0          // Status Code of RDREC in case of an error when reading a data record - invalid index (cap)
        );

        BitmaskDWord : DWORD(
            STATUS_MASK               := DWORD#16#00FF_FF00,  // Mask to filter error codes
			STATUS_RESOURCE_BUSY      := DWORD#16#0080_C200  // Status from WRREC/RDREC: Resource is busy
        );

        ReadWriteRecordStatus : BYTE(
            STATUS_RDREC_VALID    := BYTE#16#00          // Status Code of RDREC in cased of no error occurs
        );

        Mode : (NONE, READ, WRITE) := NONE;

        MasterMode : USINT (BACKUP := USINT#0, RESTORE := USINT#1, INVALID := USINT#2);

        MasterType : (FOUR_PORT, EIGHT_PORT, INVALID) := INVALID;

END_TYPE

END_NAMESPACE
