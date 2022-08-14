# Homie.lua

A Homie protocol implementation for Lua. Homie is an IoT/Home Automation protocol
build on top of MQTT. For details see the [Homie spec](https://homieiot.github.io/specification/).

This implementation will run on the [Copas scheduler](https://github.com/lunarmodules/copas). This
allows for running multiple devices in parallel.



# Requirements

| :exclamation:  Important compatibility notes |
|:---------------------------|
| The LuaMQTT client has some serious issues. Hence for now [this branch](https://github.com/Tieske/luamqtt/tree/keepalive) is required, until the [related PR](https://github.com/xHasKx/luamqtt/pull/31) gets merged. |

- [LuaMQTT client](https://github.com/xHasKx/luamqtt)
- [Copas scheduler](https://github.com/lunarmodules/copas)
- [LuaSec](https://github.com/brunoos/luasec/) required if using TLS connections
- [LuaLogging](https://github.com/lunarmodules/lualogging) optional, but strongly recommended



### Installation

```sh
luarocks install tieske/luamqtt --dev
luarocks install homie
```



# License & copyright

See [LICENSE](https://github.com/Tieske/homie.lua/blob/main/LICENSE).



# History & changelog

### Releasing a new version

 - update version in `meta.lua`
 - update copyright years if needed (in `meta.lua` and `LICENSE`)
 - update rockspec
 - commit as `release X.Y.Z`
 - tag as `X.Y.Z`
 - push commit and tag
 - upload to luarocks
 - test luarocks installation

### 0.1.0 released [xx/xxx/2022]

- initial version
