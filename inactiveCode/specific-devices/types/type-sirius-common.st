NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_typeParameterPage0 : STRUCT
      masterCommand : Byte := BYTE#16#00;   // Switch the IO-Link operation mode (Fallback, Operate, Preoperate)
      masterCycleTime : Byte := BYTE#16#00;   // Master Cycle Time
      minCycleTime : Byte := BYTE#16#00;   // Minimum Device Cycle Time
      frameCapability : Byte := BYTE#16#00;   // Supported frame types for communication
      ioLinkRevisionID : Byte := BYTE#16#00;   // IO-Link protocol version implemented on the device
      processDataIn : Byte := BYTE#16#00;   // Number and structure of the data process image of the inputs to the master
      processDataOut : Byte := BYTE#16#00;   // Number and structure of the data process image of the outputs to the master
      vendorID1 : Byte := BYTE#16#00;   // Unique vendor identification number
      vendorID2 : Byte := BYTE#16#00;   // Siemens:0x002A
      deviceID1 : Byte := BYTE#16#00;   // Unique device identification number
      deviceID2 : Byte := BYTE#16#00;   // Unique device identification number
      deviceID3 : Byte := BYTE#16#00;   // Unique device identification number
      functionID1 : Byte := BYTE#16#00;   // Unique function identification number
      functionID2 : Byte := BYTE#16#00;   // Unique function identification number
      reserved1 : Byte := BYTE#16#00;   // Reserved
      reserved2 : Byte := BYTE#16#00;   // Reserved
   END_STRUCT;

END_TYPE


END_NAMESPACE
