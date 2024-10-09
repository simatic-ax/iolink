NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3UG4822_typeDiag : STRUCT
  /// LIOLink_3UG4822_typeDiag
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
      errorNumber : Word;   // Parameter eroor number
      reserved4 : Array[20..25] of Byte;   // Reserve
      delayTimeRunning : Bool;   // ON-delay time running
      delayLevelUp : Bool;   // Tripping delay time running (threshold for overshoot)
      delayLevelDown : Bool;   // Tripping delay time running (threshold for undershoot)
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      levelUp : Bool;   // Threshold for overshoot exceeded
      levelDown : Bool;   // Threshold for undershoot violated
      warningLevelUp : Bool;   // Warning threshold for overshoot exceeded
      warningLevelDown : Bool;   // Warning threshold for undershoot violated
      reserved10 : Bool;   // Reserved
      reserved11 : Bool;   // Reserved
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4822_typeMeasure : STRUCT
  /// LIOLink_3UG4822_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserved
      currentI1Pa : Word;   // Current I1 (PA) Min:0,05A Max:10A (if trnsfrmr trnsmissn factor is deactivated)
      reserved1 : Array[18..27] of Byte;   // Reserved
      currentI1 : DWord;   // Current I1 Min:0,05A Max:10A (when transformr transmissn factor is deactivated)
      reserved2 : Array[32..51] of Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4822_typeParam : STRUCT
  /// LIOLink_3UG4822_typeParam
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
      analogValueCoding : Byte := BYTE#16#10;   // Analog value coding: Default: 16, Min: 0(disabled), Max: 255
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
      delayTime : Int := 0;   // ON-delay time: Resolution: 0.1=1s, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999.9s
      delayTimeTripUp : Int;   // Tripping delay time (in the case of current overshoot): Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s, Max: 999.9s
      delayTimeTripDown : Int;   // Tripping delay time (in the case of current undershoot): Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s, Max: 999.9s
      tresholdUp : DInt := 250;   // Threshold for overshoot: Resolution: 0.01A=1, Default: 2.5A, Min: 0.05A or 0A (disabled), Max: 10A
      tresholdDown : DInt := 150;   // Threshold for undershoot: Resolution: 0.01A=1, Default: 1.5A, Min: 0.05A or 0A (disabled), Max: 10A
      warningTresholdUp : DInt := 250;   // Warning threshold for overshoot: Resolution: 0.01A=1, Default: 2.5A, Min: 0.05A or 0A (disabled), Max: 10A
      warningTresholdDown : DInt := 150;   // Warning threshold for undershoot: Resolution: 0.01A=1, Default: 1.5A, Min: 0.05A or 0A (disabled), Max: 10A
      reserved7 : Array[48..55] of Byte;   // Reserved
      hysteresis : DInt := 50;   // Hysteresis: Resolution: Resolution: 0.01A=1, Default: 0,05A, Min: 0.01A or 0A (disabled), Max: 5A
      factorTransformer : Int;   // Transformer transmission factor: , Default: 0, Min: 0 or 2, Max: 750
      responseRelay : Byte;   // Relay switching response:Default: 16#00, 16#00: Closed-circuit principle NC, I > 50 mA, 16#01: Open-circuit principle NO, I > 50 mA, 16#10: Closed-circuit principle NC, Us = on, 16#11: Open-circuit principle NO, Us = on
      reserved8 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4822_typeAll : STRUCT
  /// LIOLink_3UG4822_typeAll
//Contains all the information about 3UG4822
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommands : Byte;   // ID2: System Commands (0x80 for device reset, 0x82 for factory reset)
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      hwRevision : String[7];   // ID22: Hardware revision
      fwRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3UG4822_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3UG4822_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3UG4822_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
