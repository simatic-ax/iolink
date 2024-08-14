NAMESPACE Simatic.Ax.IOLink
TYPE
  LIOLink_typeIdentificationObjects : STRUCT
      vendorID : Word;   // Vendor ID
      deviceID : DWord;   // Device ID
      vendorName : String[64];   // Vendor name
      vendorText : String[64];   // Vendor text
      productName : String[64];   // Product name
      productID : String[64];   // Product ID
      productText : String[64];   // Product text
      serialNumber : String[16];   // Serial number
      hwRevision : String[64];   // Hardware revision
      fwRevision : String[64];   // Firmware revision
      appSpecificTag : String[32];   // Application specific name
      locationTag : String[32];   // Location tag
      functionTag : String[32];   // Function tag
   END_STRUCT;

END_TYPE


END_NAMESPACE
