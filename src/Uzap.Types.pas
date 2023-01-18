unit Uzap.Types;

interface

uses
    System.JSON,
    UphoneNum;

type
    // enum for type of value
    TzapWebhookValue = (
        unknowValueType = 0,
        statuses,
        messages,
        errors
    );

    // handler function for the webhook parser
    zapWebhookHandler = procedure(accountId: string; numberId: string; recipientNumber: string; valueType: TzapWebhookValue; value: TJSONValue);

    // enum for message types. Remember to tosubscribe to the correct events on the meta developer webhook page, otherwise some events will not be received
    TzapWebhookMessage = (
        unknowMessageType = 0,
        interactiveButtonsReply,
        interactiveListReply,
        button,
        audio,
        document,
        text,
        image,
        sticker,
        video,
        contacts,
        location,
        futureFeature
    );

    // enum for status types. Remember to subscribe to the correct events on the meta developer webhook page, otherwise some events will not be received 
    TzapWebhookStatus = (
        unknowStatusType = 0,
        sent,
        delivered,
        visualized,
        failed
    );

    // list of supported whatsapp locales. Ref: <https://developers.facebook.com/docs/whatsapp/api/messages/message-templates#supported-languages->
    TzapLocale = (
        af  = 0,
        sq,ar,az,bn,bg,ca,zh_CN,zh_HK,zh_TW,hr,cs,da,nl,en,en_GB,en_US,et,fil,fi,fr,ka,de,el,
        gu,ha,he,hi,hu,id,ga,it,ja,kn,kk,rw_RW,ko,ky_KG,lo,lv,lt,mk,ms,ml,mr,nb,fa,pl,pt_BR,
        Tpt_P,pa,ro,ru,sr,sk,sl,es,es_AR,es_ES,es_MX,sw,sv,ta,te,th,tr,uk,ur,uz,vi,zu
    );

    // represents a whatsapp formatted phone number
    TzapPhoneNum = class(TphoneNum)
        private
        function getZapNumber(): string;

        public
        // get whatsapp number in id form (truncated no spaces)
        property zapNumber: String read getZapNumber;
    end;

    // get locale as string
    function zapLocaleToString(locale: TzapLocale): String;

implementation

uses
    System.Classes,
    System.SysUtils,
    System.TypInfo;

function zapLocaleToString(locale: TzapLocale): String;
begin
    Result := GetEnumName(TypeInfo(TzapLocale), Integer(locale));
end;

function TzapPhoneNum.getZapNumber(): string;
begin
    Result := Format('%d%d%d%d', [self.FcountryCode, self.FnetworkCode, self.FsubscriptionCode, self.FsubscriptionCode2]);
end;

end.