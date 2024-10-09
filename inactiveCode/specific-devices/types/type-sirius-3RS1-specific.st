NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3RS1_typeSensor : STRUCT
  /// LIOLink_3RS1_typeSensor
//Temperature monitoring, part of the data set (index) 92 - diagnostics
      rangeOvershoot : Bool;   // Temperature sensor - Measuring range overshoot
      wireBreak : Bool;   // Temperature sensor - Wire break
      shortCircuit : Bool;   // Temperature sensor - Short-circuit
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      reserved16 : Bool;   // Reserved
      reserved17 : Bool;   // Reserved
      aboveBothLimits : Bool;   // Temperature sensor - Measured value above the two limit values (overshoot)
      aboveFirstLimit : Bool;   // Temperature sensor - Measured value above first limit value (overshoot)
      withinRange : Bool;   // Temperature sensor - Measured value within range of limit values
      belowFirstLimit : Bool;   // Temperature sensor - Measured value below first limit value (undershoot)
      belowBothLimits : Bool;   // Temperature sensor - Measured value below the two limit values (undershoot)
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      aboveBothWarningLimits : Bool;   // Temperature sensor - Measured value above two warning thresholds (overshoot)
      aboveFirstWarningLimit : Bool;   // Temperature sensor - Measured value above first warning threshold (overshoot)
      withinRangeWarning : Bool;   // Temperature sensor - Measured value within range of warning threshold
      belowFirstWarningLimit : Bool;   // Temperature sensor - Measured value below first warning threshold (undershoot
      belowBothWarningLimits : Bool;   // Temperature sensor - Measured value below two warning threshold (undershoot)
      reserved21 : Bool;   // Reserved
      reserved22 : Bool;   // Reserved
      reserved23 : Bool;   // Reserved
      reserved24 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS1_typeDiag : STRUCT
  /// LIOLink_3RS1_typeDiag
//Data set (index) 92 - diagnostics
      reserved : Array[0..15] of Byte;   // Reserved
      ready : Bool;   // Ready
      groupError : Bool;   // Group error
      generalWarning : Bool;   // General warning
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      parameterAssign : Bool;   // Parameter assignment active
      parameterInvalid : Bool;   // Invalid parameter
      internalError : Bool;   // Self-test error/internal error
      reserved3 : Bool;   // Reserved
      errorNumber : Word;   // Parameter error number
      reserved4 : Array[20..25] of Byte;   // Reserved
      delayTimeRunning : Bool;   // ON-delay time running
      delayLevelUp : Bool;   // Tripping delay time running (limit value v1 or limit value v2)
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      levelV1Up : Bool;   // Limit value v1 overshoot
      levelV2Up : Bool;   // Limit value v2 overshot
      levelV1UpWarning : Bool;   // Warning limit for v1 overshoot
      levelV2UpWarning : Bool;   // Warning limit for v2 overshoot
      resetResponse : Bool;   // Reset response:0:Manual reset,1:Autorst/permanent jmpr between terminals y3/y4
      reserved11 : Bool;   // Reserved
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
      sensor : Array[1..3] of LIOLink_3RS1_typeSensor;   // Temperature monitoring
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS1_typeMeasure : STRUCT
  /// LIOLink_3RS1_typeMeasure
//Data set (index) 94 (measured values)
      reserved : Array[0..15] of Byte;   // Reserved
      sensorTemp1C : Int;   // Temperature in °C (Temperature sensor 1)
      sensorTemp1F : Int;   // Temperature in °F (Temperature sensor 1)
      sensorTemp2C : Int;   // Temperature in °C (Temperature sensor 2)(TEMP. 2 3RS1441 ONLY)
      sensorTemp2F : Int;   // Temperature in °F (Temperature sensor 2)(TEMP. 2 3RS1441 ONLY)
      sensorTemp3C : Int;   // Temperature in °C (Temperature sensor 3)(TEMP. 3 3RS1441 ONLY)
      sensorTemp3F : Int;   // Temperature in °F (Temperature sensor 3)(TEMP. 3 3RS1441 ONLY)
      tempMinC : Int;   // Temperature Tmin in °C
      tempMinF : Int;   // Temperature Tmin in °F
      tempMaxC : Int;   // Temperature Tmax in °C
      tempMaxF : Int;   // Temperature Tmax in °F
      tempAvgC : Int;   // Temperature Tavg in °C
      tempAvgF : Int;   // Temperature Tavg in °F
      reserved1 : Array[40..45] of Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS1_typeParam : STRUCT
  /// LIOLink_3RS1_typeParam
