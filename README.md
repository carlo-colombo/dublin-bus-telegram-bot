# DublinBusTelegramBot

Welcome to the Dublin Bus bot:

Access to the *Real Time Passenger Information (RTPI)* for Dublin Bus services. Data are retrieved parsing the still-in-development RTPI site. The html could change without notice and break the API, we don't take any responsibility for missed bus. The bot is precise as the dublin bus application or the screen at the stops.

_This service is in no way affiliated with Dublin Bus or the providers of the RTPI service_.

### Available commands

#### /stop <stop number>
Retrieve upcoming timetable at this stop
``` /stop 4242```

#### /watch <stop number> <line>
Send you a message every minute with ETA of the bus at the stop. It stop after the bus is Due or until command unwatch is sent. Only one watch at time is possible.
``` /watch 4242 184```

#### /unwatch
Stop watch
``` /unwatch ```

#### /search <query>
Search stops that match the name, if only one result is found it send also the timetable.
``` /search Townsend Street```

#### /info
Return some info about the bot
``` /info ```


### Docker

    docker run --rm -P -e 'TELEGRAM_BOT_TOKEN=<your-token-here>' carlocolombo/dublin_bus_telegram_bot
