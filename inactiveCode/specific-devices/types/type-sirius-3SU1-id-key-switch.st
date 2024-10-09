NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_3SU1_IDKeySwitch_typeKeyState : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeKeyState
//Data record (index) 79 - add individually codable ID key
      idByte0 : Byte;   // Byte 0 of Identification number of the individually codeable ID key
      idByte1 : Byte;   // Byte 1 of Identification number of the individually codeable ID key
      idByte2 : Byte;   // Byte 2 of Identification number of the individually codeable ID key
      idByte3 : Byte;   // Byte 3 of Identification number of the individually codeable ID key
      idByte4 : Byte;   // Byte 4 of Identification number of the individually codeable ID key
      authorizationLevel : Byte;   // Authorization level
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeDiag92 : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeDiag92
//Data record (index) 92 - diagnostics
      reserved : Array[0..15] of Byte;   // Reserved
      status : Byte;   // Status: 1 = Ready; 2 = Error
      outputs : Byte;   // Output state: Permission= .X0 - .X3 Key inserted= .X4
      detectionKey : Byte;   // Detection of the ID key
      statusKey : Byte;   // Status of the individually encodable ID Key
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeDiag94 : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeDiag94
//Data record (index) 94 (ID key)
      reserved : Array[0..15] of Byte;   // Reserved
      insertedKey : LIOLink_3SU1_IDKeySwitch_typeKeyState;   // Inserted ID key
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeKeyList1 : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeKeyList1
//Data record (index) 81 - memory of the individually codable ID keys
      keys : Array[1..30] of LIOLink_3SU1_IDKeySwitch_typeKeyState;   // Data record (index) 81 - memory of the individually codable ID keys
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeKeyList2 : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeKeyList2
//Data record (index) 82 - memory of the individually codable ID keys
      keys : Array[31..50] of LIOLink_3SU1_IDKeySwitch_typeKeyState;   // Data record (index) 82 - memory of the individually codable ID keys
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeParam : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeParam
//Data record (index) 131 (parameters)
      reserved : Array[0..15] of Byte;   // Reserved
      switchInStages : Bool;   // Switch in stages; 0: disabled, 1: enabled
      switchPosMemory : Bool;   // Switch position memory; 0: disabled (key position = 0), 1: enabled (last key position is retained)
      switchPosRetentive : Bool;   // Switch position retentive memory; 0: disabled, 1: enabled
      individualOnly : Bool;   // Individually encodeable ID keys only; 0: disabled, 1: enabled
      reserved1 : Bool;   // Reserved
      reserved2 : Bool;   // Reserved
      reserved3 : Bool;   // Reserved
      reserved4 : Bool;   // Reserved
      switchPosDelay : Byte;   // Switch position delay; 1 = 0.1 s (0 to 100)
      selectMem : Byte;   // Select memory range (1 to 5)
      deactSwitchOff : Bool;   // Deactivation of switch-off function (>= V2.0.0)
      deactRedLed : Bool;   // Deactivate red LEDs (>= V2.0.0)
      reductAuthLevel : Bool;   // Permit a reduction of the authorization level via the switch (>= V2.0.0)
      actLampTest : Bool;   // Activate lamp test (>= V2.0.0)
      reserved5 : Bool;   // Reserved
      reserved6 : Bool;   // Reserved
      reserved7 : Bool;   // Reserved
      reserved8 : Bool;   // Reserved
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_3SU1_IDKeySwitch_typeAll : STRUCT
  /// LIOLink_3SU1_IDKeySwitch_typeAll
//Contains all the information about 3SU1 IDKeySwitch
      parameterPage0 : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommand : Byte;   // Write System Command to Device: 0xA1 - 0xA7; 0x82 = Default
      vendorName : String[10];   // ID16: Vendor name
      vendorText : String[64];   // ID17: Vendor text
      productName : String[64];   // ID18: Product name
      productID : String[18];   // ID19: Product ID
      fwRevision : String[5];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      processDataIn : Array[0..5] of Byte;   // ID69: Process data of inputs
      addKeyID : LIOLink_3SU1_IDKeySwitch_typeKeyState;   // ID79: Add individually encodeable ID key
      delKeyID : LIOLink_3SU1_IDKeySwitch_typeKeyState;   // ID80: Delete Individually encodeable ID key
      keyList1 : LIOLink_3SU1_IDKeySwitch_typeKeyList1;   // ID81: List of saved indivually encodeable ID keys 1 to 30
      keyList2 : LIOLink_3SU1_IDKeySwitch_typeKeyList2;   // ID82: List of saved indivually encodeable ID keys 31..50
      diagnostics : LIOLink_3SU1_IDKeySwitch_typeDiag92;   // ID92: Diagnostics
      insertedKey : LIOLink_3SU1_IDKeySwitch_typeDiag94;   // ID94: Inserted ID key
      parameters : LIOLink_3SU1_IDKeySwitch_typeParam;   // ID131: Parameters
   END_STRUCT;

END_TYPE


END_NAMESPACE
