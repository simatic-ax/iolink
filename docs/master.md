# Class Master

## Public variables

| Symbol | Datatype | Explanation |
| --- | --- | --- |
| Record4Ports | REF_TO LIOLink_typeMaster4PortRecordData | Reference to a data structure, sufficient for a 4-port master |
| Record8Ports | REF_TO LIOLink_typeMaster8PortRecordData | Reference to a data structure, sufficient for a 8-port master |
| RecordLength | DINT | Number of bytes in the record structure. Will be written internally when performing a backup, used to determine the amount of data for a restore |

## Method Backup

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| hwID | HW_IO | INPUT | Hardware ID of the IO Link master |
| port | masterType | INPUT | Type of the master. Can be either 4-Port or 8-port |
| Backup | BOOL | RETURN | TRUE: The restore request is valid. FALSE: Input variables are invalid, or the internal state cannot execute such a request (e.g. a command is already active) |

## Method Restore

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| hwID | HW_IO | INPUT | Hardware ID of the IO Link master |
| port | masterType | INPUT | Type of the master. Can be either 4-Port or 8-port |
| Restore | BOOL | RETURN | TRUE: The restore request is valid. FALSE: Input variables are invalid, or the internal state cannot execute such a request (e.g. a command is already active) |

## Method Execute

This method has no interface. After starting a command (backup or restore), it needs to be called cyclically to execute the functionality, until the functionality is executed successfully or an error occured.

## Method Reset

This method has no interface. It resets the internal state in case of an error.