//Data set (index) 131 - parameters
      reserved : Array[0..15] of Byte;   // Reserved
      groupDiagnostic : Bool := TRUE;   // Group diagnostics: Default: True, False: disabled, True: enabled
      groupError : Bool := TRUE;   // Group error diagnostics: Default: True, False: disabled, True: enabled
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      localLimitChange : Bool := TRUE;   // Local threshold change: Default: True, False: disabled, True: enabled
      localParamChange : Bool := TRUE;   // Local parameter change: Default: True, False: disabled, True: enabled
      localReset : Bool := TRUE;   // Local reset: Default: True, False: disabled, True: enabled
      retentiveErrorMem : Bool := FALSE;   // Retentive error memory: Default: False, False: disabled, True: enabled
      analogValueCoding : USInt := USINT#5;   // Analog value coding: Default: 5, Min: 0 (disabled), Max: 255
      reserved3 : Array[18..23] of Byte;   // Reserved
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      monitorMode1 : Bool := FALSE;   // Temp. monitoring mode:Default: False, False: Overshoot/Range Monitor, True: Undershoot
      monitorMode2 : Bool := FALSE;   // Temp. monitoring mode:Default: False, False: Overshoot/Undershoot , True: Range Monitor
      monitorMode3 : Bool := FALSE;   // False
      unit : Bool;   // Temperature unit: False:°C (degrees Celcius) True:°F (degrees Fahrenheit)
      unit0 : Bool := FALSE;   // False
      unit1 : Bool;   // False
      delayOn : Bool := TRUE;   // ON-delay time (at Power ON): Default: true, false: disabled, true: enabled
      delayOn0 : Bool;   // False
      delayManual : Bool := TRUE;   // ON-delay time (at manual reset): Default: true, false: disabled, true: enabled
      delayManual0 : Bool;   // False
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      delayTimeOn : Int;   // ON-delay time: Resolution:0,1s=1,Default:0,Min:1 or 0(disabled),Max:999,9s
      delayTimeLevel : Int;   // Tripping delay time(temp.ovr-/undrsht):Rsltn:0,1s=1,Dflt:0,Min:1or.0,Max:999,9s
      reserved10 : Byte;   // Reserved
      sensor1Available : Bool := TRUE;   // 3RS1440/3RS1441/3RS1540:Temperature sensor 1: False: disabled, true: enabled
      sensor2Available : Bool;   // 3RS1441 ONLY: Temperature sensor 2: False: disabled, true: enabled, Default: true
      sensor3Available : Bool;   // 3RS1441 ONLY: Temperature sensor 3: False: disabled, true: enabled, Default: true
      reserved11 : Bool;   // Reserved
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      sensorType : USInt;   // Temperature sensor type: 3RS1440/1441 resistance sensor, 3RS1540 thermocouple
      limitValueV1 : Int := 80;   // Limit value v1: Min:-50(resist.sensors)/-99°(thermocouples)C, Max:750/1800°C
      limitValueV2 : Int := 50;   // Limit value v2: Min:-50(resist.sensors)/-99°C(thermocouples), Max:750/1800°C
      warningValueV1 : Int := 72;   // Warning threshold v1: Min:-50(resist.sen.)/-99°C(thermocouples), Max:750/1800°C
      warningValueV2 : Int := 45;   // Warning threshold v2: Min:-50(resist.sen.)/-99°C(thermocouples), Max:750/1800°C
      reserved16 : Array[42..45] of Byte;   // Reserved
      hysteresis : Word := WORD#16#0005;   // Hysteresis: Default: 5°C/5°F, Min:1°C/1°F or 0 (disabled),Max:99°C/99°F
      relaySwitchResponse : Bool := FALSE;   // Relay switching response:Default: false, false: Closed-circuit(NC), true: Open-ciruict(NO)
      relaySwitchResponse0 : Bool;   // False
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      reserved21 : Bool;   // Reserved
      reserved22 : Bool;   // Reserved
      reserved23 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS1_typeAll : STRUCT
  /// LIOLink_3RS1_typeAll
//Contains all the information about 3RS1
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      hardwareRevision : String[7];   // ID22: Hardware revision
      firmwareRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3RS1_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3RS1_typeMeasure;   // ID94: Measurement values
      parameters : LIOLink_3RS1_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
