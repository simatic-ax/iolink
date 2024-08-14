NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_RF200_typeEventHistory : STRUCT
  /// LIOLink_RF200_typeEventHistory
//Contains last 5 events of a RF200
      lastEvent : DWord;   // Last event
      secondLastEvent : DWord;   // Second last event
      thirdLastEvent : DWord;   // Third last event
      fourthLastEvent : DWord;   // Fourth last event
      fifthLastEvent : DWord;   // Fifth last event
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_RF200_typeParameters : STRUCT
  /// LIOLink_RF200_typeParameters
//Contains all parameters of a RF200
      eventMessage : Byte;   // 16#02: Event indication enabled (default), 16#04: No Message
      operatingMode : Byte;   // 16#04: Scan UID (default), 16#08 Scan user data
      readyDelay : Byte;   // 16#02 Turn off (default), 16#04: Turn on additional backup mechanism for
      dataHoldingTime : Byte;   // Minimum time during which the process input data is not changed by the device
      rfParameters : Byte;   // Setting the RF parameters, 16#02 ISO default, 16#04: special settings
      modulation : Byte;   // Setting for the modulation strength 16#00 (0%) ... 16#64 (100%) - default 16#16 (22%)
      subcarrier : Byte;   // Subcarrier, 16#02: Single (default), 16#04: double
      dataTransfer : Byte;   // Data transmission speed, 16#02: low, 16#04: high (default)
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_RF200_typeReaderStatus : STRUCT
  /// LIOLink_RF200_typeReaderStatus
//Contrains all information about the status of the reader
      timeSinceStartup : DWord;   // Operating time in seconds
      tagsInTheField : Byte;   // current number of transponders in the field
      antennaStatus : Byte;   // antenna turned on/off
      tagChanges : DWord;   // number of transponder changes
      lineDriverRev : Byte;   // version of the IO-Link line driver
      errorCounterPassive : Byte;   // Air interface: Counter for errors in idle state
      abortCounter : Byte;   // Air interface: Communication aborted
      codeErrorCounter : Byte;   // Air interface: Communication disruption
      signatureErrorCounter : Byte;   // Air interface: Protocol error, signature error counter, is reset when read out
      crcErrorCounter : Byte;   // Air interface: Communication disruption
      currentCommandStatus : Byte;   // Command status of the last command, is reset when read out
      errorCount : Byte;   // HOST interface: Communication disruption
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_RF200_typeTagStatus : STRUCT
  /// LIOLink_RF200_typeTagStatus
//Contains all the information about the status of the tag
      uid : Array[0..7] of Byte;   // Unique identifier of the transponder
      tagName : Byte;   // Transponder Name
      chipVersion : Byte;   // Version of the Chip
      memSize : Word;   // Memory size in Bytes
      lockStatus : Byte;   // Disable blocks on the chip
      memBlockSize : Byte;   // Size of memory blocks of the chip
      numBlocks : Byte;   // Number of memory blocks of the chip
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_RF200_typeUIDHistory : STRUCT
  /// LIOLink_RF200_typeUIDHistory
//Contains UID history 
      lastUID1 : DWord;   // Last UID
      lastUID2 : DWord;   // Last UID
      secondLastUID1 : DWord;   // Second last UID
      secondLastUID2 : DWord;   // Second last UID
      thirdLastUID1 : DWord;   // Third last UID
      thirdLastUID2 : DWord;   // Third last UID
      fourthLastUID1 : DWord;   // Fourth last UID
      fourthLastUID2 : DWord;   // Fourth last UID
      fifthLastUID1 : DWord;   // Fifth last UID
      fifthLastUID2 : DWord;   // Fifth last UID
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_RF200_typeAll : STRUCT
  /// LIOLink_RF200_typeAll
//Contains all information about RF200
      directParameterPage : LIOLink_typeParameterPage0;   // ID0: Parameter page 0
      systemCommand : Byte;   // ID2: System command
      deviceAccessLocks : Word;   // ID12: Device access locks
      vendorName : String[12];   // ID16: Vendor name
      vendorText : String[12];   // ID17: Vendor text
      productName : String[24];   // ID18: Product name
      productID : String[16];   // ID19: Product ID
      productText : String[64];   // ID20: Product Text
      serialNumber : String[12];   // ID21: Serial Number
      hwRevision : String[12];   // ID22: Hardware revision
      fwRevision : String[12];   // ID23: Firmware revision
      appSpecificName : String[32];   // ID24: Application specific name
      errorCount : Word;   // ID32: Number of errors that have occured (not warnings)
      deviceStatus : Byte;   // ID36: Device status
      deviceStatusDetailed : Byte;   // ID37: Detailed device status
      processImageIn : Array[0..7] of Byte;   // ID40: Read out last process image of the inputs
      processImageOut : Array[0..7] of Byte;   // ID41: Read out last process image of the outputs
      parameters : LIOLink_RF200_typeParameters;   // ID64: Read/Write Reader Parameters
      eventHistory : LIOLink_RF200_typeEventHistory;   // ID74: Number of events
      readerStatus : LIOLink_RF200_typeReaderStatus;   // ID90: Reader status
      tagStatus : LIOLink_RF200_typeTagStatus;   // ID91: Tag status
      uidHistory : LIOLink_RF200_typeUIDHistory;   // ID92: History of UID
   END_STRUCT;

END_TYPE


END_NAMESPACE
