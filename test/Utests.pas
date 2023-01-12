unit Utests;

interface

uses
    Dunitx.TestFramework;

type

    // remember to copy the config.ini file to where the test.exe executable is !
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

implementation

uses
    System.Classes,
    System.SysUtils,
    System.IOUtils,
    System.IniFiles,
    System.Net.HttpClient,
    Uzap,
    Uzap.Types,
    UphoneNum;

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
end.
