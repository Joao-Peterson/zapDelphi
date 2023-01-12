unit Uzap;

interface

uses
    System.Classes,
    System.Generics.Collections,
    System.JSON,
    System.Net.HttpClient,
    Uzap.Types,
    UphoneNum;

type 

    // represents a whatsapp button 
    TzapBtn = record
        title:  string;
        id:     string;
        constructor Create(title: string; id: string);
    end;

    TzapComponent = class
    end;

    TzapComponentBody = class(TzapComponent)
        Fparameters: TArray<String>;
        constructor Create(parameters: TArray<String>);
        destructor Destroy(); override;
    end;

    TzapComponentButtons = class(TzapComponent)
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

    // for ease handling of the whatsapp api webhook data
    TzapWebhook = class
        class procedure processWebhook(body: TJSONObject; statusHandler: zapWebhookHandler = nil; messageHandler: zapWebhookHandler = nil; errorHandler: zapWebhookHandler = nil);
        class function getMessageType(value: TJSONValue): TzapWebhookMessage;
        class function getErrorCode(value: TJSONValue): integer;
        class function getErrorMessage(value: TJSONValue): string;
        class function getButtonsReplyTitle(value: TJSONValue): string;
        class function getButtonsReplyId(value: TJSONValue): string;
        class function getStatusType(value: TJSONValue): TzapWebhookStatus;
        class function getTextBody(value: TJSONValue): string;

        private
        class function valueType(value: TJSONObject; out data: TJSONValue): TzapWebhookValue;
    end;

    // represents a whatsapp formatted phone number
    TzapPhoneNum = class(TphoneNum)
        private
        function getZapNumber(): string;

        public
        // get whatsapp number in id form (truncated no spaces)
        property zapNumber: String read getZapNumber;
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

function TzapPhoneNum.getZapNumber(): string;
begin
    Result := Format('%d%d%d%d', [self.FcountryCode, self.FnetworkCode, self.FsubscriptionCode, self.FsubscriptionCode2]);
end;

class function TzapWebhook.getErrorCode(value: TJSONValue): integer;
begin
    if value = nil then
    begin
        Result := -1;
        exit;
    end;

    var code: integer;
    var valueCast: TJSONObject := (value as TJSONObject);

    if valueCast.TryGetValue<integer>('[0].code', code) = false then
        Result := -1
    else
        Result := code;
end;

class function TzapWebhook.getErrorMessage(value: TJSONValue): string;
begin
    if value = nil then
    begin
        Result := '';
        exit;
    end;

    var title: string;
    var valueCast: TJSONObject := (value as TJSONObject);

    if valueCast.TryGetValue<string>('[0].title', title) = false then
        Result := ''
    else
        Result := title;
end;

