NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3RB24_typeDiag : STRUCT
  /// LIOLink_3RB24_typeDiag
//Data set (index) 94 (measured values) - solid-state overload relay for IO‑Link
      ready : Bool;   // Ready
      directionClockwise : Bool;   // Motor direction of rotation 1 (clockwise)
      directionCounterClockwise : Bool;   // Motor direction of rotation 2 (counter-clockwise)
      reserved : Bool;   // Reserved
      switchingElementDefect : Bool;   // Switching element defective
      reserved1 : Bool;   // Reserved
      groupError : Bool;   // GroupError
      generalWarning : Bool;   // General warning
      reserved2 : Byte;   // Reserved
      thermistorOverload : Bool;   // Thermistor overload
      thermistorWireBreak : Bool;   // Thermistor wire break
      thermistorShortCircuit : Bool;   // Thermistor short-circuit
      thermistorMotorOverload : Bool;   // Thermal motor model overload
      overloadTripping : Bool;   // Overload tripping
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Byte;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      reserved11 : Bool;   // Reserved
      resCurrenctDetected : Bool;   // Residual current detected
      resCurrentTripping : Bool;   // Residual current tripping
      reserved12 : Bool;   // Reserved
      reserved13 : Byte;   // Reserved
      groudFaultDetected : Bool;   // Ground fault detected
      GroundFaultTripping : Bool;   // Ground fault tripping
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      reserved16 : Bool;   // Reserved
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      supplyVoltageLow : Bool;   // Electronics supply voltage too low
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      autoMode1 : Bool;   // Automatic mode
      autoMode2 : Bool;   // Automatic mode
      manualModeOP1 : Bool;   // Manual mode (operator panel)
      manualModeOP2 : Bool;   // Manual mode (operator panel)
      manualModeConAbort : Bool;   // Manual mode connection abort (operator panel)
      processImageError : Bool;   // Process image error
      reserved21 : Byte;   // Reserved
      selfTestActive1 : Bool;   // Self-test active
      selfTestActive2 : Bool;   // Self-test active
      selfTestError : Bool;   // Self-test error
      reserved22 : Bool;   // Reserved
      reserved23 : Bool;   // Reserved
      reserved24 : Bool;   // Reserved
      reserved25 : Bool;   // Reserved
      reserved26 : Bool;   // Reserved
      reserved27 : Word;   // Reserved
      reserved28 : Bool;   // Reserved
      reserved29 : Bool;   // Reserved
      impermissibleSetting : Bool;   // Impermissible Ie/CLASS setting
      presetActualCompare : Bool;   // Preset <> actual configuration
      thermistorProtectionDeactivated : Bool;   // Thermistor protection deactivated
      reserved30 : Bool;   // Reserved
      reserved31 : Bool;   // Reserved
      reserved32 : Bool;   // Reserved
      reserved33 : Byte;   // Reserved
      coldStartActive : Bool;   // Cold start active
      coldStartTripping : Bool;   // Cold start tripping
      reserved34 : Bool;   // Reserved
      reserved35 : Bool;   // Reserved
      reserved36 : Bool;   // Reserved
      reserved37 : Bool;   // Reserved
      reserved38 : Bool;   // Reserved
      reserved39 : Bool;   // Reserved
      reserved40 : Byte;   // Reserved
      reserved41 : Array[16..23] of Byte;   // Reserved
      reserved42 : Bool;   // Reserved
      reserved43 : Bool;   // Reserved
      reserved44 : Bool;   // Reserved
      motorHeatingExceeded : Bool;   // Prewarning limit: Motor heating exceeded
      reserved45 : Bool;   // Reserved
      reserved46 : Bool;   // Reserved
      reserved47 : Bool;   // Reserved
      reserved48 : Bool;   // Reserved
      reserved49 : Byte;   // Reserved - Extension to get even field
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RB24_typeMeasure : STRUCT
  /// LIOLink_3RB24_typeMeasure
//Data set (index) 94 (measured values) - solid-state overload relay for IO‑Link
      phaseCurrentL1Rel : Byte;   // Phase current I (L1 rms in 3,125% steps) - A-4 Dataset Index 94 Page 112
      phaseCurrentL2Rel : Byte;   // Phase current I (L2 rms in 3,125 % steps)
      phaseCurrentL3Rel : Byte;   // Phase current I (L3 rms in 3,125 % steps)
      reserved : Byte;   // Reserved
      reserved1 : Array[4..27] of Byte;   // Reserved
      phaseCurrentL1Abs : DWord;   // Phase current I (L1 rms in 0,01-A steps)
      phaseCurrentL2Abs : DWord;   // Phase current I (L2 rms in 0,01-A steps)
      phaseCurrentL3Abs : DWord;   // Phase current I (L3 rms in 0,01-A steps)
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RB24_typeTechFunctions : STRUCT
  /// TechnologyFunctions_3RB24
//Data set (index) 131 (technology functions) - solid-state overload relay for IO‑Link
      reserved : Array[0..7] of Byte;   // Reserved
      groundFaultDetection : Byte;   // Ground fault detection - 16#00: Disable; 16#20: Enable - Bit 5 in Byte
      reserved8 : Word;   // Reserved
      coldStart : Byte;   // Cold Start -  16#00: Disable; 16#08: Enable - Bit 3 in Byte
      ratedOpCurrent : DWord;   // Rated operational current (in 0.01 A steps)
      reserved16 : Word;   // Reserved
      responseToOverloadMotor : Byte;   // Response to overload - thermal motor model - 16#00: Tripping without restart (MAN); 16#01: Tripping with restart (AUTO)
      tripClass : Byte;   // Trip class - 16#03: CLASS 5; 16#00: CLASS 10; 16#01: CLASS 20; 16#02: CLASS 30
      reserved17 : DWord;   // Reserved
      responseToOverloadThermistor : Bool;   // Response to overload - Thermistor - false: Tripping without restart (MAN); true: Tripping with restart (AUTO)
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      reserved21 : Bool;   // Reserved
      reserved22 : Bool;   // Reserved
      reserved23 : Bool;   // Reserved
      monitorThermistor : Bool;   // Thermistor - monitoring - false: No; true: Yes
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RB24_typePresetConfig : STRUCT
  /// TargetConfiguration_3RB24
//Data set (index) 130 (target configuration) - operator panel
      reserverd : Array[0..17] of Byte;   // Reserved
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      operationAtTarget : Bool;   // Operation at Preset <> Actual Configuration
      operationPanelAvailable : Bool;   // Operator panel available
      reserved7 : Byte;   // Reserved
      reserved8 : Byte;   // Reserved
      reserved9 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RB24_typeAll : STRUCT
  /// LIOLink_3RB24_typeAll
//Contains all the information about 3RB24
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      vendorName : String[10];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[30];   // ID18: Product name
      productID : String[12];   // ID19: Product ID
      productText : String[2];   // ID20: Product text
      serialNumber : String[8];   // ID21: Serial number
      hwRevision : String[4];   // ID22: Hardware revision
      fwRevision : String[4];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      processInput : Word;   // ID40: Process data input
      processOutput : Byte;   // ID41: Process data output
      diagnostics : LIOLink_3RB24_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3RB24_typeMeasure;   // ID94: Measurement values
      presetConfig : LIOLink_3RB24_typePresetConfig;   // ID130: Preset configuration
      techFunctions : LIOLink_3RB24_typeTechFunctions;   // ID131: Technology functions
   END_STRUCT;

END_TYPE


END_NAMESPACE
