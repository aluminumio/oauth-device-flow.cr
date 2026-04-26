# oauth-device-flow

OAuth 2.0 Device Authorization Grant ([RFC 8628](https://datatracker.ietf.org/doc/html/rfc8628)) for Crystal CLIs. Full UX, auto-refresh, pluggable token store, zero runtime dependencies.

## Install

```yaml
# shard.yml
dependencies:
  oauth-device-flow:
    github: aluminumio/oauth-device-flow.cr
    version: ~> 0.1.0
```

```sh
shards install
```

## Use

```crystal
require "oauth-device-flow"

store = OAuth::DeviceFlow::NetrcStore.new(machine: "rightdocuments.com")
client = OAuth::DeviceFlow::Client.new(
  base_url:  "https://rightdocuments.com",
  client_id: ENV["RIGHTDOCUMENTS_CLIENT_ID"],
  store:     store,
)

client.authenticate(scope: "documents:read documents:write") unless client.authenticated?

# On every API request — auto-refreshes if expired:
HTTP::Client.get(
  "https://rightdocuments.com/api/v1/me",
  headers: HTTP::Headers{"Authorization" => "Bearer #{client.access_token}"},
)
```

## API

| Method | Returns | Behavior |
| --- | --- | --- |
| `Client#authenticate(scope)` | `Token` | Full RFC 8628 flow: request device code, open browser, poll, persist. |
| `Client#access_token` | `String` | Loads from store; auto-refreshes if expired. Raises `NotAuthenticated` if empty. |
| `Client#authenticated?` | `Bool` | True if any token is stored (no expiry check, no network). |
| `Client#refresh!` | `Token` | Force a refresh. Raises `InvalidGrant` if no refresh_token. |
| `Client#logout` | `Nil` | Clears the store. |

## Stores

- `MemoryStore` — for tests.
- `NetrcStore.new(machine:)` — `~/.netrc` adapter, `0600` permissions, preserves other entries.

To plug in your own (Keychain, libsecret, JSON file): subclass `OAuth::DeviceFlow::Store` and implement `load`, `save`, `clear`.

## Errors

All under `OAuth::DeviceFlow::Error::*`, all descend from `OAuth::DeviceFlow::Error::Base`:
`AuthorizationPending`, `SlowDown`, `AccessDenied`, `ExpiredToken`, `InvalidClient`, `InvalidGrant`, `NotAuthenticated`, `NetworkError`.

`authenticate` only surfaces `AccessDenied` (user clicked Deny) or `ExpiredToken` (timeout) for normal failures — `pending` and `slow_down` are handled internally by the polling loop.

## License

MIT
