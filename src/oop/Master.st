USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.IOLink

    CLASS PUBLIC Master EXTENDS IOLinkBase
        VAR PUBLIC
            Record4Ports : REF_TO LIOLink_typeMaster4PortRecordData;
            Record8Ports : REF_TO LIOLink_typeMaster8PortRecordData;
            RecordLength : DINT;
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
            record : REF_TO ARRAY[*] OF BYTE;
        END_VAR

        VAR CONSTANT
            
			INDEX                      : USInt := USINT#120;           // Index of data record for backup/restore operations
            ERR_UNKNOWN_RECORD         : DWord := DWORD#16#DF80_B000;  // Error: Data record not known in module
        END_VAR

        METHOD PUBLIC Backup : BOOL
            VAR_INPUT
                hwID : HW_IO;
                port : masterType;
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            VAR_TEMP
                tempIndex : INT;
                tempLimit : INT;
            END_VAR

            statHwID := hwID;
            statMode := MasterMode#BACKUP;
            
            IF port = masterType#INVALID THEN
                RETURN;
            END_IF;

            IF NOT THIS.CheckCommandInternal(port) THEN
                RETURN;
            END_IF;

            IF port = MasterType#FOUR_PORT THEN
                tempLimit := Lengths#MASTER_RECORD_4_PORT;
            ELSE
                tempLimit := Lengths#MASTER_RECORD_8_PORT;
            END_IF;

            // initialize data record before backup
            FOR tempIndex := 0 TO tempLimit - 1 DO 
                record^[tempIndex] := BYTE#16#0;
            END_FOR;
        END_METHOD

        METHOD PUBLIC Restore : BOOL
            VAR_INPUT
                hwID : HW_IO;
                port : masterType;
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            statHwID := hwID;
            statMode := MasterMode#RESTORE;
            
            IF port = masterType#INVALID THEN
                RETURN;
            END_IF;

            IF NOT THIS.CheckCommandInternal(port) THEN
                status := statStatus;
                RETURN;
            END_IF;
            
        END_METHOD

        METHOD PROTECTED CheckCommandInternal : BOOL
            VAR_INPUT
                masterType : MasterType;
            END_VAR

            //check internal state
            IF statFBState <> StateDevice#FB_STATE_NO_PROCESSING THEN
                statStatus := Status#ERR_EXECUTION_ACTIVE;
                RETURN;
            END_IF;

            IF statHwID = WORD#0 THEN
                statStatus := Status#ERR_HARDWARE_ID_INVALID;
                RETURN;
            END_IF;

            statStatus := Status#STATUS_FIRST_CALL;

            // Initialize internal tags 
			statSegment := 0;
			statAddress := 0;
			statLen := 0;

            IF  masterType = MasterType#INVALID THEN
                statStatus := Status#ERR_ARRAY_REFERENCE; 
                RETURN;
            ELSIF masterType = MasterType#FOUR_PORT THEN
                IF Record4Ports = NULL THEN
                    statStatus := Status#ERR_ARRAY_UNSUPPORTED; 
                    RETURN;
                END_IF;
                record := Record4Ports;
            ELSIF masterType = MasterType#EIGHT_PORT THEN
                IF Record8Ports = NULL THEN 
                    statStatus := Status#ERR_ARRAY_UNSUPPORTED; 
                    RETURN;
                END_IF;
                record := Record8Ports;
            END_IF;
            
            //everything okay, start processing
            statFBState := StateMaster#FB_STATE_PREPARE_RESET;
            statStatus := Status#STATUS_SUBSEQUENT_CALL;

        END_METHOD

        METHOD PUBLIC Execute
            VAR_TEMP
                tempIndex : INT;
                tempLength : UINT;
            END_VAR

            CASE statFBState OF
                StateMaster#FB_STATE_NO_PROCESSING:
                    ; // No processing active
                    // END_REGION no processing

                StateMaster#FB_STATE_ERROR:
                    ; //error step. Do nothing
                    //to re-enable operation, call reset()

                StateMaster#FB_STATE_PREPARE_RESET:
                    statRecStruct.reset.ExtendedFunctionNum := FunctionType#FUNC_PUSH;
                    statRecStruct.reset.SequenceNo := SeqNoMaster#SEQ_NUM_RESET;  // reset save/restore operations
                    
                    SerializeBig(offset := UINT#0, value := statRecStruct.reset, buffer := statBuffer);
                    statFBState := stateMaster#FB_STATE_RESET;

                StateMaster#FB_STATE_RESET:

                    instWrRec(request    := true,
                        ID     := statHwID,
                        index  := index,
                        length    := TO_UINT(Lengths#MASTER_HEADER),
                        record := statBuffer);

                    IF instWrRec.DONE = TRUE THEN
                        instWrRec(request := FALSE, record := statBuffer); // Reset request

                        IF statMode = MasterMode#BACKUP THEN
                            statFBState := stateMaster#FB_STATE_BACKUP;
                        ELSE
                            statFBState := stateMaster#FB_STATE_RESTORE;
                        END_IF;

                    ELSIF instWrRec.ERROR = TRUE AND instWrRec.STATUS = ERR_UNKNOWN_RECORD THEN
                        statStatus := Status#ERR_UNKNOWN_MODULE; // set status = unknown type of module
                        statSubfunctionStatus := instWrRec.STATUS;
                        statFBErrorState := statFBState;
                    ELSIF instWrRec.ERROR = TRUE THEN
                        statStatus := Status#ERR_WRREC;
                        statSubfunctionStatus := instWrRec.STATUS;
                        statFBErrorState := statFBState;
                    END_IF;
                    // END_REGION reset

                StateMaster#FB_STATE_BACKUP:
                    instRdRec(request    := TRUE,
                        ID     := statHwID,
                        index  := index,
                        maxLength   := TO_UINT(Lengths#MASTER_RECORD_SEGMENT_WITH_HEADER),
                        record := statBuffer);

                    // evaluation of RDREC
                    IF instRdRec.VALID = TRUE THEN
                        DeserializeBig(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);
                        IF instRdRec.length > TO_UINT(Lengths#MASTER_HEADER) AND statRecStruct.backup.ExtendedFunctionNum = FunctionType#FUNC_PULL THEN
                            statStatus := Status#STATUS_OFFSET_BACKUP OR statRecStruct.backup.SequenceNo.%B0;  // append segment number
                            statSegment := TO_DINT(statRecStruct.backup.SequenceNo);
                            tempLength := instRdRec.length - TO_UINT(Lengths#MASTER_HEADER);

                            FOR tempIndex := 0 TO TO_INT(tempLength) - 1 DO
                                record^[tempIndex + statAddress] := statRecStruct.backup.payload[tempIndex];
                            END_FOR;

                            // add total length of data
                            statLen := statLen + tempLength;

                            // set pointer to next entry in parameter blob
                            statAddress := statAddress + tempLength;

                        ELSIF instRdRec.length = TO_UINT(Lengths#MASTER_HEADER) THEN
                            // Reset request
                            instRdRec(request    := FALSE,
                            record := statBuffer);

                            statStatus := Status#STATUS_EXECUTION_FINISHED;
                        END_IF;

                    ELSIF instRdRec.ERROR = TRUE THEN
                        statStatus            := Status#ERR_RDREC;
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
                        statStatus := Status#STATUS_OFFSET_RESTORE OR statRecStruct.restore.SequenceNo.%B0;

                        // load segment data = payload
                        FOR tempIndex := 0 TO Lengths#MASTER_RECORD_SEGMENT - 1 DO
                            statRecStruct.restore.payload[tempIndex] := record^[tempindex + statAddress];
                        END_FOR;

                        //move into buffer
                        SerializeBig(offset := UINT#0, value := statRecStruct.restore, buffer := statBuffer);

                    END_IF;

                    // write segment data
                    instWrRec(request    := TRUE,
                        ID     := statHwID,
                        index  := index,
                        length := TO_UINT(Lengths#MASTER_RECORD_SEGMENT_WITH_HEADER),
                        record := statBuffer);

                    IF instWrRec.DONE = TRUE THEN
                        statLen := statLen + Lengths#MASTER_RECORD_SEGMENT;
                        instWrRec(request := FALSE, record := statBuffer); // Reset request
                        statFBState := StateMaster#FB_STATE_VERIFY;

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
                        maxLength   := TO_UINT(Lengths#MASTER_RECORD_SEGMENT_WITH_HEADER),
                        record := statBuffer);

                        DeserializeBig(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);

                    IF instRdRec.VALID = TRUE AND statRecStruct.backup.ExtendedFunctionNum = FunctionType#FUNC_PULL THEN
                        IF statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_RESTORE_ONGOING
                            OR statRecStruct.backup.SequenceNo = SeqNoMaster#SEQ_NUM_ACTIVATION_ONGOING
                        THEN
                            statSegment := statSegment + 1;
                            statAddress := statAddress + Lengths#MASTER_RECORD_SEGMENT;

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

            // Write outputs
		IF (statStatus = Status#STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
			// REGION execution finished
			statDone  := TRUE;
			statBusy  := FALSE;
			statError := FALSE;
			RecordLength := statLen;
			// execution aborted --> set state no processing
			statFBState := StateMaster#FB_STATE_NO_PROCESSING;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
			// REGION error occured
			statDone  := FALSE;
			statBusy  := FALSE;
			statError := TRUE;
			// Write diagnostics
			Diagnostics.status            := statStatus;
			Diagnostics.subfunctionStatus := statSubfunctionStatus;
			Diagnostics.stateNumber       := statFBErrorState;
			// Call instructions with FALSE to be ready for next job
			instRdRec(request    := FALSE,
				record := statBuffer);

			instWrRec(request := FALSE, 
                record := statBuffer);
			// execution aborted --> set state no processing
			statFBState := StateMaster#FB_STATE_ERROR;
            RecordLength := 0;

		END_IF;

        END_METHOD

        METHOD PUBLIC OVERRIDE Reset
        
            //clear internal FB calls
			instRdRec(request    := FALSE,
				record := statBuffer);

			instWrRec(request := FALSE, 
                record := statBuffer);

            RecordLength := 0;

            SUPER.Reset();
        END_METHOD


    END_CLASS

END_NAMESPACE
    