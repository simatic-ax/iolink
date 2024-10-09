NAMESPACE Simatic.Ax.IOLink
FUNCTION_BLOCK LIOLink_3RA
  /// LIOLink_3RA
  // Author : SIOS
  // Family : LIOLink
  // Version : 3.1
//IO-Link Device FB for SIRIUS 3RAxy to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      parameterPage1 : Bool;   // Read/Write access on parameter page 1
      vendorName : Bool;   // Read Vendor Name
      vendorText : Bool;   // Read Vendor Text
      productName : Bool;   // Read Product Name
      productID : Bool;   // Read Product ID
      productText : Bool;   // Read Product Text
      serialNumber : Bool;   // Read Serial Number
      hwRevision : Bool;   // Read HW-Revision
      fwRevision : Bool;   // Read FW-Revision
      appSpecificName : Bool;   // Read/Write Application Specific Name
      diagnosis : Bool;   // Read diagnostics
      actualConfig : Bool;   // Read actual configuration
      targetConfig : Bool;   // Read/Write target configuration
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3RA_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecordParam : statRecordParamType;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statParameterPage1 : Bool;   // Static value for input 'parameterPage1'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statProductText : Bool;   // Static value for input 'productText'
      statSerialNumber : Bool;   // Static value for input 'serialNumber'
      statHwRevision : Bool;   // Static value for input 'hwRevision'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statActualConfig : Bool;   // Static value for input 'actualConfig'
      statTargetConfig : Bool;   // Static value for input 'targetConfig'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Length
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE] of Byte;   // Auxiliary tag for Parameter Page 0 record conversion
      tempFieldParameterPage1 : Array[0..UPPER_BOUND_PARAMETER_PAGE] of Byte;   // Auxiliary tag for Parameter Page 1 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldActualConfig : Array[0..UPPER_BOUND_ACTUAL_TARGET_CONFIG] of Byte;   // Auxiliary tag for Actual Configuration record conversion
      tempFieldTargetConfig : Array[0..UPPER_BOUND_ACTUAL_TARGET_CONFIG] of Byte;   // Auxiliary tag for Target Configuration record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_PARAMETER_PAGE : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 51;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_ACTUAL_TARGET_CONFIG : Int := 41;   // Upper Bound of Actual and Target Configuration auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_DIRECT_PARAM1 : Int := 1;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_PRODUCT_TEXT : Int := 20;   // Record Index
      INDEX_SERIAL_NUMBER : Int := 21;   // Record Index
      INDEX_HARDWARE_REVISION : Int := 22;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_DIAGNOSTICS : Int := 90;   // Record Index
      INDEX_ACTUAL_CONFIG : Int := 105;   // Record Index
      INDEX_TARGET_CONFIG : Int := 130;   // Record Index
      LENGTH_DIRECT_PARAM0 : Int := 16;   // Record Length
      LENGTH_DIRECT_PARAM1 : Int := 16;   // Record Length
      LENGTH_VENDOR_NAME : Int := 10;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 58;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 30;   // Record Length
      LENGTH_PRODUCT_ID : Int := 8;   // Record Length
      LENGTH_PRODUCT_TEXT : Int := 2;   // Record Length
      LENGTH_SERIAL_NUMBER : Int := 8;   // Record Length
      LENGTH_HARDWARE_REVISION : Int := 4;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 4;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 52;   // Record Length
      LENGTH_ACTUAL_TARGET_CONFIG : Int := 42;   // Record Length
      LENGTH_WRITE_TARGET_CONFIG : Int := 43;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3RA
	    // Function:         Capsule block to communicate with 3RA devices
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 11.04.2014 | Online Support         | First release
	    // 02.00.00 | 30.03.2015 | Online Support         | Upgrade to TIA Portal V13 SP1, use function IO_LINK_DEVICE, only one function for S7-1200 and 1500
	    // 02.01.00 | 23.10.2015 | Online Support         | Update to IO_LINK_DEVICE V3.1.0
	    // 03.00.00 | 22.09.2020 | Online Support         | Rewrote block for FB "LIOLink_Device" V4.0.0
	    // 03.01.00 | 05.10.2022 | SUP SPH                | Optimization
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statParameterPage1 := parameterPage1;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statProductText := productText;
	            statSerialNumber := serialNumber;
	            statHwRevision := hwRevision;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statDiagnosis := diagnosis;
	            statActualConfig := actualConfig;
	            statTargetConfig := targetConfig;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_DIRECT_PARAM0;
	            ELSIF statParameterPage1 THEN
	                statIndex := INDEX_DIRECT_PARAM1;
	                statRecordLen := LENGTH_DIRECT_PARAM1;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statProductText THEN
	                statIndex := INDEX_PRODUCT_TEXT;
	                statRecordLen := LENGTH_PRODUCT_TEXT;
	            ELSIF statSerialNumber THEN
	                statIndex := INDEX_SERIAL_NUMBER;
	                statRecordLen := LENGTH_SERIAL_NUMBER;
	            ELSIF statHwRevision THEN
	                statIndex := INDEX_HARDWARE_REVISION;
	                statRecordLen := LENGTH_HARDWARE_REVISION;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;  // The length in manual is a odd number (currently 53) as the last byte is empty, a even number (52) off bytes is used to have an optimized data access
	            ELSIF statActualConfig THEN
	                statIndex := INDEX_ACTUAL_CONFIG;
	                statRecordLen := LENGTH_ACTUAL_TARGET_CONFIG;
	            ELSIF statTargetConfig THEN
	                statIndex := INDEX_TARGET_CONFIG;
	                IF statReadWrite = MODE_READ THEN
	                    statRecordLen := LENGTH_ACTUAL_TARGET_CONFIG; // It is not a fault to use the lenght of the actual config as actual and target structure are the same - for read job it is okay to use the same even length
	                ELSE
	                    statRecordLen := LENGTH_WRITE_TARGET_CONFIG; // For write job the full data set need to be written to get accepted (currently 43 Byte) but as it is a odd structure and the last bytes are empty, internally a shorter and even structure is used 
	                END_IF;
	            ELSE
	                
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statParameterPage1 THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameterPage1, DEST_ARRAY => tempFieldParameterPage1, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameterPage1[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statTargetConfig THEN
	                    // IMPORTANT: The write job and the data preparation is special as internally the data structure of the target config has a length of 42 byte for optimized handling.
	                    // But the data set in the 3RA has a odd length of 43 byte.
	                    
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.targetConfig, DEST_ARRAY => tempFieldTargetConfig, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldTargetConfig[0],
	                              COUNT := TO_ULINT(LENGTH_ACTUAL_TARGET_CONFIG), // Only the netto data range (currently 42 Bytes) is copied to the record area
	                              OUT => statRecord[0]);
	                    statRecord[LENGTH_ACTUAL_TARGET_CONFIG] := 16#00;  // The last odd byte of the record area (Byte 43 = Index 42 in the record field) is reset to 0 as 43 Bytes need to be written as the data set is 43 Bytes long
	                ELSE // all other data sets are read only  
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	        ELSIF statParameterPage1 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage1[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage1, DEST_VARIABLE => data.parameterPage1, POS := tempPosDeserialize);
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	        ELSIF statProductText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productText);
	        ELSIF statSerialNumber THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.serialNumber);
	        ELSIF statHwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.hwRevision);
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	        ELSIF statActualConfig THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldActualConfig[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldActualConfig, DEST_VARIABLE => data.actualConfig, POS := tempPosDeserialize);
	        ELSIF statTargetConfig THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldTargetConfig[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldTargetConfig, DEST_VARIABLE => data.targetConfig, POS := tempPosDeserialize);
	        ELSE  // all other data set are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3RB24
  /// LIOLink_3RB24
  // Author : SIOS
  // Family : LIOLink
  // Version : 3.1
