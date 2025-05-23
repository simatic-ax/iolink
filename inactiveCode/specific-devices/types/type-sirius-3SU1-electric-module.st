NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3SU1_ElecModule_typeDiag92 : STRUCT
  /// LIOLink_3SU1_ElecModule_typeDiag92
//Diagnostics - data set (index) 92
      reserved : Array[0..15] of Byte;   // Reserved
      status : Byte;   // Status: 1 = Ready; 2 = Error
      switchOnDuraStatIO0_3 : Byte;   // Switch-on duration status: 0x00=Inactive; 0x01=running; 0x02=reached; 0x03=finished
      switchOnDuraStatIO4_7 : Byte;   // Switch-on duration status: 0x00=Inactive; 0x01=running; 0x02=reached; 0x03=finished
      dimStatusOutputQ0_3 : Byte;   // Dimming status: 0x00=Inactive; 0x01=running;  0x03=finished
      dimStatusOutputQ4_7 : Byte;   // Dimming status: 0x00=Inactive; 0x01=running;  0x03=finished
      switchCycleCntStatIO0_3 : Byte;   // Switching cycle counter status: 0x00=Inactive; 0x01=running; 0x02=reached; 0x03=finished
      switchCycleCntStatIO4_7 : Byte;   // Switching cycle counter status: 0x00=Inactive; 0x01=running; 0x02=reached; 0x03=finished
      reserved1 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_ElecModule_typeDiag94 : STRUCT
  /// LIOLink_3SU1_ElecModule_typeDiag94
//Diagnostics - data set (index) 94
      reserved : Array[0..15] of Byte;   // Reserved
      switchOnDurationsIO : Array[0..7] of DWord;   // Switch-on duration in seconds
      switchCycCountersIO : Array[0..7] of DWord;   // Switching cycle counter
      inputValue : Byte;   // Input value
      outputValue : Byte;   // Output value
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_ElecModule_typeParam : STRUCT
  /// LIOLink_3SU1_ElecModule_typeParam
//Parameters - Data set (index) 131
      reserved : Array[0..15] of Byte;   // Reserved
      functionModeIO : Array[0..7] of Byte;   // 0x01=Input; 0x02=Output; 0x03=PWM; 0x04=Dimming Output; 0x05=InputCounter; 0x06=OutputCounter; 0x07=TurnonTimeInput; 0x08=TurnonTimeOutput
      setupGroup : Byte;   // 0x00=individual; 0x01=all; 0x02=grouped // .x3:1 = enable data reset
      pwmFreqQ : Array[0..7] of Byte;   // Range: 1..255; 1 = 1Hz
      pwmDutyQ : Array[0..7] of Byte;   // Range: 10 - 90 %; 1 = 1%
      dimmingTimeQ : Array[0..7] of Byte;   // Range: 1 - 255; 1 = 0.1Hz
      inputDelay : Array[0..7] of Byte;   // Range: 3-255; 1 = 1ms
      inputTimeThreshold : Array[0..7] of DWord;   // Set threshold for tripping due to a value overshoot: 1 = 1s
      inputCounterThreshold : Array[0..7] of DWord;   // Set threshold for tripping due to a value overshoot
      inputCounterEdgeI0_3 : Byte;   // 0x00=no edge; 0x01=rising edge; 0x02=falling edge; 0x03=all edges
      inputCounterEdgeI4_7 : Byte;   // 0x00=no edge; 0x01=rising edge; 0x02=falling edge; 0x03=all edges
      inputInvertI0_7 : Byte;   // 0=not inverted; 1=inverted
      outputInvertQ0_7 : Byte;   // 0=not inverted; 1=inverted
      reserved1 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_ElecModule_typeAll : STRUCT
  /// LIOLink_3SU1_ElecModule_typeAll
//Contains all the information about 3SU1 ElecModule
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommand : Byte;   // Write System Command to Device: 0xA1 - 0xB1; 0x82 = Default
      vendorName : String[10];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[18];   // ID19: Product ID
      fwRevision : String[6];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      processDataOut : Array[0..5] of Byte;   // ID67: Process Data of outputs
      processDataIn : Array[0..5] of Byte;   // ID69: Process Data of inputs
      diagnostics : LIOLink_3SU1_ElecModule_typeDiag92;   // ID92: Diagnostics
      statistics : LIOLink_3SU1_ElecModule_typeDiag94;   // ID94: Statistics
      parameters : LIOLink_3SU1_ElecModule_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
