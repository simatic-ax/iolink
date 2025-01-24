USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.IOLink

    CLASS PUBLIC Diagnose EXTENDS IOLinkBase

        VAR PUBLIC
            events     : LIOLink_typeEvents;
        END_VAR
        
        VAR PROTECTED
            statHwID             : HW_ANY;                                    // Static value for input 'HwID'
			statHwIDprevious     : HW_IO;                                     // Static value for input 'hwID' from the previous execute 
			statEmptyDiagnostics : LIOLink_typeDiagnostics;                   // Empty diagnostics information (for initialization purposes only)
			instRdRec            : ReadRecord;                                // System function "read data record"
			instRdDiag           : ReadRecord;                                // System function "read data record"
			statDiagRecord       : Array[0..Lengths#RECORD - 1] of Byte;      // Data record of port diagnose
			statDiagRecordEco    : LIOLink_typeEvents;
			statCap              : UInt;                                      // Static value for input 'cap'
			statRead             : Array[0..Lengths#RECORD - 1] of Byte;      // Data record, Output of RDREC
			statIndexDiag        : UInt;                                      // Static value for index of data record of port diagnose
			statPortNumber       : Int := 8;                                  // Number of Ports of IO-Link-Master
			statPortEco          : UInt := UINT#1;                            // Static value for a port counter of EcoPN
        END_VAR

        VAR CONSTANT
            STATUS_MASK                             : DWord := DWORD#16#00FF_FF00;  // Mask to filter error codes
			STATUS_RESOURCE_BUSY                    : DWord := DWORD#16#0080_C200;  // Status from WRREC/RDREC: Resource is busy
            RESET_WORD                              : Word  := WORD#16#0000;        // Reset event codes0
            RESET_BYTE                              : Byte  := BYTE#16#00;          // Reset byte for statDiagRecord
            STATUS_RDREC_VALID                      : Byte  := BYTE#16#00;          // Status Code of RDREC in cased of no error occurs
            INDEX_DIAG_OTHER                        : Word  := WORD#16#00E5;        // Index for port status based on Siemens Standard (old): 229 => reads status of all ports
			INDEX_DIAG_ECO                          : Word  := WORD#16#B200;        // Index for port status based on IO-Link-Standard: 16#B20n, n:Port number => reads port status of only one port
            MASTER_PORT_STATUS_V2                   : Byte  := BYTE#16#02;          // Master port status version 2
			MASTER_PORT_STATUS_V3                   : Byte  := BYTE#16#03;          // Master port status version 3
			MASTER_PORT_STATUS_V4                   : Byte  := BYTE#16#04;          // Master port status version 4
            START_INDEX_MASTER_PORT_STATUS_V2       : Int   := 28;                  // Start index of relevant data in the case of port status version 2
			START_INDEX_MASTER_PORT_STATUS_V3       : Int   := 34;                  // Start index of relevant data in the case of port status version 3
			START_INDEX_MASTER_PORT_STATUS_V4       : Int   := 42;                  // Start index of relevant data in the case of port status version 4
			START_INDEX_MASTER_PORT_STATUS_STANDARD : Int   := 18;                  // Start index of relevant data in case of a IO-Link Standard data record for port status
        END_VAR

        METHOD PUBLIC Start : BOOL

            VAR_INPUT
                hwID   : HW_IO;  // Hardware identifier of IO-Link master module or first sub module
                cap    : Int;    // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
            END_VAR
            VAR_TEMP
                tempPortNumber  : Int;    // Temporary value for port number
                tempEventNumber : Int;    // Temporary value for event number
                tempIndexDiagRec: Int;    // Temporary value for index of data record (array) of diagnose
            END_VAR

            //cancel command if the internal functionality is already active
            IF statFBState <> StateDiagnose#FB_STATE_NO_PROCESSING THEN
                RETURN;
            END_IF;

            //only allow valid hardware id
            IF hwID = WORD#0 THEN
                RETURN;
            END_IF;

            //reset diagnostic data
            statStatus := Status#STATUS_FIRST_CALL;
			statSubFunctionStatus := Status#STATUS_EXECUTION_FINISHED;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;
			//save the hwID from the previous execute
			statHwIDprevious := statHwID;

			//reset static variables of Diagnose Records
			FOR tempPortNumber := 1 TO Lengths#MAX_PORTS DO
				FOR tempEventNumber := 0 TO Lengths#PORT_EVENT_CODES - 1 DO
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.instance := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.source := FALSE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.eventType := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.mode := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventCode := RESET_WORD;
				END_FOR;
			END_FOR;
			FOR tempIndexDiagRec := 0 TO Lengths#RECORD - 1 DO
				statDiagRecord[tempIndexDiagRec] := RESET_BYTE;
			END_FOR;

            // Check parameters
			IF statStatus = Status#STATUS_FIRST_CALL THEN // Parameters OK
				IF cap <> 0 THEN   //check if cap is predefined, or given by the user
					statCap := TO_UINT(cap);
					statFBState := StateDiagnose#FB_STATE_READ_DIAG;
				ELSIF (statCap <> TO_UINT(Cap#CAP_STANDARD) AND statCap <> TO_UINT(Cap#CAP_LEGACY)) OR (statHwIDprevious <> hwID) THEN
					statFBState := StateDiagnose#FB_STATE_READ_CAP;
				ELSE //CAP already known
					statFBState := StateDiagnose#FB_STATE_READ_DIAG;
				END_IF;
			END_IF;
			//save current hwID
			statHwID := hwID;

            //feedback, that command will be executed
            Start := TRUE;

        END_METHOD

        METHOD PUBLIC Execute
            VAR_TEMP
                tempPortNumber  : Int;    // Temporary value for port number
                tempEventNumber : Int;    // Temporary value for event number
                tempIndexDiagRec: Int;    // Temporary value for index of data record (array) of diagnose
            END_VAR

            CASE statFBState OF // State machine of FB
                StateDiagnose#FB_STATE_NO_PROCESSING: 
                    // No processing active (Note: this state must always be present and left empty)
                    ;
    
                StateDiagnose#FB_STATE_ERROR:
                    //error step. Do nothing
                    //to re-enable operation, call reset()
                    ;

                StateDiagnose#FB_STATE_READ_CAP:
                    // To find out CAP of IO-Link Master, data record with Index 16#B000 is read. If this reading was successful
                    // then CAP is 16#B400 (based on IO-Link Standard). If the reading was not successful and the status of RDREC
                    // is 16#DE80_B0xx, then CAP is 16#00E3 (227, based on Siemens Old Standard for IO-Link Masters).
    
                    instRdRec(record := statRead);
    
                    IF (instRdRec.BUSY = FALSE) THEN
                        IF (instRdRec.VALID = FALSE) AND (instRdRec.ERROR = FALSE) THEN
                            IF instRdRec.request = FALSE THEN
                                // call read record with Index 16#B000
                                instRdRec.request := TRUE;
                                instRdRec.ID := statHwID;
                                instRdRec.index := TO_UINT(Cap#INDEX_CAP_IOLINK);
                                instRdRec.maxLength := UINT#0;
                                statFBState := StateDiagnose#FB_STATE_READ_CAP;
                            END_IF;
                        ELSIF instRdRec.VALID = TRUE THEN
                            instRdRec.request := FALSE;
                            // if status of RDREC is valid then CAP is 16#B400 (CAP_STANDARD)
                            IF instRdRec.STATUS.%B3 = STATUS_RDREC_VALID THEN
                                statCap := TO_UINT(Cap#CAP_STANDARD);
                                statPortNumber := TO_INT(statRead[11]); //read number of ports of IO-Link-Master
                                statPortEco := UINT#1;
                                statIndexDiag := TO_UINT(INDEX_DIAG_ECO) + statPortEco; //Data Record with the status of each port: 0xB20n, n - Port number
                            END_IF;
                            statFBState := StateDiagnose#FB_STATE_READ_DIAG;
                        ELSE
                            // if RDREC is in error state and Status is 16#DE80_B0xx then CAP is 227 (CAP_Legacy)
                            IF (instRdRec.STATUS.%B3 = BitmaskByte#BITMASK_ERR_RDREC_B3) AND (instRdRec.STATUS.%B2 = BitmaskByte#BITMASK_ERR_RDREC_B2) AND (instRdRec.STATUS.%B1 = BitmaskByte#BITMASK_ERR_RDREC_B1) THEN
                                statCap := TO_UINT(Cap#CAP_LEGACY);
                                statIndexDiag := TO_UINT(INDEX_DIAG_OTHER);
                                statFBState := StateDiagnose#FB_STATE_READ_DIAG;
                            ELSE
                                statDone := FALSE;
                                statBusy := FALSE;
                                statError := TRUE;
                                statStatus := Status#ERR_RDREC;
                                statCap := UINT#0; //clear CAP if an error occurs
                                statIndexDiag := UINT#0;
                                statSubFunctionStatus := instRdRec.STATUS;
                                statFBErrorState := statFBState;
                                statFBState := StateDiagnose#FB_STATE_NO_PROCESSING;
                            END_IF;
                        END_IF;
                    ELSE
                        instRdRec.request := FALSE;
                    END_IF;
    
                    instRdRec(record := statRead);
                    // END_REGION
    
                StateDiagnose#FB_STATE_READ_DIAG:
    
                    // REGION read diagnosis in case of Siemens-Version //statIndex 229
                    //diagnose of all ports is read with only one call
                    IF statIndexDiag = TO_UINT(INDEX_DIAG_OTHER) THEN
                        instRdDiag(record := statDiagRecord);
                        IF (instRdDiag.BUSY = FALSE) THEN
                            IF (instRdDiag.VALID = FALSE) AND (instRdDiag.ERROR = FALSE) THEN
                                IF instRdDiag.request = FALSE THEN
                                    instRdDiag.request := TRUE;
                                    instRdDiag.ID := statHwID;
                                    instRdDiag.index := statIndexDiag;
                                    instRdDiag.maxLength := UINT#0;
                                END_IF;
                            ELSE
                                instRdDiag.request := FALSE;
                                IF instRdDiag.VALID = TRUE THEN  //Diagnose valid, statDone is true
                                    statStatus := Status#STATUS_EXECUTION_FINISHED;
                                    statFBState := StateDiagnose#FB_STATE_NO_PROCESSING;
                                    statDone := TRUE;
                                    statBusy := FALSE;
                                    statError := FALSE;
                                ELSE
                                    IF (instRdDiag.STATUS AND STATUS_MASK) <> STATUS_RESOURCE_BUSY THEN  //Error occured
                                        statDone := FALSE;
                                        statBusy := FALSE;
                                        statError := TRUE;
                                        statStatus := Status#ERR_RDREC;
                                        statCap := UINT#0;
                                        statIndexDiag := UINT#0;
                                        statSubFunctionStatus := instRdDiag.STATUS;
                                        statFBErrorState := statFBState;
                                        statFBState := StateDiagnose#FB_STATE_NO_PROCESSING;
                                    END_IF;
                                END_IF;
                            END_IF;
                        ELSE
                            instRdDiag.request := FALSE;
                        END_IF;
                        instRdDiag(record := statDiagRecord);
                    END_IF;
                    // END_REGION
    
                    // REGION read diagnosis in case of Standard-Version // Index 0xB20n, n - Port number
                    IF statIndexDiag = (TO_UINT(INDEX_DIAG_ECO) + statPortEco) THEN
                        //one call for each port diagnose, statPortEco starting from 1 to maximum number of ports
                        IF statPortEco < TO_UINT((statPortNumber + 1)) THEN
                            instRdDiag(record := statDiagRecord);
                            IF (instRdDiag.BUSY = FALSE) THEN
                                IF (instRdDiag.VALID = FALSE) AND (instRdDiag.ERROR = FALSE) THEN
                                    IF instRdDiag.request = FALSE THEN
                                        instRdDiag.request := TRUE;
                                        instRdDiag.ID := statHwID;
                                        instRdDiag.index := statIndexDiag;
                                        instRdDiag.maxLength := UINT#0;
                                    END_IF;
                                ELSE
                                    instRdDiag.request := FALSE;
                                    IF instRdDiag.VALID = TRUE THEN  //Diagnose of port is valid
                                        tempIndexDiagRec := START_INDEX_MASTER_PORT_STATUS_STANDARD; //starting index of data record, where events are recorded
                                        //for each port, the 5 last-events are saved in output
                                        FOR tempEventNumber := 0 TO Lengths#PORT_EVENT_CODES - 1 DO
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.instance.%X0 := statDiagRecord[tempIndexDiagRec].%X0;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.instance.%X1 := statDiagRecord[tempIndexDiagRec].%X1;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.instance.%X2 := statDiagRecord[tempIndexDiagRec].%X2;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.source := statDiagRecord[tempIndexDiagRec].%X3;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.eventType.%X0 := statDiagRecord[tempIndexDiagRec].%X4;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.eventType.%X1 := statDiagRecord[tempIndexDiagRec].%X5;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.mode.%X0 := statDiagRecord[tempIndexDiagRec].%X6;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventQualifier.mode.%X1 := statDiagRecord[tempIndexDiagRec].%X7;
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventCode.%B1 := statDiagRecord[tempIndexDiagRec + 1];
                                            statDiagRecordEco.port[statPortEco].event[tempEventNumber].eventCode.%B0 := statDiagRecord[tempIndexDiagRec + 2];
                                            tempIndexDiagRec := tempIndexDiagRec + 3; //3-bytes for each event => 2 bytes for event code + 1 byte for event type
                                        END_FOR;
                                        statPortEco := statPortEco + UINT#1; //port number is updated => next port
                                        statIndexDiag := TO_UINT(INDEX_DIAG_ECO) + statPortEco; //change index for the next port diagnose
                                    ELSE
                                        IF (instRdDiag.STATUS AND STATUS_MASK) <> STATUS_RESOURCE_BUSY THEN  //Error occured
                                            statDone := FALSE;
                                            statBusy := FALSE;
                                            statError := TRUE;
                                            statStatus := Status#ERR_RDREC;
                                            statCap := UINT#0;
                                            statIndexDiag := UINT#0;
                                            statSubFunctionStatus := instRdDiag.STATUS;
                                            statFBErrorState := statFBState;
                                            statFBState := StateDiagnose#FB_STATE_NO_PROCESSING;
                                            statPortEco := UINT#0;
                                        END_IF;
                                    END_IF;
                                END_IF;
                            ELSE
                                instRdDiag.request := FALSE;
                            END_IF;
                            instRdDiag(record := statDiagRecord);
                        ELSE
                            //diagnose of all ports was successfully read
                            statPortEco := UINT#1;
                            statIndexDiag := TO_UINT(INDEX_DIAG_ECO) + statPortEco;
                            statStatus := Status#STATUS_EXECUTION_FINISHED;
                            statFBState := StateDiagnose#FB_STATE_NO_PROCESSING;
                            statDone := TRUE;
                            statBusy := FALSE;
                            statError := FALSE;
                        END_IF;
                    END_IF;

            ELSE // Undefined state in state machine reached
                statDone := FALSE;
                statBusy := FALSE;
                statError := TRUE;
                statStatus := Status#ERR_UNDEFINED_STATE;
            END_CASE;

            // Fill event codes in case of new received diagnosis data
            IF statDone = TRUE THEN
                IF statIndexDiag = TO_UINT(INDEX_DIAG_OTHER) THEN
                    //Diagnosis record in case of Siemens Old Standard
                    // REGION EVENTCODES_SIEMENS_VERSION
                    //The master post status record has 3 versions (1,2,3-Version). For each post status record there is a different offset, from where the diagnose data can be found.
                    //The master port status version is found in Byte 0 of each port status data record e.g. statDiagRecord[0].
                    //Therefore based on the master port status version, the start index of diagnose data is found.
                    IF statDiagRecord[0] = MASTER_PORT_STATUS_V2 THEN
                        tempIndexDiagRec := START_INDEX_MASTER_PORT_STATUS_V2;
                    ELSIF statDiagRecord[0] = MASTER_PORT_STATUS_V3 THEN
                        tempIndexDiagRec := START_INDEX_MASTER_PORT_STATUS_V3;
                    ELSIF statDiagRecord[0] = MASTER_PORT_STATUS_V4 THEN
                        tempIndexDiagRec := START_INDEX_MASTER_PORT_STATUS_V4;
                    END_IF;
    
                    IF (statDiagRecord[0] = MASTER_PORT_STATUS_V2) OR (statDiagRecord[0] = MASTER_PORT_STATUS_V3) OR (statDiagRecord[0] = MASTER_PORT_STATUS_V4) THEN
                        FOR tempPortNumber := 1 TO Lengths#MAX_PORTS DO
                            FOR tempEventNumber := 0 TO Lengths#PORT_EVENT_CODES - 1 DO
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.instance.%X0 := statDiagRecord[tempIndexDiagRec].%X0;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.instance.%X1 := statDiagRecord[tempIndexDiagRec].%X1;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.instance.%X2 := statDiagRecord[tempIndexDiagRec].%X2;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.source := statDiagRecord[tempIndexDiagRec].%X3;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.eventType.%X0 := statDiagRecord[tempIndexDiagRec].%X4;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.eventType.%X1 := statDiagRecord[tempIndexDiagRec].%X5;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.mode.%X0 := statDiagRecord[tempIndexDiagRec].%X6;
                                events.port[tempPortNumber].event[tempEventNumber].eventQualifier.mode.%X1 := statDiagRecord[tempIndexDiagRec].%X7;
                                events.port[tempPortNumber].event[tempEventNumber].eventCode.%B1 := statDiagRecord[tempIndexDiagRec + 1];
                                events.port[tempPortNumber].event[tempEventNumber].eventCode.%B0 := statDiagRecord[tempIndexDiagRec + 2];
                                tempIndexDiagRec := tempIndexDiagRec + 3; //3-bits for each event, 2 bits for eventcode + 1 bit for event type
                            END_FOR;
                            tempIndexDiagRec := tempIndexDiagRec + 4; //4 bits reserved for other purposes between Port Diagnoses
                        END_FOR;
                    END_IF;
                    // END_REGION
                    //Diagnosis record in case of IO-Link-Standard
                ELSIF statIndexDiag = (TO_UINT(INDEX_DIAG_ECO) + statPortEco) THEN
                    // REGION EVENTCODES_STANDARD_VERSION
                    events := statDiagRecordEco;
                    // END_REGION
                END_IF;
            ELSIF statError = TRUE THEN  //Error occurred
                diagnostics.status := statStatus;
                diagnostics.subfunctionStatus := statSubFunctionStatus;
                diagnostics.stateNumber := statFBErrorState;
            END_IF;

        END_METHOD

        METHOD PUBLIC OVERRIDE Reset
        
            //clear internal FB calls
			instRdRec(request    := FALSE,
				record := statRead);

			instRdDiag(request := FALSE, 
                record := statDiagRecord);

            SUPER.Reset();
        END_METHOD


    END_CLASS

END_NAMESPACE