//IO-Link Device FB for SIRIUS 3RB24  to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      vendorName : Bool;   // Read vendor name
      vendorText : Bool;   // Read vendor text
      productName : Bool;   // Read product name
      productID : Bool;   // Read product ID
      productText : Bool;   // Read product text
      serialNumber : Bool;   // Read serial number
      hwRevision : Bool;   // Read hardware revision
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/Write application specific name
      processInput : Bool;   // Read input data
      processOutput : Bool;   // Read output data
      diagnosis : Bool;   // Read diagnostics
      measurements : Bool;   // Read measured values
      presetConfig : Bool;   // Read/Write preset configuration of device
      techFunctions : Bool;   // Read technology functions
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3RB24_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statProductText : Bool;   // Static value for input 'productText'
      statSerialNumber : Bool;   // Static value for input 'serialNumber'
      statHwRevision : Bool;   // Static value for input 'hwRevision'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statProcessInput : Bool;   // Static value for input 'processInput'
      statProcessOutput : Bool;   // Static value for input 'processOutput'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statMeasurements : Bool;   // Static value for input 'measurements'
      statPresetConfig : Bool;   // Static value for input 'presetConfig'
      statTechFunctions : Bool;   // Static value for input 'techFunctions'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Record Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter page 0 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldMeasuredValues : Array[0..UPPER_BOUND_MEASURED_VALUES] of Byte;   // Auxiliary tag for Measurement record conversion
      tempFieldPresetConfig : Array[0..UPPER_BOUND_PRESET_CONFIG] of Byte;   // Auxiliary tag for Preset record conversion
      tempFieldTechFunctions : Array[0..UPPER_BOUND_TECH_FUNCTIONS] of Byte;   // Auxiliary tag for Technological Functions record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 25;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_MEASURED_VALUES : Int := 39;   // Upper Bound of measured values auxiliary field
      UPPER_BOUND_PRESET_CONFIG : Int := 21;   // Upper Bound of preset configuration auxiliary field
      UPPER_BOUND_TECH_FUNCTIONS : Int := 25;   // Upper Bound of technology funtions auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_PRODUCT_TEXT : Int := 20;   // Record Index
      INDEX_SERIAL_NUMBER : Int := 21;   // Record Index
      INDEX_HARDWARE_REVISION : Int := 22;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_PROCESS_INPUT : Int := 40;   // Record Index
      INDEX_PROCESS_OUTPUT : Int := 41;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_MEASUREMENTS : Int := 94;   // Record Index
      INDEX_PRESET_CONFIG : Int := 130;   // Record Index
      INDEX_TECH_FUNCTIONS : Int := 131;   // Record Index
      LENGTH_DIRECT_PARAM0 : Int := 16;   // Record Length
      LENGTH_VENDOR_NAME : Int := 10;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 30;   // Record Length
      LENGTH_PRODUCT_ID : Int := 12;   // Record Length
      LENGTH_PRODUCT_TEXT : Int := 2;   // Record Length
      LENGTH_SERIAL_NUMBER : Int := 8;   // Record Length
      LENGTH_HARDWARE_REVISION : Int := 4;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 4;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_PROCESS_INPUT : Int := 2;   // Record Length
      LENGTH_PROCESS_OUTPUT : Int := 1;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 25;   // Record Length
      LENGTH_MEASUREMENTS : Int := 40;   // Record Length
      LENGTH_PRESET_CONFIG : Int := 22;   // Record Length
      LENGTH_TECH_FUNCTIONS : Int := 26;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3RB24
	    // Function:         Capsule block to communicate with 3RB24 devices
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 11.04.2014 | Online Support         | First release
	    // 02.00.00 | 30.03.2015 | Online Support         | Upgrade to TIA Portal V13 SP1, use function IO_LINK_DEVICE, only one function for S7-1200 and 1500
	    // 02.01.00 | 23.10.2015 | Online Support         | Update to IO_LINK_DEVICE Version 3.1
	    // 03.00.00 | 01.09.2020 | Online Support         | Upgraded FB "LIOLink_Device" to V4.0.0
	    // 03.01.00 | 05.10.2022 | SUP SPH                | Optimization   
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statProductText := productText;
	            statSerialNumber := serialNumber;
	            statHwRevision := hwRevision;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statProcessInput := processInput;
	            statProcessOutput := processOutput;
	            statDiagnosis := diagnosis;
	            statMeasurements := measurements;
	            statPresetConfig := presetConfig;
	            statTechFunctions := techFunctions;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_DIRECT_PARAM0;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statProductText THEN
	                statIndex := INDEX_PRODUCT_TEXT;
	                statRecordLen := LENGTH_PRODUCT_TEXT;
	            ELSIF statSerialNumber THEN
	                statIndex := INDEX_SERIAL_NUMBER;
	                statRecordLen := LENGTH_SERIAL_NUMBER;
	            ELSIF statHwRevision THEN
	                statIndex := INDEX_HARDWARE_REVISION;
	                statRecordLen := LENGTH_HARDWARE_REVISION;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statProcessInput THEN
	                statIndex := INDEX_PROCESS_INPUT;
	                statRecordLen := LENGTH_PROCESS_INPUT;
	            ELSIF statProcessOutput THEN
	                statIndex := INDEX_PROCESS_OUTPUT;
	                statRecordLen := LENGTH_PROCESS_OUTPUT;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statMeasurements THEN
	                statIndex := INDEX_MEASUREMENTS;
	                statRecordLen := LENGTH_MEASUREMENTS;
	            ELSIF statPresetConfig THEN
	                statIndex := INDEX_PRESET_CONFIG;
	                statRecordLen := LENGTH_PRESET_CONFIG;
	            ELSIF statTechFunctions THEN
	                statIndex := INDEX_TECH_FUNCTIONS;
	                statRecordLen := LENGTH_TECH_FUNCTIONS;
	            ELSE
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statPresetConfig THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.presetConfig, DEST_ARRAY => tempFieldPresetConfig, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldPresetConfig[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE // all other data sets are read only  
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	            
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	            
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	            
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	            
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	            
	        ELSIF statProductText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productText);
	        ELSIF statSerialNumber THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.serialNumber);
	            
	        ELSIF statHwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.hwRevision);
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	            
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	            
	        ELSIF statProcessInput THEN
	            data.processInput.%B0 := statRecord[0];
	            data.processInput.%B1 := statRecord[1];
	            
	        ELSIF statProcessOutput THEN
	            data.processOutput := statRecord[0];
	            
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	            
	        ELSIF statMeasurements THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldMeasuredValues[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldMeasuredValues, DEST_VARIABLE => data.measuredValues, POS := tempPosDeserialize);
	            
	        ELSIF statPresetConfig THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldPresetConfig[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldPresetConfig, DEST_VARIABLE => data.presetConfig, POS := tempPosDeserialize);
	            
	        ELSIF statTechFunctions THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldTechFunctions[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldTechFunctions, DEST_VARIABLE => data.techFunctions, POS := tempPosDeserialize);
	        ELSE  // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3RR24
  /// LIOLink_3RR24
  // Author : SIOS
  // Family : LIOLink
  // Version : 3.1
//IO-Link Device FB for SIRIUS 3RR24 to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      systemCommands : Bool;   // Write system commands
      vendorName : Bool;   // Read vendor name
      vendorText : Bool;   // Read vendor text
      productName : Bool;   // Read product name
      productID : Bool;   // Read product ID
      serialNumber : Bool;   // Read serial number
      hwRevision : Bool;   // Read hardware revision
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/Write application specific name
      diagnosis : Bool;   // Read diagnostics
      measurements : Bool;   // Read measurements
      parameters : Bool;   // Read/Write parameters
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3RR24_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statSystemCommands : Bool;   // Static value for input 'systemCommands'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statSerialNumber : Bool;   // Static value for input 'serialNumber'
      statHwRevision : Bool;   // Static value for input 'hwRevision'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statMeasurements : Bool;   // Static value for input 'measurements'
      statParameters : Bool;   // Static value for input 'parameters'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Record length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameters : Array[0..UPPER_BOUND_PARAMETERS] of Byte;   // Auxiliary tag for Parameter record conversion
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter page 0 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldMeasurements : Array[0..UPPER_BOUND_MEASUREMENTS] of Byte;   // Auxiliary tag for Measurement record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_PARAMETERS : Int := 61;   // Upper Bound of Parameter auxiliary field
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 29;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_MEASUREMENTS : Int := 55;   // Upper Bound of Measurements auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_SYSTEM_COMMANDS : Int := 2;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_SERIAL_NUMBER : Int := 21;   // Record Index
      INDEX_HARDWARE_REVISION : Int := 22;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_MEASUREMENTS : Int := 94;   // Record Index
      INDEX_PARAMETERS : Int := 131;   // Record Index
      LENGTH_DIRECT_PARAM0 : Int := 16;   // Record Length
      LENGTH_SYSTEM_COMMANDS : Int := 1;   // Record Length
      LENGTH_VENDOR_NAME : Int := 11;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 64;   // Record Length
      LENGTH_PRODUCT_ID : Int := 14;   // Record Length
      LENGTH_SERIAL_NUMBER : Int := 16;   // Record Length
      LENGTH_HARDWARE_REVISION : Int := 7;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 7;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 30;   // Record Length
      LENGTH_MEASUREMENTS : Int := 56;   // Record Length
      LENGTH_PARAMETERS : Int := 62;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2020
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3RR24
	    // Function:         Capsule block to communicate with 3RR24 devices
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 11.04.2014 | Online Support         | First release
	    // 01.00.01 | 12.09.2014 | Online Support         | Bugfixing write case 28 (data set 131)
	    // 02.00.00 | 30.03.2015 | Online Support         | Upgrade to TIA Portal V13 SP1, use function IO_LINK_DEVICE, only one function for S7-1200 and 1500
	    // 02.01.00 | 23.10.2015 | Online Support         | Update to IO_LINK_DEVICE Version 3.1
	    // 03.00.00 | 01.09.2020 | Online Support         | Upgraded FB "LIOLink_Device" to V4.0.0
	    // 03.01.00 | 05.10.2022 | SUP SPH                | Optimization 
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statSystemCommands := systemCommands;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statSerialNumber := serialNumber;
	            statHwRevision := hwRevision;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statDiagnosis := diagnosis;
	            statMeasurements := measurements;
	            statParameters := parameters;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_DIRECT_PARAM0;
	            ELSIF statSystemCommands THEN
	                statIndex := INDEX_SYSTEM_COMMANDS;
	                statRecordLen := LENGTH_SYSTEM_COMMANDS;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statSerialNumber THEN
	                statIndex := INDEX_SERIAL_NUMBER;
	                statRecordLen := LENGTH_SERIAL_NUMBER;
	            ELSIF statHwRevision THEN
	                statIndex := INDEX_HARDWARE_REVISION;
	                statRecordLen := LENGTH_HARDWARE_REVISION;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statMeasurements THEN
	                statIndex := INDEX_MEASUREMENTS;
	                statRecordLen := LENGTH_MEASUREMENTS;
	            ELSIF statParameters THEN
	                statIndex := INDEX_PARAMETERS;
	                statRecordLen := LENGTH_PARAMETERS;
	            ELSE
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statSystemCommands THEN
	                    statRecord[0] := data.systemCommands;
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statParameters THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameters, DEST_ARRAY => tempFieldParameters, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameters[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE    // all other data set are read only
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	        ELSIF statSerialNumber THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.serialNumber);
	        ELSIF statHwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.hwRevision);
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	        ELSIF statMeasurements THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldMeasurements[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldMeasurements, DEST_VARIABLE => data.measuredValues, POS := tempPosDeserialize);
	        ELSIF statParameters THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameters[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameters, DEST_VARIABLE => data.parameters, POS := tempPosDeserialize);
	        ELSE  // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3RS1
  /// LIOLink_3RS1
  // Author : SIOS
  // Family : LIOLink
  // Version : 3.1
