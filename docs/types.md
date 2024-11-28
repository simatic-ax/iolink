# Types

List of all possible values for named value data types and structured data types

## Structured data types

### LIOLink_typeIdentificationObjects

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| vendorID       | Word     | Vendor ID |
| deviceID       | DWord    | Device ID |
| vendorName     | String[64]| Vendor name |
| vendorText     | String[64]| Vendor text |
| productName    | String[64]| Product name |
| productID      | String[64]| Product ID |
| productText    | String[64]| Product text |
| serialNumber   | String[16]| Serial number |
| hwRevision     | String[64]| Hardware revision |
| fwRevision     | String[64]| Firmware revision |
| appSpecificTag | String[32]| Application specific name |
| locationTag    | String[32]| Location tag |
| functionTag    | String[32]| Function tag |

### LIOLink_typePortEventQualifier

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| instance | Byte | 0: Unknown / 1-3: Reserved / 4: Application / 5-7: Reserved|
| source   | Bool | (default) FALSE: Device (remote) / TRUE: Master/Port|
| eventType| Byte | 0: Reserved / 1: Notification / 2: Warning / 3: Error|
| mode     | Byte | 0: Reserved / 1: Event single shot / 2: Event disappears / 3: Event appears|

### LIOLink_typePortEventCodes

| Symbol | Datatype | Explanation |
| --- | --- | --- |
|eventCode | Word | IO-Link EventCode |
|eventQualifier | LIOLink_typePortEventQualifier | IO-Link EventQualifier|

### LIOLink_typeDiagnostics

| Symbol | Datatype | Explanation |
| --- | --- | --- |
|status | Word | Status of the Block or error identification when error occurred|
|subfunctionStatus | DWord | Status or return value of called FB's, FCs and system blocks|
|stateNumber | DInt | State in the state machine of the block where the error occurred|

### LIOLink_typePortEvents

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| event | Array[0..Lengths#PORT_EVENT_CODES - 1] of LIOLink_typePortEventCodes | Events of a port|

### LIOLink_typeEvents

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| port | Array[1..Lengths#PORT_EVENTS] of LIOLink_typePortEvents | Ports of IO-Link-Master |

## Named values

### Status

Type: WORD

| Name | Value | Explanation
| --- | --- | --- |
| STATUS_EXECUTION_FINISHED | 16#0000 | Execution finished without errors |
| STATUS_NO_CALL            | 16#7000 | No job being currently processed |
| STATUS_FIRST_CALL         | 16#7001 | First call after incoming new job (rising edge 'execute') |
| STATUS_SUBSEQUENT_CALL    | 16#7002 | Subsequent call during active processing without further details |
| STATUS_DONE			    | 16#7003 | Subsequent call when the functionality is already finished |
| STATUS_OFFSET_BACKUP      | 16#7100 | Offset for status during backup operation |
| STATUS_OFFSET_RESTORE     | 16#7200 | Offset for status during restore operation |
| ERR_EXECUTION_ACTIVE      | 16#8001 | A command is already being executed |
| ERR_HARDWARE_ID_INVALID   | 16#8002 | Error: The hardware id is not valid |
| ERR_UNKNOWN_MODULE        | 16#80B0 | unknown type of module, check subfunctionStatus |
| ERR_UNKNOWN_MODE          | 16#8200 | Unknown mode |
| ERR_ARRAY_UNSUPPORTED     | 16#8201 | Record array doesn't fit expected limits |
| ERR_ARRAY_REFERENCE       | 16#8202 | Record Array reference is not present |
| ERR_WRONG_PORT            | 16#8201 | Error: wrong port |
| ERR_WRONG_INDEX           | 16#8202 | Error: wrong index |
| ERR_WRONG_SUBINDEX        | 16#8203 | Error: wrong subindex |
| ERR_WRONG_LENGTH          | 16#8205 | Error: wrong length for write data record |
| ERR_SEQ_NUMBER            | 16#8401 | Error: IO-Link master returned a sequence number indicating an error, see "diagnostics" |
| ERR_IO_LINK               | 16#8401 | Error: IO-Link master returned error code, see "diagnostics" |
| ERR_INCONSISTENT_DATA     | 16#8402 | Error: Read data record doesn't match request |
| ERR_REQUEST_TIMEOUT       | 16#8403 | Error: Request timed out |
| ERR_UNDEFINED_STATE       | 16#8600 | Error: due to an undefined state in state machine |
| ERR_WRREC                 | 16#8601 | Error: WRREC encountered an error, see "diagnostics" |
| ERR_RDREC                 | 16#8602 | Error: RDREC encountered an error, see "diagnostics" |
| ERR_WRREC_RESTORE         | 16#8603 | Error: WRREC encountered an error during restore, see "diagnostics" |
| ERR_RDREC_VERIFY          | 16#8604 | Error: RDREC encountered an error during verification of restore, see "diagnostics" |

### MasterMode

Type: USINT

| Name | Value | Explanation
| --- | --- | --- |
| BACKUP | 0 | backup data |
| RESTORE | 1 | restore data |
| INVALID | 2 | invalid value, default |

### MasterType

| Value | Explanation |
| --- | --- |
| FOUR_PORT | Use the data structure for a 4-port master |
| EIGHT_PORT | Use the data structure for a 8-port master |
| INVALID | Invalid mode, default |

### Lengths

Type: Int

| Name | Value | Explanation |
| --- | --- | --- |
| RECORD                            | 232 | Length in bytes of a record |
| RECORD_HEADER                     | 8 | Length in bytes of a record header |
| RECORD_WITH_HEADER                | RECORD + RECORD_HEADER | Length in bytes of a complete record |
| MAX_PORTS                         | 8 | Maximum number of ports of an IO-Link master |
| PORT_EVENT_CODES                  | 5 | Number of event codes for each port of an IO-Link master |
| PORT_EVENTS                       | 8 | Number of events for every port event code |
| MASTER_HEADER                     | 6 | Length in bytes of a master header |
| MASTER_RECORD_SEGMENT             | 234 | Length in bytes of a master record segment |
| MASTER_RECORD_SEGMENT_WITH_HEADER | MASTER_RECORD_SEGMENT + MASTER_HEADER | Length in bytes of a complete master record |
| MASTER_RECORD_4_PORT              | 10240 | Maximum number of bytes of an IO-Link master record with 4 ports |
| MASTER_RECORD_8_PORT              | 17550 | Maximum number of bytes of an IO-Link master record with 8 ports |

### Cap

Type: Word

| Name | Value | Explanation |
| --- | --- | --- |
|CAP_LEGACY              | 16#00E3 |  Siemens (old) Standard CAP: 227 |
|CAP_STANDARD            | 16#B400 | IO-Link Standard CAP: 16#B400 |
|INDEX_CAP_IOLINK        | 16#B000 | Index of the data record for IOLM_Info. Only IO-Link-Masters with CAP=16#B000 support this call |

### Limit

Type: UInt

| Name | Value | Explanation |
| --- | --- | --- |
| MAX_PORT                  | USINT#63   | Max. possible port|
| MAX_INDEX                 | UINT#32767 |  Max. possible index|
| INDEX_PORT_FUNC           | UINT#65535 |  Index to address port functions|
| MAX_SUBINDEX              | USINT#255   | Max. possible subindex|

### FunctionType

Type: BYTE

| Name | Value | Explanation |
| --- | --- | --- |
|FUNC_PUSH   |16#01 |  Extended function number for push |
|FUNC_PULL   |16#02 | Extended function number for pull |

