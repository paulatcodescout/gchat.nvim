local M = {}

-- Default configuration
M.defaults = {
  -- OAuth2 settings
  auth = {
    client_id = "",
    client_secret = "",
    redirect_uri = "http://localhost:8080",
    scopes = {
      "https://www.googleapis.com/auth/chat.spaces.readonly",
      "https://www.googleapis.com/auth/chat.messages",
      "https://www.googleapis.com/auth/chat.messages.create",
    },
    token_file = vim.fn.stdpath("data") .. "/google-chat-tokens.json",
  },

  -- API settings
  api = {
    base_url = "https://chat.googleapis.com/v1",
    timeout = 10000,
    rate_limit = {
      enabled = true,
      requests_per_minute = 60,
    },
  },

  -- UI settings
  ui = {
    split = "vertical",
    width = 80,
    height = 30,
    date_format = "%Y-%m-%d %H:%M",
    show_avatars = false,
  },

  -- Cache settings
  cache = {
    enabled = true,
    ttl = 300, -- 5 minutes
    max_size = 1000,
  },

  -- Polling settings
  polling = {
    enabled = false,
    interval = 30000, -- 30 seconds
  },

  -- Telescope integration
  integrations = {
    telescope = {
      enabled = true,
      default_picker_opts = {},
      mappings = {},
    },
  },

  -- Keybindings
  keybindings = {
    send_message = "<CR>",
    reply_message = "r",
    react_message = "R",
    delete_message = "dd",
    edit_message = "e",
    quit = "q",
  },

  -- Logging
  logging = {
    enabled = false,
    level = "info", -- debug, info, warn, error
    file = vim.fn.stdpath("cache") .. "/google-chat.log",
  },
}

-- Current configuration
M.options = vim.deepcopy(M.defaults)

-- Setup function
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Validate required settings
  if M.options.auth.client_id == "" or M.options.auth.client_secret == "" then
    vim.notify(
      "Google Chat: Please configure client_id and client_secret",
      vim.log.levels.WARN
    )
  end

  return M.options
end

-- Get configuration value with dot notation
function M.get(key)
  local keys = vim.split(key, ".", { plain = true })
  local value = M.options

  for _, k in ipairs(keys) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[k]
  end

  return value
end

-- Set configuration value with dot notation
function M.set(key, value)
  local keys = vim.split(key, ".", { plain = true })
  local current = M.options

  for i = 1, #keys - 1 do
    if type(current[keys[i]]) ~= "table" then
      current[keys[i]] = {}
    end
    current = current[keys[i]]
  end

  current[keys[#keys]] = value
end

return M
