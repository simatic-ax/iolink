NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3RA_typeConfigStarterLong : STRUCT
  /// LIOLink_3RA_typeConfigStarterLong
//Contains configurations for starter with type "long"
      reserved : Byte := BYTE#16#07;   // Fixed Value
      starterItemNumber : Byte;   // Starter (item number)
      reserved1 : Byte := BYTE#16#60;   // Fixed Value
      starterDiag : Byte;   // Starter Diag: 16#00: not available; 16#02: available but defect; 16#03: available and OK
      starterType : Byte;   // Type of starter
      starterVersion1 : Byte;   // Starter Version part 1
      starterVersion2 : Byte;   // Starter Version part 2
      reserved2 : Byte := BYTE#16#07;   // Fixed Value
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeConfigStarterShort : STRUCT
  /// LIOLink_3RA_typeConfigStarterShort
//Contains configurations for starter with type "short"
      starterItemNumber : Byte;   // Starter (item number)
      reserved1 : Byte := BYTE#16#60;   // Fixed Value
      starterDiag : Byte;   // Starter Diag: 16#00: not available; 16#02: available but defect; 16#03: available and OK
      starterType : Byte;   // Type of starter
      starterVersion1 : Byte;   // Starter Version part 1
      starterVersion2 : Byte;   // Starter Version part 2
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeDiagStarterLong : STRUCT
  /// LIOLink_3RA_typeDiagStarterLong
//Contains diagnose of starter of type "long"
      reserved1 : Byte;   // Reserved
      starterItemNumber : Byte;   // Starter Item number (1 to 4)
      starterAvailable : Byte;   // Starter Available: 16#00 not available; 16#02: available
      reserved2 : Array[3..6] of Byte;   // Reserved
      contactBlockDefective : Bool;   // Contact block defective
      contactSupplyVoltageMissing : Bool;   // Contact block supply voltage missing
      reserved3 : Bool;   // Reserved
      trippMotorOverload : Bool;   // Motor overload tripping
      trippCircuitBreaker : Bool;   // Circuit breaker tripped
      switchOffendPosRight : Bool;   // Switch off - end position right
      switchOffendPosLeft : Bool;   // Switch off - end position left
      processImageError : Bool;   // Process image error
      manualOperationLocal : Bool;   // Manual operation local
      manualOperationConAborted : Bool;   // Manual operation connection aborted
      ContactCoolingTimeActive : Bool;   // Contact block cooling time active
      remainingLifeTime0 : Bool;   // Remaining life time (RLT 0%)
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeDiagStarterShort : STRUCT
  /// LIOLink_3RA_typeDiagStarterShort
//Contains diagnose of starter of type "short"
      starterItemNumber : Byte;   // Starter Item number (1 to 4)
      starterAvailable : Byte;   // Starter Available: 16#00 not available; 16#02: available
      reserved1 : Array[2..5] of Byte;   // Reserved
      contactBlockDefective : Bool;   // Contact block defective
      contactSupplyVoltageMissing : Bool;   // Contact block supply voltage missing
      reserved2 : Bool;   // Reserved
      trippMotorOverload : Bool;   // Motor overload tripping
      trippCircuitBreaker : Bool;   // Circuit breaker tripped
      switchOffendPosRight : Bool;   // Switch off - end position right
      switchOffendPosLeft : Bool;   // Switch off - end position left
      processImageError : Bool;   // Process image error
      manualOperationLocal : Bool;   // Manual operation local
      manualOperationConAborted : Bool;   // Manual operation connection aborted
      ContactCoolingTimeActive : Bool;   // Contact block cooling time active
      remainingLifeTime0 : Bool;   // Remaining life time (RLT 0%)
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeConfig : STRUCT
  /// LIOLink_3RA_typeConfig
