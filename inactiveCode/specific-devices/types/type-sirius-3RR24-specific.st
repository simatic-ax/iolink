NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3RR24_typeDiag : STRUCT
  /// LIOLink_3RR24_typeDiag
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
      delayAsymmetry : Bool;   // Tripping delay time running (threshold for current asymmetry)
      delayReclosing : Bool;   // Reclosing delay time is running
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      levelUp : Bool;   // Threshold for overshoot exceeded
      levelDown : Bool;   // Threshold for underhsoot violated
      currentAsymmetry : Bool;   // Threshold for current asymmetry exceeded
      warningLevelUp : Bool;   // Warning threshold for overshoot exceeded
      warningLevelDown : Bool;   // Warning threshold for undershoot violated
      warningCurrentAsymmetry : Bool;   // Warning threshold for current asymmetry exceedd
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      phaseFailureL1 : Bool;   // Phase failure L1
      phaseFailureL2 : Bool;   // Phase failure L2
      phaseFailureL3 : Bool;   // Phase failure L3
      overcurrentL1 : Bool;   // Overcurrent n x Imax L1
      overcurrentL2 : Bool;   // Overcurrent n x Imax L2
      overcurrentL3 : Bool;   // Overcurrent n x Imax L3
      reserved11 : Bool;   // Reserved
      faultCurrentExceeded : Bool;   // Threshold for fault current exceeded
      phaseSeqL1L2L3 : Bool;   // Phase sequence L1-L2-L3
      phaseSeqL3L2L1 : Bool;   // Phase sequence L3-L2-L1
      phaseSeqError : Bool;   // Phase sequence error
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RR24_typeMeasure : STRUCT
  /// LIOLink_3RR24_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserve 0 - E-8 Dataset Index 94 Page 208
      activeCurrentL1 : Word;   // Active current L1
      activeCurrentL2 : Word;   // Active current L2
      activeCurrentL3 : Word;   // Active current L3
      activeCurrentMin : Word;   // Active current min
      activeCurrentMax : Word;   // Active current max
      activeCurrentAvg : Word;   // Active current avg
      apparentCurrentL1 : Word;   // Apparent current L1
      apparentCurrentL2 : Word;   // Apparent current L2
      apparentCurrentL3 : Word;   // Apparent current L3
      apparentCurrentMin : Word;   // Apparent current min
      apparentCurrentMax : Word;   // Apparent current max
      apparentCurrentAvg : Word;   // Apparent current avg
      activeVoltage : Word;   // Active voltage
      cosinePhi : Word;   // Cos phi value
      asymmetrySiemens : Word;   // Asymmetry Siemens
      asymmetryIecNema : Word;   // Asymmetry IEC/NEMA
      switchCounter : DWord;   // Switching cycle counter
      runtimeMeter : DWord;   // Runtime meter
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RR24_typeParam : STRUCT
  /// LIOLink_3RR24_typeParam
