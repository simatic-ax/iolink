NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3RS2_typeCurrentInput : STRUCT
  /// LIOLink_3RS2_typeCurrentInput
//Part of the Data set 92 - Diagnostics, Current Input 4..20mA
      overstepping : Bool;   // Measuring range overstepping
      res0 : Bool;   // Reserved
      res1 : Bool;   // Reserved
      res2 : Bool;   // Reserved
      res3 : Bool;   // Reserved
      res4 : Bool;   // Reserved
      res5 : Bool;   // Reserved
      res6 : Bool;   // Reserved
      aboveBothLimits : Bool;   // Measured value is above the two limit values (monitoring for overshoot)
      aboveFirstLimit : Bool;   // Measured value is above the first limit value (monitoring for overshoot)
      withinRangeLimits : Bool;   // Measured value is within range of limit values
      belowFirstLimit : Bool;   // Measured value is below the first limit value for overshoot (monitoring for undershoot)
      belowBothLimits : Bool;   // Measured value is below the two limit values (monitoring for undershoot)
      res7 : Bool;   // Reserved
      res8 : Bool;   // Reserved
      res9 : Bool;   // Reserved
      aboveBothWarningLimits : Bool;   // Measured value is above the two warning limits (monitoring for overshoot)
      aboveFirstWarningLimit : Bool;   // Measured value is above the first warning limit (monitoring for overshoot)
      withinRangeWarningLimits : Bool;   // Measured value is within range of warning limits
      belowFirstWarningLimit : Bool;   // Measured value is below the first warning limit for overshoot (monitoring for undershoot)
      belowBothWarningLimits : Bool;   // Measured value is below the two warning limits (monitoring for undershoot)
      res10 : Bool;   // Reserved
      res11 : Bool;   // Reserved
      res12 : Bool;   // Reserved
      res13 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeSensor : STRUCT
  /// LIOLink_3RS2_typeSensor
//Part of Data set 92 - Diagnostics, diagnostics of sensor
      rangeOvershoot : Bool;   // Measuring range overshoot
      wireBreak : Bool;   // Wire break
      shortCircuit : Bool;   // Short-circuit
      reserved : Bool;   // Reserved
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      aboveBothLimits : Bool;   // Measured value is above the two limit values (monitoring for overshoot)
      aboveFirstLimit : Bool;   // Measured value is above the first limit value (monitoring for overshoot)
      withinRange : Bool;   // Measured value is within range of limit values
      belowFirstLimit : Bool;   // Measured value is below the first limit value for overshoot (monitoring for undershoot)
      belowBothLimits : Bool;   // Measured value is below the two limit values (monitoring for undershoot)
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      aboveBothWarningLimits : Bool;   // Measured value is above the two warning limits (monitoring for overshoot)
      aboveFirstWarningLimit : Bool;   // Measured value is above the first warning limit (monitoring for overshoot)
      withinRangeWarning : Bool;   // Measured value is within range of warning limits
      belowFirstWarningLimit : Bool;   // Measured value is below the first warning limit for overshoot (monitoring for undershoot)
      belowBothWarningLimits : Bool;   // Measured value is below the two warning limits (monitoring for undershoot)
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      reserved11 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeDiag : STRUCT
  /// LIOLink_3RS2_typeDiag
//Data set 92 - Diagnostics
      reserved : Array[0..15] of Byte;   // Reserved
      ready : Bool;   // Ready
      groupError : Bool;   // Group error
      groupWarning : Bool;   // Group warning
      reserved1 : Bool;   // Reserved
      communicationError : Bool;   // Sensor expansion module - communication error
      parameterAssign : Bool;   // Parameter assignment active
      parameterInvalid : Bool;   // Invalid parameter
      internalError : Bool;   // Self-test error/internal error
      paramAckReq : Bool;   // Parameter confirmation required
      reserved2 : Bool;   // Reserved
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      errorNumber : Word;   // Incorrect parameter number
      reserved9 : Array[20..25] of Byte;   // Reserved
      delayTimeRunning : Bool;   // ON-delay time running
      delayLevelUpV1 : Bool;   // Tripping delay time running (limit value v1)
      delayLevelUpV2 : Bool;   // Tripping delay time running (limit value v2)
      reserved10 : Bool;   // Reserved
      reserved11 : Bool;   // Reserved
      reserved12 : Bool;   // Reserved
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      levelV1UpDown : Bool;   // Limiting value v1 overshot/undershot
      levelV2UpDown : Bool;   // Limiting value v2 overshot/undershot
      levelV1Warning : Bool;   // Warning limit v1 overshot/undershot
      levelV2Warning : Bool;   // Warning limit v1 overshot/undershot
      reserved15 : Bool;   // Reserved
      reserved16 : Bool;   // Reserved
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      sensor : Array[1..3] of LIOLink_3RS2_typeSensor;   // Temperature sensor 1
      currentInput : LIOLink_3RS2_typeCurrentInput;   // Current input
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeMeasure : STRUCT
  /// LIOLink_3RS2_typeMeasure