class function TzapWebhook.getMessageType(value: TJSONValue): TzapWebhookMessage;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := TzapWebhookMessage.unknowMessageType;
        exit;
    end; 

    var msgType: string;
    var valueCast: TJSONObject := (value as TJSONObject);
    
    if valueCast.TryGetValue<String>('type', msgType) = false then                                                          // try getting type
    begin
        Result := TzapWebhookMessage.unknowMessageType;
        exit;  
    end;

    if msgType.CompareTo('interactive') = 0 then                                                                            // interactive
    begin
        var interactiveType: string;
        
        if valueCast.TryGetValue<string>('interactive.type', interactiveType) = false then                                  // try getting interactive type
            Result := TzapWebhookMessage.unknowMessageType;
        
        if interactiveType.CompareTo('button_reply') = 0 then                                                               // buttons reply
            Result := TzapWebhookMessage.interactiveButtonsReply

        else if interactiveType.CompareTo('list_reply') = 0 then                                                            // list reply
            Result := TzapWebhookMessage.interactiveListReply
        
        else
            Result := TzapWebhookMessage.unknowMessageType;
    end

    else if msgType.CompareTo('button') = 0 then                                                                            // button type
        Result := TzapWebhookMessage.interactiveButton

    else if msgType.CompareTo('audio') = 0 then                                                                             // audio type
        Result := TzapWebhookMessage.audio

    else if msgType.CompareTo('document') = 0 then                                                                          // document type
        Result := TzapWebhookMessage.document

    else if msgType.CompareTo('text') = 0 then                                                                              // text type
        Result := TzapWebhookMessage.text

    else if msgType.CompareTo('image') = 0 then                                                                             // image type
        Result := TzapWebhookMessage.image

    else if msgType.CompareTo('sticker') = 0 then                                                                           // sticker type
        Result := TzapWebhookMessage.sticker

    else if msgType.CompareTo('video') = 0 then                                                                             // video type
        Result := TzapWebhookMessage.video

    else if msgType.CompareTo('contacts') = 0 then                                                                          // contacts type
        Result := TzapWebhookMessage.contacts

    else if msgType.CompareTo('location') = 0 then                                                                          // location type
        Result := TzapWebhookMessage.location

    else if msgType.CompareTo('unsupported') = 0 then                                                                       // futureFeature type
        Result := TzapWebhookMessage.futureFeature

    else
        Result := TzapWebhookMessage.unknowMessageType;        
end;

class function TzapWebhook.getButtonsReplyTitle(value: TJSONValue): string;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := '';
        exit;
    end; 

    var title: string;
    var valueCast: TJSONObject := (value as TJSONObject);

    if valueCast.TryGetValue<string>('interactive.button_reply.title', title) = false then
        Result := ''
    else
        Result := title;
end;

class function TzapWebhook.getButtonsReplyId(value: TJSONValue): string;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := '';
        exit;
    end; 

    var id: string;
    var valueCast: TJSONObject := (value as TJSONObject);

    if value.TryGetValue<string>('interactive.button_reply.id', id) = false then
        Result := ''
    else
        Result := id;
end;

class function TzapWebhook.getStatusType(value: TJSONValue): TzapWebhookStatus;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := TzapWebhookStatus.unknowStatusType;
        exit;
    end; 

    var status: string;
    var valueCast: TJSONObject := (value as TJSONObject);

    if valueCast.TryGetValue<string>('status', status) = false then                                                             // try get status
        Result := TzapWebhookStatus.unknowStatusType
    
    else
    begin
      
        if status.CompareTo('delivered') = 0 then                                                                           // delivered status
            Result := TzapWebhookStatus.delivered
            
        else if status.CompareTo('read') = 0 then                                                                           // read status
            Result := TzapWebhookStatus.visualized

        else if status.CompareTo('sent') = 0 then                                                                           // sent status
            Result := TzapWebhookStatus.sent

        else if status.CompareTo('failed') = 0 then                                                                           // failed status
            Result := TzapWebhookStatus.failed

        else
            Result := TzapWebhookStatus.unknowStatusType;
    end;
end;

class function TzapWebhook.getTextBody(value: TJSONValue): string;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := '';
        exit;
    end; 

    var text: string;
    var valueCast: TJSONObject := (value as TJSONObject);

    if valueCast.TryGetValue<string>('text.body', text) = false then                                                            // try getting text
        Result := ''
    else
        Result := text;
end;

class function TzapWebhook.valueType(value: TJSONObject; out data: TJSONValue): TzapWebhookValue;
begin
    if value = nil then                                                                                                     // on nil value
    begin
        Result := TzapWebhookValue.unknowValueType;
        data := nil;
        exit;
    end; 

    var valueType: TJSONValue;

    if value.TryGetValue<TJSONValue>('statuses', valueType) then
    begin
        Result := TzapWebhookValue.statuses;
        data := valueType;
    end
    else if value.TryGetValue<TJSONValue>('messages', valueType) then
    begin
        var tmp: TJSONValue;

        // check if error inside message
        if value.TryGetValue<TJSONValue>('messages.errors', tmp) then
        begin
            Result := TzapWebhookValue.errors;
            data := tmp;
        end
        else
        begin
            Result := TzapWebhookValue.messages;
            data := valueType;
        end;
    end
    else if value.TryGetValue<TJSONValue>('errors', valueType) then
    begin
        Result := TzapWebhookValue.errors;
        data := valueType;
    end
    else
    begin
        Result := TzapWebhookValue.unknowValueType;
        data := nil;
    end;
