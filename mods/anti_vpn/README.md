# anti_vpn

Minetest mod to block connections from known VPN egress IPs

## Usage

1. Register for a "free tier" API KEY at https://vpnapi.io/. This entitles you
   to make 1000 lookups "per day". Read their terms and conditions.

1. Install this mod into your world.

1. Add the following to your `minetest.conf` file:

   ```
   anti_vpn.provider.vpnapi.apikey = YOUR_PRIVATE_API_KEY_HERE.
   anti_vpn.provider.vpnapi.url = https://vpnapi.io
   anti_vpn.kick_text = Any extra text you want appended to the kick message.
   ```

   Also add `anti_vpn` to `secure.http_mods`.

1. Restart your Minetest server.

## Theory of Operation

The `anti_vpn` mod registers three callbacks:

1. `on_prejoinplayer` - Called before a player even authenticates. Is passed
   their username and IP address.
1. `on_playerjoin` - Called after the player is logged in and about to spawn in
   the world.
1. `after` - used to running periodic functions.

When a player prejoins, the mod instantly checks the VPN lookup cache. If the IP
address belongs to a known VPN, the prejoin is rejected. If the IP address is
unknown to the cache, then a background lookup (external http request) is
initiated, and the prejoin is allowed to proceed.

When a player joins, the same lookup is performed, and if the player's IP
address is a VPN endpoint, then the player is kicked.

When the HTTP request is finished, the cache is updated, but no players are
instantly kicked. The HTTP response can arrive before, during or after a player
has logged in, and its easier to just catch these players during the periodic
worker (via `minetest.after()`).

The periodic callback checks the IP address for each connected player, and kicks
any that map to a VPN.

## Chat Commands

Chat commands require the `staff` privilege (not registered with this mod).

- `/anti_vpn add IPV4_ADDRESS`

  Queues a lookup for the given IP address.

- `/anti_vpn cleanup`

  Initiate a background "cleanup" of the cached data. Currently, this refetches
  all IP address lookups that were missing a 'country' or 'asn' (from an earlier
  version of this mod).

- `/anti_vpn flush`

  Forcably flushes data to mod_storage, and if enabled, raw JSON text files.
  Normally the mod will flush data after each lookup. This command was added to
  aide in development/debugging.

- `/anti_vpn ip VERB LIST...`

  Apply action 'VERB' to the LIST of objects (space separated IP addresses or
  player names). If the list contains a name of a connected player, their IP
  address is used. Any other items in the LIST are ignored.

  VERBS:

  - `add` - Queue a remote lookup of each IP address from the list.

  - `del` or `delete` or `rm` - Remove cached results for each IP address in the
    list. Note that the next time a player from this IP address connects, the IP
    address will be automatically queued for a remote lookup.

  - `allow` - Allow connections from IP addresses in the list (ignore results of
    the remote lookup).

  - `deny` - Block connections from IP addresses in the list (ignore results of
    the remote lookup).

  Note: The only purpose for accepting player names with the `ip` command is to
  obtain their IP addresses. Blocking by player name is not implemented with the
  `ip` command.

- `/anti_vpn mode [NEW_MODE]`

  Reports the current operating mode, or sets it to a new value:

  - `off` - Mod is effectively disabled. No join/prejoin/async checks are
    performed, no HTTP requests are send.

  - `dryrun` - Mod performs all normal behavior, except that players are not
    actually blocked of kicked. Useful for testing the mode before "going live".

  - `enforce` - Mod performs all normal behavior, and will actively block or
    kick players who are connecting/connected from banned IPs.

- `/anti_vpn stats`

  Report some generic stats via chat. If you have any better ideas, please send
  a pull request.

  Ex: `anti_vpn stats: total: 101, blocked: 4 (3.9604%)`

## Misc

1. Check logs by looking for the string `anti_vpn`:

   `$ grep -a anti_vpn ~/.minetest/debug.log`

1. A cache of IPs is in `${WORLD}/mod_storage/anti_vpn` (JSON format).

## Manual testing.

1. Edit the `local testdata_player_ip` table near the top of `api.lua`. Add a
   test username and an IP that you would like the `anti_vpn` mod to think that
   they are coming from, even though the real network will use the real IP
   address. Ex:

   ```
   local testdata_player_ip = {
     vpn_user = '185.253.162.14',
     lan_user = '10.0.0.1',
     non_vpn_user = '67.84.231.116',
   }
   ```

1. To avoid consuming calls via your APIKEY, and you test during development by
   using a small (included) python web server that pretends to be "vpnapi.io".

   1. Create a directory called `testdata` and populate it with a few manual
      lookups. Ex:

      ```
      $ mkdir testdata
      $ export APIKEY=xxxxxxxxxxxx
      $ for IP in 1.1.1.1 8.8.8.8 185.253.162.14; do \
          wget -q -O testdata/${IP}.json \
            https://vpnapi.io/api/${IP}?key=${APIKEY}; \
        done
      ```

   1. Edit `minetest.conf`:

      1. Add `anti_vpn.provider.vpnapi.url = http://localhost:48888`.
      1. Add `anti_vpn.debug.json = true`.
      1. Add `anti_vpn` to `secure.http_mods`.

   1. Run the python script. It runs in the foreground.

   1. Edit `anti_vpn/api.lua` and add some fake user/IP mappings to
      `testdata_player_ip` (see above).

   1. Start a minetest server.

   1. Connect to the minetest server and conduct your testing.

   1. Examine JSON dump of anti_vpn's data (requires
      `anti_vpn.debug.json = true`):

      ```
      # Dump raw data:
      $ jq < ${WORLD_DIR}/anti_vpn_ip_data.json
      $ jq < ${WORLD_DIR}/anti_vpn_players.json

      # List all IPs that were detected as a VPN endpoint:
      $ jq -r 'keys[] as $k | .[$k] | select(.blocked) | $k' < \
        ${WORLD_DIR}/anti_vpn_ip_data.json

      # List all IPs that were manually entered:
      $ jq -r 'keys[] as $k | .[$k] | select(.provider == "manual") | {ip: $k, blocked: .blocked}' < \
        ${WORLD_DIR}/anti_vpn_ip_data.json
      ```
