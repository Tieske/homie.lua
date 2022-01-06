#!/usr/bin/env bash

pushd ~/code/copas || exit 1; luarocks make; popd || exit 1
pushd ~/code/luamqtt || exit 1; luarocks make; popd || exit 1
luarocks make
lua example.lua
