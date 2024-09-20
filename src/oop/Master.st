USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.IOLink

    CLASS PUBLIC Master EXTENDS IOLinkBase
        VAR PUBLIC
            Record4Ports : REF_TO LIOLink_typeMaster4PortRecordData;
            Record8Ports : REF_TO LIOLink_typeMaster8PortRecordData;
        END_VAR
        
        VAR PROTECTED
            instRdRec            : ReadRecord;                                        // System function "read data record"
			instWrRec            : WriteRecord;                                       // System function "write data record"
			statRecStruct        : LIOLink_typeRecStruct;
            statHwID             : HW_IO;                                             // Static value for input 'hwID'
			statMode             : USInt;                                             // Static value for input 'mode'
			statSegment          : DInt;                                              // current segment
			statAddress          : DInt;                                              // current address
			statLen              : DInt;                                              // total length of operated data
			statBuffer           : LIOLink_typeRecordDataWithHeader;
        END_VAR

        VAR CONSTANT
            
			INDEX                      : USInt := USINT#120;           // Index of data record for backup/restore operations
            ERR_UNKNOWN_RECORD         : DWord := DWORD#16#DF80_B000;  // Error: Data record not known in module
        END_VAR

        METHOD PUBLIC Backup : BOOL
            VAR_INPUT
                hwID : HW_IO;
                port : portType;
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            VAR_TEMP
                tempIndex : INT;
            END_VAR

            statHwID := hwID;
            statMode := MasterMode#BACKUP;
            
            IF port = portType#INVALID THEN
                RETURN;
            END_IF;

            IF NOT THIS.CheckCommandInternal() THEN
                RETURN;
            END_IF;

            // initialize data record before backup
            FOR tempIndex := 0 TO tempUpperBound DO 
                record[tempIndex] := BYTE#16#0;
            END_FOR;
        END_METHOD

        METHOD PUBLIC Restore : BOOL
            VAR_INPUT
                hwID : HW_IO;
                port : portType;
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            statHwID := hwID;
            statMode := MasterMode#RESTORE;
            
            IF port = portType#INVALID THEN
                RETURN;
            END_IF;

            IF NOT THIS.CheckCommandInternal() THEN
                status := statStatus;
                RETURN;
            END_IF;
            
        END_METHOD

        METHOD PROTECTED CheckCommandInternal : BOOL;
            //check internal state
            IF statFBState <> StateDevice#FB_STATE_NO_PROCESSING THEN
                statStatus := Status#ERR_EXECUTION_ACTIVE;
                RETURN;
            END_IF;

            IF statHwID = 0 THEN
                statStatus := Status#ERR_HARDWARE_ID_INVALID;
                RETURN;
            END_IF;

            statStatus := Status#STATUS_FIRST_CALL;

            // Initialize internal tags 
			statSegment := 0;
			statAddress := 0;
			statLen := 0;

            // Check record array
			tempLowerBound := LOWER_BOUND(record, 1);
			tempUpperBound := UPPER_BOUND(record, 1);

			IF tempLowerBound <> 0
				OR (tempUpperBound <> UPPER_LIMIT_4_PORT
				AND tempUpperBound <> UPPER_LIMIT_8_PORT)
			THEN
				statStatus := Status#ERR_ARRAY_UNSUPPORTED;
                RETURN;
			ELSE // Check mode
                statFBState := FB_STATE_PREPARE_RESET;
                statStatus := Status#STATUS_SUBSEQUENT_CALL;
			END_IF;

        END_METHOD

        METHOD PUBLIC Execute
            VAR_TEMP
                tempIndex : INT;
            END_VAR

            CASE statFBState OF
                StateMaster#FB_STATE_NO_PROCESSING:
                    ; // No processing active
                    // END_REGION no processing

                StateMaster#FB_STATE_PREPARE_RESET:
                    statRecStruct.reset.ExtendedFunctionNum := FunctionType#FUNC_PUSH;
                    statRecStruct.reset.SequenceNo := SeqNoMaster#SEQ_NUM_RESET;  // reset save/restore operations
                    
                    SerializeBig(offset := UINT#0, value := statRecStruct.reset, buffer := statBuffer);
                    statFBState := stateMaster#FB_STATE_RESET;

                StateMaster#FB_STATE_RESET:

                    instWrRec(request    := true,
                        ID     := statHwID,
                        index  := index,
                        length    := LEN_HEADER,
                        record := statBuffer);

                    IF instWrRec.DONE = TRUE THEN
                        instWrRec(request := FALSE, record := statBuffer); // Reset request

                        IF statMode = MODE_BACKUP THEN
                            statFBState := stateMaster#FB_STATE_BACKUP;
                        ELSE
                            statFBState := stateMaster#FB_STATE_RESTORE;
                        END_IF;

                    ELSIF instWrRec.ERROR = TRUE AND instWrRec.STATUS = ERR_UNKNOWN_RECORD THEN
                        statStatus := Status#ERR_UNKNOWN_MODULE; // set status = unknown type of module
                        statSubfunctionStatus := instWrRec.STATUS;
                        statFBErrorState := statFBState;
                    ELSIF instWrRec.ERROR = TRUE THEN
                        statStatus := Status#ERR_WRRC_RESET;
                        statSubfunctionStatus := instWrRec.STATUS;
                        statFBErrorState := statFBState;
                    END_IF;
                    // END_REGION reset

                StateMaster#FB_STATE_BACKUP:
                    instRdRec(request    := TRUE,
                        ID     := statHwID,
                        index  := index,
                        maxLength   := LEN_HEADER + MAX_SIZE_SEGMENT,
                        record := statBuffer);

                    // evaluation of RDREC
                    IF instRdRec.VALID = TRUE THEN
                        DeserializeBig(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);
                        IF instRdRec.length > LEN_HEADER AND statRecStruct.backup.ExtendedFunctionNum = FUNC_PULL THEN
                            statStatus := STATUS_OFFSET_BACKUP OR statRecStruct.backup.SequenceNo.%B0;  // append segment number
                            statSegment := TO_DINT(statRecStruct.backup.SequenceNo);
                            tempLen := instRdRec.length - LEN_HEADER;

                            FOR tempIndex := 0 TO tempLen - UINT#1 DO
                                record[tempIndex + statAddress] := statRecStruct.backup.payload[tempIndex];
                            END_FOR;

                            // add total length of data
                            statLen := statLen + tempLen;

                            // set pointer to next entry in parameter blob
                            statAddress := statAddress + tempLen;

                        ELSIF instRdRec.length = LEN_HEADER THEN
                            // Reset request
                            instRdRec(request    := FALSE,
                            record := statBuffer);

                            statStatus := STATUS_EXECUTION_FINISHED;
                        END_IF;

                    ELSIF instRdRec.ERROR = TRUE THEN
                        statStatus            := Status#ERR_RDREC_BACKUP;
                        statSubfunctionStatus := instRdRec.STATUS;
                        statFBErrorState      := statFBState;
                        statLen               := instRdRec.length;
                    END_IF;
                    // END_REGION backup

                StateMaster#FB_STATE_RESTORE:
                    // load restore data segment from parameter blob (max. 234 Byte per segment)
                    IF instWrRec.BUSY = FALSE AND instWrRec.DONE = FALSE THEN // Writing hasn't started
                        statRecStruct.restore.ExtendedFunctionNum := FunctionType#FUNC_PUSH;
                        statRecStruct.restore.SequenceNo := TO_DWORD(statSegment); // sequence number
                        statStatus := STATUS_OFFSET_RESTORE OR statRecStruct.restore.SequenceNo.%B0;

                        // load segment data = payload
                        FOR tempIndex := 0 TO MAX_SIZE_SEGMENT - UINT#1 DO
                            statRecStruct.restore.payload[tempIndex] := record[tempindex + statAddress];
                        END_FOR;

                        //move into buffer
                        SerializeBig(offset := UINT#0, value := statRecStruct.restore, buffer := statBuffer);

                    END_IF;

                    // write segment data
                    instWrRec(request    := TRUE,
                        ID     := statHwID,
                        index  := index,
                        length := LEN_HEADER + MAX_SIZE_SEGMENT,
                        record := statBuffer);

                    IF instWrRec.DONE = TRUE THEN
                        statLen := statLen + MAX_SIZE_SEGMENT;
                        instWrRec(request := FALSE, record := statBuffer); // Reset request
                        statFBState := FB_STATE_VERIFY;

                    ELSIF instWrRec.ERROR = TRUE THEN
                        statStatus := Status#ERR_WRREC_RESTORE;
                        statSubfunctionStatus := instWrRec.STATUS;
                        statFBErrorState := statFBState;
                    END_IF;
                    // END_REGION restore

                StateMaster#FB_STATE_VERIFY: // Verify restore
                    // REGION verify
                    instRdRec(request    := TRUE,
                        ID     := statHwID,
                        index  := index,
                        maxLength   := LEN_HEADER + MAX_SIZE_SEGMENT,
                        record := statBuffer);

                        DeserializeBig(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);

                    IF instRdRec.VALID = TRUE AND statRecStruct.backup.ExtendedFunctionNum = FUNC_PULL THEN
                        IF statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_RESTORE_ONGOING
                            OR statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_ACTIVATION_ONGOING
                        THEN
                            statSegment := statSegment + 1;
                            statAddress := statAddress + MAX_SIZE_SEGMENT;

                            // Reset request
                            instRdRec(request    := FALSE,
                            record := statBuffer);

                            statFBState := StateMaster#FB_STATE_RESTORE;
                            ELSIF statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_ACTIVATION_DONE THEN //
                            // Reset request
                            instRdRec(request    := FALSE,
                            record := statBuffer);

                            statStatus := Status#STATUS_EXECUTION_FINISHED;
                        ELSIF statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_CRC_FAILED
                            OR statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_BLOB_INVALID
                            OR statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_WRONG_SEQUENCE
                            OR statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_WRONG_SIZE
                        THEN
                            statStatus := Status#ERR_SEQ_NUMBER;
                            statSubfunctionStatus := statRecStruct.backup.SequenceNo;
                            statFBErrorState := statFBState;
                        END_IF;
                    ELSIF instRdRec.ERROR = TRUE THEN
                        statStatus := Status#ERR_RDREC_VERIFY;
                        statSubfunctionStatus := instRdRec.STATUS;
                        statFBErrorState := statFBState;
                    END_IF;
                    // END_REGION verify

                ELSE // Undefined state in state machine reached
                    // REGION undefined state
                    statStatus := Status#ERR_UNDEFINED_STATE;
                    // END_REGION undefined state no relevant case, ready for new request
            END_CASE;

        END_METHOD


    END_CLASS

    TYPE
        MasterMode : USINT (BACKUP := USINT#0, RESTORE := USINT#1, INVALID := USINT#2);
    END_TYPE

END_NAMESPACE
    