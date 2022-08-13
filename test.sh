#!/usr/bin/env bash

pushd ~/code/copas || exit 1; luarocks make; popd || exit 1
pushd ~/code/luamqtt || exit 1; luarocks make; popd || exit 1
luarocks make

# lua examples/dimmable-light.lua
# lua -e "require'copas'.debug.start()" examples/presence.lua
# lua examples/presence.lua
lua examples/millheat.lua
