NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_typePortEventQualifier : STRUCT
  /// LIOLink_typePortEventQualifier
//EventQualifier: Instance, Source, Type, Mode
      instance : Byte;   // 0: Unknown / 1-3: Reserved / 4: Application / 5-7: Reserved
      source : Bool;   // (default) FALSE: Device (remote) / TRUE: Master/Port
      eventType : Byte;   // 0: Reserved / 1: Notification / 2: Warning / 3: Error
      mode : Byte;   // 0: Reserved / 1: Event single shot / 2: Event disappears / 3: Event appears
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_typePortEventCodes : STRUCT
  /// LIOLink_PortEventCodes
//UDT for Event Information: eventCode, eventQualifier
      eventCode : Word;   // IO-Link EventCode
      eventQualifier : LIOLink_typePortEventQualifier;   // IO-Link EventQualifier
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_typeDiagnostics : STRUCT
      status : Word;   // Status of the Block or error identification when error occurred
      subfunctionStatus : DWord;   // Status or return value of called FB's, FCs and system blocks
      stateNumber : DInt;   // State in the state machine of the block where the error occurred
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_typePortEvents : STRUCT
  /// LIOLink_PortEvents
//Events of a port
      event : Array[0..Lengths#PORT_EVENT_CODES - 1] of LIOLink_typePortEventCodes;   // Events of a port
   END_STRUCT;

END_TYPE

TYPE
  LIOLink_typeEvents : STRUCT
  /// LIOLink_Events
//Events of each port of a IO-Link-Master
      port : Array[1..Lengths#PORT_EVENTS] of LIOLink_typePortEvents;   // Ports of IO-Link-Master
   END_STRUCT;

END_TYPE


END_NAMESPACE
