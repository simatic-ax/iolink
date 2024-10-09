NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_8WD46_typeLightEffects : STRUCT
  /// LIOLink_8WD46_typeLightEffects
//Light Effect data record
      effect : Byte;   // light effect (permanet light, flash, ...)
      pwmR : Byte;   // Red component (only relevant for individual color PWM)
      pwmG : Byte;   // Green component (only relevant for individual color PWM)
      pwmB : Byte;   // Blue component (only relevant for individual color PWM)
      brightness : Byte;   // brightness of the segmenttt
      defaultColor : Byte;   // default color (0: individual color PWM, 1: red, 2: green, ...)
      reserved : Byte;   // reserved
      priorityAutoScaleMode : Byte;   // priority in auto scale mode
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_8WD46_typeSoundMode : STRUCT
  /// LIOLink_8WD46_typeSoundMode
//Sound Mode data record
      mode : Byte;   // tone type (0: off, 1: Continuous tone, 2: pulse tone, ...)
      frequency1Start : Word;   // Frequency at the start of a cycle in Hz
      frequency2Stop : Word;   // Frequency at the end of a cycle in Hz
      frequency1Periode : Word;   // Frequency for time betwen frequency 1 and 2 in Hz*10
      volume : Byte;   // 0: low, 1: mediummm, 2: loud, 3: very loud
      count : Word;   // repeat count
      brakeToRepeat : Word;   // Pause after repeat
      BrakeBetweenCycles : Word;   // Duration of the pause beween cycle in ms
      holdingPeriodeFrequency2 : Word;   // Setting of thehold time for full-scale frequency in ms
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_8WD46_typeAll : STRUCT
  /// LIOLink_8WD46_typeAll
//Contains all the information about 8WD46
      systemCommand : Byte;   // system command to reset to default settings
      vendorName : String[48];   // Siemens AG (default)
      vendorText : String[48];   // http://www.siemens.com/io-link (default)
      productName : String[32];   // 8WD46 IO-Link 9 Segments (default)
      productId : String[16];   // 8WD4613-5HH47 (default)
      productText : String[64];   // SIRIUS Signaling Column 8WD46 IO-Link (default)
      serialNumber : String[16];   // 0000000000000000 (default)
      hwRevision : String[16];   // 1.0 (default)
      fwRevision : String[16];   // 1.2.0 (default)
      appSpecificName : String[32];   // *** (default)
      functionTag : String[32];   // *** (default)
      locationTag : String[32];   // *** (default)
      deviceStatus : Byte;   // device status
      deviceStatusDetailed : Byte;   // detailed device status
      opHour : DWord;   // operation time in hours
      operatingMode : Byte;   // operating mode (signal mode, auto scale mode, ...)
      lightEffects : Array[1..15] of LIOLink_8WD46_typeLightEffects;   // optical effects of each segment  (1 to 9/15)
      soundMode : Array[1..10] of LIOLink_8WD46_typeSoundMode;   // sound effects (10 configurable)
      powerReduction : Byte;   // power reduction (0: on / 1: off)
      fillLevelMode : Byte;   // only in level mode (0: use settings of segment 1-9,15 / 1: use settings of segment 1 )
      headlong : Byte;   // orientation of installation (normal / overhead)
      elementCount : Byte;   // number of elements
   END_STRUCT;

END_TYPE


END_NAMESPACE