//Data set (index) 131 (parameters)
      reserved : Array[0..15] of Byte;   // Reserved
      groupDiagnostics : Bool := TRUE;   // Group diagnostics: Default: true, false; disabled, true: enabled
      groupErrorDiagnostics : Bool := TRUE;   // Group error diagnostics: Default: true, false; disabled, true: enabled
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      localLimitChange : Bool := TRUE;   // Local threshold change: Default: true, false; disabled, true: enabled
      localParameterChange : Bool := TRUE;   // Local parameter change: Default: true, false; disabled, true: enabled
      localReset : Bool := TRUE;   // Local reset: Default: true, false; disabled, true: enabled
      retentiveErrorMemory : Bool;   // Retentitve error memory: Default: false, false; disabled, true: enabled
      analogValueCoding : Byte := BYTE#16#14;   // Analog value coding: Default: 20, Min: 0 (disabled), Max: 255
      reserved3 : Array[18..23] of Byte;   // Reserved
      resetResponse : Byte := BYTE#16#01;   // Reset response: Default: true, false: manual, true: automatic
      delayTimePowerOn : Bool := TRUE;   // ON-delay time (at Power ON): Default: true, false: disabled, true: enabled
      delayTimePowerOn0 : Bool;   // False
      delayTimeManResetOn : Bool := TRUE;   // ON-delay time (at manual reset): Default: true, false; disabled, true: enabled
      delayTimeManResetOn0 : Bool;   // False
      delayTimeRestartOn : Bool := TRUE;   // ON-delay time (at restart): Default: true, false; disabled, true: enabled
      delayTimeRestartOn0 : Bool;   // False
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      phaseFault : Bool := TRUE;   // Phase failure monitoring: Default: true, false; disabled, true: enabled
      phaseFault0 : Bool;   // False
      phaseSequence : Bool := FALSE;   // Phase sequence monitoring: Default: false, false; disabled, true: enabled
      phaseSequence0 : Bool;   // False
      loadCurrent : Bool := FALSE;   // Load current monitoring(apparent current Is/active current Ip): Default: false, false: Is, true: Ip
      loadCurrent0 : Bool;   // False
      faultcurrent : Bool := FALSE;   // Fault current monitoring: Default: false, false; disabled, true: enabled
      faultcurrent0 : Bool;   // False
      asymmetry : Byte := BYTE#16#00;   // Asymmetry algorithm: Default: 0, 0: Siemens 1:IEC/NEMA
      delayTimeOn : Word := WORD#16#0000;   // ON-delay time: Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999,9s
      delayTimeTripUp : Word := WORD#16#0000;   // Tripping delay time(current overshoot): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999,9s
      delayTimeTripDown : Word := WORD#16#0000;   // Tripping delay time(current undrshoot): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999,9s
      delayTimeTripAsymmetry : Word := WORD#16#0000;   // Tripping delay time(current asymmetry): Resolution: 0.1s=1, Default: 0s, Min: 0.1s or 0s (disabled), Max: 999,9s
      delayTimeReclose : Word := WORD#16#0000;   // Reclosing delay time: Resolution: 0.1min=1, Default: 0min ,Min: 0.1min or 0min, Max: 300 min
      tresholdUp : Word := WORD#16#0000;   // Threshold overshoot: 3RR2441(S00): Min: 1.6,Max: 16A ; 3RR2442(S0): Min: 4.0, Max: 40A
      tresholdDown : Word := WORD#16#0000;   // Threshold undershoot: 3RR2441(S00): Min: 1.6, Max: 16A; 3RR2442(S0): Min: 4,0, Max: 40A
      tresholdAsymmetry : Word := WORD#16#0000;   // Threshold current asymmetry: Resolution: 0.1%=1, Default: 0, Min: 5%, Max: 50%
      warningTresholdUp : Word := WORD#16#0000;   // Warning threshold overshoot: 3RR2441(S00): Min: 1.6, Max: 16A; 3RR2442(S0): Min: 4.0, Max: 40A
      warningTresholdDown : Word := WORD#16#0000;   // Warning threshold undershoot: 3RR2441(S00): Min:1.6, Max: 16A; 3RR2442(S0): Min: 4.0, Max: 40A
      warningTresholdAsymmetry : Word := WORD#16#0000;   // Warning threshold current asymmetry: Resloution: 0.1%=1, Default: 0, Min: 5%, Max: 50%
      reserved6 : Array[50..55] of Byte;   // Reserved
      hysteresis : Word := WORD#16#0000;   // Hysteresis (current): 3RR2441(S00): Min: 0.1, Max: 3A; 3RR2442(S0): Min:0.1, Max: 8A
      blockMonitoring : Word := WORD#16#0000;   // Blocking current monitoring: Default: 0, Min: 2 or 0 (disabled), Max: 5
      reserved7 : Byte;   // Reserved
      relaySwitchResponse : Byte;   // Relay switching response:Default: 16#00, 16#00: Closed-circuit (NC), 16#01: Open-circuit(NO)
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RR24_typeAll : STRUCT
  /// LIOLink_3RR24_typeAll
//Contains all the information about 3RR24
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommands : Byte;   // ID2: System Commands (0x80 for device reset, 0x82 for factory reset, 0xA0 for switching cycle counter reset, 0xA1 for runtime meter reset)
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      serialNumber : String[16];   // ID21: Serial number
      hwRevision : String[7];   // ID22: Hardware revision
      fwRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3RR24_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3RR24_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3RR24_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
