# Types

List of all possible values for named value data types and structured data types

## Structured data types

### Stuctured type LIOLink_typeIdentificationObjects

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

### Structured type LIOLink_typePortEventQualifier

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| instance | Byte | 0: Unknown / 1-3: Reserved / 4: Application / 5-7: Reserved|
| source   | Bool | (default) FALSE: Device (remote) / TRUE: Master/Port|
| eventType| Byte | 0: Reserved / 1: Notification / 2: Warning / 3: Error|
| mode     | Byte | 0: Reserved / 1: Event single shot / 2: Event disappears / 3: Event appears|

### Structured type LIOLink_typePortEventCodes

| Symbol | Datatype | Explanation |
| --- | --- | --- |
|eventCode | Word | IO-Link EventCode |
|eventQualifier | LIOLink_typePortEventQualifier | IO-Link EventQualifier|

### Structured type LIOLink_typeDiagnostics

| Symbol | Datatype | Explanation |
| --- | --- | --- |
|status | Word | Status of the Block or error identification when error occurred|
|subfunctionStatus | DWord | Status or return value of called FB's, FCs and system blocks|
|stateNumber | DInt | State in the state machine of the block where the error occurred|

### Structured type LIOLink_typePortEvents

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| event | Array[0..Lengths#PORT_EVENT_CODES - 1] of LIOLink_typePortEventCodes | Events of a port|

### Structured type LIOLink_typeEvents

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
