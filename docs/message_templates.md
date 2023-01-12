# [Create message templates](https://www.facebook.com/business/help/2055875911147364?id=2129163877102343)
To create message templates for your WhatsApp business account:

1. Go to [Business Manager](https://business.facebook.com/home) and select your business.
1. Click 
1. Click WhatsApp Manager.
1. Click the account that you want to create the message template for.
1. Click the 3-dot icon.
1. Click Manage message templates.
1. (Optional) If you have multiple WhatsApp business accounts, use the drop down menu to select the account where you want to create a message template.
1. Click Create message template.
1. Choose your category, name and languages:
    * Category: Choose which type of template you'd like to create. You can hover over the template types to view details for each template.
    * Name: Enter name of the template in lowercase letters, numbers, and underscores only.
    * Language: Choose which languages your message template will include. You can delete or add more languages in the next step.
1. Click Continue.
1. Add your content:
    * Add sample: (Optional) You can add a content example for your template by clicking the Add sample button. This helps us during the review and approval process, so we can understand what kind of message you plan to send. Make sure these are examples and do not include any actual user or customer information.
    * Header: (Optional) Add a title or choose which type of media you'll use for this header.
    * Body: Enter the text for your message in the language you've selected. You can edit text formats, add emojis or include variables. These allow a developer to add unique information such as specific names, locations or tracking numbers when inputting the templates into WhatsApp Business Platform.
    * Footer: (Optional) Add a short line of text to the bottom of your message template.
    * Buttons: (Optional) Select from the drop down menu to create buttons that let customers respond to your message or take action:
        * None: If you don't want to add any buttons, select this option.
        * Call to action: Create up to 2 buttons that let your customers take action. The types of action include Call phone number and Visit website. This lets you add a phone number or website URL to your message. If you choose Visit website, you can choose from a Static (fixed) website URL or a Dynamic website URL, which creates a personalized link for the customer to view their specific information on your website by adding a variable at the end of the link.
        * Quick reply: Create up to 3 buttons that let your customers respond to your message.
1. When completed, click Submit.
   
Your template will now be sent for review. The status of your template is viewable under Message templates. After your message has been approved, you can work with your developer to input your message templates into WhatsApp Business Platform account by referring to the Sending Message Templates Developer Document.

# [Variables](https://developers.facebook.com/docs/whatsapp/api/messages/message-templates#local)

Templates have parameters that are dynamically incorporated into the message. For the example used in this document, the message template looks like this:

```
You made a purchase for {{1}} using a credit card ending in {{2}}.
```

# [Reference](https://developers.facebook.com/docs/whatsapp/on-premises/reference/messages#template-object)

## Sample request

```json
{
    "messaging_product": "whatsapp",
    "recipient_type": "individual",
    "to": "5542984184379",
    "preview_url": true,
    "type": "template",
    "template": {
        // correct name for the template
        "name": "service_order",
        "language": {
            // correct language code
            "code": "pt_BR"
        },
        "components": [
            // this component holds up the body varibles, they should match the declaration {{1}}
            {
                "type": "body",
                "parameters": [
                    {
                        "type": "text",
                        "text": "Joazinho", 
                    },
                    {
                        "type": "text",
                        "text": "9374849", 
                    },
                    {
                        "type": "text",
                        "text": "conserto da pirimboca da parafuseta", 
                    }
                ]
            },
            // this component holds up the payload reference for a single button (index: "0")
            // payload will be returned in the webhook
            {
                "type": "button",
                "sub_type": "quick_reply",
                "index": "0",
                "parameters": [
                    {
                        "type": "payload",
                        "payload": "7f3d7249-fdde-45c5-89c2-d5f81d76b7c4"
                    }
                ]
            }
        ]
    }
}
```

# [Supported Languages](https://developers.facebook.com/docs/whatsapp/api/messages/message-templates#supported-languages-)

| **Language**            | **Code**                                        |
| ----------------------- | ----------------------------------------------- |
| **Afrikaans**           | af                                              |
| **Albanian**            | sq                                              |
| **Arabic**              | ar                                              |
| **Azerbaijani**         | az                                              |
| **Bengali**             | bn                                              |
| **Bulgarian**           | bg                                              |
| **Catalan**             | ca                                              |
| **Chinese (CHN)**       | zh_CN                                           |
| **Chinese (HKG)**       | zh_HK                                           |
| **Chinese (TAI)**       | zh_TW                                           |
| **Croatian**            | hr                                              |
| **Czech**               | cs                                              |
| **Danish**              | da                                              |
| **Dutch**               | nl                                              |
| **English**             | en                                              |
| **English (UK)**        | en_GB                                           |
| **English (US)**        | en_US                                           |
| **Estonian**            | et                                              |
| **Filipino**            | fil                                             |
| **Finnish**             | fi                                              |
| **French**              | fr                                              |
| **Georgian**            | ka                                              |
| **German**              | de                                              |
| **Greek**               | el                                              |
| **Gujarati**            | gu                                              |
| **Hausa**               | ha                                              |
| **Hebrew**              | he                                              |
| **Hindi**               | hi                                              |
| **Hungarian**           | hu                                              |
| **Indonesian**          | id                                              |
| **Irish**               | ga                                              |
| **Italian**             | it                                              |
| **Japanese**            | ja                                              |
| **Kannada**             | kn                                              |
| **Kazakh**              | kk                                              |
| **Kinyarwanda**         | rw_RW                                           |
| **Korean**              | ko                                              |
| **Kyrgyz (Kyrgyzstan)** | ky_KG                                           |
| **Lao**                 | lo                                              |
| **Latvian**             | lv                                              |
| **Lithuanian**          | lt                                              |
| **Macedonian**          | mk                                              |
| **Malay**               | ms                                              |
| **Malayalam**           | ml                                              |
| **Marathi**             | mr                                              |
| **Norwegian**           | nb                                              |
| **Persian**             | fa                                              |
| **Polish**              | pl                                              |
| **Portuguese (BR)**     | pt_BR                                           |
| **Portuguese (POR)**    | pt_PT                                           |
| **Punjabi**             | pa                                              |
| **Romanian**            | ro                                              |
| **Russian**             | ru                                              |
| **Serbian**             | sr                                              |
| **Slovak**              | sk                                              |
| **Slovenian**           | sl                                              |
| **Spanish**             | es                                              |
| **Spanish (ARG)**       | es_AR                                           |
| **Spanish (SPA)**       | es_ES                                           |
| **Spanish (MEX)**       | es_MX                                           |
| **Swahili**             | sw                                              |
| **Swedish**             | sv                                              |
| **Tamil**               | ta                                              |
| **Telugu**              | te                                              |
| **Thai**                | th                                              |
| **Turkish**             | tr                                              |
| **Ukrainian**           | uk                                              |
| **Urdu**                | ur                                              |
| **Uzbek**               | uz                                              |
| **Vietnamese**          | vi                                              |
| **Zulu**                | zu                                              |
