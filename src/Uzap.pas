unit Uzap;

interface

uses
    System.Classes,
    System.Generics.Collections,
    System.JSON,
    System.Net.HttpClient,
    Uzap.Types,
    Uzap.Webhook,
    UphoneNum;

type 

    // represents a whatsapp button 
    TzapBtn = record
        title:  string;
        id:     string;
        constructor Create(title: string; id: string);
    end;

    TzapComponentBody = class
        Fparameters: TArray<String>;
        constructor Create(parameters: TArray<String>);
        destructor Destroy(); override;
    end;

    TzapComponentButtons = class
        FbuttonsId: TArray<String>;
        constructor Create(buttonsId: TArray<String>);
        destructor Destroy(); override;
    end;

    // class for whatsapp cloud api handling. Api version v15.0
    Tzap = class
        // intance of the class with the business numbr id and the api token
        constructor Create(id: string; token: string);
        destructor Destroy(); override;

        // send a message to a phone number 
        function sendText(phoneNumber: String; msg: String; out res: IHTTPResponse): Boolean;
        function sendButton(phoneNumber: String; msg: String; buttons: TArray<TzapBtn>; out res: IHTTPResponse): Boolean;
        function sendTemplate(phoneNumber: String; templateName: String; localeCode: TzapLocale; templateBody: TzapComponentBody; buttons: TzapComponentButtons; out res: IHTTPResponse): Boolean;

        private
        // internal business number id
        id: string;
        // whatsapp cloud api token
        token: string;
    end;

implementation

uses
    System.SysUtils,
    System.JSON.Writers,
    System.JSON.Builders,
    System.Net.URLClient,
    System.JSON.Readers,
    System.JSON.Types;

function Tzap.sendTemplate(phoneNumber: String; templateName: String; localeCode: TzapLocale; templateBody: TzapComponentBody; buttons: TzapComponentButtons; out res: IHTTPResponse): Boolean;
begin
    var client: THTTPClient := THTTPClient.Create();
    var writter: TJsonObjectWriter := TJsonObjectWriter.Create();

    with writter do
    begin
        WriteStartObject;
            WritePropertyName('messaging_product');                             WriteValue('whatsapp');
            WritePropertyName('recipient_type');                                WriteValue('individual');
            WritePropertyName('to');                                            WriteValue(phoneNumber);
            WritePropertyName('preview_url');                                   WriteValue(true);
            WritePropertyName('type');                                          WriteValue('template');
            WritePropertyName('template');                                      WriteStartObject;
                WritePropertyName('name');                                      WriteValue(templateName);
                WritePropertyName('language');                                  WriteStartObject;
                    WritePropertyName('code');                                  WriteValue(zapLocaleToString(localeCode));
                WriteEndObject;
                WritePropertyName('components');                                WriteStartArray;
                    WriteStartObject;                                                                                       // body
                        WritePropertyName('type');                              WriteValue('body');
                        WritePropertyName('parameters');                        WriteStartArray;
                            var i: Integer;
                            for i := 0 to Length(templateBody.Fparameters)-1 do                                             // for every template body variable
                            begin
                                WriteStartObject;
                                    WritePropertyName('type');                  WriteValue('text');
                                    WritePropertyName('text');                  WriteValue(templateBody.Fparameters[i]);
                                WriteEndObject;
                            end;
                            templateBody.Destroy();
                        WriteEndArray;
                    WriteEndObject;

                    var j: Integer;
                    for j := 0 to Length(buttons.FbuttonsId)-1 do                                                           // for every buttonId
                    begin
                        WriteStartObject;                                                                                   // buttonsid
                            WritePropertyName('type');                          WriteValue('button');
                            WritePropertyName('sub_type');                      WriteValue('quick_reply');
                            WritePropertyName('index');                         WriteValue(IntToStr(j));
                            WritePropertyName('parameters');                    WriteStartArray;
                                    WriteStartObject;
                                        WritePropertyName('type');              WriteValue('payload');
                                        WritePropertyName('payload');           WriteValue(buttons.FbuttonsId[j]);
                                    WriteEndObject;
                            WriteEndArray;
                        WriteEndObject;
                    end;
                    buttons.Destroy();
                WriteEndArray;
            WriteEndObject;
        WriteEndObject;
    end;

    var body := TStringStream.Create(writter.JSON.ToJSON());
    var headers: TNetHeaders := [
        TNetHeader.Create('Authorization', 'Bearer ' + token),
        TNetHeader.Create('Content-Type', 'application/json')
    ];

    try
        res := client.Post(
            'https://graph.facebook.com/v15.0/'+id+'/messages',
            body,
            nil,
            headers
        );
    except
        on E: Exception do
        begin
            Result := false;
        end;
    end;
    
    if res.StatusCode = 200 then
        Result := true
    else
        Result := false;

    body.Destroy();
    writter.Destroy();
    client.Destroy();
