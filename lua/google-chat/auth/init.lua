local config = require("google-chat.config")
local curl = require("plenary.curl")

local M = {}

-- Token storage
M.tokens = {
  access_token = nil,
  refresh_token = nil,
  expires_at = 0,
}

-- Check if authenticated
function M.is_authenticated()
  if not M.tokens.access_token then
    return false
  end

  -- Check if token is expired (with 5 minute buffer)
  local now = os.time()
  if now >= (M.tokens.expires_at - 300) then
    return false
  end

  return true
end

-- Load tokens from file
function M.load_tokens()
  local token_file = config.get("auth.token_file")
  local file = io.open(token_file, "r")
  
  if not file then
    return false
  end

  local content = file:read("*all")
  file:close()

  local ok, tokens = pcall(vim.fn.json_decode, content)
  if ok and tokens then
    M.tokens = tokens
    return M.is_authenticated()
  end

  return false
end

-- Save tokens to file
function M.save_tokens()
  local token_file = config.get("auth.token_file")
  local file = io.open(token_file, "w")
  
  if not file then
    vim.notify("Failed to save tokens", vim.log.levels.ERROR)
    return false
  end

  local content = vim.fn.json_encode(M.tokens)
  file:write(content)
  file:close()

  -- Set restrictive permissions
  vim.fn.system(string.format("chmod 600 %s", vim.fn.shellescape(token_file)))
  
  return true
end

-- Generate OAuth2 authorization URL
function M.get_auth_url()
  local client_id = config.get("auth.client_id")
  local redirect_uri = config.get("auth.redirect_uri")
  local scopes = table.concat(config.get("auth.scopes"), " ")

  local params = {
    client_id = client_id,
    redirect_uri = redirect_uri,
    response_type = "code",
    scope = scopes,
    access_type = "offline",
    prompt = "consent",
  }

  local query = {}
  for k, v in pairs(params) do
    table.insert(query, string.format("%s=%s", k, vim.fn.shellescape(v)))
  end

  return "https://accounts.google.com/o/oauth2/v2/auth?" .. table.concat(query, "&")
end

-- Exchange authorization code for tokens
function M.exchange_code(code, callback)
  local client_id = config.get("auth.client_id")
  local client_secret = config.get("auth.client_secret")
  local redirect_uri = config.get("auth.redirect_uri")

  curl.post("https://oauth2.googleapis.com/token", {
    body = vim.fn.json_encode({
      code = code,
      client_id = client_id,
      client_secret = client_secret,
      redirect_uri = redirect_uri,
      grant_type = "authorization_code",
    }),
    headers = {
      ["Content-Type"] = "application/json",
    },
    callback = vim.schedule_wrap(function(response)
      if response.status ~= 200 then
        vim.notify("Failed to exchange authorization code", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      local ok, data = pcall(vim.fn.json_decode, response.body)
      if not ok or not data.access_token then
        vim.notify("Invalid token response", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      M.tokens.access_token = data.access_token
      M.tokens.refresh_token = data.refresh_token
      M.tokens.expires_at = os.time() + (data.expires_in or 3600)

      M.save_tokens()
      vim.notify("Successfully authenticated with Google Chat!", vim.log.levels.INFO)
      
      if callback then callback(true) end
    end),
  })
end

-- Refresh access token
function M.refresh_token(callback)
  if not M.tokens.refresh_token then
    vim.notify("No refresh token available", vim.log.levels.ERROR)
    if callback then callback(false) end
    return
  end

  local client_id = config.get("auth.client_id")
  local client_secret = config.get("auth.client_secret")

  curl.post("https://oauth2.googleapis.com/token", {
    body = vim.fn.json_encode({
      refresh_token = M.tokens.refresh_token,
      client_id = client_id,
      client_secret = client_secret,
      grant_type = "refresh_token",
    }),
    headers = {
      ["Content-Type"] = "application/json",
    },
    callback = vim.schedule_wrap(function(response)
      if response.status ~= 200 then
        vim.notify("Failed to refresh token", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      local ok, data = pcall(vim.fn.json_decode, response.body)
      if not ok or not data.access_token then
        vim.notify("Invalid token refresh response", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      M.tokens.access_token = data.access_token
      M.tokens.expires_at = os.time() + (data.expires_in or 3600)

      M.save_tokens()
      
      if callback then callback(true) end
    end),
  })
end

-- Get valid access token (refreshing if needed)
function M.get_access_token(callback)
  if M.is_authenticated() then
    callback(M.tokens.access_token)
    return
  end

  -- Try to refresh
  M.refresh_token(function(success)
    if success then
      callback(M.tokens.access_token)
    else
      callback(nil)
    end
  end)
end

-- Logout (clear tokens)
function M.logout()
  M.tokens = {
    access_token = nil,
    refresh_token = nil,
    expires_at = 0,
  }

  local token_file = config.get("auth.token_file")
  os.remove(token_file)
  
  vim.notify("Logged out from Google Chat", vim.log.levels.INFO)
end

-- Start OAuth2 flow
function M.authenticate()
  local auth_url = M.get_auth_url()
  
  vim.notify("Opening browser for authentication...", vim.log.levels.INFO)
  vim.notify("URL: " .. auth_url, vim.log.levels.INFO)
  
  -- Open browser
  local open_cmd = "xdg-open"
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("win32") == 1 then
    open_cmd = "start"
  end
  
  vim.fn.system(string.format("%s '%s'", open_cmd, auth_url))
  
  -- Prompt for authorization code
  vim.ui.input({
    prompt = "Enter authorization code: ",
  }, function(code)
    if not code or code == "" then
      vim.notify("Authentication cancelled", vim.log.levels.WARN)
      return
    end
    
    M.exchange_code(code, function(success)
      if success then
        vim.notify("Authentication successful!", vim.log.levels.INFO)
      end
    end)
  end)
end

-- Initialize (load existing tokens)
function M.init()
  M.load_tokens()
end

return M
