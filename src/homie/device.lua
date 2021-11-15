local mqtt = require "mqtt"
local stringx = require "pl.stringx"
local utils = require "pl.utils"
local log = require("logging").defaultLogger()

-- Node implementation ---------------------------------------------------------
local Node = {}
Node.__index = Node

-- Topic implementation --------------------------------------------------------
local Property = {}
Property.__index = Property

--- Gets the current value.
-- @return the (unpacked) value
function Property:get()
  return self.value
end


--- Called when remotely setting the value.
-- Executes: unpack, validate, set, in that order.
-- Logs an error if something is wrong, and doesn't change the value in that case.
-- @param pvalue string, the packed value as received.
-- @return nothing
function Property:rset(pvalue)
  if not self.settable then
    log:error("setting a non-settable property '%s/%s/%'",
            self.device.base_topic, self.node.id, self.id)
    return nil, "property is not settable"
  end

  -- TODO: if prop is non-retained ignore incoming values while the device is still in "init" phase
  -- How about after reconnecting?

  local value, err = self:unpack(pvalue)
  if err then -- note: check err, not value!
    log:warn("remote device tried setting '%s/%s/%' with a bad value that failed unpacking: %s",
            self.device.base_topic, self.node.id, self.id, err)
    return nil, "bad value"
  end

  local ok, err = self:validate(value)
  if not ok then
    log:warn("remote device tried setting '%s/%s/%' with a bad value: %s",
            self.device.base_topic, self.node.id, self.id, err)
    return nil, "bad value"
  end
  self:set(value)
end


do
  local unpackers
  unpackers = {
    string = function(prop, value)
      return value
    end,

    integer = function(prop, value)
      if not value:match("^%-?%d+$") then
        return nil, "bad integer value"
      end
      return tonumber(value)
    end,

    float = function(prop, value)
      if value:match("^%-?[0-9%.e]+$") then
        local v = tonumber(value)
        if v then
          return v
        end
      end
      return nil, "bad float value"
    end,

    percent = function(prop, value)
      local v = unpackers.float(prop, value)
      if not v then
        return nil, "bad percent value"
      end
      return v
    end,

    boolean = function(prop, value)
      if value == "true" or value == "false" then
        return value == "true"
      end
      return nil, "bad boolean value"
    end,

    enum = function(prop, value)
      return value
    end,

    color = function(prop, value)
      local v = { value:match("^(%d+),(%d+),(%d+)$") }
      if not v[1] then
        return nil, "bad color value"
      end
      if prop.format == "hsv" then
        return { h = v[1], s = v[2], v = v[3] }
      else
        return { r = v[1], g = v[2], b = v[3] }
      end
    end,

    datetime = function(prop, value)
      -- TODO: implement
    end,

    duration = function(prop, value)
      -- TODO: implement
    end,
  }
  --- deserializes a received value.
  -- override in case of deserialization needs.
  -- NOTE: check return values!! nil is a valid value, so check 2nd return value for errors.
  -- @param value string value to unpack/deserialize
  -- @return any type of value (including nil), returns an error string as second value in case of errors.
  function Property:unpack(value)
    return unpackers[self.datatype](value)
  end
end


do
  local validators
  validators = {
    string = function(prop, value)
      local ok = type(value) == "string"
      return ok, not ok and "value is not of type string" or nil
    end,

    integer = function(prop, value)
      local ok = type(value) == "number" and math.floor(value) == value
      return ok, not ok and "value is not an integer number" or nil
    end,

    float = function(prop, value)
      local ok = type(value) == "number"
      return ok, not ok and "value is not of type number" or nil
    end,

    percent = function(prop, value)
      local ok = type(value) == "number"
      return ok, not ok and "value is not of type number" or nil
    end,

    boolean = function(prop, value)
      return true
    end,

    enum = function(prop, value)
      if type(value) ~= "string" or value == "" or value:find(",") then
        return false, "value must be a non-empty string, and may not contain ','"
      end
      if (","..prop.format..","):find(","..value..",", 1, true) then
        return true
      end
      return false, "value not found in enum list: " .. prop.format
    end,

    color = function(prop, value)
      if type(value) ~= "table" then
        return false, "value must be a table type"
      end
      local v
      if prop.format == "hsv" then
        v = { value.h, value.s, value.v }
      else
        v = { value.r, value.g, value.b }
      end
      if type(v[1]) ~= "number" or type(v[2]) ~= "number" or type(v[3]) ~= "number" or
         math.floor(v[1]) ~= v[1] or math.floor(v[2]) ~= v[2] or math.floor(v[3]) ~= v[3] then
        return false, "individual color values must be integer number type"
      end
      if prop.format == "hsv" then
        if v[1] < 0 or v[1] > 360 then
          return false, "hsv value h must be from 0 to 360"
        end
        if v[2] < 0 or v[2] > 100 or v[3] < 0 or v[3] > 100 then
          return false, "hsv values s and v must be from 0 to 100"
        end
      else
        if v[1] < 0 or v[1] > 255 or v[2] < 0 or v[2] > 255 or v[3] < 0 or v[3] > 255 then
          return false, "rgb values must be from 0 to 255"
        end
      end
      return true
    end,

    datetime = function(prop, value)
      -- TODO: implement
    end,

    duration = function(prop, value)
      -- TODO: implement
    end,
  }

  --- Checks an (unpacked) value. Base implementation
  -- only checks format. Override for more validation checks.
  -- @param value the (unpacked) value to validate
  -- @retrun true if ok, nil+err if not.
  function Property:validate(value)
    return validators[self.datatype](value)
  end