end;

constructor TzapComponentBody.Create(parameters: TArray<String>);
begin
    inherited Create();
    Fparameters := parameters;
end;

destructor TzapComponentBody.Destroy();
begin
    Finalize(Fparameters); 
    inherited Destroy();
end;

constructor TzapComponentButtons.Create(buttonsId: TArray<String>);
begin
    inherited Create();

    if Length(buttonsId) < 3 then
        FbuttonsId := Copy(buttonsId, 0, Length(buttonsId))
    else
        FbuttonsId := Copy(buttonsId, 0, 3);

    Finalize(buttonsId);
end;

destructor TzapComponentButtons.Destroy();
begin
    Finalize(FbuttonsId); 
    inherited Destroy();
end;

function Tzap.sendButton(phoneNumber: String; msg: String; buttons: TArray<TzapBtn>; out res: IHTTPResponse): Boolean;
begin
    var client: THTTPClient := THTTPClient.Create();

    var writter: TJsonObjectWriter := TJsonObjectWriter.Create();

    with writter do
    begin
        WriteStartObject;
            WritePropertyName('messaging_product');     WriteValue('whatsapp');
            WritePropertyName('recipient_type');        WriteValue('individual');
            WritePropertyName('to');                    WriteValue(phoneNumber);
            WritePropertyName('preview_url');           WriteValue(true);
            WritePropertyName('type');                  WriteValue('interactive');
            WritePropertyName('interactive');           WriteStartObject;
                WritePropertyName('type');              WriteValue('button');
                WritePropertyName('body');              WriteStartObject;
                    WritePropertyName('text');          WriteValue(msg);
                WriteEndObject;
                WritePropertyName('action');            WriteStartObject;
                    WritePropertyName('buttons');       WriteStartArray;

                        var i: integer;
                        for i := 0 to Length(buttons)-1 do
                        begin
                            if i >= 3 then break;                                   // max of three buttons

                            WriteStartObject;
                                WritePropertyName('type');          WriteValue('reply');            
                                WritePropertyName('reply');         WriteStartObject;
                                    WritePropertyName('title');     WriteValue(buttons[i].title);
                                    WritePropertyName('id');        WriteValue(buttons[i].id);
                                WriteEndObject;
                            WriteEndObject;
                        end;
                
                    WriteEndArray;
                WriteEndObject;
            WriteEndObject;
        WriteEndObject;
    end;

    var body := TStringStream.Create(writter.JSON.ToJSON());
    var headers: TNetHeaders := [
        TNetHeader.Create('Authorization', 'Bearer ' + token),
        TNetHeader.Create('Content-Type', 'application/json')
    ];

    try
        res := client.Post(
            'https://graph.facebook.com/v15.0/'+id+'/messages',
            body,
            nil,
            headers
        );
    except
        on E: Exception do
        begin
            Result := false;
        end;
    end;
    
    if res.StatusCode = 200 then
        Result := true
    else
        Result := false;

    body.Destroy();
    writter.Destroy();
    client.Destroy();
end;

function Tzap.sendText(phoneNumber: String; msg: String; out res: IHTTPResponse): Boolean;
begin
    var client: THTTPClient := THTTPClient.Create();

    var writter: TJsonObjectWriter := TJsonObjectWriter.Create();
    var builder: TJSONObjectBuilder := TJSONObjectBuilder.Create(writter);

    builder.BeginObject()
        .Add('messaging_product', 'whatsapp')
        .Add('recipient_type', 'individual')
        .Add('to', phoneNumber)
        .Add('type', 'text')
        .Add('preview_url', true)
        .BeginObject('text')       
            .Add('body', msg)
        .EndObject()
    .EndObject();

    var body := TStringStream.Create(writter.JSON.ToJSON());
    var headers: TNetHeaders := [
        TNetHeader.Create('Authorization', 'Bearer ' + token),
        TNetHeader.Create('Content-Type', 'application/json')
    ];

    try
        res := client.Post(
            'https://graph.facebook.com/v15.0/'+id+'/messages',
            body,
            nil,
            headers
        );
    except
        on E: Exception do
        begin
            Result := false;
        end;
    end;
    
    if res.StatusCode = 200 then
        Result := true
    else
        Result := false;

    body.Destroy();
    writter.Destroy();
    builder.Destroy();
    client.Destroy();
end;

constructor TzapBtn.Create(title: string; id: string);
begin
    Self.title := title;
    Self.id := id;
end;

constructor Tzap.Create(id: string; token: string);
begin
    inherited Create();
    self.id := id;
    self.token := token;
end;

destructor Tzap.Destroy();
begin
    inherited Destroy();
end;

end.
