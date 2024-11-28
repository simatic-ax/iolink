# Class IOLinkBase

The class IOLinkBase is used to provide common data and methods used in all IO-Link classes. It is exclusively for internal use.

## Public variables

| Symbol | Datatype | Explanation |
| --- | --- | --- | --- |
| Diagnostics | LIOLink_typeDiagnostics | Diagnostic data of the command for all IOLink classes |

## Method GetStatus

| Symbol | Datatype | Type | Explanation |
| --- | --- | --- | --- |
| busy | BOOL | OUTPUT | TRUE: A command is currently being executed |
| error | BOOL | OUTPUT | TRUE: During execution, an error occured, execution has stopped |
| done | BOOL | OUTPUT | TRUE: A command has been executed successfully |
| status | WORD | OUTPUT | Detailed status information of the internal state. See [here](types.md#status) for status values |

## Method Reset

This method has no interface. It resets the internal state of the class in case of an error.
