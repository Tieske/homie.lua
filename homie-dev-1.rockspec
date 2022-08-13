local package_name = "homie"
local package_version = "dev"
local rockspec_revision = "1"
local github_account_name = "Tieske"
local github_repo_name = "homie.lua"


package = package_name
version = package_version.."-"..rockspec_revision
source = {
   url = "git://github.com/"..github_account_name.."/"..github_repo_name..".git",
   branch = (package_version == "cvs") and "master" or nil,
   tag = (package_version ~= "cvs") and package_version or nil,
}
description = {
   summary = "Homie (an MQTT convention for IoT/M2M) implementation in Lua",
   detailed = [[
      Homie.lua provides a Lua based Homie implementation for devices and
      controllers.
   ]],
   license = "MIT/X11",
   homepage = "https://github.com/"..github_account_name.."/"..github_repo_name,
}
dependencies = {
   "lua >= 5.1, < 5.4",
   "copas >= 3.0",
   "luamqtt",
   "lualogging >= 1.6",
}
build = {
   type = "builtin",
   modules = {
      ["homie.meta"] = "src/homie/meta.lua",
      ["homie.utils"] = "src/homie/utils.lua",
      ["homie.device"] = "src/homie/device.lua",
      ["homie.controller"] = "src/homie/controller.lua",
   },
   copy_directories = {
      "docs",
   },
}
