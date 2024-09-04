USING Siemens.Simatic.S71500.DistributedIO;
USING Simatic.Ax.Conversion;
NAMESPACE Simatic.Ax.IOLink
	FUNCTION_BLOCK LIOLink_AdjSwitchingSensor
		/// LIOLink_AdjSwitchingSensor
		// Author : SUP_Applications
		// Family : LIOLink
		// Version : 2.0
		//Provides a standardized interface and access method for parameterization of a sensor using the Smart Sensor profile.
		VAR_INPUT 
		execute      : Bool;        // Execute selected function
		hwID         : HW_IO;       // Hardware identifier of IO-Link master module (sub module for ET 200eco PN)
		cap          : Int := 227;  // Client Access Point; 0xB400 for ET 200eco PN, CM 8x IO-Link, else 0x00E3 (227)
		port         : Int;         // Port on IO-Link master module
		backupEnable : Bool;        // TRUE: Data storage enabled, FALSE: disabled
		functionCmd  : Int;         // 0: no_func, 1: rd_all, 2: wr_conf, 3: wr_param, 4: teach
		logicIn      : Bool;        // This variable defines the value for a new Switchpoint to be written to the sensor on a Request with Function ‘wr_conf’
		setpointIn   : Int;         // This variable defines the value for a new Setpoint to be written to the sensor on a Request with Function ‘wr_param’
		teachMode    : Int;         // 0: no_teach, 1: single_value, 2: two_value, 3: dynamic
		teachTimer   : Time;        // Defines the duration of the dynamic teach time
		applyAuto    : Bool;        // Teaching result is applied automatically after two teach points were teached (only applies to two value teach mode) 
		teachRequest : Bool;        // A rising edge triggers one step of teach process to be executed according to the selected function at input teachFunction
		teachFunction: Int;         // 0: no teach, 1: teach 1; 2: teach 2; 3: apply; 4: abort
		END_VAR

		VAR_OUTPUT 
		done        : Bool;                     // The signal is set, if the FB has completed a requested operation.
		busy        : Bool;                     // The signal is set, if the FB is executing a requested operation.
		error       : Bool;                     // The signal is set, if an error occurred during execution of a requested operation.
		status      : Word := STATUS_NO_CALL;   // Provides block internal status
		diagnostics : LIOLink_typeDiagnostics;  // Diagnostics information of LIOLink_Device
		logicOut    : Bool;                     // Represents the current value of the parameter Logic from the sensor.
		setpointOut : Int;                      // represents the current value of the parameter Setpoint from the sensor.
		permitTeach1: Bool;                     // The signal is set, if  a teach request for teach function ‘teach_1’ is allowed
		permitTeach2: Bool;                     // The signal is set, if  a teach request for teach function ‘teach_2’ is allowed
		permitApply : Bool;                     // The signal is set, if  a teach request for teach function ‘apply’ is allowed
		permitAbort : Bool;                     // The signal is set, if  a teach request for teach function ‘abort’ is allowed
		END_VAR

		VAR 
		statExecuteOld       : Bool;                     // Old value of 'execute' input for edge detection
		statDone             : Bool;                     // Static value for output 'done'
		statBusy             : Bool;                     // Static value for output 'busy'
		statError            : Bool;                     // Static value for output 'error'
		statStatus           : Word := STATUS_NO_CALL;   // Static value for output 'status'
		statSubfunctionStatus: Word;                     // Status or return value of called FBs, FCs and system blocks
		statFBState          : Int;                      // State of the state machine
		statFBSubState       : Int;                      // Sub state of the state machine
		statFBErrorState     : DInt;                     // State in the state machine of the block where the error occurred
		statEmptyDiagnostics : LIOLink_typeDiagnostics;  //  Empty diagnostics information (for initialization purposes only)
		statTeachRequestOld  : Bool;                     // Used to check TeachRequest Input for rising edge
		statRwRecordIOLData  : Array[0..231] of Byte;    // Buffer, used to work with IO_Link_Device
		instDevice           : LIOLink_Device;
		statIndexRead        : Int;                      // Used to address the index which has to be read next
		statLenRead          : Int;                      // Used to handle the length of the parameter which has to be read next
		statTP1Teached       : Bool;                     // Is set after tp1 of two value teach has been teached
		statTP2Teached       : Bool;                     // Is set after tp2 of two value teach has been teached
		instTimer            : System.Timer.OnDelay;     // Timer for dynamic teach
		statTeachStarted     : Bool;                     // Help variable to determine if dynamic each has been started
		statMyPermitTeach1   : Bool;                     // Help variable for internal handling of PermitTeach1
		statMyPermitTeach2   : Bool;                     // Help variable for internal handling of PermitTeach2
		statMyPermitApply    : Bool;                     // Help variable for internal handling of PermitTeachApply
		statMyPermitAbort    : Bool;                     // Help variable for internal handling of PermitTeachAbort
		END_VAR

		VAR_TEMP 
		tempExecute    : Bool;  // Temporary value for input 'execute'
		tempSetpointOut: Word;  // Temporary variable to encode the output "setpointOut" in byte
		tempSetpointIn : Word;  // Temporary variable to encode the Input "setpointIn" in byte
		END_VAR

		VAR CONSTANT 
		MODE_READ                          : Bool := BOOL#0;        // Mode to read data
		MODE_WRITE                         : Bool := BOOL#1;        // Mode to write data
		FB_STATE_NO_PROCESSING             : Int  := Int#0;         // Idle State
		FB_STATE_READ_ALL                  : Int  := 102;           // State to read Setpoint and SwitchPointLogic
		FB_STATE_WRITE_CONF                : Int  := 103;           // State to write SwitchPointLogic
		FB_STATE_WRITE_PARAM               : Int  := 104;           // State to write Setpoint
		FB_STATE_BACKUP                    : Int  := 105;           // State to trigger Datastorage mechanism
		FB_STATE_CHECK_TEACH_STATE         : Int  := 201;           // State to check current teach state before starting teach-in process
		FB_STATE_CHECK_TEACH_MODE          : Int  := 202;           // State to determine which teach mode is intended (sigle value, two value, dynamic)
		FB_STATE_SINGLE_VAL_TEACH_IN       : Int  := 210;           // State for teaching single value teach
		FB_STATE_TWO_VAL_TEACH_IN          : Int  := 220;           // State for teaching two value teach
		FB_SUB_STATE_TWO_VAL_UPDATE_STATUS : Int  := 221;           // Sub state inside two value teach to check TI_Result during two value teach
		FB_SUB_STATE_TWO_VAL_WRITE_COMMAND : Int  := 222;           // Sub state inside two value teach to write teach commands during two value teach
		FB_STATE_DYNAMIC_TEACH_IN          : Int  := 230;           // State for teaching dynamic teach
		FB_SUB_STATE_DYNAMIC_UPDATE_STATUS : Int  := 231;           // Sub state inside dynamic teach to check TI_Result during dynamic teach
		FB_SUB_STATE_DYNAMIC_WRITE_COMMAND : Int  := 232;           // Sub state inside dynamic teach to write teach commands during dynamic teach
		FB_STATE_CHECK_RESULT              : Int  := 240;           // State to check result of executed teach mode
		FB_STATE_ABORT_TEACH               : Int  := 260;           // State to abort teach procedure
		INDEX_SYS_CMD                      : Int  := 2;             // Index of "System command"
		INDEX_SSC_PARAM                    : Int  := 56;            // Index of "SSC Param"
		INDEX_SSC_CONFIG                   : Int  := 57;            // Index of "SSC Config"
		INDEX_TI_RESULT                    : Int  := 59;            // Index of "Teach-in Result"
		TICMD_APPLY                        : Byte := BYTE#16#40;    // Teach-in command "Teach Apply"
		TICMD_TEACH_SP                     : Byte := BYTE#16#41;    // Teach-in command "Teach SP"
		TICMD_TEACH_SP_TP1                 : Byte := BYTE#16#43;    // Teach-in command "Teach SP TP1"
		TICMD_TEACH_SP_TP2                 : Byte := BYTE#16#44;    // Teach-in command "Teach SP TP2"
		TICMD_TEACH_SP_START               : Byte := BYTE#16#47;    // Teach-in command "Teach SP Start"
		TICMD_TEACH_SP_STOP                : Byte := BYTE#16#48;    // Teach-in command "Teach SP Stop"
		TICMD_TEACH_CANCEL                 : Byte := BYTE#16#4F;    // Teach-in command "Teach cancel"
		MASK_FLAG_TP1                      : Byte := BYTE#16#10;    // Mask flag SP TP1/Teachpoint successfully acquired
		MASK_FLAG_TP2                      : Byte := BYTE#16#20;    // Mask flag SP TP2/Teachpoint successfully acquired
		MASK_TEACH_STATE                   : Byte := BYTE#16#0F;    // Mask teach state
		TEACH_STATE_IDLE                   : Int  := 0;             // Constatnt for TI_Result = Idle
		TEACH_STATE_SUCCESS                : Int  := 1;             // Constatnt for TI_Result = Success
		TEACH_STATE_WAIT_FOR_COMMAND       : Int  := 4;             // Constatnt for TI_Result = Wait for Command
		TEACH_STATE_BUSY                   : Int  := 5;             // Constatnt for TI_Result = Busy
		TEACH_STATE_ERROR                  : Int  := 7;             // Constatnt for TI_Result = Error
		STATUS_EXECUTION_FINISHED          : Word := WORD#16#0000;  // Status: Teach process successfull/ Ready to Start Teach-In process / idle
		STATUS_NO_CALL                     : Word := WORD#16#7000;  // Status: Function block is idle
		STATUS_BUSY_READING                : Word := WORD#16#7011;  // Status: Busy reading data
		STATUS_BUSY_WRITING                : Word := WORD#16#7012;  // Status: Busy writing data
		STATUS_BUSY_BACKUP                 : Word := WORD#16#7026;  // Status: Busy with backup
		STATUS_TEACH_STARTED               : Word := WORD#16#7101;  // Status: Teach-in process started
		STATUS_TEACH_SUBSEQUENT_CALL       : Word := WORD#16#7102;  // Status: Teach-in process subsequent call
		STATUS_TEACH_SINGLE_WAITING        : Word := WORD#16#7110;  // Status: Teach-in process for single value teach-in is waiting for further command
		STATUS_TEACH_SINGLE_BUSY           : Word := WORD#16#7111;  // Status: Teach-in process for single value teach-in is executed
		STATUS_TEACH_TWO_WAITING           : Word := WORD#16#7120;  // Status: Two value teach-in process is waiting for further command
		STATUS_TEACH_TWO_BUSY              : Word := WORD#16#7121;  // Status: Two value teach-in process is being executed
		STATUS_TEACH_DYNAMIC_WAITING       : Word := WORD#16#7130;  // Status: Dynamic teach-in process is waiting for further command
		STATUS_TEACH_DYNAMIC_BUSY          : Word := WORD#16#7131;  // Status: Dynamic teach-in process is being executed
		STATUS_TEACH_WAITING_APPLY         : Word := WORD#16#7140;  // Status: Teach-in process is waiting for apply action command
		STATUS_TEACH_APPLYING              : Word := WORD#16#7141;  // Status: Teach-in process is executed, perform action
		STATUS_TEACH_ABORTING              : Word := WORD#16#7151;  // Status: Teach-in process is executed, abort action
		SUB_STATUS_NO_ERROR                : Word := WORD#16#0000;  // No error occured in subfunction call
		ERR_UNKNOWN_FUNCTION               : Word := WORD#16#8030;  // Error: Selected function unknown
		ERR_TEACH_DEVICE                   : Word := WORD#16#8330;  // Error: Device detected an error during the teach-in process
		ERR_TEACH_NOT_ALLOWED              : Word := WORD#16#8331;  // Error: Teach function not permitted in this state
		ERR_TEACH_MODE_UNKNOWN             : Word := WORD#16#8332;  // Error: Selected teach mode unknown
		ERR_DEVICE_FB                      : Word := WORD#16#8600;  // Error in LIOLink_Device, see "diagnostics"
		FUNC_NOTHING                       : Int  := 0;             // Execute no function
		FUNC_RD_ALL                        : Int  := 1;             // Function to read logic and setpoint from sensor
		FUNC_WR_CONF                       : Int  := 2;             // Function write logic to sensor
		FUNC_WR_PARAM                      : Int  := 3;             // Function to write setpoint to sensor
		FUNC_TEACH                         : Int  := 4;             // Function to enter the teach operation
		TEACH_MODE_NO_TEACH                : Int  := 0;             // No teach mode
		TEACH_MODE_SINGLE_VALUE_TEACH_IN   : Int  := 1;             // Teach Mode Single value teach-in
		TEACH_MODE_TWO_VALUE_TEACH_IN      : Int  := 2;             // Teach Mode Two value teach-in
		TEACH_MODE_DYNAMIC_TEACH_IN        : Int  := 3;             // Teach Mode dynamic teach-in
		TEACH_FUNCTION_1                   : Int  := 1;             // Teach function 1: Start Teach Step 1
		TEACH_FUNCTION_2                   : Int  := 2;             // Teach function 2: Start Teach Step 2
		TEACH_FUNCTION_APPLY               : Int  := 3;             // Apply two value teach results
		TEACH_FUNCTION_ABORT               : Int  := 4;             // Abort of the current teach sequence
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2020
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_AdjSwitchingSensor
		// Function:         This FB provides a standardized interface and access method for
		//                   parameterization of a sensor using the Smart Sensor profile.
		// Library:          LIOLink
		// Author:           SUP Applications
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     --
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 06.03.2019 | SUP Applications       | First release
		// 02.00.00 | 22.09.2020 | Online Support         | Upgraded LIOLink_Device to V4.0.0
		//                                                | Changed status outputs in accordance with PLCopen
		//===============================================================================
		// END_REGION

		tempExecute := execute; // Work with temporary value / create process image

		// REGION TRIGGERING
		IF (tempExecute = TRUE) AND (statExecuteOld = FALSE) // Check if FB is triggered
			AND (statStatus = STATUS_NO_CALL)
		THEN // First call; initialize FB
			statDone              := FALSE;
			statBusy              := TRUE;
			statError             := FALSE;
			statSubfunctionStatus := SUB_STATUS_NO_ERROR;
			statFBErrorState      := 0;
			diagnostics           := statEmptyDiagnostics;

			statMyPermitAbort  := FALSE;
			statMyPermitApply  := FALSE;
			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;

			// Set up LIOLink_Device
			instDevice(execute   := FALSE,
				hwID      := hwID,
				cap       := cap,
				readWrite := FALSE,
				port    := port,
				index     := 0,
				subindex  := 0,
				record    := statRwRecordIOLData);

			CASE functionCmd OF
				FUNC_NOTHING:
					statStatus := STATUS_EXECUTION_FINISHED;

				FUNC_RD_ALL:
					statStatus := STATUS_BUSY_READING;
					statFBState := FB_STATE_READ_ALL;
					statIndexRead := INDEX_SSC_PARAM;
					statLenRead := 2;

				FUNC_WR_CONF:
					statStatus := STATUS_BUSY_WRITING;
					statFBState := FB_STATE_WRITE_CONF;

				FUNC_WR_PARAM:
					statStatus := STATUS_BUSY_WRITING;
					statFBState := FB_STATE_WRITE_PARAM;

				FUNC_TEACH:
					statStatus := STATUS_TEACH_STARTED;
					statFBState := FB_STATE_CHECK_TEACH_STATE;

				ELSE // Error: not defined
					statStatus := ERR_UNKNOWN_FUNCTION;
			END_CASE;

		ELSIF (statStatus = STATUS_TEACH_STARTED) THEN
			statStatus := STATUS_TEACH_SUBSEQUENT_CALL;
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
			RETURN;
		END_IF;

		// REGION STATE_MACHINE
		CASE statFBState OF // State machine of FB
			FB_STATE_NO_PROCESSING:
				// No processing active
				;
				// END_REGION no processing

			FB_STATE_CHECK_TEACH_STATE..FB_STATE_ABORT_TEACH:
				// REGION check teach state
				IF statFBState = FB_STATE_CHECK_TEACH_STATE THEN
					instDevice(execute   := TRUE,
					readWrite := MODE_READ,
					index     := INDEX_TI_RESULT,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record  := statRwRecordIOLData);

						IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
							; // Keep trying until teach state of device is not busy
						ELSE
							CASE teachMode OF
								TEACH_MODE_NO_TEACH:
									statStatus := STATUS_EXECUTION_FINISHED;

								TEACH_MODE_SINGLE_VALUE_TEACH_IN:
									statStatus := STATUS_TEACH_SINGLE_WAITING;
									statMyPermitTeach1 := TRUE;
									statFBState := FB_STATE_SINGLE_VAL_TEACH_IN;

								TEACH_MODE_TWO_VALUE_TEACH_IN:
									statStatus := STATUS_TEACH_TWO_WAITING;
									statTP1Teached := FALSE;
									statTP2Teached := FALSE;
									statMyPermitTeach1 := TRUE;
									statMyPermitTeach2 := TRUE;
									statFBState := FB_STATE_TWO_VAL_TEACH_IN;
									statFBSubState := 0;

								TEACH_MODE_DYNAMIC_TEACH_IN:
									statStatus := STATUS_TEACH_DYNAMIC_WAITING;
									statMyPermitTeach1 := TRUE;
									statTeachStarted := FALSE;
									instTimer(duration := teachTimer,
										signal := FALSE);
									statFBState := FB_STATE_DYNAMIC_TEACH_IN;
									statFBSubState := 0;

								ELSE  // Error: NOT defined
									statStatus := ERR_TEACH_MODE_UNKNOWN;
							END_CASE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION check teach state

				// REGION single teach-in
				IF statFBState = FB_STATE_SINGLE_VAL_TEACH_IN THEN

					// Teach SP
					statRwRecordIOLData[0] := TICMD_TEACH_SP;
					instDevice(execute   := teachRequest AND NOT statTeachRequestOld AND teachFunction = TEACH_FUNCTION_1,
					readWrite := MODE_WRITE,
					index     := INDEX_SYS_CMD,
					writeLen  := 1,
					record    := statRwRecordIOLData);

					IF instDevice.busy THEN
						statStatus := STATUS_TEACH_SINGLE_BUSY;
					ELSIF instDevice.done THEN
						instDevice(execute := FALSE,
						record  := statRwRecordIOLData);
						statFBState := FB_STATE_CHECK_RESULT;
					END_IF;
				END_IF;
				// END_REGION single teach-in

				// REGION two value teach-in
				IF statFBState = FB_STATE_TWO_VAL_TEACH_IN THEN

					// Wait for rising edge of teachRequest
					IF teachRequest AND NOT statTeachRequestOld THEN
						statStatus := STATUS_TEACH_TWO_BUSY;

						IF teachFunction = TEACH_FUNCTION_1 THEN
							// Teach Point 1
							statRwRecordIOLData[0] := TICMD_TEACH_SP_TP1;
						ELSIF teachFunction = TEACH_FUNCTION_2 THEN
							// Teach Point 2
							statRwRecordIOLData[0] := TICMD_TEACH_SP_TP2;
						ELSIF teachFunction = TEACH_FUNCTION_APPLY THEN
							// Teach Apply
							statRwRecordIOLData[0] := TICMD_APPLY;
						END_IF;
						statFBSubState := FB_SUB_STATE_TWO_VAL_WRITE_COMMAND;
					END_IF;

					IF statFBSubState = FB_SUB_STATE_TWO_VAL_UPDATE_STATUS THEN
						instDevice(execute   := TRUE,
							readWrite := MODE_READ,
							index     := INDEX_TI_RESULT,
							record    := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							// Evaluate response from device
							IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_IDLE) OR
								(statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS)
							THEN
								statStatus := STATUS_TEACH_TWO_BUSY;
								statFBSubState := 0;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
								statStatus := STATUS_TEACH_TWO_WAITING;
								statFBSubState := 0;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
								statStatus := STATUS_TEACH_TWO_BUSY;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
								statStatus := ERR_TEACH_DEVICE;
							END_IF;

							// Check if Teachpoints were successfuly acquired
							IF (statRwRecordIOLData[0] AND MASK_FLAG_TP1) = MASK_FLAG_TP1 THEN
								statTP1Teached := TRUE;
							END_IF;

							IF (statRwRecordIOLData[0] AND MASK_FLAG_TP2) = MASK_FLAG_TP2 THEN
								statTP2Teached := TRUE;
							END_IF;
						END_IF;
					END_IF;

					// Write Teach Commands
					IF statFBSubState = FB_SUB_STATE_TWO_VAL_WRITE_COMMAND THEN
						instDevice(execute   := TRUE,
							readWrite := MODE_WRITE,
							index     := INDEX_SYS_CMD,
							writeLen  := 1,
							record    := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
								record  := statRwRecordIOLData);
								statFBSubState := FB_SUB_STATE_TWO_VAL_UPDATE_STATUS;
								statMyPermitAbort := TRUE;

							IF statRwRecordIOLData[0] = TICMD_APPLY THEN
								statFBState := FB_STATE_CHECK_RESULT;
								statStatus := STATUS_TEACH_APPLYING; // Busy, Teach process, apply action
							END_IF;
						END_IF;
					END_IF;

					IF statTP1Teached AND statTP2Teached THEN
						statMyPermitApply := TRUE;

						IF applyAuto THEN
							statRwRecordIOLData[0] := TICMD_APPLY;
							statFBSubState := FB_SUB_STATE_TWO_VAL_WRITE_COMMAND;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION

				// REGION dynamic teach-in
				IF statFBState = FB_STATE_DYNAMIC_TEACH_IN THEN

					//Wait for rising edge of TeachRequest input
					IF teachRequest AND NOT statTeachRequestOld THEN
						statStatus := STATUS_TEACH_DYNAMIC_BUSY;

						IF teachFunction = TEACH_FUNCTION_1 AND statMyPermitTeach1 THEN
							// Start Teach
							statRwRecordIOLData[0] := TICMD_TEACH_SP_START;
						ELSIF teachFunction = TEACH_FUNCTION_2 AND statMyPermitTeach2 AND statTeachStarted THEN
							// Stop Teach
							statRwRecordIOLData[0] := TICMD_TEACH_SP_STOP;
						END_IF;

						statFBSubState := FB_SUB_STATE_DYNAMIC_WRITE_COMMAND;
					END_IF;

					// Send Stop Teach Command if time is up
					IF statTeachStarted AND teachTimer <> T#0ms AND instTimer.output = TRUE THEN
						// Stop Teach
						statRwRecordIOLData[0] := TICMD_TEACH_SP_STOP;
						statFBSubState := FB_SUB_STATE_DYNAMIC_WRITE_COMMAND;
					END_IF;

					// Update status information
					IF statFBSubState = FB_SUB_STATE_DYNAMIC_UPDATE_STATUS THEN
						instDevice(execute   := TRUE,
							readWrite := MODE_READ,
							index     := INDEX_TI_RESULT,
							record    := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							// Evaluate response from device
							IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_IDLE) OR
								(statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS)
							THEN // Idle and success are handled as error because wait for command is expected here
								statStatus := ERR_TEACH_DEVICE;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
								statStatus := STATUS_TEACH_DYNAMIC_WAITING;
								statFBSubState := 0;
								statTeachStarted := TRUE;
								statMyPermitTeach1 := FALSE;
								statMyPermitTeach2 := TRUE;
								statMyPermitAbort := TRUE;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
								statStatus := STATUS_TEACH_DYNAMIC_BUSY;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
								statStatus := ERR_TEACH_DEVICE;
							ELSE
								statStatus := ERR_TEACH_DEVICE;
							END_IF;
						END_IF;
					END_IF;

					IF statFBSubState = FB_SUB_STATE_DYNAMIC_WRITE_COMMAND THEN
						instDevice(execute   := TRUE,
							readWrite := MODE_WRITE,
							index     := INDEX_SYS_CMD,
							writeLen  := 1,
							record    := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							IF statRwRecordIOLData[0] = TICMD_TEACH_SP_START THEN
								statFBSubState := FB_SUB_STATE_DYNAMIC_UPDATE_STATUS;

								// Start Teach Timer
								IF teachTimer <> T#0ms THEN
									instTimer(duration := teachTimer,
									signal := TRUE);
								END_IF;

							ELSIF statRwRecordIOLData[0] = TICMD_TEACH_SP_STOP THEN
								statFBState := FB_STATE_CHECK_RESULT;
								statStatus := STATUS_TEACH_APPLYING; // Busy, Teach process, apply action
							END_IF;

							statMyPermitAbort := TRUE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION dynamic teach-in

				// REGION check result
				IF statFBState = FB_STATE_CHECK_RESULT THEN
					statMyPermitTeach1 := FALSE;
					statMyPermitTeach2 := FALSE;
					statMyPermitApply := FALSE;
					statMyPermitAbort := FALSE;

					// Read Teach-in state
					instDevice(execute   := TRUE,
					readWrite := MODE_READ,
					index     := INDEX_TI_RESULT,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record  := statRwRecordIOLData);

						IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
							; // Keep trying until teach state of device is not busy
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS) THEN
							statMyPermitTeach1 := FALSE;
							statMyPermitTeach2 := FALSE;
							statMyPermitApply := FALSE;
							statMyPermitAbort := FALSE;

							statFBState := FB_STATE_READ_ALL; // Go to read all
							statIndexRead := INDEX_SSC_PARAM;
							statLenRead := 2;
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
							statStatus := STATUS_TEACH_WAITING_APPLY;
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
							statStatus := ERR_TEACH_DEVICE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION check result

				// REGION abort
				// Check for Abort Teach and not permitted Functions
				IF teachRequest AND NOT statTeachRequestOld THEN
					IF teachFunction = TEACH_FUNCTION_1 AND NOT statMyPermitTeach1
						OR teachFunction = TEACH_FUNCTION_2 AND NOT statMyPermitTeach2
						OR teachFunction = TEACH_FUNCTION_APPLY AND NOT statMyPermitApply
						OR teachFunction = TEACH_FUNCTION_ABORT AND NOT statMyPermitAbort 
					THEN
						statStatus := ERR_TEACH_NOT_ALLOWED;
					ELSIF teachFunction = TEACH_FUNCTION_ABORT AND statMyPermitAbort THEN
						statFBState := FB_STATE_ABORT_TEACH;
					END_IF;
				END_IF;

				IF statFBState = FB_STATE_ABORT_TEACH THEN
					statStatus := STATUS_TEACH_ABORTING;

					// Abort Teach-in sequence
					statRwRecordIOLData[0] := TICMD_TEACH_CANCEL;
					instDevice(execute   := TRUE,
					readWrite := MODE_WRITE,
					index     := INDEX_SYS_CMD,
					writeLen  := 1,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record  := statRwRecordIOLData);

						statStatus := STATUS_EXECUTION_FINISHED;
					END_IF;
				END_IF;
				// END_REGION abort

				// Error Handling
				IF instDevice.error THEN
					statStatus := ERR_DEVICE_FB;
					statSubfunctionStatus := instDevice.status;
					statFBErrorState := statFBSubState;
				END_IF;
				// END_REGION teach

			FB_STATE_READ_ALL..FB_STATE_BACKUP:
				// State to read and write Setpoint and Logic

				// REGION read all
				IF statFBState = FB_STATE_READ_ALL THEN // Read "Logic" and "Setpoint"
					statStatus := STATUS_BUSY_READING; // Busy reading data

					instDevice(execute   := TRUE,
					readWrite := MODE_READ,
					index     := statIndexRead,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record  := statRwRecordIOLData);

						IF statIndexRead >= INDEX_SSC_CONFIG THEN
							logicOut := TO_BOOL(statRwRecordIOLData[0] AND BYTE#2#00000001);

							IF backupEnable AND functionCmd = FUNC_TEACH THEN
								statFBState := FB_STATE_BACKUP;
							ELSE
								statStatus := STATUS_EXECUTION_FINISHED;
							END_IF;

						ELSE
							tempSetpointOut.%B0 := statRwRecordIOLData[1];
							tempSetpointOut.%B1 := statRwRecordIOLData[0];
							setpointOut := TO_INT(tempSetpointOut);

							// Read "Logic" after reading "Setpoint"
							statIndexRead := statIndexRead + (1);
							statLenRead := 1;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION read all

				// REGION write config
				IF statFBState = FB_STATE_WRITE_CONF THEN
					statStatus := STATUS_BUSY_WRITING; // Busy writing data
					statRwRecordIOLData[0] := TO_BYTE(logicIn);

					instDevice(execute   := true,
					readWrite := MODE_WRITE,
					index     := INDEX_SSC_CONFIG,
					writeLen  := 1,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						//Write input to output if writing was successful
						logicOut := logicIn;

						IF backupEnable THEN
							statFBState := FB_STATE_BACKUP;
							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);
						ELSE
							statStatus := STATUS_EXECUTION_FINISHED;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION write config

				// REGION write param
				IF statFBState = FB_STATE_WRITE_PARAM THEN
					statStatus := STATUS_BUSY_WRITING;

					tempSetpointIn := TO_WORD(setpointIn);
					statRwRecordIOLData[1] := tempSetpointIn.%B0;
					statRwRecordIOLData[0] := tempSetpointIn.%B1;

					instDevice(execute   := TRUE,
					readWrite := MODE_WRITE,
					index     := INDEX_SSC_PARAM,
					writeLen  := 2,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						//Write input to output if writing was successful
						setpointOut := setpointIn;
						IF backupEnable THEN
							statFBState := FB_STATE_BACKUP;
							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);
						ELSE
							statStatus := STATUS_EXECUTION_FINISHED;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION write param

				// REGION param download store
				IF statFBState = FB_STATE_BACKUP THEN
					statStatus := STATUS_BUSY_BACKUP; // Busy backup
					statRwRecordIOLData[0] := BYTE#16#05;

					instDevice(execute   := TRUE,
					readWrite := MODE_WRITE,
					index     := INDEX_SYS_CMD,
					writeLen  := 1,
					record    := statRwRecordIOLData);

					IF instDevice.done THEN
						statStatus := STATUS_EXECUTION_FINISHED;
					END_IF;
				END_IF;
				// END_REGION param download store

				// Error handling
				IF instDevice.error THEN
					statStatus := ERR_DEVICE_FB;
					statSubfunctionStatus := instDevice.status;
					statFBErrorState := statFBState;
				END_IF;
				// END_REGION param exchange
		END_CASE;
		// END_REGION STATE_MACHINE

		// REGION OUTPUTS
		// Write outputs
		IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
			// REGION execution finished
			statDone := TRUE;
			statBusy := FALSE;
			statError := FALSE;

			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;
			statMyPermitApply := FALSE;
			statMyPermitAbort := FALSE;

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			statFBState := 0;
			statFBSubState := 0;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
			// REGION error occured
			statDone := FALSE;
			statBusy := FALSE;
			statError := TRUE;

			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;
			statMyPermitApply := FALSE;
			statMyPermitAbort := FALSE;

			// Write diagnostics
			diagnostics.status := statStatus;
			diagnostics.subfunctionStatus := statSubfunctionStatus;
			diagnostics.stateNumber := statFBErrorState;

			// Reset instance for next job
			instDevice(execute := FALSE,
			record  := statRwRecordIOLData);

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			statFBState := 0;
			statFBSubState := 0;
			// END_REGION error occured

		ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
			// REGION execute reset
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;
			statStatus := STATUS_NO_CALL;

			// Reset instance for next job
			instDevice(execute := FALSE,
			record  := statRwRecordIOLData);

			// END_REGION execute reset
		END_IF;

		// REGION Write static values to outputs
		done := statDone;
		busy := statBusy;
		error := statError;
		status := statStatus;

		// Write internal used variables to outputs
		permitTeach1 := statMyPermitTeach1;
		permitTeach2 := statMyPermitTeach2;
		permitApply := statMyPermitApply;
		permitAbort := statMyPermitAbort;

		// Needed to detect rising edge at inputs
		statTeachRequestOld := teachRequest;

		// END_REGION Write static values to outputs
		// END_REGION OUTPUTS
	END_FUNCTION_BLOCK

	FUNCTION_BLOCK LIOLink_IdentAndDiag
		/// LIOLink_IdentAndDiag
		// Author : SUP_Applications
		// Family : LIOLink
		// Version : 2.0
		//Reads or writes identification and diagnosis data from an IO-Link device supporting the Common profile
		VAR_INPUT 
			execute       : Bool;        // Execute selected function
			hwID          : HW_IO;       // Hardware identifier of IO-Link master module (sub module for ET 200eco PN)
			cap           : Int := 227;  // Client Access Point; 0xB400 for ET 200eco PN, CM 8x IO-Link, else 0xE003 (227)
			port          : Int;         // Port on IO-Link master module
			functionCmd   : Int;         // 0: no_func; 1: rd_all; 2: rd_diag; 3: wr_ident
			backupEnable  : Bool;        // TRUE: data storage enabled; FALSE: disabled
			appSpecificTag: String[32];  // Application specific tag that is written with function "wr_ident"
			functionTag   : String[32];  // Function tag that is written with function "wr_ident"
			locationTag   : String[32];  // Location tag that is written with function "wr_ident"
		END_VAR

		VAR_OUTPUT 
			done                 : Bool;                               // The signal is set, if the FB has completed a requested operation.
			busy                 : Bool;                               // The signal is set, if the FB is executing a requested operation.
			error                : Bool;                               // The signal is set, if an error occurred during execution of a requested operation.
			status               : Word := STATUS_NO_CALL;             // Provides block internal status
			diagnostics          : LIOLink_typeDiagnostics;            // Diagnostics information of FB
			profileIDList        : Array[0..31] of UInt;               // List of ProfileIDs supported by the Device
			functionClassIDList  : Array[0..31] of UInt;               // List of FunctionClassIDs supported by the Device
			identificationObjects: LIOLink_typeIdentificationObjects;  // Structured list of identification objects
			deviceOK             : Bool;                               // The signal is set when no further diagnosis info is available
			deviceStatus         : Byte;                               // DeviceStatus of the device
			detailedDeviceStatus : Array[0..63] of DWord;              // Array which include detailed status information of the device
		END_VAR

		VAR 
			statExecuteOld       : Bool;                                     // Used to check Request Input for rising edge
			statDone             : Bool;                                     //  Static value for output 'done'
			statBusy             : Bool;                                     //  Static value for output 'busy'
			statError            : Bool;                                     //  Static value for output 'error'
			statStatus           : Word := STATUS_NO_CALL;                   //  Static value for output 'status'
			statSubfunctionStatus: Word;                                     //  Status or return value of called FBs, FCs and system blocks
			statFBState          : DInt := FB_STATE_NO_PROCESSING;           // State of the state machine
			statFBSubstate       : DInt;                                     // Sub State of the state machine
			statFBErrorState     : DInt;                                     // State in the state machine of the block where the error occurred
			statEmptyDiagnostics : LIOLink_typeDiagnostics;                  // Empty diagnostics information (for initialization purposes only)
			instDevice           : LIOLink_Device;
			statWriteIndex       : Int;                                      // Current Index to write data at
			statWriteLength      : UInt;                                     // Used to store the length of the Input Strings
			statIdentObjectId    : Int;                                      // Current Id of  Array Ident_Object_Info
			statIdentObjectInfo  : Array[0..11] of statIdentObjectInfoType;
			statRwRecordIOLData  : Array[0..231] of Byte;                    // Buffer, used to work with IO_Link_Device
			stat_Applspec_Tag_In : String[32];                               // Gets content of ApplicationSpecificTagIn at state_Init to prevent the unlucky case in which the input changes during write process
			stat_Function_Tag_In : String[32];                               // Gets content of FunctionTagIn at state_Init to prevent the unlucky case in which the input changes during write process
			stat_Location_Tag_In : String[32];                               // Gets content of LocationTagIn at state_Init to prevent the unlucky casein which the input changes during write process
			statWriteWarning     : Bool;                                     // Help variable to determine if an optional parameter could not be written.
		END_VAR

		VAR_TEMP 
			tempExecute                : Bool;  // Temporary value for input 'execute'
			tempCount                  : Int;   // Count variable for loops
			tempProfile                : Word;  // Help variable which is used to build Uint out of two Byte
			tempIndex_Profile_Id       : Int;   // Help variable which is used to adress current index of ProfileIDList
			tempIndex_Function_Class_Id: Int;   // Help variable which is used to adress current index of FunctionIDList
		END_VAR

		VAR CONSTANT 
			MODE_READ                          : Bool := FALSE;         // Mode to read data
			MODE_WRITE                         : Bool := TRUE;          // Mode to write data
			FB_STATE_NO_PROCESSING             : DInt := 0;             // FB state: No processing
			FB_STATE_READ_ALL                  : DInt := 10;            // State to read ProfileCharacteristics and IdentificationObjects
			FB_SUBSTATE_PROFILE_CHARACTERISTIC : DInt := 11;            // Sub State to read ProfileCharacteristics
			FB_SUBSTATE_IDENT_OBJECTS          : DInt := 12;            // Sub State to read IdentificationObjects
			FB_STATE_READ_DIAG                 : DInt := 20;            // State to read Device Status and Detailled Device Status
			FB_SUBSTATE_DEVICE_STATUS          : DInt := 21;            // Sub State to read Device Status
			FB_SUBSTATE_DETAILED_DEVICE_STATUS : DInt := 22;            // Sub State to read Detailled Device Status
			FB_STATE_WRITE_IDENT               : DInt := 30;            // State to write ApplSpecTag, FunctionTag and LocationTag
			MAX_IDENTIFICATION_OBJECTS         : Int  := 12;            // Number of Elements in Struct IdentificationObjects
			STATUS_EXECUTION_FINISHED          : Word := WORD#16#0000;  // Execution finished without errors
			WARN_WR                            : Word := WORD#16#0003;  // Execution finished with warnings, optional parameter could not be written
			STATUS_NO_CALL                     : Word := WORD#16#7000;  // No job being currently processed
			STATUS_FIRST_CALL                  : Word := WORD#16#7001;  // First call after incoming new job (rising edge 'execute')
			STATUS_SUBSEQUENT_CALL             : Word := WORD#16#7002;  // Subsequent call during active processing without further details
			SUB_STATUS_NO_ERROR                : Word := WORD#16#0000;  // No error occured in subfunction call
			ERR_WRONG_HANDLING                 : Word := WORD#16#8001;
			ERR_UNKNOWN_FUNCTION               : Word := WORD#16#8203;  // Selected function unknown
			ERR_OdurationIONAL_PARAM           : Word := WORD#16#8400;
			ERR_DEVICE_FB                      : Word := WORD#16#8600;  // Unhandled error in LIOLink_Device, see "diagnostics"
			STATUS_ERROR_RD                    : Word := WORD#16#8700;
			STATUS_ERROR_WR                    : Word := WORD#16#8800;
			FUNCTION_DO_NOTHING                : Int  := 0;             // Execute no function = 0
			FUNCTION_RD_ALL                    : Int  := 1;
			FUNCTION_RD_DIAG                   : Int  := 2;
			FUNCTION_WR_IDENT                  : Int  := 3;
			INDEX_BACKUP                       : Int  := 2;
			INDEX_APPSPEC_TAG                  : Int  := 24;
			INDEX_FUNCTION_TAG                 : Int  := 25;
			INDEX_LOCATION_TAG                 : Int  := 26;
			INDEX_DEVICE_STATUS                : Int  := 36;
			INDEX_DETAILED_STATUS              : Int  := 37;
			IDENT_OBJECTS_VENDOR_DEVICE_ID     : Int  := 0;
			IDENT_OBJECTS_VENDOR_NAME          : Int  := 1;
			IDENT_OBJECTS_VENDOR_TEXT          : Int  := 2;
			IDENT_OBJECTS_PRODUCT_NAME         : Int  := 3;
			IDENT_OBJECTS_PRODUCT_ID           : Int  := 4;
			IDENT_OBJECTS_PRODUCT_TEXT         : Int  := 5;
			IDENT_OBJECTS_SERIAL_NUMBER        : Int  := 6;
			IDENT_OBJECTS_HARDWARE_REV         : Int  := 7;
			IDENT_OBJECTS_FIRMWARE_REV         : Int  := 8;
			IDENT_OBJECTS_APPLSPEC_TAG_OUT     : Int  := 9;
			IDENT_OBJECTS_FUNCTION_TAG_OUT     : Int  := 10;
			IDENT_OBJECTS_LOCATION_TAG_OUT     : Int  := 11;
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2020
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_IdentAndDiag
		// Function:         Reads or writes identification and diagnosis data from an
		//                   IO-Link device supporting the Common profile
		// Library:          LIOLink
		// Author:           SUP Applications
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     --
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 06.03.2019 | SUP Applications       | First release
		// 02.00.00 | 22.09.2020 | Online Support         | Upgraded LIOLink_Device to V4.0.0
		//                                                | Changed status outputs in accordance with PLCopen
		//===============================================================================
		// END_REGION

		tempExecute := execute; // Work with temporary value / create process image

		// REGION TRIGGERING
		IF execute AND NOT statExecuteOld AND statStatus = STATUS_NO_CALL THEN // First call; initialize FB
			statDone := FALSE;
			statBusy := TRUE;
			statError := FALSE;
			statStatus := STATUS_FIRST_CALL;
			statSubfunctionStatus := SUB_STATUS_NO_ERROR;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;
			statWriteWarning := FALSE;

			// Set up LIOLink_Device        
			instDevice(execute  := FALSE,
			hwID     := hwID,
			cap      := cap,
			port   := port,
			subindex := 0,
			record   := statRwRecordIOLData);

			CASE functionCmd OF
				FUNCTION_DO_NOTHING:
					statStatus := STATUS_EXECUTION_FINISHED;

					FUNCTION_RD_ALL:
					tempIndex_Profile_Id := 0;
					tempIndex_Function_Class_Id := 0;
					statIdentObjectId := 0;
					instDevice.readWrite := MODE_READ;
					statFBState := FB_STATE_READ_ALL;
					statFBSubstate := FB_SUBSTATE_PROFILE_CHARACTERISTIC;

				FUNCTION_RD_DIAG:
					instDevice.readWrite := MODE_READ;
					statFBState := FB_STATE_READ_DIAG;
					statFBSubstate := FB_SUBSTATE_DEVICE_STATUS;

				FUNCTION_WR_IDENT:
					// Write inputs to static variables in case they change during write process
					stat_Applspec_Tag_In := appSpecificTag;
					stat_Function_Tag_In := functionTag;
					stat_Location_Tag_In := locationTag;
					instDevice.readWrite := MODE_WRITE;
					statWriteIndex := INDEX_APPSPEC_TAG; // Start with application specific tag
					statFBState := FB_STATE_WRITE_IDENT;

			ELSE  // Statement section ELSE -> Error: Not defined
				statStatus := ERR_UNKNOWN_FUNCTION;
			END_CASE;

		ELSIF (statStatus = STATUS_FIRST_CALL) THEN
			statStatus := STATUS_SUBSEQUENT_CALL;
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
			RETURN;
		END_IF;

		// REGION STATE_MACHINE
		CASE statFBState OF // State machine of FB
			FB_STATE_NO_PROCESSING:
				// No processing active
				;
				// END_REGION No processing

			FB_STATE_READ_ALL: // Read all parameters
				// REGION read all
				CASE statFBSubstate OF
					FB_SUBSTATE_PROFILE_CHARACTERISTIC: // Read Profile Characterisics
						instDevice(execute  := TRUE,
							index    := 16#000D,
							writeLen := 64,
							record   := statRwRecordIOLData);

						IF instDevice.done THEN
							// Set all list elements to 0
							FOR tempCount := 0 TO 31 BY 1 DO
								profileIDList[tempCount] := UINT#0;
								functionClassIDList[tempCount] := UINT#0;
							END_FOR;

							// Split PROFILE_CHARACTERISTICS (0x000D) into PROFIL_ID and FUNCTION_CLASS_ID
							FOR tempCount := 0 TO instDevice.readLen BY 2 DO
								tempProfile.%B0 := statRwRecordIOLData[tempCount + 1];
								tempProfile.%B1 := statRwRecordIOLData[tempCount];
								IF tempProfile > WORD#16#0000 AND tempProfile < WORD#16#7FFF THEN
									profileIDList[tempIndex_Profile_Id] := TO_UINT(tempProfile);
									tempIndex_Profile_Id := tempIndex_Profile_Id + (1);

								ELSIF tempProfile >= WORD#16#8000 AND tempProfile < WORD#16#C000 THEN
									functionClassIDList[tempIndex_Function_Class_Id] := TO_UINT(tempProfile);
									tempIndex_Function_Class_Id := tempIndex_Function_Class_Id + (1);
								END_IF;
							END_FOR;

							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							statFBSubstate := FB_SUBSTATE_IDENT_OBJECTS;

						END_IF;

					FB_SUBSTATE_IDENT_OBJECTS: // Read all parameters defined in Ident_Object_Info one after another

						// Clear Buffer
						FOR tempCount := 0 TO instDevice.readLen BY 1 DO
							statRwRecordIOLData[tempCount] := BYTE#0;
						END_FOR;

						instDevice(execute  := TRUE,
							index    := statIdentObjectInfo[statIdentObjectId].index,
							writeLen := statIdentObjectInfo[statIdentObjectId].len,
							record   := statRwRecordIOLData);

						IF instDevice.done THEN
							CASE statIdentObjectId OF
								IDENT_OBJECTS_VENDOR_DEVICE_ID:
									// Vendor_ID
									identificationObjects.vendorID.%B0 := statRwRecordIOLData[8];
									identificationObjects.vendorID.%B1 := statRwRecordIOLData[7];
									// Device_ID
									identificationObjects.deviceID.%B0 := statRwRecordIOLData[11];
									identificationObjects.deviceID.%B1 := statRwRecordIOLData[10];
									identificationObjects.deviceID.%B2 := statRwRecordIOLData[9];

								IDENT_OBJECTS_VENDOR_NAME: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.vendorName);

								IDENT_OBJECTS_VENDOR_TEXT: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.vendorText);

								IDENT_OBJECTS_PRODUCT_NAME: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.productName);

								IDENT_OBJECTS_PRODUCT_ID: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.productID);

								IDENT_OBJECTS_PRODUCT_TEXT: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.productText);

								IDENT_OBJECTS_SERIAL_NUMBER: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.serialNumber);

								IDENT_OBJECTS_HARDWARE_REV: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.hwRevision);

								IDENT_OBJECTS_FIRMWARE_REV: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.fwRevision);

								IDENT_OBJECTS_APPLSPEC_TAG_OUT: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.appSpecificTag);

								IDENT_OBJECTS_FUNCTION_TAG_OUT: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.functionTag);

								IDENT_OBJECTS_LOCATION_TAG_OUT: Chars_TO_Strg(Chars  := statRwRecordIOLData,
									pChars := 0,
									Cnt    := TO_UINT(instDevice.readLen),
									Strg   => identificationObjects.locationTag);

							ELSE // Statement section ELSE -> Error: Not defined
								statStatus := ERR_WRONG_HANDLING;
								statFBErrorState := statFBSubstate;
							END_CASE;

							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							IF statIdentObjectId >= MAX_IDENTIFICATION_OBJECTS - 1 THEN
								statFBState := FB_STATE_READ_DIAG;
								statFBSubstate := FB_SUBSTATE_DEVICE_STATUS;
							ELSE
								// Increment Ident_Object_Id to read next parameter
								statIdentObjectId := statIdentObjectId + (1);
							END_IF;
						END_IF;
				END_CASE;
				// END_REGION read all

			FB_STATE_READ_DIAG: // Read diagnostics
				// REGION read diag
				CASE statFBSubstate OF

					FB_SUBSTATE_DEVICE_STATUS: // Read Device Status
						instDevice(execute  := TRUE,
							index    := INDEX_DEVICE_STATUS,
							writeLen := 1,
							record   := statRwRecordIOLData);

						IF instDevice.done THEN
							deviceStatus := statRwRecordIOLData[0];
							IF deviceStatus = BYTE#0 THEN
								deviceOK := TRUE;
							ELSE
								deviceOK := FALSE;
							END_IF;

							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							statFBSubstate := FB_SUBSTATE_DETAILED_DEVICE_STATUS;
						END_IF;

					FB_SUBSTATE_DETAILED_DEVICE_STATUS: // Read Detailed Device Status

						instDevice(execute  := TRUE,
							index    := INDEX_DETAILED_STATUS,
							writeLen := 192,
							record   := statRwRecordIOLData);

						IF instDevice.done THEN
							// Clear old values of #DetailedDeviceStatus
							FOR tempCount := 0 TO 63 DO
								detailedDeviceStatus[tempCount] := DWORD#0;
							END_FOR;

							FOR tempCount := 0 TO instDevice.readLen BY 3 DO
								detailedDeviceStatus[tempCount / 3].%B0 := statRwRecordIOLData[tempCount + 2];
								detailedDeviceStatus[tempCount / 3].%B1 := statRwRecordIOLData[tempCount + 1];
								detailedDeviceStatus[tempCount / 3].%B2 := statRwRecordIOLData[tempCount];
							END_FOR;

							instDevice(execute := FALSE,
							record  := statRwRecordIOLData);

							statStatus := STATUS_EXECUTION_FINISHED;
						END_IF;
				END_CASE;
				// END_REGION read diag

			FB_STATE_WRITE_IDENT:
				IF NOT instDevice.busy THEN
					CASE statWriteIndex OF
						INDEX_APPSPEC_TAG: Strg_TO_Chars(Strg   := stat_Applspec_Tag_In,
							pChars := 0,
							Cnt    => statWriteLength,
							Chars  := statRwRecordIOLData);
						INDEX_FUNCTION_TAG: Strg_TO_Chars(Strg   := stat_Function_Tag_In,
							pChars := 0,
							Cnt    => statWriteLength,
							Chars  := statRwRecordIOLData);
						INDEX_LOCATION_TAG: Strg_TO_Chars(Strg   := stat_Location_Tag_In,
							pChars := 0,
							Cnt    => statWriteLength,
							Chars  := statRwRecordIOLData);
						INDEX_BACKUP:
							statRwRecordIOLData[0] := BYTE#16#05;
							statWriteLength := UINT#1;

					ELSE // Statement section ELSE -> Internal Error: Not defined
						statStatus := ERR_WRONG_HANDLING;
						statFBErrorState := statFBState;
					END_CASE;
				END_IF;

				instDevice(execute  := TRUE,
					index    := statWriteIndex,
					writeLen := TO_INT(statWriteLength),
					record   := statRwRecordIOLData);

				IF instDevice.done THEN
					instDevice(execute := FALSE,
						record  := statRwRecordIOLData);

					CASE statWriteIndex OF
						INDEX_APPSPEC_TAG:
							identificationObjects.appSpecificTag := appSpecificTag;
							statWriteIndex := statWriteIndex + (1);

						INDEX_FUNCTION_TAG:
							identificationObjects.functionTag := functionTag;
							statWriteIndex := statWriteIndex + (1);

						INDEX_LOCATION_TAG:
							identificationObjects.locationTag := locationTag;
							IF backupEnable THEN
							statWriteIndex := INDEX_BACKUP;
							ELSE
							statStatus := STATUS_EXECUTION_FINISHED;
							END_IF;

						INDEX_BACKUP:
							statStatus := STATUS_EXECUTION_FINISHED;
					END_CASE;
				END_IF;
				// END_REGION write ident
		END_CASE;
		// END_REGION state machine

		// REGION ERROR HANDLING
		IF instDevice.error THEN // LIOLink_Device threw error
			// Reset instance for next job
			instDevice(execute := FALSE,
			record  := statRwRecordIOLData);

			IF statFBSubstate = FB_SUBSTATE_PROFILE_CHARACTERISTIC THEN
				FOR tempCount := 0 TO 31 BY 1 DO
					profileIDList[tempCount] := UINT#0;
					functionClassIDList[tempCount] := UINT#0;
				END_FOR;

				statFBSubstate := FB_SUBSTATE_IDENT_OBJECTS;

			ELSIF statFBSubstate = FB_SUBSTATE_IDENT_OBJECTS THEN
				IF statIdentObjectInfo[statIdentObjectId].optional THEN

					// Optional Parameters
					CASE statIdentObjectId OF
						IDENT_OBJECTS_VENDOR_TEXT:
							identificationObjects.vendorText := 'na';
							statIdentObjectId := statIdentObjectId + (1);

						IDENT_OBJECTS_PRODUCT_TEXT:
							identificationObjects.productText := 'na';
							statIdentObjectId := statIdentObjectId + (1);

						IDENT_OBJECTS_SERIAL_NUMBER:
							identificationObjects.serialNumber := 'na';
							statIdentObjectId := statIdentObjectId + (1);

						IDENT_OBJECTS_HARDWARE_REV:
							identificationObjects.hwRevision := 'na';
							statIdentObjectId := statIdentObjectId + (1);

						IDENT_OBJECTS_FUNCTION_TAG_OUT:
							identificationObjects.functionTag := 'na';
							statIdentObjectId := statIdentObjectId + (1);

						IDENT_OBJECTS_LOCATION_TAG_OUT:
							identificationObjects.locationTag := 'na';
							statFBState := FB_STATE_READ_DIAG;
							statFBSubstate := FB_SUBSTATE_DEVICE_STATUS;

					ELSE // Error: Optional parameter without default value
						statStatus := ERR_OdurationIONAL_PARAM;
						statFBErrorState := statFBSubstate;
					END_CASE;
				ELSE
					statStatus := TO_WORD(TO_INT(STATUS_ERROR_RD) + TO_INT(TO_WORD(statIdentObjectInfo[statIdentObjectId].index)));
					statFBErrorState := statFBSubstate;
				END_IF;

			ELSIF statFBSubstate = FB_SUBSTATE_DEVICE_STATUS THEN
				// Set default value
				deviceStatus := BYTE#0;
				statFBSubstate := FB_SUBSTATE_DETAILED_DEVICE_STATUS;

			ELSIF statFBSubstate = FB_SUBSTATE_DETAILED_DEVICE_STATUS THEN
				// Set default value
				FOR tempCount := 0 TO 63 DO
					detailedDeviceStatus[tempCount] := DWORD#0;
				END_FOR;

				statStatus := STATUS_EXECUTION_FINISHED;
			ELSIF statFBState = FB_STATE_WRITE_IDENT THEN
				IF statWriteIndex = INDEX_FUNCTION_TAG THEN
					identificationObjects.functionTag := 'na';
					statWriteWarning := TRUE;
					statWriteIndex := statWriteIndex + (1);

				ELSIF statWriteIndex = INDEX_LOCATION_TAG THEN
					identificationObjects.locationTag := 'na';
					statWriteWarning := TRUE;
					IF backupEnable THEN
						statWriteIndex := INDEX_BACKUP;
					ELSE
						statStatus := STATUS_EXECUTION_FINISHED;
					END_IF;
				ELSE
					statStatus := TO_WORD(TO_INT(STATUS_ERROR_WR) + TO_INT(TO_WORD(statWriteIndex)));
					statFBErrorState := statFBSubstate;
				END_IF;
			ELSE // Unhandled errors from LIOLink_Device
				statStatus := ERR_DEVICE_FB;
				statSubfunctionStatus := instDevice.diagnostics.status;
				statFBErrorState := statFBSubstate;
			END_IF;
		END_IF;
		// END_REGION

		// REGION OUTPUTS
		// Write outputs
		IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
			// REGION execution finished
			IF statWriteWarning THEN // Overwrite status if warning occured during execution
				statStatus := WARN_WR;
			END_IF;

			statDone := TRUE;
			statBusy := FALSE;
			statError := FALSE;

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
		// REGION error occured
			statDone := FALSE;
			statBusy := FALSE;
			statError := TRUE;

			// Write diagnostics
			diagnostics.status := statStatus;
			diagnostics.subfunctionStatus := statSubfunctionStatus;
			diagnostics.stateNumber := statFBErrorState;
			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			// END_REGION error occured

		ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
			// REGION execute reset
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;
			statStatus := STATUS_NO_CALL;
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

	FUNCTION_BLOCK LIOLink_MeasuredDataChannel
		/// LIOLink_MeasuringDataChannel
		// Author : SUP_Applications
		// Family : LIOLink
		// Version : 1.0
		//The Measurement Data Channel defines the Process Data structure, functions and representation of measuring sensors. 
		//This Function Block provides derived status signals and defines a standardized interface for user application programs. 
		//If this FB is migrated to another automation system, than the input measurementValue of type Variant probably has to be replaced by a suitable alternative. 
		VAR_INPUT 
			profileID        : Word;  // 1 = SSP 3.1; 2 = SSP 3.2; 3 = SSP 3.3; 4 = SSP 3.4; 5 = SSP 4.1.x; 6 = SSP 4.2.x
			substituteValue  : DInt;  // This value is applied at the outputs ValueReal and Val-ueDINT if ValueStatus is not equal 0
			qualifier        : Bool;  // false = ProcessData are invalid; true = ProcessData are valid
			LogicStartAddress: Int;   // Logical address of the first byte from Process Data input structure
		END_VAR

		VAR_OUTPUT 
			valid      : Bool;                  // If “true” the provided values are valid and may be used for further calculations
			error      : Bool;                  // If “true” an internal error is occurred and futher information is provided provided by the Function Block via the Status variable
			status     : Word := WORD#16#0000;  // Provides internal error codes
			valueStatus: Int;                   // Status of process data input: 0 = OK; 1 = PC invalid; 2 = No Data; 3 = Out of range (+); 4 = Out of range (-); 5 = Not defined
			valueReal  : Real;                  // Process data in real format for evaluation within the PLC
			valueDInt  : DInt;                  // Process data in double integer format
			scale      : Int;                   // Process data scale factor
			SSCn1      : Bool;                  // Switching information channel 1
			SSCn2      : Bool;                  // Switching information channel 2
		END_VAR

		VAR_TEMP 
			iScale            : SInt;   // Scale information from process image
			byScale           : Byte;   // Scale information from process image
			iMeasurementValue : Int;    // Measurement Value as Integer
			wMeasurementValue : Word;   // Measurement Value as Word
			diMeasurementValue: DInt;   // Measurement Value as Double Integer
			dwMeasurementValue: DWord;  // Measurement Value as Double Word
		END_VAR

		VAR CONSTANT 
			LOWER_LIMIT_INT           : Int   := -32768;             // Value which represents lower limit of 16 bit measurement value
			UPPER_LIMIT_INT           : Int   := 32767;              // Value which represents upper limit of 16 bit measurement value
			LOWER_LIMIT_DINT          : DInt  := DINT#-2147482880;   // Value which represents lower limit of 32 bit measurement value
			UPPER_LIMIT_DINT          : DInt  := DINT#2147482880;    // Value which represents upper limit of 32 bit measurement value
			OUT_OF_RANGE_NEG_INT      : Int   := 16#8008;            // Value which represents that 16 bit measurement value is out of range (-)
			OUT_OF_RANGE_POS_INT      : Int   := 16#7FF8;            // Value which represents that 16 bit measurement value is out of range (+)
			OUT_OF_RANGE_NEG32        : DInt  := DINT#16#80000008;   // Value which represents that 32 bit measurement value is out of range (-)
			OUT_OF_RANGE_POS32        : DInt  := DINT#16#7FFFFFF8;   // Value which represents that 32 bit measurement value is out of range (+)
			NO_MEASUREMENT_DATA16     : Int   := 16#7FFC;            // Value which represents that IOL_Device cannot provide a 16 bit measurement value
			NO_MEASUREMENT_DATA32     : DInt  := DINT#16#7FFFFFFC;   // Value which represents that IOL_Device cannot provide a 32 bit measurement value
			VAL_STAT_OK               : Int   := 0;                  // Value for Status = OK
			VAL_STAT_PD_INVALID       : Int   := 1;                  // Value for Status = Process Data invalid
			VAL_STAT_NO_DATA          : Int   := 2;                  // Value for Status = No Data
			VAL_STAT_OUT_OF_RANGE_POS : Int   := 3;                  // Value for Status = Measurement Value out of range (-)
			VAL_STAT_OUT_OF_RANGE_NEG : Int   := 4;                  // Value for Status = Measurement Value out of range (+)
			VAL_STAT_NOT_DEFINED      : Int   := 5;                  // Value for Status = Measurement Value not defined
			ERR_UNDEFINED_PROFILE_ID  : DWord := DWORD#16#00000001;  // Status Code if the value at input ProfileId is not defined
			STATUS_READY_TO_START     : Word  := WORD#16#0000;       // Status: Teach process successfull/ Ready to Start Teach-In process / idle
			STATUS_UNKNOWN_PROFIL_ID  : Word  := WORD#16#8001;
			PROFILID_SSP1             : Word  := WORD#1;
			PROFILID_SSP2             : Word  := WORD#2;
			PROFILID_SSP3             : Word  := WORD#3;
			PROFILID_SSP4             : Word  := WORD#4;
			PROFILID_SSP5             : Word  := WORD#5;
			PROFILID_SSP6             : Word  := WORD#6;
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2020
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_MeasuredDataChannel
		// Function:         The Measurement Data Channel defines the Process Data         
		//                   structure, functions and representation of measuring sensors.   
		//                   This Function Block provides derived status signals and            
		//                   defines a standardized interface for user application programs. 
		// Library:          LIOLink
		// Author:           SUP Applications
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     --
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 06.03.2019 | SUP Applications       | First release
		// 01.00.04 | 22.09.2020 | Online Support         | Enabled block simulation support
		// 02.00.00 | 31.03.2023 | SUP Applications       | Added support of SSP 4.1.x and SSP 4.2.x                      
		//                                                 Replaced input "MeasurementValue" (Variant) by                
		//                                                 "LogicStartAddress" (INT)                                     
		//                                                 Removed input ScaleIn                                         
		//                                                 Added outputs SSCn.1 and SSCn.2
		//===============================================================================
		// END_REGION

		// REGION Init outputs
		error := FALSE;
		status := STATUS_READY_TO_START;
		SSCn1 := FALSE;
		SSCn2 := FALSE;
		// END_REGION

		// REGION Init temp variables
		iScale := SINT#0;
		byScale := BYTE#0;
		iMeasurementValue := INT#0;
		wMeasurementValue := WORD#0;
		diMeasurementValue := DINT#0;
		dwMeasurementValue := DWORD#0;
		// END_REGION

		IF qualifier = FALSE THEN
			valueDInt := substituteValue;
			valueReal := TO_REAL(substituteValue);
			valueStatus := VAL_STAT_PD_INVALID;
			valid := FALSE;

		ELSE
			//SSP 3.1 or 3.3 or 4.1.x
			IF (profileID = PROFILID_SSP1 OR profileID = PROFILID_SSP3 OR profileID = PROFILID_SSP5) THEN
				// REGION 16-bit measurement value 
				wMeasurementValue := PEEK_WORD(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress);
				iMeasurementValue := TO_INT(wMeasurementValue);
				byScale := PEEK(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 2);
				iScale := TO_SINT(byScale);

				IF profileID = PROFILID_SSP5 THEN
					SSCn1 := PEEK_BOOL(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 3, bitOffset := 0);
					SSCn2 := PEEK_BOOL(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 3, bitOffset := 1);
				END_IF;

				IF LOWER_LIMIT_INT <= iMeasurementValue AND iMeasurementValue <= UPPER_LIMIT_INT THEN
					valueDInt := iMeasurementValue;
					valueReal := TO_REAL(iMeasurementValue) * (REAL#10.0 ** TO_REAL(iScale));
					valueStatus := VAL_STAT_OK;
					valid := TRUE;

				ELSE
					IF iMeasurementValue = OUT_OF_RANGE_POS_INT THEN
						valueStatus := VAL_STAT_OUT_OF_RANGE_POS;

					ELSIF iMeasurementValue = OUT_OF_RANGE_NEG_INT THEN
						valueStatus := VAL_STAT_OUT_OF_RANGE_NEG;

					ELSIF iMeasurementValue = NO_MEASUREMENT_DATA16 THEN
						valueStatus := VAL_STAT_NO_DATA;

					ELSE // MeasurementValue does not fit any defined Value
						valueStatus := VAL_STAT_NOT_DEFINED;

					END_IF;
					valueDInt := substituteValue;
					valueReal := TO_REAL(substituteValue);
					valid := FALSE;
				END_IF;
				// END_REGION
				//SSP 3.2 or 3.4 or 4.2.x
			ELSIF (profileID = PROFILID_SSP2 OR profileID = PROFILID_SSP4 OR profileID = PROFILID_SSP6) THEN
				// REGION 32-bit measurement value
				dwMeasurementValue := PEEK_DWORD(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress);
				diMeasurementValue := TO_DINT(dwMeasurementValue);
				byScale := PEEK(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 4);
				iScale := TO_SINT(byScale);

				IF profileID = PROFILID_SSP6 THEN
					SSCn1 := PEEK_BOOL(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 5, bitOffset := 0);
					SSCn2 := PEEK_BOOL(area := WORD#16#81, dbNumber := 0, byteOffset := LogicStartAddress + 5, bitOffset := 1);
				END_IF;

				IF LOWER_LIMIT_DINT <= diMeasurementValue AND diMeasurementValue <= UPPER_LIMIT_DINT THEN
					valueDInt := diMeasurementValue;
					valueReal := TO_REAL(diMeasurementValue) * (REAL#10.0 ** TO_REAL(iScale));
					valueStatus := VAL_STAT_OK;
					valid := TRUE;

				ELSE
					IF diMeasurementValue = OUT_OF_RANGE_POS32 THEN
						valueStatus := VAL_STAT_OUT_OF_RANGE_POS;

					ELSIF diMeasurementValue = OUT_OF_RANGE_NEG32 THEN
						valueStatus := VAL_STAT_OUT_OF_RANGE_NEG;

					ELSIF diMeasurementValue = NO_MEASUREMENT_DATA32 THEN
						valueStatus := VAL_STAT_NO_DATA;

					ELSE // MeasurementValue does not fit any defined Value
						valueStatus := VAL_STAT_NOT_DEFINED;
					END_IF;

					valueDInt := substituteValue;
					valueReal := TO_REAL(substituteValue);
					valid := FALSE;
				END_IF;
			// END_REGION
			ELSE  // Statement section ELSE
				valueDInt := substituteValue;
				valueReal := TO_REAL(substituteValue);
				valueStatus := VAL_STAT_OK;
				valid := FALSE;
				error := TRUE;
				status := STATUS_UNKNOWN_PROFIL_ID;
			END_IF;
		END_IF;

		scale := iScale;

	END_FUNCTION_BLOCK

	FUNCTION_BLOCK LIOLink_MultiAdjSwitchingSensor
		/// LIOLink_MultiAdjSwitchingSensor
		// Author : SUP_Applications
		// Family : LIOLink
		// Version : 2.0
		//Provides a standardized interface and access method for parameterization of a sensor using the Smart Sensor profile. In particular, the FB can be used by sensors that can be assigned to the measuring device profile type 2, i.e. IO Link Devices that support the smart sensor profile "Multiple Adjustable Switching Sensors".
		VAR_INPUT 
			execute      : Bool;   // Execute selected function
			hwID         : HW_IO;  // Hardware identifier of IO-Link master module (sub module for ET 200eco PN)
			cap          : Int;    // Client Access Point; 0xB400 for ET 200eco PN, CM 8x IO-Link, else 0xE003 (227)
			port         : Int;    // Port on IO-Link master module
			backupEnable : Bool;   // TRUE: Data storage enabled, FALSE: disabled
			functionCmd  : Int;    // 0: no_func, 1: rd_all, 2: wr_conf, 3: wr_param, 4: teach
			logicIn      : Bool;   // This variable defines the value for a new Switchpoint to be written to the sensor on a Request with Function ‘wr_conf’
			setpointIn1  : Int;    // This variable defines the value for a new Setpoint to be written to the sensor on a Request with Function ‘wr_param’
			setpointIn2  : Int;    // This variable defines the value for a new Setpoint to be written to the sensor on a Request with Function ‘wr_param’
			teachMode    : Int;    // 0: no_teach, 1: single_value, 2: two_value, 3: dynamic
			teachTimer   : Time;   // Defines the duration of the dynamic teach time
			applyAuto    : Bool;   // Teaching result is applied automatically after two teach points were teached (only applies to two value teach mode)
			teachRequest : Bool;   // A rising edge triggers one step of teach process to be executed according to the selected function at input teachFunction
			teachFunction: Int;    // 0: no teach, 1: teach 1; 2: teach 2; 3: apply; 4: abort
		END_VAR

		VAR_OUTPUT 
			done        : Bool;                     // The signal is set, if the FB has completed a requested operation.
			busy        : Bool;                     // The signal is set, if the FB is executing a requested operation.
			error       : Bool;                     // The signal is set, if an error occurred during execution of a requested operation.
			status      : Word := STATUS_NO_CALL;   // Provides block internal status
			diagnostics : LIOLink_typeDiagnostics;  // Diagnostics information of LIOLink_Device
			logicOut    : Bool;                     // Represents the current value of the parameter Logic from the sensor.
			setpointOut1: Int;                      // represents the current value of the parameter Setpoint from the sensor.
			setpointOut2: Int;                      // represents the current value of the parameter Setpoint from the sensor.
			permitTeach1: Bool;                     // The signal is set, if  a teach request for teach function ‘teach_1’ is allowed
			permitTeach2: Bool;                     // The signal is set, if  a teach request for teach function ‘teach_2’ is allowed
			permitApply : Bool;                     // The signal is set, if  a teach request for teach function ‘apply’ is allowed
			permitAbort : Bool;                     // The signal is set, if  a teach request for teach function ‘abort’ is allowed
		END_VAR

		VAR 
			statExecuteOld       : Bool;                     // Old value of 'execute' input for edge detection
			statDone             : Bool;                     // Static value for output 'done'
			statBusy             : Bool;                     // Static value for output 'busy'
			statError            : Bool;                     // Static value for output 'error'
			statStatus           : Word := STATUS_NO_CALL;   // Static value for output 'status'
			statSubfunctionStatus: Word;                     // Status or return value of called FBs, FCs and system blocks
			statFBState          : Int;                      // State of the state machine
			statFBSubState       : Int;                      // Sub state of the state machine
			statFBErrorState     : DInt;                     // State in the state machine of the block where the error occurred
			statEmptyDiagnostics : LIOLink_typeDiagnostics;  //  Empty diagnostics information (for initialization purposes only)
			statTeachRequestOld  : Bool;                     // Used to check TeachRequest Input for rising edge
			statRwRecordIOLData  : Array[0..231] of Byte;    // Buffer, used to work with IO_Link_Device
			instDevice           : LIOLink_Device;
			statIndexRead        : Int;                      // Used to address the index which has to be read next
			statLenRead          : Int;                      // Used to handle the length of the parameter which has to be read next
			statTP1Teached       : Bool;                     // Is set after tp1 of two value teach has been teached
			statTP2Teached       : Bool;                     // Is set after tp2 of two value teach has been teached
			instTimer            : System.Timer.OnDelay;     // Timer for dynamic teach
			statTeachStarted     : Bool;                     // Help variable to determine if dynamic each has been started
			statMyPermitTeach1   : Bool;                     // Help variable for internal handling of PermitTeach1
			statMyPermitTeach2   : Bool;                     // Help variable for internal handling of PermitTeach2
			statMyPermitApply    : Bool;                     // Help variable for internal handling of PermitTeachApply
			statMyPermitAbort    : Bool;                     // Help variable for internal handling of PermitTeachAbort
		END_VAR

		VAR_TEMP 
			tempExecute     : Bool;  // Temporary value for input 'execute'
			tempSetpointOut1: Word;  // Temporary variable to encode the output "setpointOut" in byte
			tempSetpointIn1 : Word;  // Temporary variable to encode the Input "setpointIn" in byte
			tempSetpointOut2: Word;  // Temporary variable to encode the output "setpointOut" in byte
			tempSetpointIn2 : Word;  // Temporary variable to encode the Input "setpointIn" in byte
		END_VAR

		VAR CONSTANT 
			MODE_READ                          : Bool := Bool#0;        // Mode to read data
			MODE_WRITE                         : Bool := TRUE;          // Mode to write data
			FB_STATE_NO_PROCESSING             : Int  := Int#0;         // Idle State
			FB_STATE_READ_ALL                  : Int  := 102;           // State to read Setpoint and SwitchPointLogic
			FB_STATE_WRITE_CONF                : Int  := 103;           // State to write SwitchPointLogic
			FB_STATE_WRITE_PARAM               : Int  := 104;           // State to write Setpoint
			FB_STATE_BACKUP                    : Int  := 105;           // State to trigger Datastorage mechanism
			FB_STATE_CHECK_TEACH_STATE         : Int  := 201;           // State to check current teach state before starting teach-in process
			FB_STATE_CHECK_TEACH_MODE          : Int  := 202;           // State to determine which teach mode is intended (sigle value, two value, dynamic)
			FB_STATE_SINGLE_VAL_TEACH_IN       : Int  := 210;           // State for teaching single value teach
			FB_STATE_TWO_VAL_TEACH_IN          : Int  := 220;           // State for teaching two value teach
			FB_SUB_STATE_TWO_VAL_UPDATE_STATUS : Int  := 221;           // Sub state inside two value teach to check TI_Result during two value teach
			FB_SUB_STATE_TWO_VAL_WRITE_COMMAND : Int  := 222;           // Sub state inside two value teach to write teach commands during two value teach
			FB_STATE_DYNAMIC_TEACH_IN          : Int  := 230;           // State for teaching dynamic teach
			FB_SUB_STATE_DYNAMIC_UPDATE_STATUS : Int  := 231;           // Sub state inside dynamic teach to check TI_Result during dynamic teach
			FB_SUB_STATE_DYNAMIC_WRITE_COMMAND : Int  := 232;           // Sub state inside dynamic teach to write teach commands during dynamic teach
			FB_STATE_CHECK_RESULT              : Int  := 240;           // State to check result of executed teach mode
			FB_STATE_ABORT_TEACH               : Int  := 260;           // State to abort teach procedure
			INDEX_SYS_CMD                      : Int  := 2;             // Index of "System command"
			INDEX_SSC_PARAM                    : Int  := 56;            // Index of "SSC Param"
			INDEX_SSC_CONFIG                   : Int  := 57;            // Index of "SSC Config"
			INDEX_TI_RESULT                    : Int  := 59;            // Index of "Teach-in Result"
			TICMD_APPLY                        : Byte := BYTE#16#40;    // Teach-in command "Teach Apply"
			TICMD_TEACH_SP                     : Byte := BYTE#16#41;    // Teach-in command "Teach SP"
			TICMD_TEACH_SP_TP1                 : Byte := BYTE#16#43;    // Teach-in command "Teach SP TP1"
			TICMD_TEACH_SP_TP2                 : Byte := BYTE#16#44;    // Teach-in command "Teach SP TP2"
			TICMD_TEACH_SP_START               : Byte := BYTE#16#47;    // Teach-in command "Teach SP Start"
			TICMD_TEACH_SP_STOP                : Byte := BYTE#16#48;    // Teach-in command "Teach SP Stop"
			TICMD_TEACH_CANCEL                 : Byte := BYTE#16#4F;    // Teach-in command "Teach cancel"
			MASK_FLAG_TP1                      : Byte := BYTE#16#10;    // Mask flag SP TP1/Teachpoint successfully acquired
			MASK_FLAG_TP2                      : Byte := BYTE#16#20;    // Mask flag SP TP2/Teachpoint successfully acquired
			MASK_TEACH_STATE                   : Byte := BYTE#16#0F;    // Mask teach state
			TEACH_STATE_IDLE                   : Int  := 0;             // Constatnt for TI_Result = Idle
			TEACH_STATE_SUCCESS                : Int  := 1;             // Constatnt for TI_Result = Success
			TEACH_STATE_WAIT_FOR_COMMAND       : Int  := 4;             // Constatnt for TI_Result = Wait for Command
			TEACH_STATE_BUSY                   : Int  := 5;             // Constatnt for TI_Result = Busy
			TEACH_STATE_ERROR                  : Int  := 7;             // Constatnt for TI_Result = Error
			STATUS_EXECUTION_FINISHED          : Word := WORD#16#0000;  // Status: Teach process successfull/ Ready to Start Teach-In process / idle
			STATUS_NO_CALL                     : Word := WORD#16#7000;  // Status: Function block is idle
			STATUS_BUSY_READING                : Word := WORD#16#7011;  // Status: Busy reading data
			STATUS_BUSY_WRITING                : Word := WORD#16#7012;  // Status: Busy writing data
			STATUS_BUSY_BACKUP                 : Word := WORD#16#7026;  // Status: Busy with backup
			STATUS_TEACH_STARTED               : Word := WORD#16#7101;  // Status: Teach-in process started
			STATUS_TEACH_SUBSEQUENT_CALL       : Word := WORD#16#7102;  // Status: Teach-in process subsequent call
			STATUS_TEACH_SINGLE_WAITING        : Word := WORD#16#7110;  // Status: Teach-in process for single value teach-in is waiting for further command
			STATUS_TEACH_SINGLE_BUSY           : Word := WORD#16#7111;  // Status: Teach-in process for single value teach-in is executed
			STATUS_TEACH_TWO_WAITING           : Word := WORD#16#7120;  // Status: Two value teach-in process is waiting for further command
			STATUS_TEACH_TWO_BUSY              : Word := WORD#16#7121;  // Status: Two value teach-in process is being executed
			STATUS_TEACH_DYNAMIC_WAITING       : Word := WORD#16#7130;  // Status: Dynamic teach-in process is waiting for further command
			STATUS_TEACH_DYNAMIC_BUSY          : Word := WORD#16#7131;  // Status: Dynamic teach-in process is being executed
			STATUS_TEACH_WAITING_APPLY         : Word := WORD#16#7140;  // Status: Teach-in process is waiting for apply action command
			STATUS_TEACH_APPLYING              : Word := WORD#16#7141;  // Status: Teach-in process is executed, perform action
			STATUS_TEACH_ABORTING              : Word := WORD#16#7151;  // Status: Teach-in process is executed, abort action
			SUB_STATUS_NO_ERROR                : Word := WORD#16#0000;  // No error occured in subfunction call
			ERR_UNKNOWN_FUNCTION               : Word := WORD#16#8030;  // Error: Selected function unknown
			ERR_TEACH_DEVICE                   : Word := WORD#16#8330;  // Error: Device detected an error during the teach-in process
			ERR_TEACH_NOT_ALLOWED              : Word := WORD#16#8331;  // Error: Teach function not permitted in this state
			ERR_TEACH_MODE_UNKNOWN             : Word := WORD#16#8332;  // Error: Selected teach mode unknown
			ERR_DEVICE_FB                      : Word := WORD#16#8600;  // Error in LIOLink_Device, see "diagnostics"
			FUNC_NOTHING                       : Int  := 0;             // Execute no function
			FUNC_RD_ALL                        : Int  := 1;             // Function to read logic and setpoint from sensor
			FUNC_WR_CONF                       : Int  := 2;             // Function write logic to sensor
			FUNC_WR_PARAM                      : Int  := 3;             // Function to write setpoint to sensor
			FUNC_TEACH                         : Int  := 4;             // Function to enter the teach operation
			TEACH_MODE_NO_TEACH                : Int  := 0;             // No teach mode
			TEACH_MODE_SINGLE_VALUE_TEACH_IN   : Int  := 1;             // Teach Mode Single value teach-in
			TEACH_MODE_TWO_VALUE_TEACH_IN      : Int  := 2;             // Teach Mode Two value teach-in
			TEACH_MODE_DYNAMIC_TEACH_IN        : Int  := 3;             // Teach Mode dynamic teach-in
			TEACH_FUNCTION_1                   : Int  := 1;             // Teach function 1: Start Teach Step 1
			TEACH_FUNCTION_2                   : Int  := 2;             // Teach function 2: Start Teach Step 2
			TEACH_FUNCTION_APPLY               : Int  := 3;             // Apply two value teach results
			TEACH_FUNCTION_ABORT               : Int  := 4;             // Abort of the current teach sequence
		END_VAR


		// REGION BLOCK INFO HEADER
		//===============================================================================
		// Siemens / (c)Copyright 2023
		//-------------------------------------------------------------------------------
		// Title:            LIOLink_MultiAdjSwitchingSensor
		// Function:         This FB provides a standardized interface and access method for
		//                   parameterization of a sensor using the Smart Sensor profile.
		//                   In particular, the FB can be used by sensors that can be assigned
		//                   to the measuring device profile type 2, i.e. IO Link Devices that
		//                   support the smart sensor profile "Multiple Adjustable Switching Sensors".
		// Library:          LIOLink
		// Author:           SUP Applications
		// Tested with:      CPU 1513-1 PN FW 2.8
		// Engineering:      TIA Portal V16
		// Restrictions:     --
		// Requirements:     --
		//-------------------------------------------------------------------------------
		// Change log table:
		// Version  | Date       | Expert in charge       | Changes applied
		//----------|------------|------------------------|------------------------------
		// 01.00.00 | 28.02.2023 | SUP Applications       | First release
		//===============================================================================
		// END_REGION

		tempExecute := execute; // Work with temporary value / create process image

		// REGION TRIGGERING
		IF (tempExecute = TRUE) AND (statExecuteOld = FALSE) // Check if FB is triggered
			AND (statStatus = STATUS_NO_CALL)
		THEN // First call; initialize FB
			statDone := FALSE;
			statBusy := TRUE;
			statError := FALSE;
			statSubfunctionStatus := SUB_STATUS_NO_ERROR;
			statFBErrorState := 0;
			diagnostics := statEmptyDiagnostics;

			statMyPermitAbort := FALSE;
			statMyPermitApply := FALSE;
			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;


			// Set up LIOLink_Device
			instDevice(execute := FALSE,
			hwID := hwID,
			cap := cap,
			readWrite := FALSE,
			port := port,
			index := 0,
			subindex := 0,
			record := statRwRecordIOLData);

			CASE functionCmd OF
				FUNC_NOTHING:
					statStatus := STATUS_EXECUTION_FINISHED;

				FUNC_RD_ALL:
					statStatus := STATUS_BUSY_READING;
					statFBState := FB_STATE_READ_ALL;
					statIndexRead := INDEX_SSC_PARAM;
					statLenRead := 2;

				FUNC_WR_CONF:
					statStatus := STATUS_BUSY_WRITING;
					statFBState := FB_STATE_WRITE_CONF;

				FUNC_WR_PARAM:
					statStatus := STATUS_BUSY_WRITING;
					statFBState := FB_STATE_WRITE_PARAM;

				FUNC_TEACH:
					statStatus := STATUS_TEACH_STARTED;
					statFBState := FB_STATE_CHECK_TEACH_STATE;

			ELSE // Error: not defined
				statStatus := ERR_UNKNOWN_FUNCTION;
			END_CASE;

		ELSIF (statStatus = STATUS_TEACH_STARTED) THEN
			statStatus := STATUS_TEACH_SUBSEQUENT_CALL;
		END_IF;

		// Edge detection 'execute' input
		statExecuteOld := tempExecute;
		// END_REGION TRIGGERING

		IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
			RETURN;
		END_IF;

		// REGION STATE_MACHINE
		CASE statFBState OF // State machine of FB
			FB_STATE_NO_PROCESSING:
				// No processing active
				;
				// END_REGION no processing

			FB_STATE_CHECK_TEACH_STATE..FB_STATE_ABORT_TEACH:
				// REGION check teach state
				IF statFBState = FB_STATE_CHECK_TEACH_STATE THEN //check Teach status 
					instDevice(execute := TRUE,
						readWrite := MODE_READ,
						index := INDEX_TI_RESULT,
						record := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
							record := statRwRecordIOLData);

						IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
							; // Keep trying until teach state of device is not busy
						ELSE
							CASE teachMode OF
								TEACH_MODE_NO_TEACH:
									statStatus := STATUS_EXECUTION_FINISHED;

								TEACH_MODE_SINGLE_VALUE_TEACH_IN:
									statStatus := STATUS_TEACH_SINGLE_WAITING;
									statMyPermitTeach1 := TRUE;
									statFBState := FB_STATE_SINGLE_VAL_TEACH_IN;

								TEACH_MODE_TWO_VALUE_TEACH_IN:
									statStatus := STATUS_TEACH_TWO_WAITING;
									statTP1Teached := FALSE;
									statTP2Teached := FALSE;
									statMyPermitTeach1 := TRUE;
									statMyPermitTeach2 := TRUE;
									statFBState := FB_STATE_TWO_VAL_TEACH_IN;
									statFBSubState := 0;

								TEACH_MODE_DYNAMIC_TEACH_IN:
									statStatus := STATUS_TEACH_DYNAMIC_WAITING;
									statMyPermitTeach1 := TRUE;
									statTeachStarted := FALSE;
									instTimer(duration := teachTimer,
									signal := FALSE);
									statFBState := FB_STATE_DYNAMIC_TEACH_IN;
									statFBSubState := 0;

								ELSE  // Error: NOT defined
									statStatus := ERR_TEACH_MODE_UNKNOWN;
							END_CASE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION check teach state

				// REGION single teach-in
				IF statFBState = FB_STATE_SINGLE_VAL_TEACH_IN THEN

					// Teach SP
					statRwRecordIOLData[0] := TICMD_TEACH_SP;
					instDevice(execute := teachRequest AND NOT statTeachRequestOld AND teachFunction = TEACH_FUNCTION_1,
					readWrite := MODE_WRITE,
					index := INDEX_SYS_CMD,
					writeLen := 1,
					record := statRwRecordIOLData);

					IF instDevice.busy THEN
						statStatus := STATUS_TEACH_SINGLE_BUSY;
					ELSIF instDevice.done THEN
						instDevice(execute := FALSE,
						record := statRwRecordIOLData);
						statFBState := FB_STATE_CHECK_RESULT;
					END_IF;
				END_IF;
				// END_REGION single teach-in

				// REGION two value teach-in
				IF statFBState = FB_STATE_TWO_VAL_TEACH_IN THEN

					// Wait for rising edge of teachRequest
					IF teachRequest AND NOT statTeachRequestOld THEN
						statStatus := STATUS_TEACH_TWO_BUSY;

						IF teachFunction = TEACH_FUNCTION_1 THEN
							// Teach Point 1
							statRwRecordIOLData[0] := TICMD_TEACH_SP_TP1;
						ELSIF teachFunction = TEACH_FUNCTION_2 THEN
							// Teach Point 2
							statRwRecordIOLData[0] := TICMD_TEACH_SP_TP2;
						ELSIF teachFunction = TEACH_FUNCTION_APPLY THEN
							// Teach Apply
							statRwRecordIOLData[0] := TICMD_APPLY;
						END_IF;
						statFBSubState := FB_SUB_STATE_TWO_VAL_WRITE_COMMAND;
					END_IF;

					IF statFBSubState = FB_SUB_STATE_TWO_VAL_UPDATE_STATUS THEN
						instDevice(execute := TRUE,
						readWrite := MODE_READ,
						index := INDEX_TI_RESULT,
						record := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
								record := statRwRecordIOLData);

							// Evaluate response from device
							IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_IDLE) OR
								(statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS)
							THEN
								statStatus := STATUS_TEACH_TWO_BUSY;
								statFBSubState := 0;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
								statStatus := STATUS_TEACH_TWO_WAITING;
								statFBSubState := 0;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
								statStatus := STATUS_TEACH_TWO_BUSY;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
								statStatus := ERR_TEACH_DEVICE;
							END_IF;

							// Check if Teachpoints were successfuly acquired
							IF (statRwRecordIOLData[0] AND MASK_FLAG_TP1) = MASK_FLAG_TP1 THEN
								statTP1Teached := TRUE;
							END_IF;

							IF (statRwRecordIOLData[0] AND MASK_FLAG_TP2) = MASK_FLAG_TP2 THEN
								statTP2Teached := TRUE;
							END_IF;
						END_IF;
					END_IF;

					// Write Teach Commands
					IF statFBSubState = FB_SUB_STATE_TWO_VAL_WRITE_COMMAND THEN
						instDevice(execute := TRUE,
						readWrite := MODE_WRITE,
						index := INDEX_SYS_CMD,
						writeLen := 1,
						record := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
							record := statRwRecordIOLData);
							statFBSubState := FB_SUB_STATE_TWO_VAL_UPDATE_STATUS;
							statMyPermitAbort := TRUE;

							IF statRwRecordIOLData[0] = TICMD_APPLY THEN
								statFBState := FB_STATE_CHECK_RESULT;
								statStatus := STATUS_TEACH_APPLYING; // Busy, Teach process, apply action
							END_IF;
						END_IF;
					END_IF;

					IF statTP1Teached AND statTP2Teached THEN
						statMyPermitApply := TRUE;

						IF applyAuto THEN
							statRwRecordIOLData[0] := TICMD_APPLY;
							statFBSubState := FB_SUB_STATE_TWO_VAL_WRITE_COMMAND;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION

				// REGION dynamic teach-in
				IF statFBState = FB_STATE_DYNAMIC_TEACH_IN THEN

					//Wait for rising edge of TeachRequest input
					IF teachRequest AND NOT statTeachRequestOld THEN
						statStatus := STATUS_TEACH_DYNAMIC_BUSY;

						IF teachFunction = TEACH_FUNCTION_1 AND statMyPermitTeach1 THEN
							// Start Teach
							statRwRecordIOLData[0] := TICMD_TEACH_SP_START;
						ELSIF teachFunction = TEACH_FUNCTION_2 AND statMyPermitTeach2 AND statTeachStarted THEN
							// Stop Teach
							statRwRecordIOLData[0] := TICMD_TEACH_SP_STOP;
						END_IF;

						statFBSubState := FB_SUB_STATE_DYNAMIC_WRITE_COMMAND;
					END_IF;

					// Send Stop Teach Command if time is up
					IF statTeachStarted AND teachTimer <> T#0ms AND instTimer.output = TRUE THEN
						// Stop Teach
						statRwRecordIOLData[0] := TICMD_TEACH_SP_STOP;
						statFBSubState := FB_SUB_STATE_DYNAMIC_WRITE_COMMAND;
					END_IF;

					// Update status information
					IF statFBSubState = FB_SUB_STATE_DYNAMIC_UPDATE_STATUS THEN
						instDevice(execute := TRUE,
						readWrite := MODE_READ,
						index := INDEX_TI_RESULT,
						record := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
							record := statRwRecordIOLData);

							// Evaluate response from device
							IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_IDLE) OR
								(statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS)
							THEN // Idle and success are handled as error because wait for command is expected here
								statStatus := ERR_TEACH_DEVICE;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
								statStatus := STATUS_TEACH_DYNAMIC_WAITING;
								statFBSubState := 0;
								statTeachStarted := TRUE;
								statMyPermitTeach1 := FALSE;
								statMyPermitTeach2 := TRUE;
								statMyPermitAbort := TRUE;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
								statStatus := STATUS_TEACH_DYNAMIC_BUSY;
							ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
								statStatus := ERR_TEACH_DEVICE;
							ELSE
								statStatus := ERR_TEACH_DEVICE;
							END_IF;
						END_IF;
					END_IF;

					IF statFBSubState = FB_SUB_STATE_DYNAMIC_WRITE_COMMAND THEN
						instDevice(execute := TRUE,
						readWrite := MODE_WRITE,
						index := INDEX_SYS_CMD,
						writeLen := 1,
						record := statRwRecordIOLData);

						IF instDevice.done THEN
							instDevice(execute := FALSE,
								record := statRwRecordIOLData);

							IF statRwRecordIOLData[0] = TICMD_TEACH_SP_START THEN
								statFBSubState := FB_SUB_STATE_DYNAMIC_UPDATE_STATUS;

								// Start Teach Timer
								IF teachTimer <> T#0ms THEN
									instTimer(duration := teachTimer,
									signal := TRUE);
								END_IF;

							ELSIF statRwRecordIOLData[0] = TICMD_TEACH_SP_STOP THEN
								statFBState := FB_STATE_CHECK_RESULT;
								statStatus := STATUS_TEACH_APPLYING; // Busy, Teach process, apply action
							END_IF;

						statMyPermitAbort := TRUE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION dynamic teach-in

				// REGION check result
				IF statFBState = FB_STATE_CHECK_RESULT THEN
					statMyPermitTeach1 := FALSE;
					statMyPermitTeach2 := FALSE;
					statMyPermitApply := FALSE;
					statMyPermitAbort := FALSE;

					// Read Teach-in state
					instDevice(execute := TRUE,
					readWrite := MODE_READ,
					index := INDEX_TI_RESULT,
					record := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record := statRwRecordIOLData);

						IF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_BUSY) THEN
							; // Keep trying until teach state of device is not busy
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_SUCCESS) THEN
							statMyPermitTeach1 := FALSE;
							statMyPermitTeach2 := FALSE;
							statMyPermitApply := FALSE;
							statMyPermitAbort := FALSE;

							statFBState := FB_STATE_READ_ALL; // Go to read all
							statIndexRead := INDEX_SSC_PARAM;
							statLenRead := 2;
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_WAIT_FOR_COMMAND) THEN
							statStatus := STATUS_TEACH_WAITING_APPLY;
						ELSIF (statRwRecordIOLData[0] AND MASK_TEACH_STATE) = TO_BYTE(TEACH_STATE_ERROR) THEN
							statStatus := ERR_TEACH_DEVICE;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION check result

				// REGION abort
				// Check for Abort Teach and not permitted Functions
				IF teachRequest AND NOT statTeachRequestOld THEN
					IF teachFunction = TEACH_FUNCTION_1 AND NOT statMyPermitTeach1
						OR teachFunction = TEACH_FUNCTION_2 AND NOT statMyPermitTeach2
						OR teachFunction = TEACH_FUNCTION_APPLY AND NOT statMyPermitApply
						OR teachFunction = TEACH_FUNCTION_ABORT AND NOT statMyPermitAbort
					THEN
						statStatus := ERR_TEACH_NOT_ALLOWED;
					ELSIF teachFunction = TEACH_FUNCTION_ABORT AND statMyPermitAbort THEN
						statFBState := FB_STATE_ABORT_TEACH;
					END_IF;
				END_IF;

				IF statFBState = FB_STATE_ABORT_TEACH THEN
					statStatus := STATUS_TEACH_ABORTING;

					// Abort Teach-in sequence
					statRwRecordIOLData[0] := TICMD_TEACH_CANCEL;
					instDevice(execute := TRUE,
					readWrite := MODE_WRITE,
					index := INDEX_SYS_CMD,
					writeLen := 1,
					record := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record := statRwRecordIOLData);

						statStatus := STATUS_EXECUTION_FINISHED;
					END_IF;
				END_IF;
				// END_REGION abort

				// Error Handling
				IF instDevice.error THEN
					statStatus := ERR_DEVICE_FB;
					statSubfunctionStatus := instDevice.status;
					statFBErrorState := statFBSubState;
				END_IF;
				// END_REGION teach

			FB_STATE_READ_ALL..FB_STATE_BACKUP:
				// State to read and write Setpoint and Logic

				// REGION read all
				IF statFBState = FB_STATE_READ_ALL THEN // Read "Logic" and "Setpoint"
					statStatus := STATUS_BUSY_READING; // Busy reading data

					instDevice(execute := TRUE,
					readWrite := MODE_READ,
					index := statIndexRead,
					record := statRwRecordIOLData);

					IF instDevice.done THEN
						instDevice(execute := FALSE,
						record := statRwRecordIOLData);

						IF statIndexRead >= INDEX_SSC_CONFIG THEN
							logicOut := TO_BOOL(statRwRecordIOLData[0] AND BYTE#2#00000001);

							IF backupEnable AND functionCmd = FUNC_TEACH THEN
								statFBState := FB_STATE_BACKUP;
							ELSE
								statStatus := STATUS_EXECUTION_FINISHED;
							END_IF;

						ELSE
							tempSetpointOut1.%B0 := statRwRecordIOLData[1];
							tempSetpointOut1.%B1 := statRwRecordIOLData[0];
							setpointOut1 := TO_INT(tempSetpointOut1);

							tempSetpointOut2.%B0 := statRwRecordIOLData[1];
							tempSetpointOut2.%B1 := statRwRecordIOLData[0];
							setpointOut2 := TO_INT(tempSetpointOut2);

							// Read "Logic" after reading "Setpoint"
							statIndexRead := statIndexRead + (1);
							statLenRead := 1;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION read all

				// REGION write config
				IF statFBState = FB_STATE_WRITE_CONF THEN
					statStatus := STATUS_BUSY_WRITING; // Busy writing data
					statRwRecordIOLData[0] := TO_BYTE(logicIn);

					instDevice(execute := true,
						readWrite := MODE_WRITE,
						index := INDEX_SSC_CONFIG,
						writeLen := 1,
						record := statRwRecordIOLData);

					IF instDevice.done THEN
						//Write input to output if writing was successful
						logicOut := logicIn;

						IF backupEnable THEN
							statFBState := FB_STATE_BACKUP;
							instDevice(execute := FALSE,
							record := statRwRecordIOLData);
						ELSE
							statStatus := STATUS_EXECUTION_FINISHED;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION write config

				// REGION write param
				IF statFBState = FB_STATE_WRITE_PARAM THEN
					statStatus := STATUS_BUSY_WRITING;

					tempSetpointIn1 := TO_WORD(setpointIn1);
					statRwRecordIOLData[1] := tempSetpointIn1.%B0;
					statRwRecordIOLData[0] := tempSetpointIn1.%B1;

					tempSetpointIn2 := TO_WORD(setpointIn2);
					statRwRecordIOLData[1] := tempSetpointIn2.%B0;
					statRwRecordIOLData[0] := tempSetpointIn2.%B1;

					instDevice(execute := TRUE,
					readWrite := MODE_WRITE,
					index := INDEX_SSC_PARAM,
					writeLen := 2,
					record := statRwRecordIOLData);

					IF instDevice.done THEN
						//Write input to output if writing was successful
						setpointOut1 := setpointIn1;
						setpointOut2 := setpointIn2;
						IF backupEnable THEN
							statFBState := FB_STATE_BACKUP;
							instDevice(execute := FALSE,
							record := statRwRecordIOLData);
						ELSE
							statStatus := STATUS_EXECUTION_FINISHED;
						END_IF;
					END_IF;
				END_IF;
				// END_REGION write param

				// REGION param download store
				IF statFBState = FB_STATE_BACKUP THEN
					statStatus := STATUS_BUSY_BACKUP; // Busy backup
					statRwRecordIOLData[0] := BYTE#16#05;

					instDevice(execute := TRUE,
					readWrite := MODE_WRITE,
					index := INDEX_SYS_CMD,
					writeLen := 1,
					record := statRwRecordIOLData);

					IF instDevice.done THEN
						statStatus := STATUS_EXECUTION_FINISHED;
					END_IF;
				END_IF;
				// END_REGION param download store

				// Error handling
				IF instDevice.error THEN
					statStatus := ERR_DEVICE_FB;
					statSubfunctionStatus := instDevice.status;
					statFBErrorState := statFBState;
				END_IF;
				// END_REGION param exchange
		END_CASE;
		// END_REGION STATE_MACHINE

		// REGION OUTPUTS
		// Write outputs
		IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
			// REGION execution finished
			statDone := TRUE;
			statBusy := FALSE;
			statError := FALSE;

			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;
			statMyPermitApply := FALSE;
			statMyPermitAbort := FALSE;

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			statFBState := 0;
			statFBSubState := 0;
			// END_REGION execution finished

		ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
			// REGION error occured
			statDone := FALSE;
			statBusy := FALSE;
			statError := TRUE;

			statMyPermitTeach1 := FALSE;
			statMyPermitTeach2 := FALSE;
			statMyPermitApply := FALSE;
			statMyPermitAbort := FALSE;

			// Write diagnostics
			diagnostics.status := statStatus;
			diagnostics.subfunctionStatus := statSubfunctionStatus;
			diagnostics.stateNumber := statFBErrorState;

			// Reset instance for next job
			instDevice(execute := FALSE,
			record := statRwRecordIOLData);

			// execution aborted --> set state no processing
			statFBState := FB_STATE_NO_PROCESSING;
			statFBState := 0;
			statFBSubState := 0;
			// END_REGION error occured

		ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
			// REGION execute reset
			statDone := FALSE;
			statBusy := FALSE;
			statError := FALSE;
			statStatus := STATUS_NO_CALL;

			// Reset instance for next job
			instDevice(execute := FALSE,
			record := statRwRecordIOLData);

			// END_REGION execute reset
		END_IF;

		// REGION Write static values to outputs
		done := statDone;
		busy := statBusy;
		error := statError;
		status := statStatus;

		// Write internal used variables to outputs
		permitTeach1 := statMyPermitTeach1;
		permitTeach2 := statMyPermitTeach2;
		permitApply := statMyPermitApply;
		permitAbort := statMyPermitAbort;

		// Needed to detect rising edge at inputs
		statTeachRequestOld := teachRequest;

		// END_REGION Write static values to outputs
		// END_REGION OUTPUTS
	END_FUNCTION_BLOCK

	TYPE
		statIdentObjectInfoType : STRUCT   // Contains information about the elements of output IdentificationObjects
			index : Int := 0;   // Index of parameter
			len : Int := 12;   // Length of parameter
			optional : Bool := false;   // Parameter is optional
		END_STRUCT;
	END_TYPE

END_NAMESPACE
