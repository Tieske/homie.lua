describe("Homie device", function()

  local D

  setup(function()
    _G._TEST = true
    D = require "homie.Device"
  end)

  teardown(function()
    _G._TEST = nil
  end)


  describe("property:get()", function()

    pending("returns the current value", function()
      --test
    end)

  end)



  describe("property:unpack()", function()

    pending("string", function()
      -- TODO: implement
    end)

    pending("integer", function()
      -- TODO: implement
    end)

    pending("float", function()
      -- TODO: implement
    end)

    pending("percent", function()
      -- TODO: implement
    end)

    pending("boolean", function()
      -- TODO: implement
    end)

    pending("enum", function()
      -- TODO: implement
    end)

    pending("color", function()
      -- TODO: implement
    end)

    pending("datetime", function()
      -- TODO: implement
    end)

    pending("duration", function()
      -- TODO: implement
    end)

  end)



  describe("property:validate()", function()

    pending("string", function()
      -- TODO: implement
    end)

    pending("integer", function()
      -- TODO: implement
    end)

    pending("float", function()
      -- TODO: implement
    end)

    pending("percent", function()
      -- TODO: implement
    end)

    pending("boolean", function()
      -- TODO: implement
    end)

    pending("enum", function()
      -- TODO: implement
    end)

    pending("color", function()
      -- TODO: implement
    end)

    pending("datetime", function()
      -- TODO: implement
    end)

    pending("duration", function()
      -- TODO: implement
    end)

  end)



  describe("property:rset()", function()

    pending("doesn't set on non-settable properties", function()
      -- TODO: implement
    end)

    pending("unpacks received values", function()
      -- TODO: implement
    end)

    pending("validates received values", function()
      -- TODO: implement
    end)

  end)



  describe("property:pack()", function()

    pending("string", function()
      -- TODO: implement
    end)

    pending("integer", function()
      -- TODO: implement
    end)

    pending("float", function()
      -- TODO: implement
    end)

    pending("percent", function()
      -- TODO: implement
    end)

    pending("boolean", function()
      -- TODO: implement
    end)

    pending("enum", function()
      -- TODO: implement
    end)

    pending("color", function()
      -- TODO: implement
    end)

    pending("datetime", function()
      -- TODO: implement
    end)

    pending("duration", function()
      -- TODO: implement
    end)

  end)



  describe("property:values_same()", function()

    pending("string", function()
      -- TODO: implement
    end)

    pending("integer", function()
      -- TODO: implement
    end)

    pending("float", function()
      -- TODO: implement
    end)

    pending("percent", function()
      -- TODO: implement
    end)

    pending("boolean", function()
      -- TODO: implement
    end)

    pending("enum", function()
      -- TODO: implement
    end)

    pending("color", function()
      -- TODO: implement
    end)

    pending("datetime", function()
      -- TODO: implement
    end)

    pending("duration", function()
      -- TODO: implement
    end)

  end)



  describe("property:update()", function()

    pending("onlu updates if different", function()
      -- TODO: implement
    end)

    pending("packs value", function()
      -- TODO: implement
    end)

    pending("send MQTT topic update", function()
      -- TODO: implement
    end)

  end)



  describe("property:set()", function()

    pending("calls 'update'", function()
      -- TODO: implement
    end)

  end)


end)

