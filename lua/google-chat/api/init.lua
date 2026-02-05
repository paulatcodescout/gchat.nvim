local config = require("google-chat.config")
local auth = require("google-chat.auth")
local curl = require("plenary.curl")

local M = {}

-- Make authenticated API request
local function request(method, endpoint, opts, callback)
  opts = opts or {}
  
  auth.get_access_token(function(token)
    if not token then
      vim.notify("Not authenticated. Please run :GoogleChatAuth", vim.log.levels.ERROR)
      if callback then callback(nil, "Not authenticated") end
      return
    end

    local base_url = config.get("api.base_url")
    local url = base_url .. endpoint
    
    local headers = {
      ["Authorization"] = "Bearer " .. token,
      ["Content-Type"] = "application/json",
    }

    local request_opts = {
      headers = headers,
      callback = vim.schedule_wrap(function(response)
        if response.status >= 200 and response.status < 300 then
          local ok, data = pcall(vim.fn.json_decode, response.body)
          if ok then
            if callback then callback(data, nil) end
          else
            if callback then callback(nil, "Invalid JSON response") end
          end
        else
          local error_msg = string.format("API error: %d - %s", response.status, url)
          local error_body = response.body or ""
          if error_body ~= "" then
            local ok, error_data = pcall(vim.fn.json_decode, error_body)
            if ok and error_data.error then
              error_msg = error_msg .. "\n" .. (error_data.error.message or "Unknown error")
            end
          end
          vim.notify(error_msg, vim.log.levels.ERROR)
          if callback then callback(nil, error_msg) end
        end
      end),
    }

    if opts.body then
      request_opts.body = vim.fn.json_encode(opts.body)
    end

    if opts.query then
      local query_parts = {}
      for k, v in pairs(opts.query) do
        table.insert(query_parts, string.format("%s=%s", k, vim.uri_encode(tostring(v))))
      end
      url = url .. "?" .. table.concat(query_parts, "&")
    end

    if method == "GET" then
      curl.get(url, request_opts)
    elseif method == "POST" then
      curl.post(url, request_opts)
    elseif method == "PUT" then
      curl.put(url, request_opts)
    elseif method == "DELETE" then
      curl.delete(url, request_opts)
    end
  end)
end

-- Get list of spaces
function M.list_spaces(callback, page_token, opts)
  opts = opts or {}
  
  local query = {
    pageSize = opts.page_size or 100,
  }
  
  if page_token then
    query.pageToken = page_token
  end
  
  -- Add filter if specified
  if opts.filter then
    query.filter = opts.filter
  end

  request("GET", "/spaces", { query = query }, callback)
end

-- Normalize space/message ID (remove leading slash if present, ensure no double spaces/)
local function normalize_resource_name(resource_name)
  if not resource_name then return "" end
  -- Remove leading slash
  resource_name = resource_name:gsub("^/", "")
  -- If it already starts with "spaces/", don't add prefix
  -- Otherwise, it's just the ID, so we don't add anything (API expects full path)
  return resource_name
end

-- Get space details
function M.get_space(space_id, callback)
  local path = "/" .. normalize_resource_name(space_id)
  request("GET", path, {}, callback)
end

-- List messages in a space
function M.list_messages(space_id, callback, opts)
  opts = opts or {}
  
  local query = {
    pageSize = opts.page_size or 50,
  }
  
  if opts.page_token then
    query.pageToken = opts.page_token
  end
  
  if opts.filter then
    query.filter = opts.filter
  end

  local path = "/" .. normalize_resource_name(space_id) .. "/messages"
  request("GET", path, { query = query }, callback)
end

-- Get a specific message
function M.get_message(space_id, message_id, callback)
  local path = "/" .. normalize_resource_name(space_id) .. "/messages/" .. message_id
  request("GET", path, {}, callback)
end

-- Create a message
function M.create_message(space_id, text, callback, opts)
  opts = opts or {}
  
  local body = {
    text = text,
  }
  
  if opts.thread_key then
    body.thread = {
      threadKey = opts.thread_key,
    }
  end
  
  if opts.message_reply_option then
    body.messageReplyOption = opts.message_reply_option
  end

  local path = "/" .. normalize_resource_name(space_id) .. "/messages"
  request("POST", path, { body = body }, callback)
end

-- Update a message
function M.update_message(space_id, message_id, text, callback)
  local path = "/" .. normalize_resource_name(space_id) .. "/messages/" .. message_id
  local body = {
    text = text,
  }
  
  local query = {
    updateMask = "text",
  }

  request("PUT", path, { body = body, query = query }, callback)
end

-- Delete a message
function M.delete_message(space_id, message_id, callback)
  local path = "/" .. normalize_resource_name(space_id) .. "/messages/" .. message_id
  request("DELETE", path, {}, callback)
end

-- Get members of a space
function M.list_members(space_id, callback)
  local query = {
    pageSize = 100,
  }

  local path = "/" .. normalize_resource_name(space_id) .. "/members"
  request("GET", path, { query = query }, callback)
end

-- Create a reaction
function M.create_reaction(space_id, message_id, emoji, callback)
  local path = "/" .. normalize_resource_name(space_id) .. "/messages/" .. message_id .. "/reactions"
  local body = {
    emoji = {
      unicode = emoji,
    },
  }

  request("POST", path, { body = body }, callback)
end

-- List reactions
function M.list_reactions(space_id, message_id, callback)
  local path = "/" .. normalize_resource_name(space_id) .. "/messages/" .. message_id .. "/reactions"
  request("GET", path, {}, callback)
end

-- Search spaces (client-side filtering for MVP)
function M.search_spaces(query, callback)
  M.list_spaces(function(data, err)
    if err then
      callback(nil, err)
      return
    end

    if not data or not data.spaces then
      callback({ spaces = {} }, nil)
      return
    end

    local filtered = {}
    local query_lower = query:lower()
    
    for _, space in ipairs(data.spaces) do
      local display_name = space.displayName or ""
      if display_name:lower():find(query_lower, 1, true) then
        table.insert(filtered, space)
      end
    end

    callback({ spaces = filtered }, nil)
  end)
end

return M
