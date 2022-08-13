-- TODO: implement a controller

-- local mqtt = require "luamqtt"
-- local log = require("lualogging").defaultLogger()

local Controller = {}
Controller.__index = Controller
require("homie.meta")(Controller)

--- Instantiate a new controller.
-- @tparam table[opt={}] opts Options table to create the instance from.
-- @return new controller object.
function Controller.new(opts, empty)
  if empty ~= nil then error("do not call 'new' with colon-notation", 2) end
  local self = opts or {}
  assert(type(self) == "table", "expected table, got: ".. type(self))
  setmetatable(self, Controller)
  self.super = Controller
  self:__init()
  return self
end

--- Initializer, called upon instantiation.
function Controller:__init()
  local bt = self.base_topic
  bt = bt or "homie/"
  assert(type(bt) == "string", "expected 'base_topic' to be a string")
  if bt:sub(-1,-1) ~= "/" then
    bt = bt .. "/"
  end
  self.base_topic = bt
end

function Controller:start()
end

function Controller:stop()
end


return Controller