end;

class procedure TzapWebhook.processWebhook(body: TJSONObject; statusHandler: zapWebhookHandler = nil; messageHandler: zapWebhookHandler = nil; errorHandler: zapWebhookHandler = nil);
begin
    try
        var entryCount: integer;
        var changeCount: integer;
        var currentAccountId: string;
        var currentNumberId: string;
        var currentRecipientNumber: string;

        var entries: TJSONArray := body.GetValue<TJSONArray>('entry');
                                                                                                                
        for entryCount := 0 to entries.Count - 1 do                                                                         // loop over entries
        begin
            currentAccountId := 'notFound';
            currentAccountId := entries[entryCount].GetValue<string>('id');
            var changes: TJSONArray := entries[entryCount].GetValue<TJSONArray>('changes');
            
            for changeCount := 0 to changes.Count - 1 do                                                                    // loop over changes
            begin
                var value: TJSONObject := changes[changeCount].GetValue<TJSONObject>('value');                              // get a value

                currentNumberId := 'notFound';
                currentNumberId := value.GetValue<string>('metadata.phone_number_id');

                var data: TJSONValue;
                var webhookValueType: TzapWebhookValue := valueType(value, data);

                case webhookValueType of
                    TzapWebhookValue.statuses:                                                                              // depending on type
                    begin                                                                                                   // status type
                        var statusCount: integer;
                        var statuses: TJSONArray := data.AsType<TJSONArray>;
                        for statusCount := 0 to statuses.Count - 1 do
                        begin
                            if Assigned(statusHandler) then
                            begin
                                currentRecipientNumber := 'notFound';
                                currentRecipientNumber := statuses[statusCount].GetValue<string>('recipient_id');           // get recipient number
                            
                                statusHandler(
                                    currentAccountId,
                                    currentNumberId,
                                    currentRecipientNumber,
                                    webhookValueType,
                                    statuses[statusCount].AsType<TJSONValue>
                                );
                            end;
                        end;  
                    end;
                    
                    TzapWebhookValue.messages:                                                                              // message type
                    begin
                        if Assigned(messageHandler) then
                        begin
                            var messageCount: Integer;
                            var messages: TJSONArray := data.AsType<TJSONArray>;
                            for messageCount := 0 to messages.Count - 1 do
                            begin
                                currentRecipientNumber := 'notFound';
                                if value.TryGetValue<string>('contacts[0].wa_id', currentRecipientNumber) = false then      // get recipient number
                                    value.TryGetValue<string>('from', currentRecipientNumber);

                                messageHandler(
                                    currentAccountId,
                                    currentNumberId,
                                    currentRecipientNumber,
                                    webhookValueType,
                                    messages[messageCount].AsType<TJSONValue>
                                );
                            end;
                        end;
                    end;

                    TzapWebhookValue.errors:                                                                                // error type
                    begin
                        currentRecipientNumber := 'noRecipient';                                                            // get recipient number

                        if Assigned(errorHandler) then
                            errorHandler(
                                currentAccountId, 
                                currentNumberId, 
                                currentRecipientNumber, 
                                webhookValueType,
                                data.AsType<TJSONValue>
                            );
                    end;   

                    TzapWebhookValue.unknowValueType:                                                                       // if unknow type then just continue
                    begin
                        continue;
                    end;   
                end;
            end;
        end;
    except
        on E: Exception do raise Exception.Create('Error parsing webhook data');
    end;
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