//IO-Link Device FB for SIRIUS 3RS1 to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      vendorName : Bool;   // Read vendor name
      vendorText : Bool;   // Read vendor text
      productName : Bool;   // Read product name
      productID : Bool;   // Read product ID
      hwRevision : Bool;   // Read hardware revision
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/Write application specific name
      diagnosis : Bool;   // Read diagnostics
      measurements : Bool;   // Read measurements
      parameters : Bool;   // Read/Write parameters
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3RS1_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statHwRevision : Bool;   // Static value for input 'hwRevision'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statMeasurements : Bool;   // Static value for input 'measurements'
      statParameters : Bool;   // Static value for input 'parameters'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Record Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameters : Array[0..UPPER_BOUND_PARAMETERS] of Byte;   // Auxiliary tag for Parameter record conversion
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter page 0 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldMeasurements : Array[0..UPPER_BOUND_MEASUREMENTS] of Byte;   // Auxiliary tag for Measurement record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_PARAMETERS : Int := 49;   // Upper Bound of Parameter auxiliary field
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 39;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_MEASUREMENTS : Int := 45;   // Upper Bound of measured values auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_HARDWARE_REVISION : Int := 22;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_MEASUREMENTS : Int := 94;   // Record Index
      INDEX_PARAMETERS : Int := 131;   // Record Index
      LENGTH_DIRECT_PARAM0 : Int := 16;   // Record Length
      LENGTH_VENDOR_NAME : Int := 11;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 64;   // Record Length
      LENGTH_PRODUCT_ID : Int := 14;   // Record Length
      LENGTH_HARDWARE_REVISION : Int := 7;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 7;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 40;   // Record Length
      LENGTH_MEASUREMENTS : Int := 46;   // Record Length
      LENGTH_PARAMETERS : Int := 50;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3RS1x
	    // Function:         Capsule block to communicate with 3RS1 devices
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 11.04.2014 | Online Support         | First release
	    // 02.00.00 | 30.03.2015 | Online Support         | Upgrade to TIA Portal V13 SP1, use function IO_LINK_DEVICE, only one function for S7-1200 and 1500
	    // 02.01.00 | 23.10.2015 | Online Support         | Update to IO_LINK_DEVICE Version 3.1
	    // 03.00.00 | 01.09.2020 | Online Support         | Rewrote block for FB "LIOLink_Device" V4.0.0
	    // 03.01.00 | 05.10.2022 | SUP SPH                | Optimization   
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statHwRevision := hwRevision;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statDiagnosis := diagnosis;
	            statMeasurements := measurements; 
	            statParameters := parameters;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_DIRECT_PARAM0;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statHwRevision THEN
	                statIndex := INDEX_HARDWARE_REVISION;
	                statRecordLen := LENGTH_HARDWARE_REVISION;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statMeasurements THEN
	                statIndex := INDEX_MEASUREMENTS;
	                statRecordLen := LENGTH_MEASUREMENTS;
	            ELSIF statParameters THEN
	                statIndex := INDEX_PARAMETERS;
	                statRecordLen := LENGTH_PARAMETERS;
	            ELSE
	                RETURN; // No data set selected, abort execution
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statParameters THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameters, DEST_ARRAY => tempFieldParameters, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameters[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE // All other data sets are read only
	                    ;
	                END_IF;
	                ;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	        ELSIF statHwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.hardwareRevision);
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.firmwareRevision);
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	        ELSIF statMeasurements THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldMeasurements[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldMeasurements, DEST_VARIABLE => data.measuredValues, POS := tempPosDeserialize);
	        ELSIF statParameters THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameters[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameters, DEST_VARIABLE => data.parameters, POS := tempPosDeserialize);
	        ELSE  // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3RS2
  /// LIOLink_3RS2
  // Author : SIOS
  // Family : LIOLink
  // Version : 1.1
