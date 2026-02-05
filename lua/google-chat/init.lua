local M = {}

local config = require("google-chat.config")

-- Lazy-loaded modules
local auth = nil
local api = nil
local ui = nil

-- Setup function
function M.setup(opts)
  config.setup(opts)
  
  -- Initialize auth on setup
  auth = require("google-chat.auth")
  auth.init()
end

-- Authentication commands
function M.authenticate()
  if not auth then
    auth = require("google-chat.auth")
  end
  auth.authenticate()
end

function M.logout()
  if not auth then
    auth = require("google-chat.auth")
  end
  auth.logout()
end

function M.status()
  if not auth then
    auth = require("google-chat.auth")
    auth.init()
  end
  
  if auth.is_authenticated() then
    vim.notify("✓ Authenticated with Google Chat", vim.log.levels.INFO)
  else
    vim.notify("✗ Not authenticated. Run :GoogleChatAuth to authenticate.", vim.log.levels.WARN)
  end
end

-- UI commands
function M.show_spaces()
  if not ui then
    ui = require("google-chat.ui")
  end
  ui.show_spaces()
end

function M.open_space(space_id)
  if not ui then
    ui = require("google-chat.ui")
  end
  ui.open_space(space_id)
end

function M.send_message(space_id, text)
  if not ui then
    ui = require("google-chat.ui")
  end
  ui.send_message(space_id, text)
end

-- Telescope integration
function M.telescope_spaces()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is not installed", vim.log.levels.ERROR)
    return
  end
  
  telescope.extensions.google_chat.spaces()
end

function M.telescope_messages(space_id)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is not installed", vim.log.levels.ERROR)
    return
  end
  
  telescope.extensions.google_chat.messages({ space_id = space_id })
end

function M.telescope_search()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is not installed", vim.log.levels.ERROR)
    return
  end
  
  telescope.extensions.google_chat.search_spaces()
end

return M
