NAMESPACE Simatic.Ax.iolink


FUNCTION CRC16
    VAR_INPUT
        iDataLen : INT; //Length of data the CRC calculated from
        startValue : WORD;
    END_VAR

    VAR_IN_OUT
        aData    : ARRAY[*] OF BYTE; //Checksum is calculated to this data
    END_VAR
    
    VAR_OUTPUT
        // Output Parameters
        crcCalc : WORD; // CRC in hex format
    END_VAR
    
    VAR_TEMP
        wCRC    : WORD; // Variable for calculation of CRC
        wTmp    : WORD; // Temp variable for CRC
        i,j     : INT;  // For-loop help variables
    END_VAR
    
        wCRC := startValue; //Initialize to FFFF
        FOR i := 1 TO iDataLen DO    
            wCRC := wCRC XOR aData[i];
            FOR j := 1 TO 8 DO
                wTmp := SHR( wCRC, USINT#1);
                IF ((wCRC AND WORD#16#0001)) = WORD#16#0001 THEN
                    wCRC := wTmp XOR WORD#16#A001;
                ELSE 
                    wCRC := wTmp;
                END_IF;
            END_FOR;
        END_FOR;
        crcCalc := wCRC;
    END_FUNCTION

    FUNCTION CRC32
        VAR_INPUT
            iDataLen : INT; //Length of data the CRC calculated from
            startValue : DWORD := DWORD#16#FFFF_FFFF;
            polynom : DWORD := DWORD#0000_0001;
        END_VAR
    
        VAR_IN_OUT
            aData    : ARRAY[*] OF BYTE; //Checksum is calculated to this data
        END_VAR
        
        VAR_OUTPUT
            // Output Parameters
            crcCalc : DWORD; // CRC in hex format
        END_VAR
        
        VAR_TEMP
            wCRC    : DWORD; // Variable for calculation of CRC
            wTmp    : DWORD; // Temp variable for CRC
            i,j     : INT;  // For-loop help variables
        END_VAR
        
            wCRC := startValue;
            FOR i := 1 TO iDataLen DO    
                wCRC := wCRC XOR aData[i];
                FOR j := 1 TO 8 DO
                    wTmp := SHR( wCRC, USINT#1);
                    IF ((wCRC AND polynom)) <> DWORD#0 THEN
                        wCRC := wTmp XOR polynom;
                    ELSE 
                        wCRC := wTmp;
                    END_IF;
                END_FOR;
            END_FOR;
            crcCalc := wCRC;
        END_FUNCTION

        FUNCTION crc32_test

            VAR_IN_OUT
                data : ARRAY[*] OF BYTE;
            END_VAR

            ;

        END_FUNCTION


END_NAMESPACE