//Capsule block to communicate with 3RS2 devices via IO-Link
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read parameter page 0
      systemCommands : Bool;   // Write system commands
      vendorName : Bool;   // Read vendor name
      vendorText : Bool;   // Read vendor text
      productName : Bool;   // Read product name
      productID : Bool;   // Read product ID
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/write application specific name
      diagnosis : Bool;   // Read diagnostics
      measuredValues : Bool;   // Read measured values
      measuredValuesFloat : Bool;   // Read measured values as Float
      parameters : Bool;   // Read/Write parameters
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3RS2_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statSystemCommands : Bool;   // Static value for input 'systemCommands'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statMeasuredValues : Bool;   // Static value for input 'measuredValues'
      statMeasuredValuesFloat : Bool;   // Static value for input 'measuredValuesFloat'
      statParameters : Bool;   // Static value for input 'parameters'
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
      statParametersJob : Bool;   // Input 'parameters' is triggered
      statConfirmParameters : Bool;   // Variable used to show if user confirmed the changes he made in parameters
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Record Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameters : Array[0..UPPER_BOUND_PARAMETERS] of Byte;   // Auxiliary tag for Parameter record conversion
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter page 0 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldMeasurementsFloat : Array[0..UPPER_BOUND_MEASUREMENTS] of Byte;   // Auxiliary tag for Measurement record conversion
      tempFieldMeasurements : Array[0..UPPER_BOUND_MEASUREMENTS] of Byte;   // Auxiliary tag for Measurement record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
      tempDeviceDone : Bool;   // Auxiliary tag for signaling functionality has been completed successfully
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      UPPER_BOUND_PARAMETERS : Int := 71;   // Upper Bound of Parameter auxiliary field
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 42;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_MEASUREMENTS : Int := 41;   // Upper Bound of measured values auxiliary field
      UPPER_BOUND_MEASUREMENTS_FLOAT : Int := 67;   // Upper Bound of measured values auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_SYSTEM_COMMANDS : Int := 2;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_MEASUREMENTS : Int := 94;   // Record Index
      INDEX_MEASUREMENTS_FLOAT : Int := 95;   // Record Index
      INDEX_PARAMETERS : Int := 131;   // Record Index
      LENGTH_PARAMETER_PAGE0 : Int := 16;   // Record Length
      LENGTH_SYSTEM_COMMANDS : Int := 1;   // Record Length
      LENGTH_VENDOR_NAME : Int := 11;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 64;   // Record Length
      LENGTH_PRODUCT_ID : Int := 14;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 7;   // Record Length
      LENGTH_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 43;   // Record Length
      LENGTH_MEASURED_VALUES : Int := 42;   // Record Length
      LENGTH_MEASURED_FLOAT_VALUES : Int := 68;   // Record Length
      LENGTH_PARAMETERS : Int := 72;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
      SYSTEM_COMMAND_CONFIRM : Byte := BYTE#16#A1;   // System command to confirm new parameters
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3RS2
	    // Function:         Capsule block to communicate with 3RS2 devices
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 22.09.2020 | Online Support         | First release
	    // 01.01.00 | 05.10.2022 | SUP SPH                | Optimization   
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statSystemCommands := systemCommands;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statDiagnosis := diagnosis;
	            statMeasuredValues := measuredValues;
	            statMeasuredValuesFloat := measuredValuesFloat;
	            statParameters := parameters;
	        // END_REGION
	        
	        // REGION Request-specific parameters
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_PARAMETER_PAGE0;
	            ELSIF statSystemCommands OR statConfirmParameters THEN
	                statIndex := INDEX_SYSTEM_COMMANDS;
	                statRecordLen := LENGTH_SYSTEM_COMMANDS;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_SPECIFIC_NAME;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statMeasuredValues THEN
	                statIndex := INDEX_MEASUREMENTS;
	                statRecordLen := LENGTH_MEASURED_VALUES;
	            ELSIF statMeasuredValuesFloat THEN
	                statIndex := INDEX_MEASUREMENTS_FLOAT;
	                statRecordLen := LENGTH_MEASURED_FLOAT_VALUES;
	            ELSIF statParameters THEN
	                statIndex := INDEX_PARAMETERS;
	                statRecordLen := LENGTH_PARAMETERS;
	            ELSE
	                RETURN; // No data set selected, abort execution
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION Write
	                IF statConfirmParameters THEN
	                    statRecord[0] := SYSTEM_COMMAND_CONFIRM;
	                    statConfirmParameters := false;
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statSystemCommands THEN
	                    statRecord[0] := data.systemCommand;
	                    
	                ELSIF statParameters THEN
	                    statParametersJob := true;
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameters, DEST_ARRAY => tempFieldParameters, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameters[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE // All other data sets are read only
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord,
	                done => tempDeviceDone);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE THEN
	        IF statParametersJob THEN
	            statParametersJob := false;
	            statConfirmParameters := true;
	            tempDeviceDone := false;
	        ELSIF statReadWrite = MODE_READ THEN
	            IF statParameterPage0 THEN
	                UMOVE_BLK(IN := statRecord[0],
	                          COUNT := TO_ULINT(statRecordLen),
	                          OUT => tempFieldParameterPage0[0]);
	                tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	            ELSIF statVendorName THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.vendorName);
	            ELSIF statVendorText THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.vendorText);
	            ELSIF statProductName THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.productName);
	            ELSIF statProductID THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.productID);
	            ELSIF statFwRevision THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.firmwareRevision);
	            ELSIF statAppSpecificName THEN
	                Chars_TO_Strg(Chars := statRecord,
	                              pChars := 0,
	                              Cnt := TO_UINT(statRecordLen),
	                              Strg => data.appSpecificName);
	            ELSIF statDiagnosis THEN
	                UMOVE_BLK(IN := statRecord[0],
	                          COUNT := TO_ULINT(statRecordLen),
	                          OUT => tempFieldDiagnostics[0]);
	                tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	            ELSIF statMeasuredValues THEN
	                UMOVE_BLK(IN := statRecord[0],
	                          COUNT := TO_ULINT(statRecordLen),
	                          OUT => tempFieldMeasurements[0]);
	                tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldMeasurements, DEST_VARIABLE => data.measuredValues, POS := tempPosDeserialize);
	            ELSIF statMeasuredValuesFloat THEN
	                UMOVE_BLK(IN := statRecord[0],
	                          COUNT := TO_ULINT(statRecordLen),
	                          OUT => tempFieldMeasurementsFloat[0]);
	                tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldMeasurementsFloat, DEST_VARIABLE => data.measuredValuesFloat, POS := tempPosDeserialize);
	            ELSIF statParameters THEN
	                UMOVE_BLK(IN := statRecord[0],
	                          COUNT := TO_ULINT(statRecordLen),
	                          OUT => tempFieldParameters[0]);
	                tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameters, DEST_VARIABLE => data.parameters, POS := tempPosDeserialize);
	            ELSE // Other data sets are not defined
	                ;
	            END_IF;
	            tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	        END_IF;
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := tempDeviceDone;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3SU1_ElecModule
  /// LIOLink_3SU1_ElecModule
  // Author : SIOS
  // Family : LIOLink
  // Version : 2.1
//IO-Link Device FB for SIRIUS ACT 3SU1 Electronic Module to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      systemCommands : Bool;   // Write system commands
      vendorName : Bool;   // Read Vendor Name
      vendorText : Bool;   // Read Vendor Text
      productName : Bool;   // Read Product Name
      productID : Bool;   // Read Product ID
      fwRevision : Bool;   // Read FW-Revision
      appSpecificName : Bool;   // Read/Write Application Specific Name
      processOutput : Bool;   // Read Process Output Data
      processInput : Bool;   // Read Process Input Data
      diagnosis : Bool;   // Read diagnostics
      statistics : Bool;   // Read statistic data
      parameters : Bool;   // Read / write Parameters
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3SU1_ElecModule_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time;   // Static value for input 'pollingPeriod'
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statSystemCommands : Bool;   // Static value for input 'systemCommands'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statProcessOutput : Bool;   // Static value for input 'processOutput'
      statProcessInput : Bool;   // Static value for input 'processInput'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statStatistics : Bool;   // Static value for input 'statistics'
      statParameters : Bool;   // Static value for input 'parameters'
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Record Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameters : Array[0..UPPER_BOUND_PARAMETERS] of Byte;   // Auxiliary tag for Parameter record conversion
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter page 0 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldStatistics : Array[0..UPPER_BOUND_STATISTICS] of Byte;   // Auxiliary tag for Measurement record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_PARAMETERS : Int := 125;   // Upper Bound of Parameters auxiliary field
      UPPER_BOUND_STATISTICS : Int := 81;   // Upper Bound of Statistics auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 23;   // Upper Bound of Diagnostics auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_SYSTEM_COMMANDS : Int := 2;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_PROCESS_OUTPUT : Int := 67;   // Record Index
      INDEX_PROCESS_INPUT : Int := 69;   // Record Index
      INDEX_STATISTICS : Int := 94;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_PARAMETERS : Int := 131;   // Record Index
      LENGTH_PARAMETER_PAGE0 : Int := 16;   // Record Length
      LENGTH_SYSTEM_COMMANDS : Int := 1;   // Record Length
      LENGTH_VENDOR_NAME : Int := 10;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 40;   // Record Length
      LENGTH_PRODUCT_ID : Int := 18;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 6;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_PROCESS_OUTPUT : Int := 6;   // Record Length
      LENGTH_PROCESS_INPUT : Int := 6;   // Record Length
      LENGTH_STATISTICS : Int := 82;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 24;   // Record Length
      LENGTH_PARAMETERS : Int := 126;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3SU1_ElecModule
	    // Function:         Capsule block to communicate with 3SU1 Electronic Module
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 23.10.2015 | Online Support         | First release
	    // 02.00.00 | 22.09.2020 | Online Support         | Upgraded FB "LIOLink_Device" to V4.0.0
	    // 02.01.00 | 05.10.2022 | SUP SPH                | Optimization   
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs 
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statSystemCommands := systemCommands;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statProcessOutput := processOutput;
	            statProcessInput := processInput;
	            statDiagnosis := diagnosis;
	            statStatistics := statistics;
	            statParameters := parameters;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_PARAMETER_PAGE0;
	            ELSIF statSystemCommands THEN
	                statIndex := INDEX_SYSTEM_COMMANDS;
	                statRecordLen := LENGTH_SYSTEM_COMMANDS;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statProcessOutput THEN
	                statIndex := INDEX_PROCESS_OUTPUT;
	                statRecordLen := LENGTH_PROCESS_OUTPUT;
	            ELSIF statProcessInput THEN
	                statIndex := INDEX_PROCESS_INPUT;
	                statRecordLen := LENGTH_PROCESS_INPUT;
	            ELSIF statStatistics THEN
	                statIndex := INDEX_STATISTICS;
	                statRecordLen := LENGTH_STATISTICS;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statParameters THEN
	                statIndex := INDEX_PARAMETERS;
	                statRecordLen := LENGTH_PARAMETERS;
	            ELSE
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statParameterPage0 THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameterPage0, DEST_ARRAY => tempFieldParameterPage0, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameterPage0[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statSystemCommands THEN
	                    statRecord[0] := data.systemCommand;
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statParameters THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameters, DEST_ARRAY => tempFieldParameters, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameters[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE // All other data sets are read only  
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	            
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	            
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	            
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	            
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	            
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	            
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	            
	        ELSIF statProcessOutput THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => data.processDataOut[0]);
	            
	        ELSIF statProcessInput THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => data.processDataIn[0]);
	            
	        ELSIF statStatistics THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldStatistics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldStatistics, DEST_VARIABLE => data.statistics, POS := tempPosDeserialize);
	            
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	            
	        ELSIF statParameters THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameters[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameters, DEST_VARIABLE => data.parameters, POS := tempPosDeserialize);
	            
	        ELSE // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_3SU1_IDKeySwitch
  /// LIOLink_3SU1_IDKeySwitch
  // Author : SIOS
  // Family : LIOLink
  // Version : 2.1
