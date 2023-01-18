unit Utests;

interface

uses
    Dunitx.TestFramework;

type

    // remember to copy the config.ini file to where the test.exe executable is !
    [Ignore('Disabled to not spam messages. Comment this out to enable message send testing')]
    [TestFixture]
    TzapTest = class
        [Test]
        procedure zapSendTemplate();

        [Test]
        procedure zapSendSimple();

        [Test]
        [TestCase('Case 0: +55 49 95769-8674',  '+55 49 95769-8674,5549957698674,1')]
        [TestCase('Case 1: 55 49 95769-8674',   '55 49 95769-8674,5549957698674,1')]
        [TestCase('Case 2: 55 (49) 95769-8674', '55 (49) 95769-8674,5549957698674,1')]
        [TestCase('Case 3: 55 049 95769-8674',  '55 049 95769-8674,5549957698674,1')]
        [TestCase('Case 4: 55 049 957698674',   '55 049 957698674,5549957698674,1')]
        [TestCase('Case 5: 55049957698674',     '55049957698674,5549957698674,1')]
        [TestCase('Case 6: 49 95769-8674',      '49 95769-8674,5549957698674,1')]
        [TestCase('Case 7: 49 95769-8674',      '49 95769-8674,5549957698674,1')]
        [TestCase('Case 8: (49) 95769-8674',    '(49) 95769-8674,5549957698674,1')]
        [TestCase('Case 9: 049 95769-8674',     '049 95769-8674,5549957698674,1')]
        [TestCase('Case 10: 049 957698674',     '049 957698674,5549957698674,1')]
        [TestCase('Case 11: 049957698674',      '049957698674,5549957698674,1')]
        [TestCase('Case 12: 49 5769-8674',      '49 5769-8674,5549957698674,1')]
        [TestCase('Case 13: 49 5769-8674',      '49 5769-8674,5549957698674,1')]
        [TestCase('Case 14: (49) 5769-8674',    '(49) 5769-8674,5549957698674,1')]
        [TestCase('Case 15: 049 5769-8674',     '049 5769-8674,5549957698674,1')]
        [TestCase('Case 16: 049 57698674',      '049 57698674,5549957698674,1')]
        [TestCase('Case 17: 04957698674',       '04957698674,5549957698674,1')]
        [TestCase('Case 18: 554284184379',      '554284184379,5542984184379,1')]
        [TestCase('Case 18: 5542984184379',     '5542984184379,5542984184379,1')]
        procedure zapPhoneNumTest(phone: string; expectedFull: string; shouldPass: Integer);
    end;

    [TestFixture]
    TzapWebhookTest = class
        [Test]
        [TestCase('Case 0: interactiveButtonReply', '../../files/interactiveButtonReply.json,Teste,8151fb8e-bb51-443c-a2a6-23c73c56a7da')]
        [TestCase('Case 1: buttonReply',            '../../files/buttonReply.json,Teste,8151fb8e-bb51-443c-a2a6-23c73c56a7da')]
        procedure zapWebhookButtonsReply(testFile: string; expectedTitle: string; expectedId: string);
    end;

implementation

uses
    System.Classes,
    System.SysUtils,
    System.IOUtils,
    System.IniFiles,
    System.Net.HttpClient,
    Uzap,
    Uzap.Webhook,
    Uzap.Types,
    System.JSON,
    UphoneNum;

var
    buttonReplyId: string;
    buttonReplyTitle: string;

procedure webhookButtonReplyHandler(accountId: string; numberId: string; recipientNumber: string; valueType: TzapWebhookValue; value: TJSONValue);
begin
    var mt := TzapWebhook.getMessageType(value);

    if(
        (mt = TzapWebhookMessage.interactiveButtonsReply) or 
        (mt = TzapWebhookMessage.button)
    ) then
    begin
        buttonReplyId    := TzapWebhook.getButtonsReplyId(value);
        buttonReplyTitle := TzapWebhook.getButtonsReplyTitle(value);
    end
    else
    begin
        buttonReplyId    := '';
        buttonReplyTitle := '';
    end;
