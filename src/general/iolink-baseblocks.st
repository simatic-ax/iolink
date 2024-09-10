USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.IOLink
	FUNCTION_BLOCK LIOLink_Device
		/// LIOLink_Device
		// Author : SIOS
		// Family : LIOLink
		// Version : 4.0
		//Acyclically reads or writes data records from and to IO-Link devices
		VAR_INPUT 
			execute      : Bool;             // Request to execute function
			hwID         : HW_IO;            // Hardware identifier of IO-Link master module or first sub module
			cap          : Int;              // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
			readWrite    : Bool;             // FALSE: read-mode, TRUE: write-mode
			port         : Int;              // Port on IO-Link master module
			index        : Int;              // Address parameter index (IO-Link device); 0..32767: IOL-D; 65535: port functions
			subindex     : Int;              // Address parameter subindex (IO-Link device); 0: full record; 1-255: single parameter
			writeLen     : Int;              // Length of writing data (net data); 1..232
			timeout      : Time := T#20S;    // Time after which the request is aborted
			pollingPeriod: Time := T#100MS;  // Time period of polling
		END_VAR

		VAR_OUTPUT 
			done       : Bool;                     // TRUE: FB processing successfully completed
			busy       : Bool;                     // TRUE: FB is active and new output values can be expected.
			error      : Bool;                     // FALSE: No error / TRUE: An error occurred during the execution of the FB.
			status     : Word := STATUS_NO_CALL;   // 16#0000-16#7FFF: Status of the FB / 16#8000-16#FFFF: Error identification (see following table)
			diagnostics: LIOLink_typeDiagnostics;  // Diagnostics information of FB
			readLen    : Int;                      // Length of read data record (number of bytes)
		END_VAR

		VAR_IN_OUT 
			record : LIOLink_typeRecordData;   // Data area for reading/writing data (max. 232 byte)
		END_VAR

		VAR 
			statExecuteOld       : Bool;                                              // Old value of 'execute' input for edge detection
			statDone             : Bool;                                              // Static value for output 'done'
			statBusy             : Bool;                                              // Static value for output 'busy'
			statError            : Bool;                                              // Static value for output 'error'
			statStatus           : Word := STATUS_NO_CALL;                            // Static value for output 'status'
			statPollingPeriod    : Time := T#100MS;                                   // Static value for input 'pollingPeriod'
			statHwID             : HW_IO;                                             // Static value for input 'hwID'
			statHwIDprevious     : HW_IO;                                             // Static value for input 'hwID' from the previous execute 
			statReadWrite        : Bool;                                              // Static value for input 'readWrite'
			statCap              : UInt;                                              // Static value for input 'cap'
			statTimeout          : Time;                                              // Static value for input 'timeout'
			statLen              : UInt;                                              // Length of data to be written to device
			statSubfunctionStatus: DWord;                                             // Status of WRREC/RDREC or error code from IO-Link Master (%W1: IO-Link Master error, %W0: ISDU error)
			statFBErrorState     : DInt;                                              // State in the state machine of the block where the error occurred
			statFBState          : DInt := FB_STATE_NO_PROCESSING;                    // State in the state machine of the FB
			statEmptyDiagnostics : LIOLink_typeDiagnostics;                           // Empty diagnostics information (for initialization purposes only)
			instRdRec            : ReadRecord;                                        // System function "read data record"
			instWrRec            : WriteRecord;                                       // System function "write data record"
			instPoll             : System.Timer.Pulse;                                // poll rate read data record
			instMonitor          : System.Timer.OnDelay;                              // request monitoring time
			statRead             : LIOLink_typeReadWrite;
			statWrite            : LIOLink_typeReadWrite;
			statBuffer           : Array[0..Lengths#RECORD_WITH_HEADER - 1] OF BYTE;
		END_VAR

		VAR_TEMP 
			tempExecute     : Bool;        // Temporary value for input 'execute'
			tempHwID        : HW_IO;       // Temporary value for input 'hwID'
			tempPort        : Int;         // Temporary value for input 'port'
			tempIndex       : Int;         // Temporary value for input 'index'
			tempSubindex    : Int;         // Temporary value for input 'subindex'
			tempIndexCounter: DInt;        // run tag for counting loops
			tempEmptyRecord : LIOLink_typeRecordData;
		END_VAR

		VAR CONSTANT 
			MODE_READ                 : Bool  := FALSE;               // Mode to read data
			MODE_WRITE                : Bool  := TRUE;                // Mode to write data
			MAX_PORT                  : USInt := USINT#63;            // Max. possible port
			MAX_INDEX                 : UInt  := UINT#32767;          // Max. possible index
			INDEX_PORT_FUNC           : UInt  := UINT#65535;          // Index to address port functions
			MAX_SUBINDEX              : USInt := USINT#255;           // Max. possible subindex
			MAX_DATA                  : USInt := USINT#232;           // Max. size of data to be transferred
			UPPER_LIMIT               : DInt  := 231;                 // Upper limit of data to be transferred
			FB_STATE_NO_PROCESSING    : DInt  := 0;                   // FB state: No processing
			FB_STATE_PREPARE_WRITE    : DINT  := 10;
			FB_STATE_WRITE            : DInt  := 1;                   // FB state: Write data record
			FB_STATE_POLL             : DInt  := 2;                   // FB state: Wait and poll for response
			FB_STATE_READ_CAP         : DInt  := 3;                   // FB state: Read cap
			IOL_HEADER                : UInt  := UINT#65098;          // Header IO-Link
			LEN_HEADER                : USInt := USINT#8;             // Length of header
			CONTROL_WRITE             : Byte  := BYTE#16#02;          // Write data record
			CONTROL_READ              : Byte  := BYTE#16#03;          // Read data record
			STATUS_EXECUTION_FINISHED : Word  := WORD#16#0000;        // Execution finished without errors
			STATUS_NO_CALL            : Word  := WORD#16#7000;        // No job being currently processed
			STATUS_FIRST_CALL         : Word  := WORD#16#7001;        // First call after incoming new job (rising edge 'execute')
			STATUS_SUBSEQUENT_CALL    : Word  := WORD#16#7002;        // Subsequent call during active processing without further details
			SUB_STATUS_NO_ERROR       : Word  := WORD#16#0000;        // No error occured in subfunction call
			ERR_WRONG_PORT            : Word  := WORD#16#8201;        // Error: wrong port
			ERR_WRONG_INDEX           : Word  := WORD#16#8202;        // Error: wrong index
			ERR_WRONG_SUBINDEX        : Word  := WORD#16#8203;        // Error: wrong subindex
			ERR_WRONG_LENGTH          : Word  := WORD#16#8205;        // Error: wrong length for write data record
			ERR_IO_LINK               : Word  := WORD#16#8401;        // Error: IO-Link master returned error code, see "diagnostics"
			ERR_INCONSISTENT_DATA     : Word  := WORD#16#8402;        // Error: Read data record doesn't match request
			ERR_REQUEST_TIMEOUT       : Word  := WORD#16#8403;        // Error: Request timed out
			ERR_UNDEFINED_STATE       : Word  := WORD#16#8600;        // Error: due to an undefined state in state machine
			ERR_WRREC                 : Word  := WORD#16#8601;        // Error: WRREC encountered an error, see "diagnostics"
			ERR_RDREC                 : Word  := WORD#16#8602;        // Error: RDREC encountered an error, see "diagnostics"
			STATUS_MASK               : DWord := DWORD#16#00FF_FF00;  // Mask to filter error codes
			STATUS_RESOURCE_BUSY      : DWord := DWORD#16#0080_C200;  // Status from WRREC/RDREC: Resource is busy
			INDEX_CAP_IOLINK          : Word  := WORD#16#B000;        // Index of the data record for IOLM_Info. Only IO-Link-Masters with CAP=16#B000 support this call.
			CAP_LEGACY                : Word  := WORD#16#00E3;        // Siemens (old) Standard CAP: 227
			CAP_STANDARD              : Word  := WORD#16#B400;        // IO-Link Standard CAP: 16#B400
			STATUS_RDREC_VALID        : Byte  := BYTE#16#00;          // Status Code of RDREC in cased of no error occurs
			BITMASK_ERR_RDREC_B3      : Byte  := BYTE#16#DE;          // Status Code of RDREC in case of an error when reading a data record
			BITMASK_ERR_RDREC_B2      : Byte  := BYTE#16#80;          // Status Code of RDREC in case of an error when reading a data record - Error according to IEC 61158-6
			BITMASK_ERR_RDREC_B1      : Byte  := BYTE#16#B0;          // Status Code of RDREC in case of an error when reading a data record - invalid index (cap)
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2023
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_Device
		// Function:         Acyclically reads or writes data records from and to IO-Link devices
		// Library:          LIOLink
		// Author:           Siemens Industry Online Support
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     S7-1200/1500
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 02.00.00 | 30.09.2013 | Online Support         | First release for TIA Portal V12 SP1 as IO_LINK_CALL
		// 02.01.00 | 14.03.2014 | Online Support         | Upgrade to TIA Portal V13
		//                                                | Upgrade of system function 'WRREC' from V1.0 to V1.1
		// 03.00.00 | 28.02.2015 | SUP Applications       | Upgrade to TIA Portal V13 SP1
		//                                                | Renamed FB to IO_LINK_DEVICE 
		// 03.01.00 | 15.09.2015 | SUP Applications       | Change of #IOL_INDEX AND #Port lower boundry to 0 and improved behaviour when called in cyclic OBs with > 100 ms
		// 04.00.00 | 01.09.2020 | Online Support         | Implemented Programming styleguide for S7-1200/1500 and PLCopen
		//                                                | Renamed FB to LIOLink_Device 
		// 05.00.00 | 28.02.2023 | SUP SPH                | Added Polling Time as predefined input
		//                                                | #record is changed to a variable array (Array[*])
		//                                                | Changed CAP as predefined variable, added functionality to automatically find CAP of IO-Link-Masters from SIEMENS                                               
		//===============================================================================
		// END_REGION

		// REGION TRIGGERING
		tempExecute := execute; // Work with temporary value / create process image

		IF (tempExecute = TRUE) AND (statExecuteOld = FALSE) // Check if FB is triggered
			AND (statStatus = STATUS_NO_CALL)
		THEN
			// REGION Initialize data
			// First call; initialize FB
			statDone := FALSE;
			statBusy := TRUE;
			statError := FALSE;
			statStatus := STATUS_FIRST_CALL;
			statSubfunctionStatus := SUB_STATUS_NO_ERROR;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;
			readLen := 0;

			// Initialize data area
			statRead.header.call.port := BYTE#16#0;
			statRead.header.iolHeader.indexLowByte := BYTE#16#0;
			statRead.header.iolHeader.indexHighByte := BYTE#16#0;
			statRead.header.iolHeader.subindex := BYTE#16#0;
			tempIndexCounter := 0; // initialize loop counter      
			FOR tempIndexCounter := 0 TO UPPER_LIMIT DO
				statWrite.data[tempIndexCounter] := BYTE#16#0;
				statRead.data[tempIndexCounter] := BYTE#16#0;
			END_FOR;
			// END_REGION

			// REGION Save inputs
			// Copy input variables to temporary variables
			tempHwID := hwID;
			statReadWrite := readWrite;
			statTimeout := timeout;
			statPollingPeriod := pollingPeriod;
			tempPort := port;
			tempIndex := index;
			tempSubindex := subindex;
			// END_REGION

			// REGION Build header
			// setup call header
			statWrite.header.call.port := TO_BYTE(tempPort);

			// setup IOL header 
			statWrite.header.iolHeader.indexLowByte := TO_BYTE(tempIndex);
			statWrite.header.iolHeader.indexHighByte := TO_BYTE(SHR(TO_WORD(tempIndex), UINT#8));
			statWrite.header.iolHeader.subindex := TO_BYTE(tempSubindex);

			// BODY (data max. 232 Byte, Array 0..231 of Byte) 
			IF statReadWrite = MODE_WRITE THEN // Write data record requested, copy data from "record"
				statWrite.header.iolHeader.control := CONTROL_WRITE;
				statLen := TO_UINT(writeLen) + LEN_HEADER; // data length header + data = IO-Link write data record
				// copy "record" to working area
				FOR tempIndexCounter := 0 TO writeLen - 1 DO
					statWrite.data[tempIndexCounter] := record.data[tempIndexCounter];
				END_FOR;
			ELSE // Read data record requested
				// Empty record array
				record := tempEmptyRecord;

				statWrite.header.iolHeader.control := CONTROL_READ;
				statLen := LEN_HEADER; // data length only header = IO-Link read data record
			END_IF;
			// END_REGION

			// REGION Check parameters
			// Check parameters
			IF (tempPort < 0) OR (tempPort > MAX_PORT) THEN
				statStatus := ERR_WRONG_PORT;
			ELSIF (tempIndex < 0) OR FALSE (*(tempIndex > MAX_INDEX AND tempIndex <> INDEX_PORT_FUNC)*) THEN //deactivate check, since it could never be valid anyway
				statStatus := ERR_WRONG_INDEX;
			ELSIF (tempSubindex < 0) OR (tempSubindex > MAX_SUBINDEX) THEN
				statStatus := ERR_WRONG_SUBINDEX;
			ELSIF statReadWrite = MODE_WRITE AND (writeLen < 1 OR writeLen > MAX_DATA) THEN
				statStatus := ERR_WRONG_LENGTH;
			END_IF;
			//save the hwID from the previous execute
			statHwIDprevious := statHwID;

			IF statStatus = STATUS_FIRST_CALL THEN // Parameters OK
				IF cap <> 0 THEN
					statCap := TO_UINT(cap);
					statFBState := FB_STATE_PREPARE_WRITE;
				ELSIF (statCap <> TO_UINT(CAP_STANDARD) AND statCap <> TO_UINT(CAP_LEGACY)) OR (statHwIDprevious <> tempHwID) THEN // check if new device is connected => hwID changed
					statFBState := FB_STATE_READ_CAP;
				ELSE
					statFBState := FB_STATE_PREPARE_WRITE;
				END_IF;
			END_IF;
			// save current hwID
			statHwID := tempHwID;
			// END_REGION

		ELSIF (statStatus = STATUS_FIRST_CALL) THEN
			statStatus := STATUS_SUBSEQUENT_CALL;
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		// REGION STATE_MACHINE
		CASE statFBState OF
			FB_STATE_NO_PROCESSING:
			; // No processing active
			// END_REGION no processing    

			FB_STATE_READ_CAP:
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
							instRdRec.index := TO_UINT(INDEX_CAP_IOLINK);
							instRdRec.maxLength := UINT#0;
							statFBState := FB_STATE_READ_CAP;
						END_IF;
					ELSIF instRdRec.VALID = TRUE THEN
						instRdRec.request := FALSE;
						// if status of RDREC is valid then CAP is 16#B400 (CAP_STANDARD)
						IF instRdRec.STATUS.%B3 = STATUS_RDREC_VALID THEN
							statCap := TO_UINT(CAP_STANDARD);
						END_IF;
						statFBState := FB_STATE_PREPARE_WRITE;
					ELSE
						// if RDREC is in error state and Status is 16#DE80_B0xx then CAP is 227 (CAP_Legacy)
						IF (instRdRec.STATUS.%B3 = BITMASK_ERR_RDREC_B3) AND (instRdRec.STATUS.%B2 = BITMASK_ERR_RDREC_B2) AND (instRdRec.STATUS.%B1 = BITMASK_ERR_RDREC_B1) THEN
							statCap := TO_UINT(CAP_LEGACY);
							statFBState := FB_STATE_PREPARE_WRITE;
						ELSE
							statStatus := ERR_RDREC;
							statSubfunctionStatus := instRdRec.STATUS;
							statCap := UINT#0; //clear CAP if an error occurs
						END_IF;
					END_IF;
				ELSE
					instRdRec.request := FALSE;
					IF instRdRec.ERROR = TRUE THEN
						statStatus := ERR_RDREC;
						statSubfunctionStatus := instRdRec.STATUS;
						statCap := UINT#0; //clear CAP if an error occurs
					END_IF;
				END_IF;

				instRdRec(record := statBuffer);
				// END_REGION

			FB_STATE_PREPARE_WRITE:

				//read and write record system functions in SIMATIC AX are more strict
				//it is not possible to add a struct as VAR_IN_OUT to them
				//instead, a byte array is needed. This intermediate step converts the struct data to write into the byte array for the system function
				SerializeLittle(offset := UDINT#0, value := statWrite, buffer := statBuffer);
				statFBState := FB_STATE_WRITE;

				FB_STATE_WRITE:
				// To read data records, the IO-Link master modules needs to know which port is required. Therefore it is necessary
				// to send at first a request via write data record (header, 8 byte). As response the IO-Link master module will 
				// send the required data record.

				instWrRec(request := TRUE,
					ID := statHwID,
					index := statCap,
					length := statLen,
					record := statBuffer);

				IF instWrRec.ERROR THEN
					IF (instWrRec.STATUS AND STATUS_MASK) = STATUS_RESOURCE_BUSY THEN
						instWrRec(request := FALSE, record := statBuffer); // Reset request
					ELSE
						statStatus := ERR_WRREC;
						statSubfunctionStatus := instWrRec.STATUS;
						statFBErrorState := statFBState;
					END_IF;
				ELSIF instWrRec.DONE = TRUE THEN
					instWrRec(request := FALSE, record := statBuffer); // Reset request

					//read back written values from buffer
					DeserializeLittle(offset := UDINT#0, value := statWrite, buffer := statBuffer);
					statFBState := FB_STATE_POLL;
				END_IF;
				// END_REGION write

			FB_STATE_POLL: // wait and poll for response
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
					IF (instRdRec.STATUS AND STATUS_MASK) = STATUS_RESOURCE_BUSY THEN
						// Reset requests and try again
						instPoll(signal := FALSE,
						duration := statPollingPeriod);

						instRdRec(request := FALSE,
						record := statBuffer);
					ELSE
						statStatus := ERR_RDREC;
						statSubfunctionStatus := instRdRec.STATUS;
						statFBErrorState := statFBState;
					END_IF;
				ELSIF instRdRec.VALID THEN
					//deserialize received data
					DeserializeLittle(offset := UDINT#0, value := statRead, buffer := statBuffer);
					IF // check the response wether it matches the request (compare PORT, index and SUBINDEX)
						(statWrite.header.call.port <> statRead.header.call.port)
						OR (statWrite.header.iolHeader.indexHighByte <> statRead.header.iolHeader.indexHighByte)
						OR (statWrite.header.iolHeader.indexLowByte <> statRead.header.iolHeader.indexLowByte)
						OR (statWrite.header.iolHeader.subindex <> statRead.header.iolHeader.subindex)
					THEN // read data record doesn't match the request
						statStatus := ERR_INCONSISTENT_DATA;  // output status no consistent data
					ELSIF statRead.header.iolHeader.control = Byte#16#80 THEN // check the response for IO-Link errors
						// State 0x80 = IOL_CALL_RES PDU shows IO-Link error detect
						statStatus := ERR_IO_LINK;
						statSubfunctionStatus.%B3 := statRead.data[0]; // IO-Link master error code
						statSubfunctionStatus.%B2 := statRead.data[1]; // IO-Link master error code
						statSubfunctionStatus.%B1 := statRead.data[2]; // ISDU error code
						statSubfunctionStatus.%B0 := statRead.data[3]; // ISDU additional code
						statFBErrorState := statFBState;
					ELSE // read data is valid
						IF statReadWrite = MODE_READ THEN
							readLen := TO_INT(instRdRec.length - LEN_HEADER);
							// only data will be output
							FOR tempIndexCounter := 0 TO TO_INT(instRdRec.length - LEN_HEADER - UINT#1) DO
								record.data[tempIndexCounter] := statRead.data[tempIndexCounter];
							END_FOR;
						END_IF;

						// Reset requests
						instRdRec(request := FALSE,
						record := statBuffer);

						instPoll(signal := FALSE,
						duration := statPollingPeriod);

						statStatus := STATUS_EXECUTION_FINISHED;  // request finished
					END_IF;
				END_IF;
				// END_REGION poll

			ELSE // Undefined state in state machine reached
				// REGION undefined state
				statStatus := ERR_UNDEFINED_STATE;
				// END_REGION undefined state no relevant case, ready for new request
		END_CASE;
		// END_REGION

		// REGION MONITORING
		instMonitor(signal := statBusy,
		duration := statTimeout);

		IF instMonitor.output THEN
			statStatus := ERR_REQUEST_TIMEOUT; // request time out
		END_IF;
		// END_REGION

		// REGION OUTPUTS
		// Write outputs
		IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors, available only for one cycle
			// REGION execution finished
			statDone := TRUE;
			statBusy := FALSE;
			statError := FALSE;
			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF), Error status is true only for one cycle (the second last cycle)
			// REGION error occured
			statDone := FALSE;
			statBusy := FALSE;
			statError := TRUE;
			statCap := UINT#0; //Reset statcap, if error occurs, get cap has to be performed again
			// Write diagnostics
			diagnostics.status := statStatus;
			diagnostics.subfunctionStatus := statSubfunctionStatus;
			diagnostics.stateNumber := statFBErrorState;
			// Call instructions with FALSE to be ready for next job
			instWrRec(request := FALSE, record := statBuffer);

			instRdRec(request := FALSE,
			record := statBuffer);

			instPoll(signal := FALSE,
			duration := statPollingPeriod);

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION error occured

		ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs, Last cycle
			// REGION execute reset
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;
			statStatus := STATUS_NO_CALL;
			readLen := 0;
			// END_REGION execute reset
		END_IF;

		// REGION write static values to outputs
		done := statDone;
		busy := statBusy;
		error := statError;
		status := statStatus;
		//ENO := NOT #statError;
		// END_REGION write static values to outputs
		// END_REGION OUTPUTS
	END_FUNCTION_BLOCK

	FUNCTION_BLOCK LIOLink_Diagnose
		/// LIOLink_Diagnose
		// Author : SIOS
		// Family : LIOLink
		//LIOLink_Diagnose is used to read the diagnose of all the ports of any IO-Link-Master Product of Siemens.
		VAR_INPUT 
			execute: Bool;   // Rising edge starts the execution of the action once
			hwID   : HW_IO;  // Hardware identifier of IO-Link master module or first sub module
			cap    : Int;    // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
		END_VAR

		VAR_OUTPUT 
			done       : Bool;                     // TRUE: FB processing successfully completed
			busy       : Bool;                     // TRUE: FB is active and new output values can be expected.
			error      : Bool;                     // FALSE: No error / TRUE: An error occurred during the execution of the FB.
			status     : Word := STATUS_NO_CALL;   // 16#0000-16#7FFF: Status of the FB / 16#8000-16#FFFF: Error identification (see following table)
			diagnostics: LIOLink_typeDiagnostics;  // Diagnostics information of FB
			events     : LIOLink_typeEvents;
		END_VAR

		VAR 
			statExecuteOld       : Bool;                                      // Previous value of input `execute` for edge detection
			statDone             : Bool;                                      // Static value for output 'done'
			statBusy             : Bool;                                      // Static value for output 'busy'
			statError            : Bool;                                      // Static value for output 'error'
			statStatus           : Word;                                      // Static value for output 'status'
			statSubFunctionStatus: DWord;                                     // Static value for output 'subFunctionStatus'.
			statFBState          : DInt;                                      // State of the state machine
			statFBErrorState     : DInt;                                      // State in the state machine of the block where the error occurred
			statHwID             : HW_ANY;                                    // Static value for input 'HwID'
			statHwIDprevious     : HW_IO;                                     // Static value for input 'hwID' from the previous execute 
			statEmptyDiagnostics : LIOLink_typeDiagnostics;                   // Empty diagnostics information (for initialization purposes only)
			instRdRec            : ReadRecord;                                // System function "read data record"
			instRdDiag           : ReadRecord;                                // System function "read data record"
			statDiagRecord       : Array[0..LAST_INDEX_DIAG_RECORD] of Byte;  // Data record of port diagnose
			statDiagRecordEco    : LIOLink_typeEvents;
			statCap              : UInt;                                      // Static value for input 'cap'
			statRead             : Array[0..231] of Byte;                     // Data record, Output of RDREC
			statIndexDiag        : UInt;                                      // Static value for index of data record of port diagnose
			statPortNumber       : Int := 8;                                  // Number of Ports of IO-Link-Master
			statPortEco          : UInt := UINT#1;                            // Static value for a port counter of EcoPN
		END_VAR

		VAR_TEMP 
			tempExecute     : Bool;   // Temporary value for input 'execute'
			tempHwID        : HW_IO;  // Temporary value for input 'hwID'
			tempCap         : Int;    // Temporary value for input 'cap'
			tempPortNumber  : Int;    // Temporary value for port number
			tempEventNumber : Int;    // Temporary value for event number
			tempIndexDiagRec: Int;    // Temporary value for index of data record (array) of diagnose
		END_VAR

		VAR CONSTANT 
			INDEX_CAP_IOLINK                        : Word  := WORD#16#B000;        // Index of the data record for IOLM_Info. Only IO-Link-Masters with CAP=16#B000 support this call.
			INDEX_DIAG_OTHER                        : Word  := WORD#16#00E5;        // Index for port status based on Siemens Standard (old): 229 => reads status of all ports
			INDEX_DIAG_ECO                          : Word  := WORD#16#B200;        // Index for port status based on IO-Link-Standard: 16#B20n, n:Port number => reads port status of only one port
			CAP_LEGACY                              : Word  := WORD#16#00E3;        // Siemens (old) Standard CAP: 227
			CAP_STANDARD                            : Word  := WORD#16#B400;        // IO-Link Standard CAP: 16#B400
			STATUS_EXECUTION_FINISHED_NO_ERROR      : Word  := WORD#16#0000;        // Processing finished without error
			STATUS_NO_CALL                          : Word  := WORD#16#7000;        // No current processing request / no order in process
			STATUS_FIRST_CALL                       : Word  := WORD#16#7001;        // First call after new incoming job request (rising edge at 'execute')
			STATUS_SUBSEQUENT_CALL                  : Word  := WORD#16#7002;        // Subfunction call in progress without further detailing
			STATUS_MASK                             : DWord := DWORD#16#00FF_FF00;  // Mask to filter error codes
			STATUS_RESOURCE_BUSY                    : DWord := DWORD#16#0080_C200;  // Status from WRREC/RDREC: Resource is busy
			ERR_UNDEFINED_STATE                     : Word  := WORD#16#8600;        // Error in function due to an undefined state in the state machine
			ERR_RDREC                               : Word  := WORD#16#8602;        // Error: RDREC encountered an error, see "diagnostics"
			FB_STATE_NO_PROCESSING                  : DInt  := 0;                   // FB state: No processing
			FB_STATE_READ_CAP                       : DInt  := 1;                   // FB state: Read CAP
			FB_STATE_READ_DIAG                      : DInt  := 2;                   // FB state: Read diagnose
			MIN_PORT                                : Int   := 1;                   // Minimum number of ports
			MAX_PORT                                : Int   := 8;                   // Maximum number of ports
			MIN_EVENTS                              : Int   := Int#0;               // Minimum number of events
			MAX_EVENTS                              : Int   := 4;                   // Maximum number of events
			MASTER_PORT_STATUS_V2                   : Byte  := BYTE#16#02;          // Master port status version 2
			MASTER_PORT_STATUS_V3                   : Byte  := BYTE#16#03;          // Master port status version 3
			MASTER_PORT_STATUS_V4                   : Byte  := BYTE#16#04;          // Master port status version 4
			START_INDEX_MASTER_PORT_STATUS_V2       : Int   := 28;                  // Start index of relevant data in the case of port status version 2
			START_INDEX_MASTER_PORT_STATUS_V3       : Int   := 34;                  // Start index of relevant data in the case of port status version 3
			START_INDEX_MASTER_PORT_STATUS_V4       : Int   := 42;                  // Start index of relevant data in the case of port status version 4
			START_INDEX_MASTER_PORT_STATUS_STANDARD : Int   := 18;                  // Start index of relevant data in case of a IO-Link Standard data record for port status
			START_INDEX_DIAG_RECORD                 : Int   := 0;                   // Start index of diagnose record array
			LAST_INDEX_DIAG_RECORD                  : Int   := 231;                 // Last index of diagnose record array
			RESET_WORD                              : Word  := WORD#16#0000;        // Reset event codes
			RESET_BYTE                              : Byte  := BYTE#16#00;          // Reset byte for statDiagRecord
			STATUS_RDREC_VALID                      : Byte  := BYTE#16#00;          // Status Code of RDREC in cased of no error occurs
			BITMASK_ERR_RDREC_B3                    : Byte  := BYTE#16#DE;          // Status Code of RDREC in case of an error when reading a data record
			BITMASK_ERR_RDREC_B2                    : Byte  := BYTE#16#80;          // Status Code of RDREC in case of an error when reading a data record - Error according to IEC 61158-6
			BITMASK_ERR_RDREC_B1                    : Byte  := BYTE#16#B0;          // Status Code of RDREC in case of an error when reading a data record - invalid index (cap)
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2023
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_Diagnosis
		// Function:         Reads diagnose of ports of IO-Link-Masters in IO-Link Standard
		// Library:          LIOLink
		// Author:           SUP SPH
		// Tested with:      CPU 1511F-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     S7-1200/1500
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 28.02.2023 | SUP SPH                | First release for TIA Portal V16
		// 
		//===============================================================================
		// END_REGION


		// REGION TRIGGERING
		tempExecute := execute; // Work with temporary value / create process image

		IF (tempExecute = TRUE) AND (statExecuteOld = FALSE) // Check if FB is triggered
			// FB shall finish current job before new job can be started with rising edge of execute
			AND (statStatus = STATUS_NO_CALL)
		THEN
			// REGION Initialize data
			// First call; initialize FB
			statDone := FALSE;
			statBusy := TRUE;
			statError := FALSE;
			statStatus := STATUS_FIRST_CALL;
			statSubFunctionStatus := STATUS_EXECUTION_FINISHED_NO_ERROR;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;
			//save the hwID from the previous execute
			statHwIDprevious := statHwID;

			//reset static variables of Diagnose Records
			FOR tempPortNumber := MIN_PORT TO MAX_PORT DO
				FOR tempEventNumber := MIN_EVENTS TO MAX_EVENTS DO
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.instance := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.source := FALSE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.eventType := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventQualifier.mode := RESET_BYTE;
					statDiagRecordEco.port[tempPortNumber].event[tempEventNumber].eventCode := RESET_WORD;
				END_FOR;
			END_FOR;
			FOR tempIndexDiagRec := START_INDEX_DIAG_RECORD TO LAST_INDEX_DIAG_RECORD DO
				statDiagRecord[tempIndexDiagRec] := RESET_BYTE;
			END_FOR;
			// END_REGION

			// REGION Save inputs
			//save input parameters
			tempHwID := hwID;
			tempCap := cap;
			// END_REGION

			// REGION Check parameters
			IF statStatus = STATUS_FIRST_CALL THEN // Parameters OK
				IF tempCap <> 0 THEN   //check if cap is predefined, or given by the user
					statCap := TO_UINT(tempCap);
					statFBState := FB_STATE_READ_DIAG;
				ELSIF (statCap <> TO_UINT(CAP_STANDARD) AND statCap <> TO_UINT(CAP_LEGACY)) OR (statHwIDprevious <> tempHwID) THEN
					statFBState := FB_STATE_READ_CAP;
				ELSE //CAP already known
					statFBState := FB_STATE_READ_DIAG;
				END_IF;
			END_IF;
			//save current hwID
			statHwID := tempHwID;
			// END_REGION

		ELSIF (statStatus = STATUS_FIRST_CALL) THEN
			statStatus := STATUS_SUBSEQUENT_CALL;
		ELSIF (statFBState = FB_STATE_NO_PROCESSING) THEN
			statStatus := STATUS_NO_CALL;
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;

			instRdDiag(request := FALSE,
			record := statDiagRecord);

			instRdRec(request := FALSE,
			record := statRead);
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		// REGION STATE_MACHINE
		CASE statFBState OF // State machine of FB
			FB_STATE_NO_PROCESSING: // No processing active (Note: this state must always be present and left empty)
				// REGION No processing
				;
				// END_REGION

			FB_STATE_READ_CAP:
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
							instRdRec.index := TO_UINT(INDEX_CAP_IOLINK);
							instRdRec.maxLength := UINT#0;
							statFBState := FB_STATE_READ_CAP;
						END_IF;
					ELSIF instRdRec.VALID = TRUE THEN
						instRdRec.request := FALSE;
						// if status of RDREC is valid then CAP is 16#B400 (CAP_STANDARD)
						IF instRdRec.STATUS.%B3 = STATUS_RDREC_VALID THEN
							statCap := TO_UINT(CAP_STANDARD);
							statPortNumber := TO_INT(statRead[11]); //read number of ports of IO-Link-Master
							statPortEco := UINT#1;
							statIndexDiag := TO_UINT(INDEX_DIAG_ECO) + statPortEco; //Data Record with the status of each port: 0xB20n, n - Port number
						END_IF;
						statFBState := FB_STATE_READ_DIAG;
					ELSE
						// if RDREC is in error state and Status is 16#DE80_B0xx then CAP is 227 (CAP_Legacy)
						IF (instRdRec.STATUS.%B3 = BITMASK_ERR_RDREC_B3) AND (instRdRec.STATUS.%B2 = BITMASK_ERR_RDREC_B2) AND (instRdRec.STATUS.%B1 = BITMASK_ERR_RDREC_B1) THEN
							statCap := TO_UINT(CAP_LEGACY);
							statIndexDiag := TO_UINT(INDEX_DIAG_OTHER);
							statFBState := FB_STATE_READ_DIAG;
						ELSE
							statDone := FALSE;
							statBusy := FALSE;
							statError := TRUE;
							statStatus := ERR_RDREC;
							statCap := UINT#0; //clear CAP if an error occurs
							statIndexDiag := UINT#0;
							statSubFunctionStatus := instRdRec.STATUS;
							statFBErrorState := statFBState;
							statFBState := FB_STATE_NO_PROCESSING;
						END_IF;
					END_IF;
				ELSE
					instRdRec.request := FALSE;
				END_IF;

				instRdRec(record := statRead);
				// END_REGION

			FB_STATE_READ_DIAG:

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
								statStatus := STATUS_EXECUTION_FINISHED_NO_ERROR;
								statFBState := FB_STATE_NO_PROCESSING;
								statDone := TRUE;
								statBusy := FALSE;
								statError := FALSE;
							ELSE
								IF (instRdDiag.STATUS AND STATUS_MASK) <> STATUS_RESOURCE_BUSY THEN  //Error occured
									statDone := FALSE;
									statBusy := FALSE;
									statError := TRUE;
									statStatus := ERR_RDREC;
									statCap := UINT#0;
									statIndexDiag := UINT#0;
									statSubFunctionStatus := instRdDiag.STATUS;
									statFBErrorState := statFBState;
									statFBState := FB_STATE_NO_PROCESSING;
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
									FOR tempEventNumber := MIN_EVENTS TO MAX_EVENTS DO
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
										statStatus := ERR_RDREC;
										statCap := UINT#0;
										statIndexDiag := UINT#0;
										statSubFunctionStatus := instRdDiag.STATUS;
										statFBErrorState := statFBState;
										statFBState := FB_STATE_NO_PROCESSING;
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
						statStatus := STATUS_EXECUTION_FINISHED_NO_ERROR;
						statFBState := FB_STATE_NO_PROCESSING;
						statDone := TRUE;
						statBusy := FALSE;
						statError := FALSE;
					END_IF;
				END_IF;
				// END_REGION


			// END_REGION

		ELSE // Undefined state in state machine reached
			statDone := FALSE;
			statBusy := FALSE;
			statError := TRUE;
			statStatus := ERR_UNDEFINED_STATE;
		END_CASE;
		// END_REGION STATE_MACHINE

		// REGION OUTPUTS
		// Write outputs

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
					FOR tempPortNumber := MIN_PORT TO MAX_PORT DO
						FOR tempEventNumber := MIN_EVENTS TO MAX_EVENTS DO
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

		// Write static function block status values to outputs
		done := statDone;
		busy := statBusy;
		error := statError;
		status := statStatus;

		// END_REGION OUTPUTS

	END_FUNCTION_BLOCK

	FUNCTION_BLOCK LIOLink_Master
		/// LIOLink_Master
		// Author : SIOS
		// Family : LIOLink
		// Version : 4.0
		//Backs up or restores the complete configuration of Siemens IO-Link master modules
		VAR_INPUT 
			execute: Bool;   // Request to execute function
			hwID   : HW_IO;  // Hardware identifier of IO-Link master module (sub module for ET 200eco PN)
			mode   : USInt;  // 0: backup, 1: restore
		END_VAR

		VAR_OUTPUT 
			done       : Bool;                     // TRUE: Commanded functionality has been completed successfully
			busy       : Bool;                     // TRUE: FB is not finished and new output values can be expected
			error      : Bool;                     // TRUE: An error occurred during the execution of the FB
			status     : Word;                     // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
			diagnostics: LIOLink_typeDiagnostics;  // Diagnostics information of FB
			len        : DInt;                     // Total length of parameter record (number of bytes)
		END_VAR

		VAR_IN_OUT 
		record : Array[*] of Byte;   // Record to store backup in or restore from; limits for 4 Port masters: 0..10239, limits for 8 Port masters: 0..17549
		END_VAR

		VAR 
			statExecuteOld       : Bool;                                              // Old value of 'execute' input for edge detection
			statDone             : Bool;                                              // Static value for output 'done'
			statBusy             : Bool;                                              // Static value for output 'busy'
			statError            : Bool;                                              // Static value for output 'error'
			statStatus           : Word := STATUS_NO_CALL;                            // Static value for output 'status'
			statSubfunctionStatus: DWord;                                             // Status or return value of called FBs, FCs and system blocks
			statFBErrorState     : Int;                                               // State in the state machine of the block where the error occurred
			statFBState          : Int := FB_STATE_NO_PROCESSING;                     // State in the state machine of the FB
			statEmptyDiagnostics : LIOLink_typeDiagnostics;                           // Empty diagnostics information (for initialization purposes only)
			instRdRec            : ReadRecord;                                        // System function "read data record"
			instWrRec            : WriteRecord;                                       // System function "write data record"
			statRecStruct        : LIOLink_typeRecStruct;
			statHwID             : HW_IO;                                             // Static value for input 'hwID'
			statMode             : USInt;                                             // Static value for input 'mode'
			statSegment          : DInt;                                              // current segment
			statAddress          : DInt;                                              // current address
			statLen              : DInt;                                              // total length of operated data
			statBuffer           : Array[0..Lengths#RECORD_WITH_HEADER - 1] OF BYTE;
		END_VAR

		VAR_TEMP 
			tempExecute   : Bool;  // Temporary value for input 'execute'
			tempLowerBound: DInt;  // Lower bound of record array
			tempUpperBound: DInt;  // Upper bound of record array
			tempIndex     : DInt;  // loop index
			tempLen       : UInt;  // current length of data record
		END_VAR

		VAR CONSTANT 
			UPPER_LIMIT_4_PORT         : DInt  := 10239;               // Upper limit of data record array for 4 port master
			UPPER_LIMIT_8_PORT         : DInt  := 17549;               // Upper limit of data record array for 8 port master
			INDEX                      : USInt := USINT#120;           // Index of data record for backup/restore operations
			MODE_BACKUP                : USInt := USINT#0;             // Mode backup
			MODE_RESTORE               : USInt := USINT#1;             // Mode restore
			FUNC_PUSH                  : Byte  := BYTE#16#01;          // Extended function number for push
			FUNC_PULL                  : Byte  := BYTE#16#02;          // Extended function number for pull
			LEN_HEADER                 : USInt := USINT#6;             // Length of header
			MAX_SIZE_SEGMENT           : UInt  := UINT#234;            // Max. 234 Byte per segment
			FB_STATE_NO_PROCESSING     : Int   := 0;                   // FB state: No processing
			FB_STATE_RESET             : Int   := 1;                   // FB state: reset (essential before each backup/restore operation)
			FB_STATE_PREPARE_RESET	   : INT   := 10;			
			FB_STATE_BACKUP            : Int   := 11;                  // FB state: backup
			FB_STATE_RESTORE           : Int   := 21;                  // FB state: restore segment data
			FB_STATE_VERIFY            : Int   := 22;                  // FB state: verify restore
			STATUS_EXECUTION_FINISHED  : Word  := WORD#16#0000;        // Execution finished without errors
			STATUS_NO_CALL             : Word  := WORD#16#7000;        // No job being currently processed
			STATUS_FIRST_CALL          : Word  := WORD#16#7001;        // First call after incoming new job (rising edge 'execute')
			STATUS_SUBSEQUENT_CALL     : Word  := WORD#16#7002;        // Subsequent call during active processing without further details
			STATUS_OFFSET_BACKUP       : Word  := WORD#16#7100;        // Offset for status during backup operation
			STATUS_OFFSET_RESTORE      : Word  := WORD#16#7200;        // Offset for status during restore operation
			SUB_STATUS_NO_ERROR        : Word  := WORD#16#0000;        // No error occured in subfunction call
			ERR_UNKNOWN_MODULE         : Word  := WORD#16#80B0;        // unknown type of module, check subfunctionStatus
			ERR_UNKNOWN_MODE           : Word  := WORD#16#8200;        // Unknown mode
			ERR_ARRAY_UNSUPPORTED      : Word  := WORD#16#8201;        // Record array doesn't fit expected limits
			ERR_SEQ_NUMBER             : Word  := WORD#16#8401;        // Error: IO-Link master returned a sequence number indicating an error, see "diagnostics"
			ERR_UNDEFINED_STATE        : Word  := WORD#16#8600;        // Error: due to an undefined state in state machine
			ERR_WRRC_RESET             : Word  := WORD#16#8601;        // Error: WRREC encountered an error during reset, see "diagnostics"
			ERR_RDREC_BACKUP           : Word  := WORD#16#8602;        // Error: RDREC encountered an error during backup, see "diagnostics"
			ERR_WRREC_RESTORE          : Word  := WORD#16#8603;        // Error: WRREC encountered an error during restore, see "diagnostics"
			ERR_RDREC_VERIFY           : Word  := WORD#16#8604;        // Error: RDREC encountered an error during verification of restore, see "diagnostics"
			ERR_UNKNOWN_RECORD         : DWord := DWORD#16#DF80_B000;  // Error: Data record not known in module
			SEQ_NUM_RESET              : DWord := DWORD#16#FFFF_FFFF;  // Sequence number for reset before backup/restore operations
			SEQ_NUM_RESTORE_ONGOING    : DWord := DWORD#16#FFFF_FF01;  // Sequence number: restore ongoing
			SEQ_NUM_ACTIVATION_ONGOING : DWord := DWORD#16#FFFF_FF02;  // Sequence number: activation ongoing
			SEQ_NUM_ACTIVATION_DONE    : DWord := DWORD#16#FFFF_FF03;  // Sequence number: activation done
			SEQ_NUM_CRC_FAILED         : DWord := DWORD#16#FFFF_FF04;  // Sequence number: CRC check failed
			SEQ_NUM_BLOB_INVALID       : DWord := DWORD#16#FFFF_FF05;  // Sequence number: blob data invalid
			SEQ_NUM_WRONG_SEQUENCE     : DWord := DWORD#16#FFFF_FF06;  // Sequence number: wrong sequence number
			SEQ_NUM_WRONG_SIZE         : DWord := DWORD#16#FFFF_FF07;  // Sequence number: wrong data record size

		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2020
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_Master
		// Function:         Backs up or restores the complete configuration of Siemens IO-Link master modules
		// Library:          LIOLink
		// Author:           Siemens Industry Online Support
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     --
		// Requirements:     One of the following IO-Link master modules:
		//                   - ET 200SP, CM 4x IO-Link 6ES7137-6BD00-0BA0 FW V2.2.0 or higher
		//                   - ET 200AL, CM 4x IO-Link 6ES7147-5JD00-0BA0 FW V1.1.0 or higher
		//                   - ET 200pro, EM 4 IO-Link 6ES7147-4JD00-0AB0 FW V1.0.0 or higher
		//                   - ET 200eco PN, IO-Link Master 6ES7148-6JD00-0AB0 FW V1.0.0 or higher
		//                   - ET 200eco PN, CM 8x IO-Link 6ES7148-6JG00-0BB0 FW V1.0.0 or higher
		//                   - S7-1500, CM 8xIO-Link 6ES7547-1JF00-0AB0 FW V1.0.0 or higher
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 28.02.2015 | SUP Applications       | First release
		// 02.00.00 | 30.09.2016 | SUP Applications       | Integration of complete backup/restore for master and device parameter (new ET 200eco PN)
		// 03.00.00 | 30.09.2017 | SUP Applications       | Reduction to use only one way for complete backup/restore of master and device parameter
		// 03.00.01 | 14.12.2018 | SUP Applications       | Renamed function block from IO_LINK_MASTER to IO_LINK_MASTER_4. No functional changes
		// 04.00.00 | 01.09.2020 | Online Support         | Implemented Programming styleguide for S7-1200/1500 and PLCopen
		//                                                | Combined FBs for 4 Port and 8 Port IO-Link Masters to one FB
		//                                                | Renamed FB to LIOLink_Master
		//===============================================================================
		// END_REGION

		tempExecute := execute; // Work with temporary value / create process image

		// REGION TRIGGERING
		IF (tempExecute = TRUE) AND (statExecuteOld = FALSE)
			AND (statStatus = STATUS_NO_CALL)
		THEN // First call; initialize FB
			statDone := FALSE;
			statBusy := TRUE;
			statError := FALSE;
			statStatus := STATUS_FIRST_CALL;
			statSubfunctionStatus := SUB_STATUS_NO_ERROR;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;

			// Save input parameters
			statHwID := hwID;
			statMode := mode;

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
				statStatus := ERR_ARRAY_UNSUPPORTED;
			ELSE // Check mode
				IF statMode = MODE_BACKUP THEN
				FOR tempIndex := 0 TO tempUpperBound DO // initialize data record before backup
					record[tempIndex] := BYTE#16#0;
				END_FOR;
				statFBState := FB_STATE_PREPARE_RESET;
				ELSIF statMode = MODE_RESTORE THEN
					statFBState := FB_STATE_PREPARE_RESET;
				ELSE
					statStatus := ERR_UNKNOWN_MODE;
				END_IF;
			END_IF;

		ELSIF (statStatus = STATUS_FIRST_CALL) THEN
			statStatus := STATUS_SUBSEQUENT_CALL;
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		// REGION STATE_MACHINE
		CASE statFBState OF
			FB_STATE_NO_PROCESSING:
				; // No processing active
				// END_REGION no processing

			FB_STATE_PREPARE_RESET:
				statRecStruct.reset.ExtendedFunctionNum := FUNC_PUSH;
				statRecStruct.reset.SequenceNo := SEQ_NUM_RESET;  // reset save/restore operations
				
				SerializeLittle(offset := UINT#0, value := statRecStruct.reset, buffer := statBuffer);
			FB_STATE_RESET:

				instWrRec(request    := true,
					ID     := statHwID,
					index  := index,
					length    := LEN_HEADER,
					record := statBuffer);

				IF instWrRec.DONE = TRUE THEN
					instWrRec(request := FALSE, record := statBuffer); // Reset request

					IF statMode = MODE_BACKUP THEN
						statFBState := FB_STATE_BACKUP;
					ELSE
						statFBState := FB_STATE_RESTORE;
					END_IF;

				ELSIF instWrRec.ERROR = TRUE AND instWrRec.STATUS = ERR_UNKNOWN_RECORD THEN
					statStatus := ERR_UNKNOWN_MODULE; // set status = unknown type of module
					statSubfunctionStatus := instWrRec.STATUS;
					statFBErrorState := statFBState;
				ELSIF instWrRec.ERROR = TRUE THEN
					statStatus := ERR_WRRC_RESET;
					statSubfunctionStatus := instWrRec.STATUS;
					statFBErrorState := statFBState;
				END_IF;
				// END_REGION reset

			FB_STATE_BACKUP:
				instRdRec(request    := TRUE,
					ID     := statHwID,
					index  := index,
					maxLength   := LEN_HEADER + MAX_SIZE_SEGMENT,
					record := statBuffer);

				// evaluation of RDREC
				IF instRdRec.VALID = TRUE THEN
					DeserializeLittle(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);
					IF instRdRec.length > LEN_HEADER AND statRecStruct.backup.ExtendedFunctionNum = FUNC_PULL THEN
						statStatus := STATUS_OFFSET_BACKUP OR statRecStruct.backup.SequenceNo.%B0;  // append segment number
						statSegment := TO_DINT(statRecStruct.backup.SequenceNo);
						tempLen := instRdRec.length - LEN_HEADER;

						FOR tempIndex := 0 TO tempLen - UINT#1 DO
							record[tempIndex] := statRecStruct.backup.payload[tempIndex];
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
					statStatus            := ERR_RDREC_BACKUP;
					statSubfunctionStatus := instRdRec.STATUS;
					statFBErrorState      := statFBState;
					statLen               := instRdRec.length;
				END_IF;
				// END_REGION backup

			FB_STATE_RESTORE:
				// load restore data segment from parameter blob (max. 234 Byte per segment)
				IF instWrRec.BUSY = FALSE AND instWrRec.DONE = FALSE THEN // Writing hasn't started
					statRecStruct.restore.ExtendedFunctionNum := FUNC_PUSH;
					statRecStruct.restore.SequenceNo := TO_DWORD(statSegment); // sequence number
					statStatus := STATUS_OFFSET_RESTORE OR statRecStruct.restore.SequenceNo.%B0;

					// load segment data = payload
					FOR tempIndex := 0 TO MAX_SIZE_SEGMENT - UINT#1 DO
						statRecStruct.restore.payload[tempIndex] := record[tempindex + statAddress];
					END_FOR;

					//move into buffer
					SerializeLittle(offset := UINT#0, value := statRecStruct.restore, buffer := statBuffer);

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
					statStatus := ERR_WRREC_RESTORE;
					statSubfunctionStatus := instWrRec.STATUS;
					statFBErrorState := statFBState;
				END_IF;
				// END_REGION restore

			FB_STATE_VERIFY: // Verify restore
				// REGION verify
				instRdRec(request    := TRUE,
					ID     := statHwID,
					index  := index,
					maxLength   := LEN_HEADER + MAX_SIZE_SEGMENT,
					record := statBuffer);

					DeserializeLittle(offset := UINT#0, value := statRecStruct.backup, buffer := statBuffer);

				IF instRdRec.VALID = TRUE AND statRecStruct.backup.ExtendedFunctionNum = FUNC_PULL THEN
					IF statRecStruct.backup.SequenceNo = SEQ_NUM_RESTORE_ONGOING
						OR statRecStruct.backup.SequenceNo = SEQ_NUM_ACTIVATION_ONGOING
					THEN
						statSegment := statSegment + 1;
						statAddress := statAddress + MAX_SIZE_SEGMENT;

						// Reset request
						instRdRec(request    := FALSE,
						record := statBuffer);

						statFBState := FB_STATE_RESTORE;
						ELSIF statRecStruct.backup.SequenceNo = SEQ_NUM_ACTIVATION_DONE THEN //
						// Reset request
						instRdRec(request    := FALSE,
						record := statBuffer);

						statStatus := STATUS_EXECUTION_FINISHED;
					ELSIF statRecStruct.backup.SequenceNo = SEQ_NUM_CRC_FAILED
						OR statRecStruct.backup.SequenceNo = SEQ_NUM_BLOB_INVALID
						OR statRecStruct.backup.SequenceNo = SEQ_NUM_WRONG_SEQUENCE
						OR statRecStruct.backup.SequenceNo = SEQ_NUM_WRONG_SIZE
					THEN
						statStatus := ERR_SEQ_NUMBER;
						statSubfunctionStatus := statRecStruct.backup.SequenceNo;
						statFBErrorState := statFBState;
					END_IF;
				ELSIF instRdRec.ERROR = TRUE THEN
					statStatus := ERR_RDREC_VERIFY;
					statSubfunctionStatus := instRdRec.STATUS;
					statFBErrorState := statFBState;
				END_IF;
				// END_REGION verify

			ELSE // Undefined state in state machine reached
				// REGION undefined state
				statStatus := ERR_UNDEFINED_STATE;
				// END_REGION undefined state no relevant case, ready for new request
		END_CASE;
		// END_REGION

		// REGION OUTPUTS
		// Write outputs
		IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
			// REGION execution finished
			statDone  := TRUE;
			statBusy  := FALSE;
			statError := FALSE;
			len       := statLen;
			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
			// REGION error occured
			statDone  := FALSE;
			statBusy  := FALSE;
			statError := TRUE;
			// Write diagnostics
			diagnostics.status            := statStatus;
			diagnostics.subfunctionStatus := statSubfunctionStatus;
			diagnostics.stateNumber       := statFBErrorState;
			// Call instructions with FALSE to be ready for next job
			instRdRec(request    := FALSE,
				record := statBuffer);

			instWrRec(request := FALSE, record := statBuffer);
			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION error occured

		ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
			// REGION execute reset
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;
			statStatus := STATUS_NO_CALL;
			len := 0;
			// END_REGION execute reset
		END_IF;

		// REGION write static values to outputs
		done := statDone;
		busy := statBusy;
		error := statError;
		status := statStatus;
		// END_REGION write static values to outputs
		// END_REGION OUTPUTS
	END_FUNCTION_BLOCK

END_NAMESPACE