//IO-Link Device FB for SIRIUS ACT ID Key Switch to use with S7-1200/1500 controllers!
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      parameterPage0 : Bool;   // Read access on parameter page 0
      systemCommands : Bool;   // Write system commands
      vendorName : Bool;   // Read Vendor Name
      vendorText : Bool;   // Read Vendor Text
      productName : Bool;   // Read Product Name
      productID : Bool;   // Read Product ID
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/Write Application Specific Name
      processInput : Bool;   // Read Process Input Data
      addKeyID : Bool;   // Read/Write: Add key ID
      delKeyID : Bool;   // Read/Write: Delete key ID
      keyList1 : Bool;   // Read keys 1 to key 30
      keyList2 : Bool;   // Read keys 31 to key 50
      diagnosis : Bool;   // Read diagnostics
      insertedIDKey : Bool;   // Read ID of the inserted ID key
      parameters : Bool;   // Read/write Parameters
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_3SU1_IDKeySwitch_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time := T#100MS;   // Static value for input 'pollingPeriod'
      statParameterPage0 : Bool;   // Static value for input 'parameterPage0'
      statSystemCommands : Bool;   // Static value for input 'systemCommands'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statProcessInput : Bool;   // Static value for input 'processInput'
      statAddKeyID : Bool;   // Static value for input 'addKeyID'
      statDelKeyID : Bool;   // Static value for input 'delKeyID'
      statKeyList1 : Bool;   // Static value for input 'keyList1'
      statKeyList2 : Bool;   // Static value for input 'keyList2'
      statDiagnosis : Bool;   // Static value for input 'diagnosis'
      statInsertedIDKey : Bool;   // Static value for input 'insertedIDKey'
      statParameters : Bool;   // Static value for input 'parameters'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldParameterPage0 : Array[0..UPPER_BOUND_PARAMETER_PAGE0] of Byte;   // Auxiliary tag for Parameter Page 0 record conversion
      tempFieldParameters : Array[0..UPPER_BOUND_PARAMETERS] of Byte;   // Auxiliary tag for Parameter record conversion
      tempFieldKeyId : Array[0..UPPER_BOUND_KEY_ID] of Byte;   // Auxiliary tag for Delete Key record conversion
      tempFieldKeyList1 : Array[0..UPPER_BOUND_KEY_LIST1] of Byte;   // Auxiliary tag for Key List 1 record conversion
      tempFieldKeyList2 : Array[0..UPPER_BOUND_KEY_LIST2] of Byte;   // Auxiliary tag for Key List 2 record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempFieldInsertedKey : Array[0..UPPER_BOUND_INSERTED_KEY] of Byte;   // Auxiliary tag for Inserted Key record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_PARAMETER_PAGE0 : Int := 15;   // Upper Bound of Parameter Page 0 auxiliary field
      UPPER_BOUND_PARAMETERS : Int := 19;   // Upper Bound of Parameter auxiliary field
      UPPER_BOUND_KEY_ID : Int := 5;   // Upper Bound of Key ID auxiliary field
      UPPER_BOUND_KEY_LIST1 : Int := 179;   // Upper Bound of Key List 1 auxiliary field
      UPPER_BOUND_KEY_LIST2 : Int := 119;   // Upper Bound of Key List 2 auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 19;   // Upper Bound of Diagnostics auxiliary field
      UPPER_BOUND_INSERTED_KEY : Int := 21;   // Upper Bound of Inserted Key auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_DIRECT_PARAM0 : Int := 0;   // Record Index
      INDEX_SYSTEM_COMMANDS : Int := 2;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_PROCESS_INPUT : Int := 69;   // Record Index
      INDEX_ADD_KEY_ID : Int := 79;   // Record Index
      INDEX_DELETE_KEY_ID : Int := 80;   // Record Index
      INDEX_KEY_LIST1 : Int := 81;   // Record Index
      INDEX_KEY_LIST2 : Int := 82;   // Record Index
      INDEX_DIAGNOSTICS : Int := 92;   // Record Index
      INDEX_INSERTED_ID_KEY : Int := 94;   // Record Index
      INDEX_PARAMETERS : Int := 131;   // Record Index
      LENGTH_DIRECT_PARAM0 : Int := 16;   // Record Length
      LENGTH_SYSTEM_COMMANDS : Int := 1;   // Record Length
      LENGTH_VENDOR_NAME : Int := 10;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 64;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 55;   // Record Length
      LENGTH_PRODUCT_ID : Int := 18;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 5;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_PROCESS_INPUT : Int := 6;   // Record Length
      LENGTH_ADD_KEY_ID : Int := 6;   // Record Length
      LENGTH_DELETE_KEY_ID : Int := 5;   // Record Length
      LENGTH_KEY_LIST1 : Int := 180;   // Record Length
      LENGTH_KEY_LIST2 : Int := 120;   // Record Length
      LENGTH_DIAGNOSTICS : Int := 20;   // Record Length
      LENGTH_INSERTED_ID_KEY : Int := 22;   // Record Length
      LENGTH_PARAMETERS : Int := 20;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_3SU1_IDKeySwitch
	    // Function:         Capsule block to communicate with 3SU1 ID Key Switch
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 23.10.2015 | Online Support         | First release
	    // 02.00.00 | 22.09.2020 | Online Support         | Upgraded FB "LIOLink_Device" to V4.0.0
	    // 02.01.00 | 06.10.2022 | SUP SPH                | Optimization
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        
	        // REGION Inputs 
	            //save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statParameterPage0 := parameterPage0;
	            statSystemCommands := systemCommands;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statProcessInput := processInput;
	            statAddKeyID := addKeyID;
	            statDelKeyID := delKeyID;
	            statKeyList1 := keyList1;
	            statKeyList2 := keyList2;
	            statDiagnosis := diagnosis;
	            statInsertedIDKey := insertedIDKey;
	            statParameters := parameters;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statParameterPage0 THEN
	                statIndex := INDEX_DIRECT_PARAM0;
	                statRecordLen := LENGTH_DIRECT_PARAM0;
	            ELSIF statSystemCommands THEN
	                statIndex := INDEX_SYSTEM_COMMANDS;
	                statRecordLen := LENGTH_SYSTEM_COMMANDS;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statProcessInput THEN
	                statIndex := INDEX_PROCESS_INPUT;
	                statRecordLen := LENGTH_PROCESS_INPUT;
	            ELSIF statAddKeyID THEN
	                statIndex := INDEX_ADD_KEY_ID;
	                statRecordLen := LENGTH_ADD_KEY_ID;
	            ELSIF statDelKeyID THEN
	                statIndex := INDEX_DELETE_KEY_ID;
	                statRecordLen := LENGTH_DELETE_KEY_ID;
	            ELSIF statKeyList1 THEN
	                statIndex := INDEX_KEY_LIST1;
	                statRecordLen := LENGTH_KEY_LIST1;
	            ELSIF statKeyList2 THEN
	                statIndex := INDEX_KEY_LIST2;
	                statRecordLen := LENGTH_KEY_LIST2;
	            ELSIF statDiagnosis THEN
	                statIndex := INDEX_DIAGNOSTICS;
	                statRecordLen := LENGTH_DIAGNOSTICS;
	            ELSIF statInsertedIDKey THEN
	                statIndex := INDEX_INSERTED_ID_KEY;
	                statRecordLen := LENGTH_INSERTED_ID_KEY;
	            ELSIF statParameters THEN
	                statIndex := INDEX_PARAMETERS;
	                statRecordLen := LENGTH_PARAMETERS;
	            ELSE
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statParameterPage0 THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameterPage0, DEST_ARRAY => tempFieldParameterPage0, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameterPage0[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statSystemCommands THEN
	                    statRecord[0] := data.systemCommand;
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statAddKeyID THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.addKeyID, DEST_ARRAY => tempFieldKeyId, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldKeyId[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statDelKeyID THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.delKeyID, DEST_ARRAY => tempFieldKeyId, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldKeyId[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statParameters THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.parameters, DEST_ARRAY => tempFieldParameters, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldParameters[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                ELSE // All other data sets are read only  
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	            
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statParameterPage0 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameterPage0[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameterPage0, DEST_VARIABLE => data.parameterPage0, POS := tempPosDeserialize);
	            
	        ELSIF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	            
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	            
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	            
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productID);
	            
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	            
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	            
	        ELSIF statProcessInput THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => data.processDataIn[0]);
	            
	        ELSIF statAddKeyID THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldKeyId[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldKeyId, DEST_VARIABLE => data.addKeyID, POS := tempPosDeserialize);
	            
	        ELSIF statDelKeyID THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldKeyId[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldKeyId, DEST_VARIABLE => data.delKeyID, POS := tempPosDeserialize);
	            
	        ELSIF statKeyList1 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldKeyList1[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldKeyList1, DEST_VARIABLE => data.keyList1, POS := tempPosDeserialize);
	            
	        ELSIF statKeyList2 THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldKeyList2[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldKeyList2, DEST_VARIABLE => data.keyList2, POS := tempPosDeserialize);
	            
	        ELSIF statDiagnosis THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldDiagnostics[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldDiagnostics, DEST_VARIABLE => data.diagnostics, POS := tempPosDeserialize);
	            
	        ELSIF statInsertedIDKey THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldInsertedKey[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldInsertedKey, DEST_VARIABLE => data.insertedKey, POS := tempPosDeserialize);
	            
	        ELSIF statParameters THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldParameters[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldParameters, DEST_VARIABLE => data.parameters, POS := tempPosDeserialize);
	            
	        ELSE // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
END_FUNCTION_BLOCK

FUNCTION_BLOCK LIOLink_8WD46
  /// LIOLink_8WD46
  // Family : LIOLink
  // Version : 1.0
//Capsule block to communicate with 8WD46
   VAR_INPUT 
      execute : Bool;   // Request to execute function
      hwID : HW_IO;   // Hardware identifier of IO-Link master module or first sub module
      cap : Int;   // Client Access Point (CAP) 0xB400 or 0x00E3 (227)
      readWrite : Bool;   // FALSE: read, TRUE: write
      port : Int;   // Port of the IO-Link Master for the Device
      pollingPeriod : Time := T#100MS;   // Time period of polling
      systemCommands : Bool;   // Write system commands
      vendorName : Bool;   // Read Vendor Name
      vendorText : Bool;   // Read Vendor Text
      productName : Bool;   // Read Product Name
      productID : Bool;   // Read Product ID
      productText : Bool;   // Read Product Text
      hwRevision : Bool;   // Read Hardware revision
      fwRevision : Bool;   // Read firmware revision
      appSpecificName : Bool;   // Read/Write Application Specific Name
      functionTag : Bool;   // Read/Write: function tag
      locationTag : Bool;   // Read/Write: location tag
      opHour : Bool;   // Read operating hour
      operatingMode : Bool;   // Read/Write: operating mode (signal mode, auto scale mode, ...)
      lightEffect : USInt;   // Read/Write light effect - 1 to 15: select segment
      soundMode : USInt;   // Read ID of the inserted ID key
      powerReduction : Bool;   // Read/Write power reduction (0: on / 1: off)
      fillLevelMode : Bool;   // Read/Write only in level mode (0: use settings of segment 1-9,15 / 1: use settings of segment 1 )
      headlong : Bool;   // Read/Write orientation of installation (normal / overhead)
      elementCount : Bool;   // Read/Write number of elements
   END_VAR

   VAR_OUTPUT 
      done : Bool;   // TRUE: Commanded functionality has been completed successfully
      busy : Bool;   // TRUE: FB is not finished and new output values can be expected
      error : Bool;   // TRUE: An error occurred during the execution of the FB
      status : Word;   // 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
      diagnostics : LIOLink_typeDiagnostics;   // Diagnostics information of LIOLink_Device
   END_VAR

   VAR_IN_OUT 
      data : LIOLink_8WD46_typeAll;   // Data area, device specific (Data Type)
   END_VAR

   VAR 
      instDevice : LIOLink_Device;
      statRecord : Array[0..UPPER_BOUND_RECORD] of Byte;   // Record buffer
      statIndex : Int;   // Requested index
      statSubindex : Int;   // Requested subindex
      statRecordLen : Int;   // Length of record to be written
      statHwID : HW_IO;   // Static value for input 'hwID'
      statCap : Int;   // Static value for input 'cap'
      statReadWrite : Bool;   // Static value for input 'readWrite'
      statPort : Int;   // Static value for input 'port'
      statPollingPeriod : Time;   // Static value for input 'pollingPeriod'
      statSystemCommands : Bool;   // Static value for input 'systemCommands'
      statVendorName : Bool;   // Static value for input 'vendorName'
      statVendorText : Bool;   // Static value for input 'vendorText'
      statProductName : Bool;   // Static value for input 'productName'
      statProductID : Bool;   // Static value for input 'productID'
      statProductText : Bool;   // Static value for input 'productText'
      statHwRevision : Bool;   // Static value for input 'hwRevision'
      statFwRevision : Bool;   // Static value for input 'fwRevision'
      statAppSpecificName : Bool;   // Static value for input 'appSpecificName'
      statFunctionTag : Bool;   // Static value for input 'functionTag'
      statLocationTag : Bool;   // Static value for input 'locationTag'
      statOpHour : Bool;   // Static value for input 'opHour'
      statOperatingMode : Bool;   // Static value for input 'operatingMode'
      statLightEffect : USInt;   // Static value for input 'lightEffect'
      statSoundMode : USInt;   // Static value for input 'soundMode'
      statPowerReduction : Bool;   // Static value for input 'powerReduction'
      statFillLevelMode : Bool;   // Static value for input 'fillLevelMode'
      statHeadlong : Bool;   // Static value for input 'headLong'
      statElementCount : Bool;   // Static value for input 'elementCount'
      statRequest : Int;   // Case of request (data set)
      statDoneOld : Bool;   // Last cycle's value of instDevice.done
   END_VAR

   VAR_TEMP 
      tempIndex : Int;   // Loop index
      tempLen : UInt;   // Length
      tempRetValSerialize : Int;   // Auxiliary tag for Serialize RetVal
      tempRetValDeserialize : Int;   // Auxiliary tag for Deserialize RetVal
      tempPosSerialize : DInt;   // Auxiliary tag for Serialize POS Output
      tempPosDeserialize : DInt;   // Auxiliary tag for Deserialize POS Output
      tempFieldLightEffects : Array[0..UPPER_BOUND_LIGHT_EFFECTS] of Byte;   // Auxiliary tag for Light Effects record conversion
      tempFieldSoundMode : Array[0..UPPER_BOUND_SOUND_MODE] of Byte;   // Auxiliary tag for Sound Mode record conversion
      tempFieldOpHour : Array[0..UPPER_BOUND_OP_HOUR] of Byte;   // Auxiliary tag for Op Hour record conversion
      tempFieldDiagnostics : Array[0..UPPER_BOUND_DIAGNOSTICS] of Byte;   // Auxiliary tag for Diagnostics record conversion
      tempInternalError : Bool;   // Auxiliary tag to collect serialize and Deserialize issues
   END_VAR

   VAR CONSTANT 
      UPPER_BOUND_RECORD : Int := 231;   // Upper Bound of record buffer
      HIGHEST_REQUEST_NUMBER : Int := 28;   // Highest available request number
      UPPER_BOUND_LIGHT_EFFECTS : Int := 7;   // Upper Bound of Light Effects auxiliary field
      UPPER_BOUND_SOUND_MODE : Int := 15;   // Upper Bound of Sound Mode auxiliary field
      UPPER_BOUND_OP_HOUR : Int := 3;   // Upper Bound of Op Hours auxiliary field
      UPPER_BOUND_DIAGNOSTICS : Int := 19;   // Upper Bound of Diagnostics auxiliary field
      MODE_READ : Bool := FALSE;   // Mode to read data
      MODE_WRITE : Bool := TRUE;   // Mode to write data
      STATUS_IDLE : Word := WORD#16#7000;   // Status: Idle
      STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;   // Execution finished without errors
      ERR_INCONSISTENT_DATA : Word := WORD#16#8402;   // Error: Read data record doesn't match request
      INDEX_SYSTEM_COMMANDS : Int := 2;   // Record Index
      INDEX_VENDOR_NAME : Int := 16;   // Record Index
      INDEX_VENDOR_TEXT : Int := 17;   // Record Index
      INDEX_PRODUCT_NAME : Int := 18;   // Record Index
      INDEX_PRODUCT_ID : Int := 19;   // Record Index
      INDEX_PRODUCT_TEXT : Int := 20;   // Record Index
      INDEX_HARDWARE_REVISION : Int := 22;   // Record Index
      INDEX_FIRMWARE_REVISION : Int := 23;   // Record Index
      INDEX_APP_SPECIFIC_NAME : Int := 24;   // Record Index
      INDEX_FUNCTION_TAG : Int := 25;   // Record Index
      INDEX_LOCATION_TAG : Int := 26;   // Record Index
      INDEX_OPERATING_HOURS : Int := 74;   // Record Index
      INDEX_OPERATING_MODE : Int := 100;   // Record Index
      INDEX_LIGHT_EFFECT : Int := 101;   // Record Index - start of range
      SEGMENT_COUNT_MAX : Int := 15;   // maximum count of segments
      INDEX_SOUND_MODE : Int := 120;   // Record Index - start of range
      SOUND_COUNT_MAX : Int := 10;   // maximum count of sound types
      INDEX_POWER_REDUCTION : Int := 131;   // Record Index
      INDEX_FILL_LEVEL_MODE : Int := 132;   // Record Index
      INDEX_HEADLONG : Int := 138;   // Record Index
      INDEX_COUNT_OF_ELEMENTS : Int := 139;   // Record Index
      LENGTH_SYSTEM_COMMANDS : Int := 1;   // Record Length
      LENGTH_VENDOR_NAME : Int := 48;   // Record Length
      LENGTH_VENDOR_TEXT : Int := 48;   // Record Length
      LENGTH_PRODUCT_NAME : Int := 32;   // Record Length
      LENGTH_PRODUCT_ID : Int := 16;   // Record Length
      LENGTH_PRODUCT_TEXT : Int := 64;   // Record Length
      LENGTH_HARDWARE_REVISION : Int := 16;   // Record Length
      LENGTH_FIRMWARE_REVISION : Int := 16;   // Record Length
      LENGTH_APP_SPECIFIC_NAME : Int := 32;   // Record Length
      LENGTH_FUNCTION_TAG : Int := 32;   // Record Length
      LENGTH_LOCATION_TAG : Int := 32;   // Record Length
      LENGTH_OPERATING_HOURS : Int := 4;   // Record Length
      LENGTH_OPERATING_MODE : Int := 1;   // Record Length
      LENGTH_LIGHT_EFFECT : Int := 8;   // Record Length
      LENGTH_SOUND_MODE : Int := 16;   // Record Length
      LENGTH_POWER_REDUCTION : Int := 1;   // Record Length
      LENGTH_FILL_LEVEL_MODE : Int := 1;   // Record Length
      LENGTH_HEADLONG : Int := 1;   // Record Length
      LENGTH_COUNT_OF_ELEMENTS : Int := 1;   // Record Length
      EMPTY_CHAR : Char := '$00';   // Default empty char to fill empty field entries
      DEVICE_TIMEOUT : Time := T#20S;   // Timeout value for the IO-Link Device Instance
   END_VAR


	// REGION BLOCK INFO HEADER
	    //===============================================================================
	    // Siemens / (c)Copyright 2022
	    //-------------------------------------------------------------------------------
	    // Title:            LIOLink_8WD46
	    // Function:         Capsule block to communicate with 8WD46
	    // Library:          LIOLink
	    // Author:           Siemens Industry Online Support
	    // Tested with:      CPU 1513-1 PN FW 2.8
	    // Engineering:      TIA Portal V16
	    // Restrictions:     --
	    // Requirements:     --
	    //-------------------------------------------------------------------------------
	    // Change log table:
	    // Version  | Date       | Expert in charge       | Changes applied
	    //----------|------------|------------------------|------------------------------
	    // 01.00.00 | 06.10.2022 | SUP SPH                | First release
	    //===============================================================================
	// END_REGION
	
	// REGION INIT
	    IF (execute = TRUE AND instDevice.status = STATUS_IDLE) THEN
	        // REGION Inputs
	            //Save inputs
	            statHwID := hwID;
	            statCap := cap;
	            statReadWrite := readWrite;
	            statPort := port;
	            statPollingPeriod := pollingPeriod;
	            statSystemCommands := systemCommands;
	            statVendorName := vendorName;
	            statVendorText := vendorText;
	            statProductName := productName;
	            statProductID := productID;
	            statProductText := productText;
	            statHwRevision := hwRevision;
	            statFwRevision := fwRevision;
	            statAppSpecificName := appSpecificName;
	            statFunctionTag := functionTag;
	            statLocationTag := locationTag;
	            statOpHour := opHour;
	            statOperatingMode := operatingMode;
	            statLightEffect := lightEffect;
	            statSoundMode := soundMode;
	            statPowerReduction := powerReduction;
	            statFillLevelMode := fillLevelMode;
	            statHeadlong := headlong;
	            statElementCount := elementCount;
	        // END_REGION
	        
	        // REGION Request selector
	            //set Index and RecordLen based on the request
	            IF statSystemCommands THEN
	                statIndex := INDEX_SYSTEM_COMMANDS;
	                statRecordLen := LENGTH_SYSTEM_COMMANDS;
	            ELSIF statVendorName THEN
	                statIndex := INDEX_VENDOR_NAME;
	                statRecordLen := LENGTH_VENDOR_NAME;
	            ELSIF statVendorText THEN
	                statIndex := INDEX_VENDOR_TEXT;
	                statRecordLen := LENGTH_VENDOR_TEXT;
	            ELSIF statProductName THEN
	                statIndex := INDEX_PRODUCT_NAME;
	                statRecordLen := LENGTH_PRODUCT_NAME;
	            ELSIF statProductID THEN
	                statIndex := INDEX_PRODUCT_ID;
	                statRecordLen := LENGTH_PRODUCT_ID;
	            ELSIF statProductText THEN
	                statIndex := INDEX_PRODUCT_TEXT;
	                statRecordLen := LENGTH_PRODUCT_TEXT;
	            ELSIF statHwRevision THEN
	                statIndex := INDEX_HARDWARE_REVISION;
	                statRecordLen := LENGTH_HARDWARE_REVISION;
	            ELSIF statFwRevision THEN
	                statIndex := INDEX_FIRMWARE_REVISION;
	                statRecordLen := LENGTH_FIRMWARE_REVISION;
	            ELSIF statAppSpecificName THEN
	                statIndex := INDEX_APP_SPECIFIC_NAME;
	                statRecordLen := LENGTH_APP_SPECIFIC_NAME;
	            ELSIF statFunctionTag THEN
	                statIndex := INDEX_FUNCTION_TAG;
	                statRecordLen := LENGTH_FUNCTION_TAG;
	            ELSIF statLocationTag THEN
	                statIndex := INDEX_LOCATION_TAG;
	                statRecordLen := LENGTH_LOCATION_TAG;
	            ELSIF statOpHour THEN
	                statIndex := INDEX_OPERATING_HOURS;
	                statRecordLen := LENGTH_OPERATING_HOURS;
	            ELSIF statOperatingMode THEN
	                statIndex := INDEX_OPERATING_MODE;
	                statRecordLen := LENGTH_OPERATING_MODE;
	            ELSIF statLightEffect > 0 AND statLightEffect <= SEGMENT_COUNT_MAX THEN
	                statIndex := INDEX_LIGHT_EFFECT + statLightEffect - 1;
	                statRecordLen := LENGTH_LIGHT_EFFECT;
	            ELSIF statSoundMode > 0 AND statSoundMode <= SOUND_COUNT_MAX THEN
	                statIndex := INDEX_SOUND_MODE + statSoundMode - 1;
	                statRecordLen := LENGTH_SOUND_MODE;
	            ELSIF statPowerReduction THEN
	                statIndex := INDEX_POWER_REDUCTION;
	                statRecordLen := LENGTH_POWER_REDUCTION;
	            ELSIF statFillLevelMode THEN
	                statIndex := INDEX_FILL_LEVEL_MODE;
	                statRecordLen := LENGTH_FILL_LEVEL_MODE;
	            ELSIF statHeadlong THEN
	                statIndex := INDEX_HEADLONG;
	                statRecordLen := LENGTH_HEADLONG;
	            ELSIF statElementCount THEN
	                statIndex := INDEX_COUNT_OF_ELEMENTS;
	                statRecordLen := LENGTH_COUNT_OF_ELEMENTS;
	            ELSE
	                RETURN;
	            END_IF;
	        // END_REGION
	        
	        IF statReadWrite = MODE_WRITE THEN
	            //prepare statRecord in case of a writing request
	            // REGION write
	                IF statSystemCommands THEN
	                    statRecord[0] := data.systemCommand;
	                    
	                ELSIF statAppSpecificName THEN
	                    Strg_TO_Chars(Strg := data.appSpecificName,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statFunctionTag THEN
	                    Strg_TO_Chars(Strg := data.functionTag,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statLocationTag THEN
	                    Strg_TO_Chars(Strg := data.locationTag,
	                                  pChars := 0,
	                                  Cnt => tempLen,
	                                  Chars := statRecord);
	                    
	                    // Fill remaining characters with null
	                    FOR tempIndex := TO_INT(tempLen) TO statRecordLen - 1 DO
	                        statRecord[tempIndex] := TO_BYTE(EMPTY_CHAR);
	                    END_FOR;
	                    
	                ELSIF statOperatingMode THEN
	                    statRecord[0] := data.operatingMode;
	                    
	                ELSIF statLightEffect > 0 AND statLightEffect <= SEGMENT_COUNT_MAX THEN
	                    tempRetValSerialize := Serialize(SRC_VARIABLE := data.lightEffects[statLightEffect], DEST_ARRAY => tempFieldLightEffects, POS := tempPosSerialize);
	                    UMOVE_BLK(IN := tempFieldLightEffects[0],
	                              COUNT := TO_ULINT(statRecordLen),
	                              OUT => statRecord[0]);
	                    
	                ELSIF statSoundMode > 0 AND statSoundMode <= SOUND_COUNT_MAX THEN
	                    statRecord[0] := data.soundMode[statSoundMode].mode;
	                    statRecord[1] := data.soundMode[statSoundMode].frequency1Start.%B1;
	                    statRecord[2] := data.soundMode[statSoundMode].frequency1Start.%B0;
	                    statRecord[3] := data.soundMode[statSoundMode].frequency2Stop.%B1;
	                    statRecord[4] := data.soundMode[statSoundMode].frequency2Stop.%B0;
	                    statRecord[5] := data.soundMode[statSoundMode].frequency1Periode.%B1;
	                    statRecord[6] := data.soundMode[statSoundMode].frequency1Periode.%B0;
	                    statRecord[7] := data.soundMode[statSoundMode].volume;
	                    statRecord[8] := data.soundMode[statSoundMode].count.%B1;
	                    statRecord[9] := data.soundMode[statSoundMode].count.%B0;
	                    statRecord[10] := data.soundMode[statSoundMode].brakeToRepeat.%B1;
	                    statRecord[11] := data.soundMode[statSoundMode].brakeToRepeat.%B0;
	                    statRecord[12] := data.soundMode[statSoundMode].BrakeBetweenCycles.%B1;
	                    statRecord[13] := data.soundMode[statSoundMode].BrakeBetweenCycles.%B0;
	                    statRecord[14] := data.soundMode[statSoundMode].holdingPeriodeFrequency2.%B1;
	                    statRecord[15] := data.soundMode[statSoundMode].holdingPeriodeFrequency2.%B0;
	                    
	                ELSIF statPowerReduction THEN
	                    statRecord[0] := data.powerReduction;
	                    
	                ELSIF statFillLevelMode THEN
	                    statRecord[0] := data.fillLevelMode;
	                    
	                ELSIF statHeadlong THEN
	                    statRecord[0] := data.headlong;
	                    
	                ELSIF statElementCount THEN
	                    statRecord[0] := data.elementCount;
	                    
	                ELSE // All other data sets are read only  
	                    ;
	                END_IF;
	                tempInternalError := tempRetValSerialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	            // END_REGION
	        END_IF;
	    END_IF;
	// END_REGION
	
	// REGION CALL
	    //IOL-Call -> Request to read/write from an IO-Link-Device
	    instDevice(execute := execute,
	                hwID := statHwID,
	                cap := statCap,
	                readWrite := statReadWrite,
	                port := statPort,
	                pollingPeriod := statPollingPeriod,
	                index := statIndex,
	                subindex := statSubindex,
	                writeLen := statRecordLen,
	                timeout := DEVICE_TIMEOUT,
	                record := statRecord);
	// END_REGION
	
	// REGION READ
	    // Copy data if available and valid
	    IF instDevice.done = TRUE AND statDoneOld = FALSE AND statReadWrite = MODE_READ THEN
	        IF statVendorName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorName);
	            
	        ELSIF statVendorText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.vendorText);
	            
	        ELSIF statProductName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productName);
	            
	        ELSIF statProductID THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productId);
	            
	        ELSIF statProductText THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.productText);
	            
	        ELSIF statHwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.hwRevision);
	            
	        ELSIF statFwRevision THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.fwRevision);
	            
	        ELSIF statAppSpecificName THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.appSpecificName);
	            
	        ELSIF statFunctionTag THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.functionTag);
	            
	        ELSIF statLocationTag THEN
	            Chars_TO_Strg(Chars := statRecord,
	                          pChars := 0,
	                          Cnt := TO_UINT(statRecordLen),
	                          Strg => data.locationTag);
	            
	        ELSIF statOpHour THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldOpHour[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldOpHour, DEST_VARIABLE => data.opHour, POS := tempPosDeserialize);
	            
	        ELSIF statLightEffect > 0 AND statLightEffect <= SEGMENT_COUNT_MAX THEN
	            UMOVE_BLK(IN := statRecord[0],
	                      COUNT := TO_ULINT(statRecordLen),
	                      OUT => tempFieldLightEffects[0]);
	            tempRetValDeserialize := Deserialize(SRC_ARRAY := tempFieldLightEffects, DEST_VARIABLE => data.lightEffects[statLightEffect], POS := tempPosDeserialize);
	            
	        ELSIF statSoundMode > 0 AND statSoundMode <= SOUND_COUNT_MAX THEN
	            data.soundMode[statSoundMode].mode := statRecord[0];
	            data.soundMode[statSoundMode].frequency1Start.%B0 := statRecord[2];
	            data.soundMode[statSoundMode].frequency1Start.%B1 := statRecord[1];
	            data.soundMode[statSoundMode].frequency2Stop.%B0 := statRecord[4];
	            data.soundMode[statSoundMode].frequency2Stop.%B1 := statRecord[3];
	            data.soundMode[statSoundMode].frequency1Periode.%B0 := statRecord[6];
	            data.soundMode[statSoundMode].frequency1Periode.%B1 := statRecord[5];
	            data.soundMode[statSoundMode].volume := statRecord[7];
	            data.soundMode[statSoundMode].count.%B0 := statRecord[9];
	            data.soundMode[statSoundMode].count.%B1 := statRecord[8];
	            data.soundMode[statSoundMode].brakeToRepeat.%B0 := statRecord[11];
	            data.soundMode[statSoundMode].brakeToRepeat.%B1 := statRecord[10];
	            data.soundMode[statSoundMode].BrakeBetweenCycles.%B0 := statRecord[13];
	            data.soundMode[statSoundMode].BrakeBetweenCycles.%B1 := statRecord[12];
	            data.soundMode[statSoundMode].holdingPeriodeFrequency2.%B0 := statRecord[15];
	            data.soundMode[statSoundMode].holdingPeriodeFrequency2.%B1 := statRecord[14];
	            
	            
	        ELSIF statPowerReduction THEN
	            data.powerReduction := statRecord[0];
	            
	        ELSIF statFillLevelMode THEN
	            data.fillLevelMode := statRecord[0];
	            
	        ELSIF statHeadlong THEN
	            data.headlong := statRecord[0];
	            
	        ELSIF statElementCount THEN
	            data.elementCount := statRecord[0];
	        ELSE // Other data sets are not defined
	            ;
	        END_IF;
	        tempInternalError := tempRetValDeserialize <> TO_INT(STATUS_EXECUTION_FINISHED);
	    END_IF;
	    
	    statDoneOld := instDevice.done;
	// END_REGION
	
	// REGION OUTPUTS
	    IF tempInternalError THEN //Error occured
	        done := false;
	        busy := false;
	        error := true;
	        status := ERR_INCONSISTENT_DATA;
	    ELSE //Execute successful
	        done := instDevice.done;
	        busy := instDevice.busy;
	        error := instDevice.error;
	        status := instDevice.status;
	        diagnostics := instDevice.diagnostics;
	    END_IF;
	// END_REGION
