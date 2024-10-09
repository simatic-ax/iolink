NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3UG4825_typeDiag : STRUCT
  /// LIOLink_3UG4825_typeDiag
//Data set (index) 92 - diagnostics
      reserved : Array[0..15] of Byte;   // Reserved
      ready : Bool;   // Ready
      groupError : Bool;   // Group error
      groupWarning : Bool;   // Group warning
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      parameterAssign : Bool;   // Parameter assignment active
      parameterInvalid : Bool;   // Invalid parameter
      internalError : Bool;   // Self-test error/internal error
      reserved3 : Byte;   // Reserved
      errorNumber : Word;   // Parameter error number
      reserved4 : Array[20..25] of Byte;   // Reserved
      delayTimeRunning : Bool;   // ON-delay time running
      delayLevelUp : Bool;   // Tripping delay time running (threshold for overshoot)
      reserved5 : Bool;   // Reserved
      initTimeRunning : Bool;   // Initialization time running after applying the control supply voltage
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      levelUp : Bool;   // Threshold for overshoot exceeded
      reserved10 : Bool;   // Reserved
      warningLevelUp : Bool;   // Warning threshold for overshoot exceeded
      reserved11 : Bool;   // Reserved
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      wireBreak : Bool;   // Wire break
      shortCircuit : Bool;   // Short-circuit
      rangeOvershoot : Bool;   // Measuring range overshoot
      reserved16 : Bool;   // Reserved
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      reserved21 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4825_typeMeasure : STRUCT
  /// LIOLink_3UG4825_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserved
      residualCurrentIrPa : Word;   // Residual current Ir (PA), Min: 0,0 A, Max: 43,0 A
      residualCurrentIr : DWord;   // Residual current Ir, Min: 0,0 A, Max: 43,0 A
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4825_typeParam : STRUCT
  /// LIOLink_3UG4825_typeParam
//Data set (index) 131 (parameters)
      reserved : Array[0..15] of Byte;   // Reserved
      groupDiagnostics : Bool := TRUE;   // Group diagnostics: Default: true, false; disabled, true: enabled
      groupErrorDiagnostics : Bool := TRUE;   // Group error diagnostics: Default: true, false; disabled, true: enabled
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      localLimitChange : Bool := TRUE;   // Local threshold change: Default: true, false; disabled, true: enabled
      localParameterChange : Bool := TRUE;   // Local parameter change: Default: true, false; disabled, true: enabled
      localReset : Bool := TRUE;   // Local reset: Default: true, false; disabled, true: enabled
      retentiveErrorMemory : Bool;   // Retentive error memory: Default: false, false; disabled, true: enabled
      analogValueCoding : Byte := BYTE#16#0E;   // Analog value coding: Default: 14, Min: 0(disabled), Max: 255
      reserved3 : Array[18..23] of Byte;   // Reserved
      resetResponse : Byte := BYTE#16#01;   // Reset response: Default: 16#01, 16#00: manual, 16#01: automatic
      delayOn : Bool := TRUE;   // ON-delay time (at Power ON): Default: true, false: disabled, true: enabled
      delayOn0 : Bool;   // False
      delayReset : Bool := TRUE;   // ON-delay time (at manual reset): Default: true, false: disabled, true: enabled
      delayReset0 : Bool;   // False
      delayRestart : Bool;   // ON-delay time (at restart): Default: true, false: disabled, true: enabled
      delayRestart0 : Bool;   // False
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      delayTime : Int;   // ON-delay time: Resolution: 0.1=1s, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999.9s
      delayTimeTripUp : Int;   // Tripping delay time (in the case of current overshoot): Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s, Max: 999.9s
      reserved6 : Word;   // Reserved
      tresholdUp : Int := 100;   // Threshold for overshoot: Resolution: 0.01A=1, Default: 1A, Min: 0.03A, Max: 40A
      reserved9 : Word;   // Reserved
      warningTresholdUp : Int := 50;   // Warning threshold for overshoot: Resolution: 0.01A=1, Default: 0,5A, Min: 0.03A or 0A (disabled), Max: 40A
      reserved7 : Array[38..43] of Byte;   // Reserved
      hysteresis : Int := 5;   // Hysteresis: Resolution: Resolution: 1%=1, Default: 5%, Min: 5% or 0% (disabled), Max: 50%
      reserved10 : Byte;   // Reserved
      responseRelay : Byte;   // Relay switching response: Default: 16#00, 16#00: Closed-circuit principle NC, 16#01: Open-circuit principle NO
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4825_typeAll : STRUCT
  /// LIOLink_3UG4825_typeAll
//Contains all the information about 3UG4825
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommands : Byte;   // ID2: System Commands (0x80 for device reset, 0x82 for factory reset)
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      serialNumber : String[16];   // ID21: Serial number
      hwRevision : String[7];   // ID22: Hardware revision
      fwRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3UG4825_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3UG4825_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3UG4825_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
