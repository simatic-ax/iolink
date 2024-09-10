NAMESPACE Simatic.Ax.IOLink

TYPE
    Status : WORD(
        STATUS_EXECUTION_FINISHED := WORD#16#0000,   // Execution finished without errors
        STATUS_NO_CALL            := WORD#16#7000,   // No job being currently processed
        STATUS_FIRST_CALL         := WORD#16#7001,   // First call after incoming new job (rising edge 'execute')
        STATUS_SUBSEQUENT_CALL    := WORD#16#7002,   // Subsequent call during active processing without further details
        STATUS_OFFSET_BACKUP      := WORD#16#7100,   // Offset for status during backup operation
        STATUS_OFFSET_RESTORE     := WORD#16#7200,   // Offset for status during restore operation
        ERR_EXECUTION_ACTIVE      := WORD#16#8001,   // A command is already being executed
        ERR_UNKNOWN_MODULE        := WORD#16#80B0,   // unknown type of module, check subfunctionStatus
        ERR_UNKNOWN_MODE          := WORD#16#8200,   // Unknown mode
        ERR_ARRAY_UNSUPPORTED     := WORD#16#8201,   // Record array doesn't fit expected limits
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
            PORT_EVENT_CODES := 5,
            PORT_EVENTS := 8

        );

        Control : BYTE(
            CONTROL_WRITE               := BYTE#16#02,          // Write data record
			CONTROL_READ                := BYTE#16#03          // Read data record
        );

        Cap : WORD(
            CAP_LEGACY              := WORD#16#00E3,        // Siemens (old) Standard CAP: 227
			CAP_STANDARD            := WORD#16#B400        // IO-Link Standard CAP: 16#B400
        );

        Limit : UINT (
            MAX_PORT                  := USINT#63,           // Max. possible port
			MAX_INDEX                 := UINT#32767,          // Max. possible index
			INDEX_PORT_FUNC           := UINT#65535,          // Index to address port functions
			MAX_SUBINDEX              := USINT#255           // Max. possible subindex
        );

        ClassDeviceState : DINT(
            FB_STATE_NO_PROCESSING     := 0,
            FB_STATE_PREPARE_WRITE     := 10,
            FB_STATE_WRITE             := 1,
            FB_STATE_POLL              := 2,
            FB_STATE_READ_CAP          := 3
        );

END_TYPE

END_NAMESPACE
