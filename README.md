# Homie.lua

A Homie protocol implementation for Lua. Homie is an IoT/Home Automation protocol
build on top of MQTT. For details see the [Homie spec](https://homieiot.github.io/specification/).

This implementation will run on the [Copas scheduler](https://github.com/lunarmodules/copas). This
allows for running multiple devices in parallel.



# Requirements

| :exclamation:  Important compatibility notes |
|:---------------------------|
| The LuaMQTT client has some serious issues. Hence for now `luamqttt` (note the extra 't') is required |

- [LuaMQTT client](https://github.com/Tieske/luamqtt) fork
- [Copas scheduler](https://github.com/lunarmodules/copas)
- [LuaSec](https://github.com/brunoos/luasec/) required if using TLS connections
- [LuaLogging](https://github.com/lunarmodules/lualogging) optional, but strongly recommended
- [LuaBitOp] a manual dependency on Lua 5.1


### Installation

```sh
luarocks install homie
luarocks install luabitop
```



# License & copyright

See [LICENSE](https://github.com/Tieske/homie.lua/blob/main/LICENSE).



# History & changelog

### Releasing a new version

 - update version in `meta.lua`
 - update copyright years if needed (in `meta.lua` and `LICENSE`)
 - update rockspec
 - commit as `release vX.Y.Z`
 - tag as `vX.Y.Z`
 - push commit and tag
 - upload to luarocks
 - test luarocks installation

### 0.1.0 released 6-Dec-2022

- initial version