END_FUNCTION_BLOCK

TYPE
  statRecordParamType : STRUCT   // Parameters to read/write specific records
         index : Array[0..HIGHEST_REQUEST_NUMBER] of Int := [0, INDEX_DIRECT_PARAM0, INDEX_DIRECT_PARAM1, 7(0), INDEX_VENDOR_NAME, INDEX_VENDOR_TEXT, INDEX_PRODUCT_NAME, INDEX_PRODUCT_ID, INDEX_PRODUCT_TEXT, INDEX_SERIAL_NUMBER, INDEX_HARDWARE_REVISION, INDEX_FIRMWARE_REVISION, INDEX_APP_SPECIFIC_NAME, 4(0), INDEX_DIAGNOSTICS, 2(0), INDEX_ACTUAL_CONFIG, INDEX_TARGET_CONFIG, 0];   // Index of data set
         subindex : Array[0..HIGHEST_REQUEST_NUMBER] of Int;   // Subindex of data sets
         length : Array[0..HIGHEST_REQUEST_NUMBER] of Int := [0, LENGTH_DIRECT_PARAM0, LENGTH_DIRECT_PARAM1, 7(0), LENGTH_VENDOR_NAME, LENGTH_VENDOR_TEXT, LENGTH_PRODUCT_NAME, LENGTH_PRODUCT_ID, LENGTH_PRODUCT_TEXT, LENGTH_SERIAL_NUMBER, LENGTH_HARDWARE_REVISION, LENGTH_FIRMWARE_REVISION, LENGTH_APP_SPECIFIC_NAME, 4(0), LENGTH_DIAGNOSTICS, 2(0), LENGTH_ACTUAL_TARGET_CONFIG, LENGTH_WRITE_TARGET_CONFIG, 0];   // Length of data set
      END_STRUCT;
END_TYPE

END_NAMESPACE
