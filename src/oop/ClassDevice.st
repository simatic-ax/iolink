NAMESPACE Simatic.Ax.IOLink

    CLASS IoLinkDevice
        VAR PUBLIC
            data : LIOLink_typeRecordData;
        END_VAR
        VAR PRIVATE
			dataInternal         : LIOLink_typeRecordData;
			statDone             : Bool;                                  // Static value for output 'done'
			statBusy             : Bool;                                  // Static value for output 'busy'
			statError            : Bool;                                  // Static value for output 'error'
			statStatus           : Word := Status#STATUS_NO_CALL;         // Static value for output 'status'                               
			statHwID             : HW_IO;                                 // Static value for input 'hwID'
			statHwIDprevious     : HW_IO;                                 // Static value for input 'hwID' from the previous execute 
			statCap              : UInt;                                  // Static value for input 'cap'
			statPort             : INT;
			statIndex            : INT;
			statSubIndex         : INT;
            statLength           : UInt;                                              // Length of data to be written to device
			statPollingPeriod    : LTIME := LTIME#100MS;                       // Static value for input 'pollingPeriod'
			statTimeout          : LTIME := LTIME#20s;                         // Static value for input 'timeout'
            statRead             : LIOLink_typeReadWrite;
			statWrite            : LIOLink_typeReadWrite;
			statSubfunctionStatus: DWord;                                 // Status of WRREC/RDREC or error code from IO-Link Master (%W1: IO-Link Master error, %W0: ISDU error)
			statFBErrorState     : DInt;                                  // State in the state machine of the block where the error occurred
			statFBState          : DInt := ClassDeviceState#FB_STATE_NO_PROCESSING;  // State in the state machine of the FB
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

        METHOD SetWriteCommand : BOOL
            VAR_INPUT
                writeLength : UINT;
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            VAR_TEMP
                tempIndexCounter : INT;
            END_VAR

            IF statFBState = ClassDeviceState#FB_STATE_NO_PROCESSING THEN
                statStatus := Status#STATUS_FIRST_CALL;
                IF writeLength < UINT#1 OR writeLength > TO_UINT(Lengths#RECORD) THEN
                    statStatus := Status#ERR_WRONG_LENGTH;
                    //stop execution to prohibit access out of array bounds
                    RETURN;
                END_IF;

                // REGION Build header
                // setup call header
                statWrite.header.call.port := TO_BYTE(statPort);

                // setup IOL header 
                statWrite.header.iolHeader.indexLowByte := TO_BYTE(statIndex);
                statWrite.header.iolHeader.indexHighByte := TO_BYTE(SHR(TO_WORD(statIndex), UINT#8));
                statWrite.header.iolHeader.subindex := TO_BYTE(statSubindex);

                // BODY (data max. 232 Byte, Array 0..231 of Byte) 
                statWrite.header.iolHeader.control := Control#CONTROL_WRITE;
                statLength := writeLength + TO_UINT(Lengths#RECORD_HEADER); // data length header + data = IO-Link write data record
                // copy "record" to working area
                FOR tempIndexCounter := 0 TO TO_INT(writeLength) - 1 DO
                    statWrite.data[tempIndexCounter] := data.data[tempIndexCounter];
                END_FOR;

                // REGION Check parameters
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

                IF statStatus = Status#STATUS_FIRST_CALL THEN // Parameters OK
                    IF statcap <> UINT#0 THEN
                        statFBState := ClassDeviceState#FB_STATE_WRITE;
                    ELSIF (statCap <> TO_UINT(Cap#CAP_STANDARD) AND statCap <> TO_UINT(Cap#CAP_LEGACY)) OR (statHwIDprevious <> statHwID) THEN // check if new device is connected => hwID changed
                        statFBState := ClassDeviceState#FB_STATE_READ_CAP;
                    ELSE
                        statFBState := ClassDeviceState#FB_STATE_WRITE;
                    END_IF;
                    //feedback, that command will be executed
                    SetWriteCommand := TRUE;
                END_IF;
                // END_REGION
                    ;
            ELSE
                statStatus := Status#ERR_EXECUTION_ACTIVE;
            END_IF;

            //write status to output for diagnostic purposes
            status := statStatus;
            
        END_METHOD

        METHOD PUBLIC SetReadCommand : BOOL
            VAR_INPUT
            END_VAR
            VAR_OUTPUT
                status : WORD;
            END_VAR
            VAR_TEMP
                tempEmptyRecord : LIOLink_typeRecordData;
            END_VAR
            
            IF statFBState = ClassDeviceState#FB_STATE_NO_PROCESSING THEN
                // REGION Build header
                // setup call header
                statWrite.header.call.port := TO_BYTE(statPort);

                // setup IOL header 
                statWrite.header.iolHeader.indexLowByte := TO_BYTE(statIndex);
                statWrite.header.iolHeader.indexHighByte := TO_BYTE(SHR(TO_WORD(statIndex), UINT#8));
                statWrite.header.iolHeader.subindex := TO_BYTE(statSubindex);

                // BODY (data max. 232 Byte, Array 0..231 of Byte) 
                // Read data record requested
                // Empty record array
                data := tempEmptyRecord;

                statWrite.header.iolHeader.control := Control#CONTROL_READ;
                statLength := TO_UINT(Lengths#RECORD_HEADER); // data length only header = IO-Link read data record
                // END_REGION

                // REGION Check parameters
                // Check parameters
                IF (statPort < 0) OR (statPort > TO_INT(Limit#MAX_PORT)) THEN
                    statStatus := Status#ERR_WRONG_PORT;
                ELSIF (statIndex < 0) OR FALSE (*(tempIndex > MAX_INDEX AND tempIndex <> INDEX_PORT_FUNC)*) THEN //deactivate check, since it could never be valid anyway
                    statStatus := Status#ERR_WRONG_INDEX;
                ELSIF (statSubindex < 0) OR (statSubindex > TO_INT(Limit#MAX_SUBINDEX)) THEN
                    statStatus := Status#ERR_WRONG_SUBINDEX;
                END_IF;
                //save the hwID from the previous execute
                statHwIDprevious := statHwID;

                IF statStatus = Status#STATUS_FIRST_CALL THEN // Parameters OK
                    IF statcap <> UINT#0 THEN
                        statFBState := ClassDeviceState#FB_STATE_WRITE;
                    ELSIF (statCap <> TO_UINT(Cap#CAP_STANDARD) AND statCap <> TO_UINT(Cap#CAP_LEGACY)) OR (statHwIDprevious <> statHwID) THEN // check if new device is connected => hwID changed
                        statFBState := ClassDeviceState#FB_STATE_READ_CAP;
                    ELSE
                        statFBState := ClassDeviceState#FB_STATE_WRITE;
                    END_IF;
                    //feedback: request is valid and will be processed
                    SetReadCommand := TRUE;
                END_IF;
            ELSE
                statStatus := Status#ERR_EXECUTION_ACTIVE;
            END_IF;

            //write status to output for diagnostic purposes
            status := statStatus;

        END_METHOD

        METHOD PUBLIC SetDiagnose : BOOL
            VAR_INPUT
                hwID : HW_IO;
                cap : INT;
            END_VAR
            ;
        END_METHOD

        METHOD PUBLIC Execute
            ;
        END_METHOD

        METHOD PUBLIC GetStatus
            VAR_OUTPUT
                busy  : BOOL;
                error : BOOL;
                done  : BOOL;
            END_VAR
            ;
        END_METHOD

    END_CLASS

    TYPE
        Command : (READ, WRITE, DIAGNOSE);
    END_TYPE

END_NAMESPACE
