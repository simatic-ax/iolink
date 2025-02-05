NAMESPACE Simatic.Ax.iolink

    {TestFixture}
    CLASS Test_CRC

        VAR PUBLIC
            testarray : ARRAY [1..8] OF BYTE;
            result32 : DWORD;
            result16 : WORD;
        END_VAR

        {FixtureSetup}
        METHOD PUBLIC TestFixtureSetup
            ;
        END_METHOD
        
        {Test}
        METHOD PUBLIC TestCRC32

            testarray[1] := BYTE#16#AF;
            testarray[2] := BYTE#16#FE;
            testarray[3] := BYTE#16#01;
            testarray[4] := BYTE#16#23;
            testarray[5] := BYTE#16#45;
            testarray[6] := BYTE#16#67;
            testarray[7] := BYTE#16#89;
            testarray[8] := BYTE#16#10;

            CRC32(startValue := DWORD#16#FFFF_FFFF, polynom := DWORD#16#F4AC_FB13, iDataLen := 8, aData := testarray, crcCalc => result32);
            AxUnit.Assert.Equal(expected := DWORD#16#4A2AB95F, actual := result32);


        END_METHOD

        {Test}
        METHOD PUBLIC TestCRC16

            testarray[1] := BYTE#16#AF;
            testarray[2] := BYTE#16#FE;
            testarray[3] := BYTE#16#01;
            testarray[4] := BYTE#16#23;
            testarray[5] := BYTE#16#45;
            testarray[6] := BYTE#16#67;
            testarray[7] := BYTE#16#89;
            testarray[8] := BYTE#16#10;

            CRC16(startValue := WORD#16#FFFF, iDataLen := 8, aData := testarray, crcCalc => result16);
            AxUnit.Assert.Equal(expected := WORD#16#6513, actual := result16);

        END_METHOD     

    END_CLASS

END_NAMESPACE
