NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3UG481_typeDiag : STRUCT
  /// LIOLink_3UG481_typeDiag
//Data set (index) 92 - diagnostics
      reserved : Array[0..15] of Byte;   // Reserved
      ready : Bool;   // Read
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
      delayTimeRunning : Bool;   // Stabilization delay running
      delayLevelUp : Bool;   // Tripping delay time running (threshold for overshoot)
      delayLevelDown : Bool;   // Tripping delay time running (threshold for undershoot)
      delayAsymmetry : Bool;   // Tripping delay time running (threshold for voltage asymmetry)
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      levelUp : Bool;   // Threshold for overshoot exceeded
      levelDown : Bool;   // Threshold for undershoot violated
      voltageAsymmetry : Bool;   // Threshold for voltage asymmetry exceeded
      warningLevelUp : Bool;   // Warning threshold for overshoot exceeded
      warningLevelDown : Bool;   // Warning threshold for undershoot violated
      warningVoltageAsymmetry : Bool;   // Warning threshold for voltage asymmetry exceeded
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      reserved11 : Bool;   // Reserved
      phaseFailureL1 : Bool;   // Phase failure L1
      phaseFailureL2 : Bool;   // Phase failure L2
      phaseFailureL3 : Bool;   // Phase failure L3
      phaseFailureN : Bool;   // Phase failure N conductor
      phaseSeqL1L2L3 : Bool;   // Phase sequence L1-L2-L3
      phaseSeqL3L2L1 : Bool;   // Phase sequence L3-L2-L1
      phaseSeqError : Bool;   // Phase sequence error
      reserved12 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG481_typeMeasure : STRUCT
  /// LIOLink_3UG481_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserved
      voltageL1L2 : Word;   // (only 3UG4815) Voltage U L1-L2 Min:160V Max:690V
      voltageL2L3 : Word;   // (only 3UG4815) Voltage U L2-L3 Min:160V Max:690V
      voltageLxL1 : Word;   // (only 3UG4815) Voltage U L3-L1 Min:160V Max:690V
      voltageLxLyMin : Word;   // (only 3UG4815) Voltage U Lx-Ly min Min:160V Max:690V
      voltageLxLyMax : Word;   // (only 3UG4815) Voltage U Lx-Ly max Min:160V Max:690V
      voltageL1N : Word;   // (only 3UG4816) Voltage U L1-N Min:90V Max:400V
      voltageL2N : Word;   // (only 3UG4816) Voltage U L2-N Min:90V Max:400V
      voltageL3N : Word;   // (only 3UG4816) Voltage U L3-N Min:90V Max:400V
      voltageLxNmin : Word;   // (only 3UG4816) Voltage U Lx-N min Min:90V Max:400V
      voltageLxNmax : Word;   // (only 3UG4816) Voltage U Lx-N max Min:90V Max:400V
      asymmetry : Word;   // Asymmetry Min:0% Max:20%
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG481_typeParam : STRUCT
  /// LIOLink_3UG481_typeParam
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
      analogValueCoding : Byte := BYTE#16#30;   // Analog value coding: Default: 48, Min: 0(disabled), Max: 255
      reserved3 : Array[18..23] of Byte;   // Reserved
      resetResponse : Byte := BYTE#16#01;   // Reset response: Default: 16#01, 16#00: manual, 16#01: automatic
      delayOn : Bool := TRUE;   // Stabilzation delay (at Power ON): Default: true, false: disabled, true: enabled
      delayOn0 : Bool;   // False
      delayReset : Bool := TRUE;   // Stabilzation delay (at manual reset): Default: true, false: disabled, true: enabled
      delayReset0 : Bool;   // False
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      phaseSequence : Byte := BYTE#16#04;   // Phase sequence monitoring: Default: 16#04, 16#00: disabled, 16#04: enabled - Bit 2 in Byte
      reserved14 : Byte;   // Reserved
      delayTimeStabilization : Int;   // Stabilization delay: Resolution: 0.1s=1, Default: 0, Min: 0.1s or 0s (disabled), Max: 999.9s
      delayTimeTripUp : Int;   // Stabilization delay(voltg ovrshoot): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s, Max: 999.9s
      delayTimeTripDown : Int;   // Stabilization delay(voltg undrshoot): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s, Max: 999.9s
      delayTimeTripAsymmetry : Int;   // Stabilization delay(asymmetry): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s, Max: 999.9s
      tresholdUp : Int;   // Threshold for overshoot: Resolution: 0.1V=1, Default:425/245V,Min: 160/90V or 0V, Max: 690/400V
      tresholdDown : Int;   // Threshold for undershoot: Resolution: 0.1V=1, Default: 375/215V, Min: 160/90V or 0V ,Max: 690/400V
      tresholdAsymmetry : Int := 50;   // Threshold for asymmetry: Resolution: 0.1%=1, Default: 5%, Min: 0.1% or 0% , Max: 20%
      warningTresholdUp : Int;   // Warng threshold for overshoot: Resolution: 0.1V=1, Default: 425/245V, Min: 160/90V or .0V, Max: 690/400V
      warningTresholdDown : Int;   // Warng threshold for undershoot:Resolution: 0.1V=1, Default: 375/215V, Min: 160/90V or0V ,Max: 690/400V
      warningTresholdAsymmetry : Int := 50;   // Warning threshold for asymmetry: Resolution: 0.1%=1, Default: 5%, Min: 0.1% or 0% , Max: 20%
      reserved15 : Array[48..53] of Byte;   // Reserved
      hysteresis : Int;   // Hysteresis: Resolution: 0.1V=1, Default: 5V, Min: 0.1V or 0V (disabled), Max: 20V
      hysteresisAsymmetry : Int;   // Hysteresis (asymmetry): Resolution: 0.1%=1, Default: 2%, Min: 0.1%  or 0%, Max=5%
      responseRelay : Byte;   // Relay switching response:Default: 16#00, 16#00: Closed-circuit (NC), 16#01: Open-circuit(NO)
      reserved16 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3UG481_typeAll : STRUCT
  /// LIOLink_3UG481_typeAll
//Contains all the information about 3UG481
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommands : Byte;   // ID2: System Commands (0x80 for device reset, 0x82 for factory reset)
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      hwRevision : String[7];   // ID22: Hardware revision
      fwRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3UG481_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3UG481_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3UG481_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