//Contains all the possible configurations of 3RA
      reserved : Array[0..7] of Byte := [BYTE#16#0021, 3(BYTE#16#0000), BYTE#16#0005, 3(BYTE#16#0000)];   // Reserved
      starter1 : LIOLink_3RA_typeConfigStarterLong;   // Config Data of Starter 1
      starter2 : LIOLink_3RA_typeConfigStarterShort;   // Config Data of Starter 2
      starter3 : LIOLink_3RA_typeConfigStarterLong;   // Config Data of Starter 3
      starter4 : LIOLink_3RA_typeConfigStarterShort;   // Config Data of Starter 4
      reserved1 : Byte := BYTE#16#07;   // Reserved
      operatorItemNumber : Byte;   // Operator panel (item number)
      reserved2 : Byte := BYTE#16#60;   // Reserved
      operatorAvailable : Byte;   // Operator panel available: 16#00 not available; 16#02: available
      reserved3 : Byte := BYTE#16#D2;   // Reserved
      reserved4 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeDiag : STRUCT
  /// LIOLink_3RA_typeDiag
//Data set (index) 90 - group diagnostics: Starter group
      reserved : Array[0..3] of Byte;   // Reserved - Dataset Index 90 - Length 53 / read length 52
      numberOfStarters : Byte;   // Number of starters (compact starters and operator panel)
      configurationCompare : Byte;   // Preset <> actual configuration 16#00: equal 16#01: different
      reserved1 : Word;   // Reserved
      starter1 : LIOLink_3RA_typeDiagStarterLong;   // Starter 1 - module and specific diagnostics
      starter2 : LIOLink_3RA_typeDiagStarterShort;   // Starter 2 - module and specific diagnostics
      starter3 : LIOLink_3RA_typeDiagStarterLong;   // Starter 3 - module and specific diagnostics
      starter4 : LIOLink_3RA_typeDiagStarterShort;   // Starter 4 - module and specific diagnostics
      reserved3 : Byte;   // Reserved
      operatorItemNumber : Byte;   // Operator panel (item number)
      operatorAvailable : Byte;   // Operator panel available: 16#00 not available; 16#02: available
      reserved4 : Byte;   // Reserved
      reserved5 : Array[48..51] of Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeParameterPage1 : STRUCT
  /// LIOLink_3RA_typeParameterPage1
  // Author : SIE_RS
  // Family : '3RA'
  // Name : 'IO-Link'
  // Version : 1.0
//Contains Parameter Page 1 of 3RA
      productFamiliy : Byte;   // Produktfamily SIRIUS (0x60) - A-9 Dataset Index 1 Page 75
      starter1Compare : Bool;   // Starter 1 - 0: Target/actual comparison: Yes, 1: Target/actual comparison: No,
      starter1Available : Bool;   // Starter 1 - 0: Starter available: No, 1: Starter available: Yes,
      starter2Compare : Bool;   // Starter 2 - 0: Target/actual comparison: Yes, 1: Target/actual comparison: No,
      starter2Available : Bool;   // Starter 2 - 0: Starter available: No, 1: Starter available: Yes,
      starter3Compare : Bool;   // Starter 3 - 0: Target/actual comparison: Yes, 1: Target/actual comparison: No,
      starter3Available : Bool;   // Starter 3 - 0: Starter available: No, 1: Starter available: Yes,
      starter4Compare : Bool;   // Starter 4 - 0: Target/actual comparison: Yes, 1: Target/actual comparison: No,
      starter4Available : Bool;   // Starter 4 - 0: Starter available: No, 1: Starter available: Yes,
      operatorPanelCompare : Bool;   // Operator panel - 0:Target/actual comparison: Yes, 1:Target/actual comparison:No
      operatorPanelAvailable : Bool;   // Operator panel - 0: Starter available: No, 1: Starter available: Yes,
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      profileVersion1 : Bool;   // Profile version
      profileVersion2 : Bool;   // Profile version
      profileVersion3 : Bool;   // Profile version
      profileVersion4 : Bool;   // Profile version
      starter1Type : Byte;   // Starter 1 - Type of starter
      starter1Version : Byte;   // Starter 1 - Starter version
      starter2Type : Byte;   // Starter 2 - Type of starter
      starter2Version : Byte;   // Starter 2 - Starter version
      starter3Type : Byte;   // Starter 3 - Type of starter
      starter3Version : Byte;   // Starter 3 - Starter version
      starter4Type : Byte;   // Starter 4 - Type of starter
      starter4Version : Byte;   // Starter 4 - Starter version
      operatorPanel : Byte;   // 210: Operator panel
      reserved3 : Byte;   // Reserved
      reserved4 : Byte;   // Reserved
      reserved5 : Byte;   // Reserved
      reserved6 : Byte;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3RA_typeAll : STRUCT
  /// LIOLink_3RA_typeAll
//Contains all the information about 3RA
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      parameterPage1 : LIOLink_3RA_typeParameterPage1;   // ID1: Parameter page 1
      vendorName : String[10];   // ID16: Vendor name
      vendorText : String[58];   // ID17: Vendor text
      productName : String[30];   // ID18: Product name
      productID : String[8];   // ID19: Product ID
      productText : String[2];   // ID20: Product text
      serialNumber : String[8];   // ID21: Serial number
      hwRevision : String[4];   // ID22: Hardware revision
      fwRevision : String[4];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      diagnostics : LIOLink_3RA_typeDiag;   // ID90: Group diagnostics
      actualConfig : LIOLink_3RA_typeConfig;   // ID105: Actual configuration
      targetConfig : LIOLink_3RA_typeConfig;   // ID130: Target configuration
   END_STRUCT;

END_TYPE


END_NAMESPACE
