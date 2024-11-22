USING Siemens.Simatic.S71500.DistributedIO;
NAMESPACE Simatic.Ax.iolink
    
    CLASS INTERNAL IOLinkBase

        VAR PROTECTED
            statDone             : Bool;                                  // Static value for output 'done'
            statBusy             : Bool;                                  // Static value for output 'busy'
            statError            : Bool;                                  // Static value for output 'error'
            statStatus           : Word := Status#STATUS_NO_CALL;         // Static value for output 'status' 
            statSubfunctionStatus: DWord;                                 // Status of WRREC/RDREC or error code from IO-Link Master (%W1: IO-Link Master error, %W0: ISDU error)
			statFBErrorState     : DInt;                                  // State in the state machine of the block where the error occurred
			statFBState          : DInt := StateDevice#FB_STATE_NO_PROCESSING;  // State in the state machine of the FB
        END_VAR
        VAR PUBLIC
            Diagnostics       : LIOLink_typeDiagnostics;  // Diagnostics information of FB
        END_VAR

        METHOD PUBLIC GetStatus
            VAR_OUTPUT
                busy  : BOOL;
                error : BOOL;
                done  : BOOL;
                status : WORD;
            END_VAR

            // REGION write static values to outputs
            done := statDone;
            busy := statBusy;
            error := statError;
            status := statStatus;
            //ENO := NOT #statError;
            // END_REGION write static values to outputs
        END_METHOD

        METHOD PUBLIC Reset

            // execute reset
            statDone := FALSE;
            statBusy := FALSE;
            statError := FALSE;
            statStatus := status#STATUS_NO_CALL;

            //reset state to initial state
            statFBstate := StateDevice#FB_STATE_NO_PROCESSING;
            
        END_METHOD

    END_CLASS
    
END_NAMESPACE
