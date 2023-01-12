# Whatsapp cloud API phone number handling

# TOC
- [Whatsapp cloud API phone number handling](#whatsapp-cloud-api-phone-number-handling)
- [TOC](#toc)
- [Requirements](#requirements)
- [Manage WABA Phone Numbers](#manage-waba-phone-numbers)
  - [Add Phone Number to a WABA](#add-phone-number-to-a-waba)
  - [Delete Phone Number from a WABA](#delete-phone-number-from-a-waba)
    - [Requirements](#requirements-1)
- [Register Phone Number](#register-phone-number)
  - [Resetting Verification Code in WhatsApp Manager](#resetting-verification-code-in-whatsapp-manager)
- [Retrieve Phone Numbers](#retrieve-phone-numbers)
- [Verify Phone Numbers](#verify-phone-numbers)
  - [Request code](#request-code)
    - [Parameters](#parameters)
    - [Example](#example)
  - [Verify code](#verify-code)
    - [Example](#example-1)
- [Formatting](#formatting)


# Requirements
The phone number for your business must be a valid phone number which meets the following criteria:

* Owned by you
* Has a country and area code, such as landline and cell numbers
* Able to receive voice calls or SMS
* Not a short code
* Not previously used with the WhatsApp Business Platform

# Manage WABA Phone Numbers
## Add Phone Number to a WABA
Once you have chosen your business's phone number(s), you need to add them to your WABA. Learn more. 

If a phone number is banned by WhatsApp it cannot be added to a WABA. If you believe the phone number was banned in error, please contact support.

## Delete Phone Number from a WABA
### Requirements
* Only a business admin for the WhatsApp Business Account can delete a phone number.
* A number can not be deleted if the business has sent paid messages within the last 30 days using that number.
    * If the business has sent paid messages in the past 30 days, you will be redirected to the Insights page showing the date of the last paid message. You will be able to delete the phone number 30 days after this date.

To delete a phone number, complete the following steps:

1. In the Business Manager, go to your Business Settings page.
2. Go to Settings > Business Settings > WhatsApp Accounts > WhatsApp Manager > Phone Numbers.
3. From the WhatsApp Manager, find the phone number that you wish to delete. Click on the trash icon under Delete in the upper right.
4. You may be asked to provide the password for your Facebook account connected to the WABA if the phone number had the status “Connected” previously.

# Register Phone Number
We currently impose a **20 phone number limit across the Business Manager**, which can have multiple WABAs. Instead of 25 phone numbers per WABA, only 20 phone numbers will be allowed across all WABAs for that Business Manager for mid-trust businesses. Some legacy businesses are exempt from this limitation, and also those that have Official Business Accounts. If you want to register more than 20 phone numbers across all your WABAs, please contact direct support. You can only register your phone number on one API at a time, whether it is the WhatsApp Business Platform On-Premises API or theWhatsApp Business Platform Cloud API.

## Resetting Verification Code in WhatsApp Manager
If you forget or misplace your PIN, follow these steps to reset it in WhatsApp Manager:

1. Go to settings, log into your Facebook Business, and click the business you are using to manage your WABA (WhatsApp Business Account)
1. In the settings screen, click WhatApp Accounts and find the WABA you want to reset the verification code for. Click on the WABA and a panel with its respective info will come up on the right-side of the page
1. In the WABA information module, click Settings
1. In the new tab, click WhatsApp Manager
1. In WhatsApp Manager, find your phone number and click Settings
1. Click Two-step verification
1. In the Two-step verification tab, click Turn off two-step verification. A message with instructions will be sent to your email address
1. Your two-step verification code is now removed and depending on your platform, you can set it using one of these APIs:
    * Set up PIN using the On-Premises API
    * Set up PIN using the Cloud API

# Retrieve Phone Numbers

To get a list of all phone numbers associated with a WhatsApp Business Account, send a GET request to the `/{whatsapp-business-account-id}/phone_numbers endpoint`.

Sample Request
Formatted for readability.
```console
curl -X GET "https://graph.facebook.com/v15.0/{whatsapp-business-account-id}/phone_numbers
      ?access_token={system-user-access-token}"
```

On success, a JSON object is returned with a list of all the business names, phone numbers, phone number IDs, and quality ratings associated with a business.

```json
{
  "data": [
    {
      "verified_name": "Jasper's Market",
      "display_phone_number": "+1 631-555-5555",
      "id": "1906385232743451",
      "quality_rating": "GREEN"
      
    },
    {
      "verified_name": "Jasper's Ice Cream",
      "display_phone_number": "+1 631-555-5556",
      "id": "1913623884432103",
      "quality_rating": "NA"
    }
  ],
}
```

# Verify Phone Numbers
You need to verify the phone number you want to use to send messages to your customers. Phone numbers must be verified using a code sent via an SMS/voice call. The verification process can be done via Graph API calls specified below.

To verify a phone number using Graph API, make a POST request to `PHONE_NUMBER_ID/request_code`. In your call, include your chosen verification method and language.

| Endpoint                                                        | Authentication |
| --------------------------------------------------------------- | -------------- |
| /PHONE_NUMBER_ID/request_code <br>([See Get Phone Number ID]()) | Authenticate yourself with a system user access token.If you are requesting the code on behalf of another business, the access token needs to have Advanced Access to the whatsapp_business_management permission. |

## Request code

### Parameters

| Name          | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `code_method` | `SMS` or `VOICE`                                                    |
| `language`    | The language's two-character language code code. For example: `en`. |

### Example
Sample request:

```console
curl -X POST \
  'https://graph.facebook.com/v15.0/FROM_PHONE_NUMBER_ID/request_code' \
  -H 'Authorization: Bearer ACCESS_TOKEN' \
  -F 'code_method=SMS' \
  -F 'language=en'
```

## Verify code

After the API call, you will receive your verification code via the method you selected. To finish the verification process, include your code in a POST request to `PHONE_NUMBER_ID/verify_code`.

| Endpoint | Authentication                                                          |
| -------- | ----------------------------------------------------------------------- |
| `code`   | The code you received after calling `FROM_PHONE_NUMBER_ID/request_code` |

### Example
Sample request:

```console
curl -X POST \
  'https://graph.facebook.com/v15.0/FROM_PHONE_NUMBER_ID/verify_code' \
  -H 'Authorization: Bearer ACCESS_TOKEN' \
  -F 'code=000000'
```
A successful response looks like this:

```json
{
  "success": true
}
```

# Formatting
The phone numbers in Cloud API requests can be provided in any dialable format, as long as they include their country code.

Here are some examples of supported phone number formats:

* `"1-000-000-0000"`
* `"1 (000) 000-0000"`
* `"1 000 000 0000"`
* `"1 (000) 000 0000"`