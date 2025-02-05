NAMESPACE Simatic.Ax.iolink

    CLASS Decoder

        VAR PUBLIC
            RefToMasterConfig4Port : REF_TO LIOLink_typeMaster4PortRecordData;
            RefToMasterConfig8Port : REF_TO LIOLink_typeMaster8PortRecordData;
            DecodedConfig : DecodedConfig;
        END_VAR

        METHOD DecodeMasterConfig

        VAR_TEMP
            configInternal : MasterType;
        END_VAR

        VAR_OUTPUT
            ConfigValid : BOOL;
            ConfigType : MasterType;
        END_VAR

        IF RefToMasterConfig8Port <> NULL THEN
            configType := MasterType#EIGHT_PORT;
        ELSIF RefToMasterConfig4Port <> NULL THEN
            configType := MasterType#FOUR_PORT;
        ELSE
            //stop functionality if no data is attached
            RETURN;
        END_IF;
        

        

        //Write outputs
        ConfigType := configInternal;
        ConfigValid := TRUE;
    END_METHOD
END_CLASS

END_NAMESPACE