end


--- Local application code can set a value through this method.
-- Default just calls `update`. Implement actual changing device behaviour here
-- by overriding. When overriding, it should always end by calling `update`.
-- @param value the (unpacked) value to set
-- @return nothing
function Property:set(value)
  self:update(value)
end


do
  local packers
  packers = {
    string = function(prop, value)
      return value
    end,

    integer = function(prop, value)
      return tostring(value)
    end,

    float = function(prop, value)
      return tostring(value)
    end,

    percent = function(prop, value)
      return tostring(value)
    end,

    boolean = function(prop, value)
      return tostring(not not value)
    end,

    enum = function(prop, value)
      return value
    end,

    color = function(prop, value)
      return prop.format == "hsv" and
        ("%d,%d,%d"):format(value.h, value.s, value.v) or
        ("%d,%d,%d"):format(value.r, value.g, value.b)
    end,

    datetime = function(prop, value)
      -- TODO: implement
    end,

    duration = function(prop, value)
      -- TODO: implement
    end,
  }
  --- serializes a received value.
  -- override in case of deserialization needs
  -- @param value the unpacked value to be serialized into a string
  -- @return packed value (string), or nil+err on failure
  function Property:pack(value)
    return packers[self.datatype](value)
  end
end


--- Compares 2 (unpacked) values for equality. If old and new values are equal,
-- no updates need to be transmitted. If values are unpacked into complex structures
-- override this to check for equality.
-- @param value1 the (unpacked) value to compare with the 2nd
-- @param value2 the (unpacked) value to compare with the 1st
-- @return boolean
function Property:values_same(value1, value2)
  if type(value1) == type(value2) then
    return value1 == value2
  else
    return false
  end
end

-- update(value) validates and updates local .value and send mqtt message. No need to
-- override. Throws an error if either validation or packing fails.
-- @param value the new (unpacked) value to set
-- @return nothing
function Property:update(value)
  assert(self:validate(value))
  if self:values_same(value, self.value) then
    return -- no need for updates
  end

  local pvalue = assert(self:pack(value))
  self.value = value

  -- craft mqtt packet and send it
  self.device:send_property_update(self, pvalue)
end


-- Device implementation -------------------------------------------------------
local Device = {}
Device.__index = Device
require("homie.meta")(Device)

log:info("loaded homie.lua library; Device (version %s)", Device._VERSION)

-- device states enumeration
Device.states = setmetatable({
  init = "init",
  ready = "ready",
  disconnected = "disconnected",
  sleeping = "sleeping",
  lost = "lost",
  alert = "alert",
}, {
  __index = function(self, key)
    error("'"..tostring(key).."' is not a valid device-state")
  end,
})

Device.datatypes = {
  string = "string",
  integer = "integer",
  float = "float",
  percent = "percent",
  boolean = "boolean",
  enum = "enum",
  color = "color",
  datetime = "datetime",
  duration = "duration",
}

-- validate homie topic segment
-- @param segment string the segment to validate
-- @param attrib if truthy then validate it as a attribute, starting with a $
-- @return valid segment, or nil+err
local function validate_segment(segment, attrib)
  if type(segment) ~= "string" then
    return nil, "expected sgement to be a string"
  end
  local t = segment
  if attrib then
    if t:sub(1,1) ~= "$" then
      return nil, "attributes must start with a '$'"
    end
    t = t:sub(2,-1)
  end
  if t:match("^[a-z0-9]+[a-z0-9%-]*$") and t:sub(-1,-1) ~= "-" then
    return segment
  end
  return nil, ("invalid Homie topic segment; '%s', only: a-z, 0-9 and '-' (not start nor end with '-')"):format(segment)