end;

procedure TzapWebhookTest.zapWebhookButtonsReply(testFile: string; expectedTitle: string; expectedId: string);
begin
    var jsonText := TFile.ReadAllText(testFile);
    var json: TJSONObject := TJSONObject.ParseJSONValue(jsonText) as TJSONObject;

    try
        TzapWebhook.processWebhook(
            json,
            nil,
            webhookButtonReplyHandler,
            nil
        );

        Assert.AreEqual(expectedId, buttonReplyId, 'buttonReplyId');
        Assert.AreEqual(expectedTitle, buttonReplyTitle, 'buttonReplyTitle');

        json.Destroy();
    except
        on E: Exception do raise;
    end;
end;

procedure TzapTest.zapSendSimple();
begin
    var config: TIniFile;
    try
        config := TIniFile.Create('./config.ini');
    except 
        on E: Exception do raise;
    end;

    try
        var token                := config.ReadString('api', 'token', '');
        var webhookToken         := config.ReadString('api', 'webhookToken', '');
        var phoneid              := config.ReadString('api', 'phoneid', '');
        var businessAccountid    := config.ReadString('api', 'businessAccountid', '');
        var notificationTemplate := config.ReadString('api', 'notificationTemplate', '');
        var receiveNumber        := config.ReadString('data', 'receiveNumber', '');
        
        var zap := Tzap.Create(phoneid, token);
        var res: IHTTPResponse;
        var status := zap.sendText(
            receiveNumber,
            'hello there!',
            res
        );

        WriteLn(res.ContentAsString());

        zap.Destroy();
        config.Destroy();

        Assert.AreEqual(true, status);
    except
        on E: Exception do 
        begin
            raise;
        end;
    end;  
end;

procedure TzapTest.zapSendTemplate();
begin
    var config: TIniFile;
    try
        config := TIniFile.Create('./config.ini');
    except 
        on E: Exception do raise;
    end;

    try
        var token                := config.ReadString('api', 'token', '');
        var webhookToken         := config.ReadString('api', 'webhookToken', '');
        var phoneid              := config.ReadString('api', 'phoneid', '');
        var businessAccountid    := config.ReadString('api', 'businessAccountid', '');
        var notificationTemplate := config.ReadString('api', 'notificationTemplate', '');
        var receiveNumber        := config.ReadString('data', 'receiveNumber', '');
        
        var zap := Tzap.Create(phoneid, token);
        var res: IHTTPResponse;
        var status := zap.sendTemplate(
            receiveNumber,
            notificationTemplate,
            TzapLocale.pt_BR,
            TzapComponentBody.Create([
                'ze ninguem',
                '0880',
                'troca de oleo'
            ]),
            TzapComponentButtons.Create([
                '4f935d07-e344-4935-a81e-ac269c97d87c'
            ]),
            res
        );

        WriteLn(res.ContentAsString());

        zap.Destroy();
        config.Destroy();

        Assert.AreEqual(true, status);
    except
        on E: Exception do 
        begin
            raise;
        end;
    end;
end;

procedure TzapTest.zapPhoneNumTest(phone: string; expectedFull: string; shouldPass: Integer);
begin
    var p: TzapPhoneNum; 
    try
        p := TzapPhoneNum.CreateFromBrazil(phone);
    except
        on E: Exception do raise;
    end;

    if shouldPass = 1 then
    begin
        Assert.AreEqual(expectedFull, p.zapNumber, 'expectedFullStringNumber');
    end
    else
    begin
        Assert.AreNotEqual(expectedFull, p.zapNumber, 'expectedFullStringNumber');
    end;
end;

initialization
    TDUnitX.RegisterTestFixture(TzapTest);
    TDUnitX.RegisterTestFixture(TzapWebhookTest);
end.
