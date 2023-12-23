--- === PasteTransform ===
--- Allow the contents of the pasteboard to be transformed using
--- a script selected by the user.
---
--- The script takes the contents on stdio and returns the transformed
--- contents on stdout.

local PasteTransform = {}

-- Metadata {{{ --
PasteTransform.name="PasteTransform"
PasteTransform.version="0.1"
PasteTransform.author="Von Welch"
PasteTransform.license="Creative Commons Zero v1.0 Universal"
PasteTransform.homepage="https://github.com/von/PasteTransform.spoon"
-- }}} Metadata --

--- PasteTransform.defaultScriptPath
--- Variable
--- Default path for transformation scripts: $HOME/.paste-transform/
---
PasteTransform.defaultScriptPath = os.getenv("HOME") .. "/.paste-transform/"

-- PasteTransform:init() {{{ --
--- PasteTransform:init()
--- Method
--- Initializes the PasteTransform spoon.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PasteTransform object
function PasteTransform:init()
  self.log = hs.logger.new("PasteX")

  self.transformScriptPath = PasteTransform.defaultScriptPath

  -- Last transformation for xformRepeat()
  self.lastTransformScript = nil

  return self
end
-- }}} PasteTransform:init() --


-- PasteTransform:debug() {{{ --
--- PasteTransform:debug()
--- Method
--- Enable or disable debugging
---
--- Parameters:
---  * enable - Boolean indicating whether debugging should be on
---
--- Returns:
---  * Nothing
function PasteTransform:debug(enable)
  if enable then
    self.log.setLogLevel('debug')
    self.log.d("Debugging enabled")
  else
    self.log.d("Disabling debugging")
    self.log.setLogLevel('info')
  end
end
-- }}} PasteTransform:debug() --


-- PasteTransform:transformChooser() {{{ --
--- PasteTransform:transformChooser()
--- Method
--- Present user with selection of transformation scripts in a chooser menu
--- so they can select one and then perform the transformation on the
--- pastebuffer using the selected script.
---
--- Parameters:
--- * Nothing
---
--- Returns:
--- * Nothing
function PasteTransform:transformChooser()
  local path = self.transformScriptPath
  local choices = {}

  local status, err = pcall(function()
    for file in hs.fs.dir(path) do
      -- If filename starts with "." ignore it
      -- This catches "." ".." as well
      if file:sub(1,1) == "." then -- noop
      else
        local choice = {
          ["text"] = file,
          ["path"] = path .. "/" .. file
        }
        table.insert(choices, choice)
      end
    end
  end)

  if not status then
    self.log.ef("Cannot read path: %s", err)
    hs.alert("Cannot read " .. path)
    return
  end

  if #choices == 0 then
    hs.alert("No files found in " .. path)
    return
  end

  local chooserCallback = function(info)
    if not info then
      self.log.d("User canceled selection")
      return false
    end
    self.lastTransformScript = info["path"]
    return PasteTransform:transform(info["path"])
  end

  table.sort(choices, function(a,b) return a.text:lower() < b.text:lower() end)
  chooser = hs.chooser.new(chooserCallback)
  chooser:choices(choices)
  chooser:show()
end
-- }}} PasteTransform:transformChooser() --


-- PasteTransform:transform() {{{ --
--- PasteTransform:transform()
--- Method
--- Transform pastebuffer using script at given path.
--- Callback for chooser.
---
--- Parameters:
--- * Path to transformation script
---
--- Returns:
--- * Nothing
function PasteTransform:transform(path)
  self.log.df("Transforming pasteboard data with %s", path)

  -- Read all strings from pasteboard and concatenate them
  local strings = hs.pasteboard.readString(true)
  if strings == nil then
    self.log.e("No data in pasteboard.")
    hs.alert("Pasteboard empty")
    return
  end
  local data = table.concat(strings)

  -- Task callback. Write stdout from task back into pastebuffer.
  local taskCallback = function(exitCode, stdout, stderr)
    if exitCode > 0 then
      local s = string.format("Transform script failed: %s (code = %d)",
        stderr, exitCode)
      hs.alert(s)
      self.log.e(s)
      return
    end

    if not hs.pasteboard.setContents(stdout) then
      hs.alert("Failed to put transformed data into pastebuffer")
      self.log.e("Failed to put transformed data into pastebuffer")
    else
      hs.alert("Paste buffer transformed")
    end
  end -- taskCallback()

  local task = hs.task.new(path, taskCallback)
  task:setInput(data)
  if not task:start() then
    hs.alert("Failed to launch transform script: " .. path)
    self.log.e("Failed to launch transform script: " .. path)
  end
end
-- }}} PasteTransform:transform() --


-- PasteTransform:transformRepeat() {{{ --
--- PasteTransform:transformRepeat()
--- Method
--- Repeat the last transformation on the current pastebuffer.
---
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing

function PasteTransform:transformRepeat()
  if self.lastTransformScript then
    PasteTransform:transform(self.lastTransformScript)
  else
    hs.alert("No previous transformation.")
  end
end
-- }}} PasteTransform:transformRepeat() --

-- PasteTransform:edit() {{{ --
--- PasteTransform:edit()
--- Method
--- Edit the pastbuffer using scripts/edit.sh
--- Uses MacVim by default.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing

function PasteTransform:edit()
  local scriptPath = hs.spoons.resourcePath("/scripts/edit.sh")
  self:transform(scriptPath)
end
-- }}} PasteTransform:edit() --

return PasteTransform
-- vim: foldmethod=marker:
