NAMESPACE Simatic.Ax.IOLink.Test
    
    {TestFixture}
    CLASS Test_CharsTO_Strg
        {TestSetup}
        METHOD PUBLIC TestSetup
            ;
        END_METHOD
        {Test}
        METHOD PUBLIC test_singleCharacter
            VAR_TEMP
                CharArrayAsBytes : ARRAY[0..10] OF BYTE;
                result : STRING;
            END_VAR

            CharArrayAsBytes[0] := BYTE#16#69; //i

            Chars_TO_Strg(Chars := CharArrayAsBytes, pChars := 0, Cnt := UINT#1 , Strg => result);

            AxUnit.Assert.Equal(expected := TRUE, actual := result = 'i');
            ; // AxUnit.Assert.Equal(y, x)
        END_METHOD

        {TestTeardown}
        METHOD PUBLIC TestTeardown
            ;
        END_METHOD
    END_CLASS

END_NAMESPACE