//Data set 94 - measured values
      reserved : Array[0..15] of Byte;   // Reserved
      sensorTemp1C : Int;   // Temperature in °C (Temperature sensor 1)
      sensorTemp1F : Int;   // Temperature in °F (Temperature sensor 1)
      sensorTemp2C : Int;   // Temperature in °C (Temperature sensor 2)
      sensorTemp2F : Int;   // Temperature in °F (Temperature sensor 2)
      sensorTemp3C : Int;   // Temperature in °C (Temperature sensor 3)
      sensorTemp3F : Int;   // Temperature in °F (Temperature sensor 3)
      tempMinC : Int;   // Temperature Tmin in °C
      tempMinF : Int;   // Temperature Tmin in °F
      tempMaxC : Int;   // Temperature Tmax in °C
      tempMaxF : Int;   // Temperature Tmax in °F
      tempAvgC : Int;   // Temperature Tavg in °C
      tempAvgF : Int;   // Temperature Tavg in °F
      currentInput : Int;   // Current input
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeMeasureFloat : STRUCT
  /// LIOLink_3RS2_typeMeasureFloat
//Data set 95 - measured values (floating-point format)
      reserved : Array[0..15] of Byte;   // Reserved
      sensorTemp1C : Real;   // Temperature in °C (Temperature sensor 1)
      sensorTemp1F : Real;   // Temperature in °F (Temperature sensor 1)
      sensorTemp2C : Real;   // Temperature in °C (Temperature sensor 2)
      sensorTemp2F : Real;   // Temperature in °F (Temperature sensor 2)
      sensorTemp3C : Real;   // Temperature in °C (Temperature sensor 3)
      sensorTemp3F : Real;   // Temperature in °F (Temperature sensor 3)
      tempMinC : Real;   // Temperature Tmin in °C
      tempMinF : Real;   // Temperature Tmin in °F
      tempMaxC : Real;   // Temperature Tmax in °C
      tempMaxF : Real;   // Temperature Tmax in °F
      tempAvgC : Real;   // Temperature Tavg in °C
      tempAvgF : Real;   // Temperature Tavg in °F
      currentInput : Real;   // Current input
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeParam : STRUCT
  /// LIOLink_3RS2_typeParam
