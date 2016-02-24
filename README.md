# Hubot voip.ms Adapter

This basic adapter for [hubot](https://github.com/github/hubot) receives an HTTP request from voip.ms and answers back using the voip.ms API. Handy for querying hubot via SMS!  

The voip.ms adapter was largely based on [this Twilio adapter](https://github.com/mbilker/hubot-twilio) and conceived as a first hubot project.

## Hubot Setup

Once hubot is [properly set up](https://hubot.github.com/docs), the following variables need to be defined in the bin/hubot script:

```bash
export HUBOT_VOIPMS_DID=<10-digits number>            # voip.ms phone number
export HUBOT_VOIPMS_USER=<account email address>      # voip.ms user account
export HUBOT_VOIPMS_PASS=<password for api>           # voip.ms API password
export HUBOT_VOIPMS_PATH=<http path hubot listens to> # defaults to /hubot/voipms
export HUBOT_VOIPMS_SECRET=<password for hubot>       # restricts access to hubot adapter
```

NOTE: It is recommended to host hubot on a secured (HTTPS) server in order to ensure privacy and prevent SMS spoofing.

## Voip.ms Setup

The voip.ms DID should be configured with the following SMS URL Callback:

```
https://{DOMAIN}:{PORT}/{PATH}?to={TO}&from={FROM}&message={MESSAGE}&id={ID}&date={TIMESTAMP}&secret={SECRET}
```

You should replace the following tokens based on your configuration:

| Token         | Description |
|:------------- |:----------- |
| `{DOMAIN}`    | Domain where hubot is hosted. |
| `{PORT}`      | Value of the `PORT` environment variable. (normally defaults to 8080) |
| `{PATH}`      | Value of `HUBOT_VOIPMS_PATH`. |
| `{SECRET}`    | Should match the `HUBOT_VOIPMS_SECRET` variable. The secret key is optional, but recommended. |

These tokens will be automatically substituted by voip.ms:

| Token         | Description |
|:------------- |:----------- |
| `{TO}`        | Voip.ms DID number that received the message. |
| `{FROM}`      | Phone number that sent you the message. |
| `{MESSAGE}`   | Content of the message. |
| `{ID}`        | ID of the SMS message. (currently ignored) |
| `{TIMESTAMP}` | Date and time the message was received. (currently ignored) |

The `hubot-voipms` adapter expects to receive the `to`, `from` and `message` fields from the GET query above. The `{ID}` and `{TIMESTAMP}` values are currently ignored.

## Hubot Options

| Option                    | Value       | Effect      |
|:------------------------- |:-----------:|:----------- |
| `HUBOT_VOIPMS_LEADER`     | string      | Text message prefix to replace with hubot name, for quickly getting hubot's attention. |
| `HUBOT_VOIPMS_LEADER`     | `[ALWAYS]`  | Automatically prefixes every text message with hubot name, so that it may interpret every command received. |
| `HUBOT_VOIPMS_MAXLINES`   | number      | Maximum number of 140 characters SMS hubot will send out. (defaults to 3) |
| `HUBOT_VOIPMS_MAXLINES`   | `0`         | Never restrict the quantity of SMS hubot sends out as a reply. |
| `HUBOT_VOIPMS_WHITELIST`  | phone list  | Phone number(s) hubot will answer to. |
| `HUBOT_VOIPMS_WHITELIST`  | empty value | hubot will answer to any phone number that is not included in the blacklist. *(Try to avoid this or use another authentication method to restrict access to hubot)* |
| `HUBOT_VOIPMS_BLACKLIST`  | phone list  | Phone number(s) hubot will never answer to. |

A phone list is series of 10-digits phone numbers separated by a space character and excluding any sort of punctuation (ex: "8901234567 8907654321 5555555555").

## Known Limitations

* MMS are not supported as voip.ms doesn't appear to support sending them.
* As reported by voip.ms, non-latin characters may not be supported.
