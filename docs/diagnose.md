# Class Diagnose

## Public variables

| Symbol | Datatype | Explanation |
| --- | --- | --- | --- |
| events | LIOLink_typeEvents | Diagnostic data, that has been retreived |

## Method Start

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| hwID | HW_IO | INPUT | Hardware ID of the IO Link device |
| cap | INT | INPUT | Client access point. If left zero, this will be determined internally |
| Backup | BOOL | RETURN | TRUE: The restore request is valid. FALSE: Input variables are invalid, or the internal state cannot execute such a request (e.g. a command is already active) |

## Method Execute

This method has no interface. After starting a command (backup or restore), it needs to be called cyclically to execute the functionality, until the functionality is executed successfully or an error occured. 

## Method Reset

This method has no interface. It resets the internal state in case of an error. 