//Data set 131 - parameters
      reserved : Array[0..15] of Byte;   // Reserved
      groupDiag : Bool := TRUE;   // Group diagnostics: Default: True, False: disabled, True: enabled
      groupErrorDiag : Bool := TRUE;   // Group error diagnostics: Default: True, False: disabled, True: enabled
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      localLimChange : Bool := TRUE;   // Local limit change: Default: True, False: disabled, True: enabled
      localParamChange : Bool := TRUE;   // Local parameter change: Default: True, False: disabled, True: enabled
      localReset : Bool := TRUE;   // Local reset: Default: True, False: disabled, True: enabled
      retentiveErrorMem : Bool := TRUE;   // Retentive error memory: Default: True, False: disabled, True: enabled
      analogValueCoding : USInt := USINT#5;   // Analog value coding: Default: 5, Min: 1, Max: 160
      reserved3 : Array[18..23] of Byte;   // Reserved
      reset : Bool;   // Reset: Default: False, False: manual, True: auto
      reserved5 : Bool;   // Reserved
      monitorMode1 : Bool;   // Monitoring mode [0] overshoot [Default]; [1] undershoot; [2] window monitoring
      monitorMode2 : Bool;   // Monitoring mode [0] overshoot [Default]; [1] undershoot; [2] window monitoring
      monitorMode3 : Bool;   // Monitoring mode [0] overshoot [Default]; [1] undershoot; [2] window monitoring
      unit1 : Bool;   // Temperature unit [0]°C [Default]; [1] °F; [2] mA; [3] %
      unit2 : Bool;   // Temperature unit [0]°C [Default]; [1] °F; [2] mA; [3] %
      unit3 : Bool;   // Temperature unit [0]°C [Default]; [1] °F; [2] mA; [3] %
      onDelayStart : Bool;   // ON-delay time (at Power ON): Default: [0], [0] disabled, [1] enabled
      reserved6 : Bool;   // Reserved
      onDelayReset : Bool;   // ON-delay time (at manual reset): Default: [0], [0] disabled, [1] enabled
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
      reserved9 : Bool;   // Reserved
      reserved10 : Bool;   // Reserved
      reserved11 : Bool;   // Reserved
      startupDly : Int;   // Startup delay; Resolution: 0.1s=1, Default: 0, Min: 1 or 0 (disabled), Max: 9999 * 0.1 s = 999.9 s
      tripDly : Int;   // Tripping delay time (if the temperature is overshot or undershot); Resolution: 0.1s=1, Default: 0, Min: 1 or 0 (disabled), Max: 9999 * 0.1 s = 999.9 s
      reserved12 : Int;   // Reserved
      sensor1En : Bool := TRUE;   // Sensor 1 enabled; Default: False, False: disabled, True: enabled
      sensor2En : Bool;   // Sensor 2 enabled; Default: False, False: disabled, True: enabled
      sensor3En : Bool;   // Sensor 3 enabled; Default: False, False: disabled, True: enabled
      currentInputEn : Bool;   // Current input 4..20 mA enabled; Default: False, False: disabled, True enabled
      sensorExpModule : Bool;   // Sensor expansion module / output relay K3; Default: False, False: disabled, True enabled
      reserved13 : Bool;   // Reserved
      reserved14 : Bool;   // Reserved
      reserved15 : Bool;   // Reserved
      sensorType : Byte := BYTE#16#80;   // Sensor type; Default: 128, 128: Pt100 (2-wire), 129: Pt1000 (2-wire), 130: KTY83 (2-wire), 131: KTY84 (2-wire), 132: NTC (2-wire), 136: Pt100 (3-wire), 137: Pt1000 (3-wire), 138: KTY83 (3-wire), 139: KTY84 (3-wire), 140: NTC (3-wire), 1: J, 2: K, 3: T, 4: E, 5: N, 6: S, 7: R, 8: B, 160: current input 4..20 mA
      limitV1 : Int := 80;   // Limit v1; Default: 80, Min: -50 °C (resistance sensors) / -99 °C (thermocouples), Max: 750 °C (resistance sensors)/1800 °C (thermocouples)
      limitV2 : Int := 50;   // Limit v2; Default: 50, Min: -50 °C (resistance sensors) / -99 °C (thermocouples), Max: 750 °C (resistance sensors)/1800 °C (thermocouples)
      warnLimitV1 : Int := 75;   // Warning limit v1; Default: 75, Min: -50 °C (resistance sensors) / -99 °C (thermocouples), Max: 750 °C (resistance sensors)/1800 °C (thermocouples)
      warnLimitV2 : Int := 45;   // Warning limit v2; Default: 45, Min: -50 °C (resistance sensors) / -99 °C (thermocouples), Max: 750 °C (resistance sensors)/1800 °C (thermocouples)
      reserved16 : DWord;   // Reserved
      hysteresis : Int := 5;   // Hysteresis; Default: 5 °C / 5 °F, Min: 1 °C/1 °F, Max: 999 °C / 999 °F
      relayBehavior : Bool;   // Relay switching behavior; Default: False, False: Quiescent current principle, True Open-circuit principle
      reserved17 : Bool;   // Reserved
      reserved18 : Bool;   // Reserved
      reserved19 : Bool;   // Reserved
      reserved20 : Bool;   // Reserved
      reserved21 : Bool;   // Reserved
      reserved22 : Bool;   // Reserved
      reserved23 : Bool;   // Reserved
      reserved24 : Byte;   // Reserved
      minRange : Int := 40;   // Current input 4..20 mA minimum range; Default: 40, Min: -200 (°C/°F) / 0 (%), Max: 9999 (°C/°F) / 150 (%)
      maxRange : Int := 80;   // Current input 4..20 mA maximum range; Default: 40, Min: -200 (°C/°F) / 0 (%), Max: 9999 (°C/°F) / 150 (%)
      offsetSensor1 : Int;   // Offset sensor 1; Default: 0, Min: -99, Max: 99
      offsetSensor2 : Int;   // Offset sensor 2; Default: 0, Min: -99, Max: 99
      offsetSensor3 : Int;   // Offset sensor 3; Default: 0, Min: -99, Max: 99
      offsetCurrentInput : Int;   // Offset current input 4..20 mA; Default: 0, Min: -10.0 mA / -99 °C/°F, Max: 10.0 mA / 99 °C / °F, reading always returns 0
      compMeasuringPt : Int;   // Comparison measuring point in °C/°F; Default: 0, Min: -25 °C / -13 °F, Max: 80 °C / 176 °F, reading always returns 0
      ecoMode : Bool := TRUE;   // Eco mode; Default [1], [0] disabled, [1] enabled
      ponProtection : Bool;   // Pin Protection Default [0], [0] disabled, [1] enabled
      extCompMeasuringPt : Bool;   // External comparison measuring point; Default [0], [0] disabled, [1] enabled
      reserved25 : Bool;   // Reserved
      reserved26 : Bool;   // Reserved
      reserved27 : Bool;   // Reserved
      reserved28 : Bool;   // Reserved
      reserved29 : Bool;   // Reserved
      reserved30 : Byte;   // Reserved
      pin : Int;   // PIN; Default: 0, Min: 0, Max: 999, reading always returns 0
      newPin : Int;   // New PIN; Default: 0, Min: 0, Max: 999, reading always returns 0
      deviceMode : Byte;   // Device mode; Default: [0], [0] standard, [1] ATEX, [2] Temperature monitor TW, [3] Temperature limiter TB
      reserved31 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RS2_typeAll : STRUCT
  /// LIOLink_3RS2_typeAll
//Contains all the information about 3RS2
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommand : Byte;   // ID2: System commands
      vendorName : String[11];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[14];   // ID19: Product ID
      firmwareRevision : String[7];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3RS2_typeDiag;   // ID92: Diagnostics
      measuredValues : LIOLink_3RS2_typeMeasure;   // ID94: Measurement values
      measuredValuesFloat : LIOLink_3RS2_typeMeasureFloat;   // ID95: Measurement as floating values
      parameters : LIOLink_3RS2_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
