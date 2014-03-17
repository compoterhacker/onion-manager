Tor Onion Manager for UnrealIRCd
=============

A simple bash script I originally wrote with an obfuscated backdoor,
but decided to fix it and make it functional(ie remove backdoor. ethics, etc.), because why 
the hell not?

The script just adds, removes, gets and lists user onions on a Tor
based UnrealIRC network. The concept of individualized onions is to enable 
the admin to only allow trusted individuals(identified by the ports they 
connect to) on the network. Breach of trust, ie leaking of a users onion,
can be easily identified and that user can be dealt with via expungement,
or, ya know, fuckyou.pl THEN expungement.

This idea isn't new by any stretch nor mine, but it's been effective in keeping meanies away, and works
especially well with a mod'd Unreal to give the admin necessary notification 
of duplicate onions on the network(remember, shit is open source for, 
well, reasons).

I'm putting this script up here because there's a lot of new/different ways of doing 
this and similar such things out there, but figured some people interested in private IRC ch@s can 
get some mileage or ideas out of it.

Also, client-side crypto is your friend.