end

-- validates a broadcast topic, and fully qualifies it.
-- @param self the device object
-- @param topic
-- @return the fully qualified topic, or nil+err
local function validate_broadcast_topic(self, topic)
  if topic:find("/$broadcast/", 1, true) then
    -- is fully qualified, so must match domain
    local start = self.domain.."/$broadcast/"
    if topic:sub(1, #start) ~= start then
      return nil, ("broadcast topic '%s' doesn't match device domain '%s/$broadcast/'"):format(topic, self.domain)
    end
    return topic
  end

  -- relative, so prefix with domain
  if topic:sub(1,1) == "/" then
    return self.domain.."/$broadcast" .. topic
  end
  return self.domain.."/$broadcast/" .. topic
end

-- wraps a broadcast handler function.
-- does the acknowledge, calls the handler while injuecting 'self' (the device).
local function create_broadcast_handler(device, handler)
  return function(msg, mqttclient)
    assert(mqttclient == device.mqtt, "mqtt client instance mismatch!")
    local ok, err = mqttclient:acknowledge(msg)
    if not ok then
      log:error("failed to acknowledge broadcast message: %s", err)
    end
    return handler(device, msg, mqttclient)
  end
end

-- validates a single property
-- @param datatype string, data-type, MUST be valid, not validated here
-- @param format string the format string to validate for the datatype
-- @return format string, or nil + err
local function validate_format(datatype, format)
  if type(format) ~= "string" then
    return nil, "expected `property.format` to be a string"
  end

  -- we're also allowing percent dattype here
  if datatype == "integer" or datatype == "float" or datatype == "percent" then
    local min, max = utils.splitv(format, ":", 2)
    if not min or not max then
      return nil, "bad min:max format specified"
    end
    local min = tonumber(min)
    if not min then
      return nil, "bad min:max format specified"
    end
    local max = tonumber(max)
    if not max then
      return nil, "bad min:max format specified"
    end
    if min > max then
      return nil, "bad min:max format specified"
    end

  elseif datatype == "enum" then
    local enum = stringx.split(format, ",")
    for i, val in ipairs(enum) do
      if val == "" then
        return nil, "enum format cannot have empty strings"
      end
      if stringx.strip(val) ~= val then
        return nil, "enum format cannot have leading/trailing whitespace"
      end
    end


  elseif datatype == "color" then
    if format ~= "hsv" and format ~= "rgb" then
      return nil, ("format '%s' is not valid for datatype '%s'"):format(format, datatype)
    end

  else
    return nil, ("format '%s' is not valid for datatype '%s'"):format(format, datatype)
  end

  return format
end

-- validates a single property
-- @param prop property table to verify
-- @return property table, or nil + err
local function validate_property(prop)
  if type(prop) ~= "table" then
    return nil, "expected 'property' to be a table"
  end

  if type(prop.name) ~= "string" or #prop.name < 1 then
    return nil, "expected `property.name` to be a string of at least 1 character"
  end

  if type(prop.datatype) ~= "string" or Device.datatypes[prop.datatype] == nil then
    return nil, "expected `property.datatype` to be a string and a valid datatype"
  end

  if prop.settable ~= nil then
    if type(prop.settable) ~= "boolean" then
      return nil, "expected `property.settable` to be a boolean if given"
    end
  else
    prop.settable = false
  end

  if prop.retained ~= nil then
    if type(prop.retained) ~= "boolean" then
      return nil, "expected `property.retained` to be a boolean if given"
    end
  else
    prop.retained = true
  end

  if prop.unit ~= nil then
    if type(prop.unit) ~= "string" or #prop.unit < 1 then
      return nil, "expected `property.unit` to be a string of at least 1 character if given"
    end
  end

  if prop.format ~= nil then
    local ok, err = validate_format(prop.datatype, prop.format)
    if not ok then
      return nil, err
    end
  end

  -- percent special case
  if prop.datatype == "percent" then
    if prop.unit == nil then
      prop.unit = "%"
    else
      if prop.unit ~= "%" then
        return nil, "expected `property.unit` to be a string for datatype 'percent', if given"
      end
    end
  end

  for key in pairs(prop) do
    if not ({
        name = true,
        datatype = true,
        settable = true,
        retained = true,
        format = true,
        unit = true,
        id = true,
        node = true,
        device = true,
        topic = true,
        super = true,
      })[key] then
      return nil, "property contains unknown key '" .. tostring(key) .. "'"
    end
  end

  return prop
end


-- validates a properties table
-- @param props hashtable, property table by property-id
-- @return properties table or nil+err
local function validate_properties(props, node, device)
  if type(props) ~= "table" then
    return nil, "expected 'properties' to be a table"
  end

  for propid, prop in pairs(props) do
    local ok, err
    ok, err = validate_segment(propid)
    if not ok then
      return nil, "bad property-id: " .. err
    end

    if type(prop) ~= "table" then
      return nil, "expected 'property' to be a table"
    end

    -- add the id, node and device, create topic, and make an object of type Property
    prop.id = propid
    prop.node = assert(node, "node parameter is missing")
    prop.device = assert(device, "device parameter is missing")
    prop.topic = device.base_topic .. "/" .. node.id .. "/" .. propid
    setmetatable(prop, Property)
    prop.super = Property

    ok, err = validate_property(prop)
    if not ok then
      return nil, "bad property '" .. propid .. "': " .. err
    end
  end

  return props
end


-- validates a single node
-- @param node node table to verify
-- @return node, or nil + err
local function validate_node(node, device)
  if type(node) ~= "table" then
    return nil, "expected 'node' to be a table"
  end

  if type(node.name) ~= "string" or #node.name < 1 then
    return nil, "expected `node.name` to be a string of at least 1 character"
  end

  if type(node.type) ~= "string" or #node.type < 1 then
    return nil, "expected `node.type` to be a string of at least 1 character"
  end

  if type(node.properties) ~= "table" then
    return nil, "expected `node.properties` to be a table"
  end

  local ok, err = validate_properties(node.properties, node, device)
  if not ok then
    return nil, err
  end

  for key in pairs(node) do
    if not ({
        name = true,
        type = true,
        properties = true,
        id = true,
        device = true,
        super = true,
      })[key] then
      return nil, "node contains unknown key '" .. tostring(key) .. "'"
    end
  end

  return node
end


-- validates a nodes table
-- @param nodes hashtable, nodes table by nodeid
-- @return nodes table or nil+err
local function validate_nodes(nodes, device)
  if type(nodes) ~= "table" then
    return nil, "expected 'nodes' to be a table"
  end

  for nodeid, node in pairs(nodes) do
    local ok, err
    ok, err = validate_segment(nodeid)
    if not ok then
      return nil, "bad nodeid: " .. err
    end

    if type(node) ~= "table" then
      return nil, "expected 'node' to be a table"
    end

    -- add the id and device, make an object of type Node
    node.id = nodeid
    node.device = assert(device, "device parameter is missing")
    setmetatable(node, Node)
    node.super = Node

    ok, err = validate_node(node, device)
    if not ok then
      return nil, "bad node '" .. nodeid .. "': " .. err
    end
  end

  return nodes
end


-- validates a device
-- @param device device table to verify
-- @return device, or nil + err
local function validate_device(device)
  if type(device) ~= "table" then
    return nil, "expected 'device' to be a table"
  end

  if device.homie ~= "4.0.0" then
    return nil, "expected `device.homie` to be a string '4.0.0'"
  end

  if type(device.name) ~= "string" or #device.name < 1 then
    return nil, "expected `device.name` to be a string of at least 1 character"
  end

  if device.state ~= nil then
    return nil, "expected `device.state` to be 'nil', since it is managed by the homie library"
  end

  if device.extensions ~= "" then
    return nil, "expected `device.extensions` to be an empty string, since we do not support any yet"
  end

  if type(device.nodes) ~= "table" then
    return nil, "expected `device.nodes` to be a table"
  end

  if device.implementation == nil then
    device.implementation = ""
  end
  if type(device.implementation) ~= "string" then
    return nil, "expected `device.implementation` to be a string if given"
  end
  if device.implementation == "" then
    device.implementation = "homie.lua " .. Device._VERSION
  else
    device.implementation = device.implementation .. ", homie.lua " .. Device._VERSION
  end

  local ok, err = validate_nodes(device.nodes, device)
  if not ok then
    return nil, err
  end

  return device
end


--- Instantiate a new Homie device.
-- @tparam table[opt={}] opts Options table to create the instance from.
-- @tparam string[opt="homie/"] opts.domain base domain
-- @tparam string[opt] opts.id device id. Defaults to `homie-xxxxxxx` randomized.
-- @tparam string[opt] opts.state_dir location to save device state file. Ommit to not save/load.
-- @return new device object.
function Device.new(opts, empty)
  if empty ~= nil then error("do not call 'new' with colon-notation", 2) end
  assert(type(opts) == "table", "expected 'opts' to be a table")
  local self = setmetatable(opts, Device)
  self.super = Device
  self:__init()
  return self
end

--- Initializer, called upon instantiation.
function Device:__init()
  -- domain: Base topic
  if self.domain == nil then
    self.domain = "homie"
  end
  self.domain = assert(validate_segment(self.domain))

  -- id: Homie device ID
  if self.id == nil then
    self.id = ("homie-lua-%07x"):format(math.random(1, 0xFFFFFFF))
  end
  self.id = assert(validate_segment(self.id))

  -- base_topic
  self.base_topic = self.domain .. "/" .. self.id .. "/"

  -- broadcast subscriptions
  local bc = self.broadcast or {}
  self.broadcast = {}
  assert(type(bc) == "table", "expected 'broadcast' to be a table")
  for topic, handler in pairs(bc) do
    topic = assert(validate_broadcast_topic(self, topic))
    handler = assert(type(handler) == "function" and handler, "expected broadcast handler to be a function")
    -- inject 'self' as first parameter on call backs
    self.broadcast[topic] = create_broadcast_handler(self, handler)
  end

  -- Validate device and nodes
  assert(validate_device(self))

  -- generate subscriptions for settable properties
  self.settable_subscriptions = {}
  for nodeid, node in pairs(self.nodes) do
    for propid, prop in pairs(node.properties) do
      if prop.settable then
        local topic = self.base_topic .. nodeid .. "/" .. propid .. "/set"
        local handler = function(...)
            return prop.rset(prop, self, ...)
          end
        self.settable_subscriptions[topic] = handler
      end
    end
  end

  -- Instantiate mqtt device
  self.mqtt = mqtt.client {
    uri = self.uri,
    clean = true,
    reconnect = true,
    will = {
      topic = self.base_topic.."/"..self.id.."/$state",
      payload = self.states.lost,
      qos = 1,
      retain = true,
    }
  }
end

--- Method to verify initial values. Can be used to verify values received from
-- broker, or to just initialize values. When this returns the values must be in
-- a consistent state.
function Device:verify_initial_values()
  -- override in instances
end

--- Send an MQTT message with the value update.
-- @param prop the property object issuing the update
-- @param pvalue the packed/serialized value to send over the wire
-- @return nothing
function Device:send_property_update(prop, pvalue)
  local topic = prop.topic
  local retained = prop.retained

  -- non-retained messages should be dropped if not connected
  -- retained ones should be queued, and coalesced.

  -- TODO: implement
end

function Device:start()
    -- prepare for cleanup broker-side
    -- connect
    -- subscribe to own topics
    -- wait for timeout and updates
    -- unsubscribe own topics
    -- compare and clean unknown topics received
  self:verify_initial_values()

end

function Device:stop()
end


if _G._TEST then
  -- export local functions for test purposes
  Device._validate_segment = validate_segment
  Device._validate_broadcast_topic = validate_broadcast_topic
  Device._validate_format = validate_format
  Device._validate_property = validate_property
  Device._validate_properties = validate_properties
  Device._validate_node = validate_node
  Device._validate_nodes = validate_nodes
  Device._validate_device = validate_device
  -- object metatables
  Device._Property = Property
  Device._Node = Node
end

return Device

--[[
local dev = {
  id = "mydevice",
  domain = "homie" -- optional
  name = "my refridgerator in the kitchen",  -- friendly name
  broadcast = {
    -- hash-table of broadcast subscriptions, with handlers; either relative, or fully
    -- qualified topics. will be updated to fully-qualified
  },
  nodes = {
    nodeid = {
      name = "friendly node name",
      type = "type description",
      properties = {
        propid = { -- value goes directly here
          name = "fiendly prop name",
          datatype = "integer, float, boolean, string, enum, color",
          -- optionals and their defaults
          settable = false,
          retained = true, -- after changing to false retained ones must be deleted?
          format = { -- has a different format on the wire!!!
            -- float/integer:  "[min]:[max]"
            min = 0, --minimum for float/integer
            max = 100, -- maximum for float/integer
            -- enum; "one,two,three"
            enum = { "one", "two", "three", one = "one", two = "two", three = "three" },

          },
          unit = nil,
        }
      }
    }
  }
}
--]]
