NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3UG4851_typeDiag : STRUCT
  /// LIOLink_3UG4851_typeDiag
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
      rangeOvershoot : Bool;   // Sensor - Measuring range overshoot
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      reserved16 : Bool;   // Reserved
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      reserved21 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4851_typeMeasure : STRUCT
  /// LIOLink_3UG4851_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserved
      speed : Word;   // Speed Min:0 Max:2200
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4851_typeParam : STRUCT
  /// LIOLink_3UG4851_typeParam
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
      analogValueCoding : Byte := BYTE#16#0D;   // Analog value coding: Default: 13, Min: 0(disabled), Max: 255
      reserved3 : Array[18..23] of Byte;   // Reserved
      resetResponse : Byte := BYTE#16#01;   // Reset response: Default: 16#01, 16#00: manual, 16#01: automatic
      delayOn : Bool := TRUE;   // ON-delay time (at Power ON): Default: true, false: disabled, true: enabled
      delayOn0 : Bool;   // False
      delayReset : Bool := TRUE;   // ON-delay time (at manual reset): Default: true, false: disabled, true: enabled
      delayReset0 : Bool;   // False
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      delayTime : Int;   // ON-delay time: Resolution: 0.1=1s, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999.9s
      delayTimeTripUp : Int;   // Tripping delay time (in the case of speed overshoot): Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s, Max: 999.9s
      delayTimeTripDown : Int;   // Tripping delay time (in the case of speed undershoot): Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s, Max: 999.9s
      tresholdUp : Int := 1400;   // Threshold for speed overshoot: Default: 1400rpm, Min: 0.1rpm or 0rpm (disabled), Max: 2200rpm
      tresholdDown : Int := 800;   // Threshold for speed undershoot: Default: 800rpm, Min: 0.1rpm or 0rpm (disabled), Max: 2200rpm
      warningTresholdUp : Int := 1400;   // Warning threshold for speed overshoot: Default: 1400rpm, Min: 0.1rpm or 0rpm (disabled), Max: 2200rpm
      warningTresholdDown : Int := 800;   // Warning threshold for speed undershoot: Default: 800rpm, Min: 0.1rpm or 0rpm (disabled), Max: 2200rpm
      reserved8 : Array[40..43] of Byte;   // Reserved
      hysteresis : Int := 50;   // Hysteresis: Resolution: 0.1=1, Default: 5, Min: 0.1 or 0 (disabled), Max: 99.9
      responseRelay : Byte;   // Relay switching response: Default: 16#00, 16#00: Closed-circuit principle NC, 16#01: Open-circuit principle NO
      reserved9 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG4851_typeAll : STRUCT
  /// LIOLink_3UG4851_typeAll
//Contains all the information about 3UG4851
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommands : Byte;   // ID2: System Commands (0x80 for device reset, 0x82 for factory reset)
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      hwRevision : String[7];   // ID22: Hardware revision
      fwRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3UG4851_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3UG4851_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3UG4851_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
