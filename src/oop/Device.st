USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.IOLink

    CLASS PUBLIC Device EXTENDS IOLinkBase
        VAR PUBLIC            
            data : LIOLink_typeRecordData;
            length : UINT;
        END_VAR

        VAR PRIVATE
			dataInternal         : LIOLink_typeRecordData;
    		statHwID             : HW_IO;                                 // Static value for input 'hwID'
			statHwIDprevious     : HW_IO;                                 // Static value for input 'hwID' from the previous execute 
			statCap              : UInt;                                  // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
			statPort             : INT;                                   // Port on IO-Link master module
			statIndex            : INT;                                   // Address parameter index (IO-Link device); 0..32767: IOL-D; 65535: port functions
			statSubIndex         : INT;                                   // Address parameter subindex (IO-Link device); 0: full record; 1-255: single parameter  
            statLength           : UInt;                                  // Length of data to be written to device
            statMode             : Mode;
			statPollingPeriod    : LTIME := LTIME#100MS;                       // Static value for input 'pollingPeriod'
			statTimeout          : LTIME := LTIME#20s;                         // Static value for input 'timeout'
            statRead             : LIOLink_typeReadWrite;
			statWrite            : LIOLink_typeReadWrite;
            statBuffer           : Array[0..Lengths#RECORD_WITH_HEADER - 1] OF BYTE;
            instRdRec            : ReadRecord;                                        // System function "read data record"
			instWrRec            : WriteRecord;                                       // System function "write data record"
			instPoll             : System.Timer.Pulse;                                // poll rate read data record
			instMonitor          : System.Timer.OnDelay;                              // request monitoring time
        END_VAR

        METHOD PUBLIC Setup
            VAR_INPUT
                hwID         : HW_IO;
                cap          : UINT;
                port         : INT;
                index        : INT;
                subindex     : INT;
                timeout      : LTIME := LTIME#20s;
                pollingPeriod: LTIME := LTIME#100ms;
            END_VAR

            statHwID := hwID;
            statcap := cap;
            statPort := port;
            statIndex := index;
            statSubIndex := subindex;
            IF timeout > LTIME#0s THEN
                statTimeout := timeout;
            END_IF;
            IF pollingPeriod > LTIME#0s THEN
                statPollingPeriod := pollingPeriod;
            END_IF;
            
        END_METHOD

        METHOD PUBLIC Read : BOOL
            VAR_OUTPUT
                status : WORD;
            END_VAR
            VAR_TEMP
                tempEmptyRecord : LIOLink_typeRecordData;
            END_VAR
            
            // Empty record array
            data := tempEmptyRecord;
            
            IF NOT THIS.ReadWriteReqInternal() THEN
                RETURN;
            END_IF;

            statWrite.header.iolHeader.control := Control#CONTROL_READ;
            statLength := TO_UINT(Lengths#RECORD_HEADER); // data length only header = IO-Link read data record
            Read := TRUE;
            statMode := Mode#READ;
            status := statStatus;

        END_METHOD

        METHOD PUBLIC Write : BOOL
            VAR_OUTPUT
                status : WORD;
            END_VAR

            IF NOT THIS.ReadWriteReqInternal() THEN
                RETURN;
            END_IF;

            //check length of write request
            IF length < UINT#1 OR length > TO_UINT(Lengths#RECORD) THEN
                statStatus := Status#ERR_WRONG_LENGTH;
                //stop execution to prohibit access out of array bounds
                RETURN;
            END_IF;

            //copy write request data to internal structure to prevent changes while executing
            statWrite.data := data;

            statWrite.header.iolHeader.control := Control#CONTROL_WRITE;
            statLength := length + TO_UINT(Lengths#RECORD_HEADER); // data length header + data = IO-Link write data record
            //set status
            Write := TRUE;
            statMode := Mode#WRITE;
            status := statStatus;
            
        END_METHOD

        METHOD PROTECTED ReadWriteReqInternal : BOOL

            //check internal state
            IF statFBState <> StateDevice#FB_STATE_NO_PROCESSING THEN
                statStatus := Status#ERR_EXECUTION_ACTIVE;
                RETURN;
            END_IF;

            statStatus := Status#STATUS_FIRST_CALL;

            // setup call header
            statWrite.header.call.port := TO_BYTE(statPort);

            // setup IOL header 
            statWrite.header.iolHeader.indexLowByte := TO_BYTE(statIndex);
            statWrite.header.iolHeader.indexHighByte := TO_BYTE(SHR(TO_WORD(statIndex), UINT#8));
            statWrite.header.iolHeader.subindex := TO_BYTE(statSubindex);

            // Check parameters
            IF (statPort < 0) OR (statPort > TO_INT(Limit#MAX_PORT)) THEN
                statStatus := Status#ERR_WRONG_PORT;
            ELSIF (statIndex < 0) OR FALSE (*(statIndex > MAX_INDEX AND statIndex <> INDEX_PORT_FUNC)*) THEN //deactivate check, since it could never be valid anyway
                statStatus := Status#ERR_WRONG_INDEX;
            ELSIF (statSubIndex < 0) OR (statSubIndex > TO_INT(Limit#MAX_SUBINDEX)) THEN
                statStatus := Status#ERR_WRONG_SUBINDEX;
            END_IF;

            //save the hwID from the previous execute
            statHwIDprevious := statHwID;

            IF statStatus = Status#STATUS_FIRST_CALL THEN
                //found no issues, return TRUE
                ReadWriteReqInternal := TRUE;
                statBusy := TRUE;

                //check if cap needs to be read out before accessing the device
                IF statcap <> UINT#0 THEN
                    statFBState := StateDevice#FB_STATE_PREPARE_WRITE;
                ELSIF (statCap <> TO_UINT(Cap#CAP_STANDARD) AND statCap <> TO_UINT(Cap#CAP_LEGACY)) OR (statHwIDprevious <> statHwID) THEN // check if new device is connected => hwID changed
                    statFBState := StateDevice#FB_STATE_READ_CAP;
                ELSE
                    statFBState := StateDevice#FB_STATE_PREPARE_WRITE;
                END_IF;
            END_IF;

        END_METHOD

        METHOD PUBLIC Execute

            VAR_TEMP
                tempIndexCounter : INT;
                temploopTest : INT;
            END_VAR

            CASE statFBState OF
                StateDevice#FB_STATE_NO_PROCESSING:
                    ; // No processing active
                    // END_REGION no processing    
    
                StateDevice#FB_STATE_READ_CAP:
                    // To find out CAP of IO-Link Master, data record with Index 16#B000 is read. If this reading was successful
                    // then CAP is 16#B400 (based on IO-Link Standard). If the reading was not successful and the status of RDREC
                    // is 16#DE80_B0xx, then CAP is 16#00E3 (227, based on Siemens Old Standard for IO-Link Masters).
    
                    instRdRec(record := statBuffer);
    
                    IF (instRdRec.BUSY = FALSE) THEN
                        IF (instRdRec.VALID = FALSE) AND (instRdRec.ERROR = FALSE) THEN
                            IF instRdRec.request = FALSE THEN
                                // call read record with Index 16#B000
                                instRdRec.request := true;
                                instRdRec.ID := statHwID;
                                instRdRec.index := TO_UINT(Cap#INDEX_CAP_IOLINK);
                                instRdRec.maxLength := UINT#0;
                                statFBState := StateDevice#FB_STATE_READ_CAP;
                            END_IF;
                        ELSIF instRdRec.VALID = TRUE THEN

                            instRdRec.request := FALSE;
                            // if status of RDREC is valid then CAP is 16#B400 (CAP_STANDARD)
                            IF instRdRec.STATUS.%B3 = ReadWriteRecordStatus#STATUS_RDREC_VALID THEN
                                statCap := TO_UINT(Cap#CAP_STANDARD);
                            END_IF;
                            statFBState := StateDevice#FB_STATE_PREPARE_WRITE;
                        ELSE
                            // if RDREC is in error state and Status is 16#DE80_B0xx then CAP is 227 (CAP_Legacy)
                            IF (instRdRec.STATUS.%B3 = BitmaskByte#BITMASK_ERR_RDREC_B3) AND (instRdRec.STATUS.%B2 = BitmaskByte#BITMASK_ERR_RDREC_B2) AND (instRdRec.STATUS.%B1 = BitmaskByte#BITMASK_ERR_RDREC_B1) THEN
                                statCap := TO_UINT(Cap#CAP_LEGACY);
                                statFBState := StateDevice#FB_STATE_PREPARE_WRITE;
                            ELSE
                                statStatus := Status#ERR_RDREC;
                                statSubfunctionStatus := instRdRec.STATUS;
                                statCap := UINT#0; //clear CAP if an error occurs
                            END_IF;
                        END_IF;
                    ELSE
                        instRdRec.request := FALSE;
                        IF instRdRec.ERROR = TRUE THEN
                            statStatus := Status#ERR_RDREC;
                            statSubfunctionStatus := instRdRec.STATUS;
                            statCap := UINT#0; //clear CAP if an error occurs
                        END_IF;
                    END_IF;
                    
    
                    instRdRec(record := statBuffer);
                    // END_REGION
    
                StateDevice#FB_STATE_PREPARE_WRITE:
    
                    //read and write record system functions in SIMATIC AX are more strict
                    //it is not possible to add a struct as VAR_IN_OUT to them
                    //instead, a byte array is needed. This intermediate step converts the struct data to write into the byte array for the system function
                    SerializeBig(offset := UDINT#0, value := statWrite, buffer := statBuffer);
                    statFBState := StateDevice#FB_STATE_WRITE;
    
                StateDevice#FB_STATE_WRITE:
                    // To read data records, the IO-Link master modules needs to know which port is required. Therefore it is necessary
                    // to send at first a request via write data record (header, 8 byte). As response the IO-Link master module will 
                    // send the required data record.
    
                    instWrRec(request := TRUE,
                        ID := statHwID,
                        index := statCap,
                        length := statLength,
                        record := statBuffer);
    
                    IF instWrRec.ERROR THEN
                        IF (instWrRec.STATUS AND BitmaskDWord#STATUS_MASK) = BitmaskDWord#STATUS_RESOURCE_BUSY THEN
                            instWrRec(request := FALSE, record := statBuffer); // Reset request
                        ELSE
                            statStatus := status#ERR_WRREC;
                            statSubfunctionStatus := instWrRec.STATUS;
                            statFBErrorState := statFBState;
                        END_IF;
                    ELSIF instWrRec.DONE = TRUE THEN
                        instWrRec(request := FALSE, record := statBuffer); // Reset request
    
                        //write read config into buffer
                        SerializeBig(offset := UDINT#0, value := statRead, buffer := statBuffer);
                        statFBState := StateDevice#FB_STATE_POLL;
                    END_IF;
                    // END_REGION write
    
                StateDevice#FB_STATE_POLL: // wait and poll for response
                    // REGION poll
                    instPoll(signal := TRUE,
                        duration := statPollingPeriod);
    
                    // read data record on falling edge
                    instRdRec(request := NOT instPoll.output,
                        ID := statHwID,
                        index := statCap,
                        maxLength := UINT#0, // read all data available,
                        record := statBuffer);
    
                    IF instRdRec.ERROR = TRUE THEN
                        IF (instRdRec.STATUS AND BitmaskDWord#STATUS_MASK) = BitmaskDWord#STATUS_RESOURCE_BUSY THEN
                            // Reset requests and try again
                            instPoll(signal := FALSE,
                            duration := statPollingPeriod);
    
                            instRdRec(request := FALSE,
                            record := statBuffer);
                        ELSE
                            statStatus := status#ERR_RDREC;
                            statSubfunctionStatus := instRdRec.STATUS;
                            statFBErrorState := statFBState;
                        END_IF;
                    ELSIF instRdRec.VALID THEN

                        //deserialize received data
                        DeserializeBig(offset := UDINT#0, value := statRead, buffer := statBuffer);
                        IF // check the response wether it matches the request (compare PORT, index and SUBINDEX)
                            (statWrite.header.call.port <> statRead.header.call.port)
                            OR (statWrite.header.iolHeader.indexHighByte <> statRead.header.iolHeader.indexHighByte)
                            OR (statWrite.header.iolHeader.indexLowByte <> statRead.header.iolHeader.indexLowByte)
                            OR (statWrite.header.iolHeader.subindex <> statRead.header.iolHeader.subindex)
                        THEN // read data record doesn't match the request
                            statStatus := status#ERR_INCONSISTENT_DATA;  // output status no consistent data
                        ELSIF statRead.header.iolHeader.control = Byte#16#80 THEN // check the response for IO-Link errors
                            // State 0x80 = IOL_CALL_RES PDU shows IO-Link error detect
                            statStatus := status#ERR_IO_LINK;
                            statSubfunctionStatus.%B3 := statRead.data[0]; // IO-Link master error code
                            statSubfunctionStatus.%B2 := statRead.data[1]; // IO-Link master error code
                            statSubfunctionStatus.%B1 := statRead.data[2]; // ISDU error code
                            statSubfunctionStatus.%B0 := statRead.data[3]; // ISDU additional code
                            statFBErrorState := statFBState;
                        ELSE // read data is valid
                            IF statMode = Mode#READ THEN
                                length := instRdRec.length - TO_UINT(Lengths#RECORD_HEADER);
                                // only data will be output
                                FOR tempIndexCounter := 0 TO TO_INT(instRdRec.length - TO_UINT(Lengths#RECORD_HEADER) - UINT#1) DO
                                    data[tempIndexCounter] := statRead.data[tempIndexCounter];
                                END_FOR;
                            END_IF;
    
                            // Reset requests
                            instRdRec(request := FALSE,
                            record := statBuffer);
    
                            instPoll(signal := FALSE,
                            duration := statPollingPeriod);
    
                            statStatus := status#STATUS_EXECUTION_FINISHED;  // request finished
                        END_IF;
                    END_IF;
                    // END_REGION poll
    
                ELSE // Undefined state in state machine reached
                    // REGION undefined state
                    statStatus := status#ERR_UNDEFINED_STATE;
                    // END_REGION undefined state no relevant case, ready for new request
            END_CASE;
            // END_REGION

            IF (statStatus = status#STATUS_EXECUTION_FINISHED)  THEN // Execution finished without errors
                // REGION execution finished
                statDone := TRUE;
                statBusy := FALSE;
                statError := FALSE;
                // execution aborted --> set state no processing
                statFBState := StateDevice#FB_STATE_NO_PROCESSING;
                // END_REGION execution finished
    
            ELSIF (statStatus.%X15 = TRUE)  THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
                // REGION error occured
                statDone := FALSE;
                statBusy := FALSE;
                statError := TRUE;
                statCap := UINT#0; //Reset statcap, if error occurs, get cap has to be performed again
                // Write diagnostics
                statDiagnostics.status := statStatus;
                statDiagnostics.subfunctionStatus := statSubfunctionStatus;
                statDiagnostics.stateNumber := statFBErrorState;
                // Call instructions with FALSE to be ready for next job
                instWrRec(request := FALSE, record := statBuffer);
    
                instRdRec(request := FALSE,
                record := statBuffer);
    
                instPoll(signal := FALSE,
                duration := statPollingPeriod);

                statFBState := StateDevice#FB_STATE_ERROR;
    
            END_IF;

        END_METHOD

    END_CLASS

END_NAMESPACE
