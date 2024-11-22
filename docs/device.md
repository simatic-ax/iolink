# Class Device

## Method Setup

Set the communication properties to the device you want to communicate with. These connection properties will be used internally when executing Read() or Write().

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| hwID | HW_IO | INPUT | Hardware ID of the IO Link device |
| cap | UINT | INPUT | client access point. If left zero, this will be read internally |
| port | INT | INPUT | port of the device |
| index | INT | INPUT | index of the device |
| subindex | INT | INPUT | subindex in the device |
| timeout | LTIME | INPUT | timout value for communication. Default: 20s |
| pollingPeriod | LTIME | INPUT | polling time for retrieving data. Default: 200ms |

## Method Read

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| status | WORD | OUTPUT | Internal status of the class when the request (this method) is called |
| Read | BOOL | RETURN | TRUE: The restore request is valid. FALSE: Input variables are invalid, or the internal state cannot execute such a request (e.g. a command is already active) |

## Method Write

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| status | WORD | OUTPUT | Internal status of the class when the request (this method) is called |
| Read | BOOL | RETURN | TRUE: The restore request is valid. FALSE: Input variables are invalid, or the internal state cannot execute such a request (e.g. a command is already active) |

## Method Execute

This method has no interface. After starting a command (read or write), it needs to be called cyclically to execute the functionality, until the functionality is executed successfully or an error occured. 

## Method Reset

This method has no interface. It resets the internal state in case of an error. Only after executing reset, a new command can be successfully executed.
