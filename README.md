# Homie.lua

A Homie protocol implementation for Lua. Homie is an IoT/Home Automation protocol
build on top of MQTT. For details see the [Homie spec](https://homieiot.github.io/specification/).

### Releasing a new version

 - update version in `meta.lua`
 - update copyright years if needed
 - update rockspec
 - commit as `release X.Y.Z`
 - tag as `X.Y.Z`
 - push commit and tag
 - upload to luarocks
 - test luarocks installation
