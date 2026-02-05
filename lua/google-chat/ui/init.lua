local api = require("google-chat.api")
local config = require("google-chat.config")

local M = {}

-- State management
M.state = {
  spaces = {},
  current_space = nil,
  current_messages = {},
  buffers = {},
}

-- Create or get buffer for spaces list
function M.get_spaces_buffer()
  if M.state.buffers.spaces and vim.api.nvim_buf_is_valid(M.state.buffers.spaces) then
    return M.state.buffers.spaces
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "google-chat://spaces")
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "google-chat-spaces")

  M.state.buffers.spaces = bufnr
  return bufnr
end

-- Create or get buffer for messages
function M.get_messages_buffer(space_id)
  local buf_key = "messages_" .. space_id
  
  if M.state.buffers[buf_key] and vim.api.nvim_buf_is_valid(M.state.buffers[buf_key]) then
    return M.state.buffers[buf_key]
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "google-chat://messages/" .. space_id)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  M.state.buffers[buf_key] = bufnr
  return bufnr
end

-- Format space for display
local function format_space(space)
  local display_name = space.displayName or space.name or "Unknown"
  local space_type = space.spaceType or "SPACE"
  
  return string.format("[%s] %s", space_type, display_name)
end

-- Format message for display
local function format_message(message)
  -- Try multiple fields for sender name
  local sender = "Unknown"
  if message.sender then
    -- First check our user cache (populated from members list)
    if message.sender.name and M.user_cache[message.sender.name] then
      sender = M.user_cache[message.sender.name]
    -- Try displayName from message (might be populated)
    elseif message.sender.displayName and message.sender.displayName ~= "" then
      sender = message.sender.displayName
    -- If sender has email, extract username
    elseif message.sender.email and message.sender.email ~= "" then
      sender = message.sender.email:match("([^@]+)") or message.sender.email
    -- If we only have the resource name (users/123), show a shortened version
    elseif message.sender.name then
      local user_id = message.sender.name:match("users/(.+)")
      sender = user_id and ("User-" .. user_id:sub(1, 8)) or "User"
    end
  end
  
  local text = message.text or message.argumentText or ""
  local create_time = message.createTime or ""
  
  -- Extract timestamp
  local timestamp = create_time:match("(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d)")
  if timestamp then
    timestamp = timestamp:gsub("T", " ")
  else
    timestamp = create_time
  end

  local lines = {}
  table.insert(lines, "")
  table.insert(lines, string.format("**%s** • %s", sender, timestamp))
  table.insert(lines, string.format(string.rep("─", 80)))
  table.insert(lines, "")
  
  -- Process text as markdown-like content
  for line in text:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  table.insert(lines, "")

  return lines
end

-- Create centered floating window
local function create_float_win(bufnr, title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = title or "Google Chat",
    title_pos = "center",
  }
  
  local win = vim.api.nvim_open_win(bufnr, true, opts)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "linebreak", true)
  
  return win
end

-- Display spaces list
function M.show_spaces()
  local bufnr = M.get_spaces_buffer()
  
  -- Create floating window
  local win = create_float_win(bufnr, "Google Chat Spaces")

  -- Show loading
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Loading spaces..." })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Fetch spaces
  api.list_spaces(function(data, err)
    if err then
      vim.notify("Failed to load spaces: " .. err, vim.log.levels.ERROR)
      return
    end

    M.state.spaces = data.spaces or {}
    
    local lines = { "Google Chat Spaces", "" }
    
    if #M.state.spaces == 0 then
      table.insert(lines, "No spaces found")
    else
      for i, space in ipairs(M.state.spaces) do
        table.insert(lines, string.format("%d. %s", i, format_space(space)))
      end
    end

    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    -- Set up keybindings
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "<CR>", function()
      local line = vim.api.nvim_win_get_cursor(0)[1]
      if line > 2 and line <= #M.state.spaces + 2 then
        local space_idx = line - 2
        local space = M.state.spaces[space_idx]
        if space then
          M.open_space(space.name)
        end
      end
    end, opts)
    
    vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
    vim.keymap.set("n", "r", function()
      M.show_spaces()
    end, opts)
  end)
end

-- Cache for user display names
M.user_cache = {}

-- Open a space and show messages
function M.open_space(space_id)
  M.state.current_space = space_id
  local bufnr = M.get_messages_buffer(space_id)
  
  -- Get space name for title
  local space_title = "Messages"
  for _, space in ipairs(M.state.spaces or {}) do
    if space.name == space_id then
      space_title = space.displayName or space.name or "Messages"
      break
    end
  end
  
  -- Create floating window
  local win = create_float_win(bufnr, space_title)

  -- Show loading
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Loading messages..." })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- First, fetch members to cache display names
  api.list_members(space_id, function(member_data, member_err)
    if not member_err and member_data and member_data.memberships then
      -- Cache member display names
      for _, membership in ipairs(member_data.memberships) do
        if membership.member then
          local user_id = membership.member.name
          local display_name = membership.member.displayName
          if user_id and display_name then
            M.user_cache[user_id] = display_name
          end
        end
      end
    end
    
    -- Now fetch messages
    api.list_messages(space_id, function(data, err)
    if err then
      vim.notify("Failed to load messages: " .. err, vim.log.levels.ERROR)
      return
    end

    M.state.current_messages = data.messages or {}
    
    -- Get space name for header
    local space_name = space_id
    for _, space in ipairs(M.state.spaces or {}) do
      if space.name == space_id then
        space_name = space.displayName or space.name
        break
      end
    end
    
    local lines = { 
      string.format("# %s", space_name),
      "",
      string.format("*%d messages* • Press `s` to send, `r` to refresh, `q` to close", #M.state.current_messages),
      "",
      string.rep("═", 80),
      ""
    }
    
    if #M.state.current_messages == 0 then
      table.insert(lines, "")
      table.insert(lines, "*No messages found in this space*")
      table.insert(lines, "")
    else
      for _, message in ipairs(M.state.current_messages) do
        local msg_lines = format_message(message)
        for _, line in ipairs(msg_lines) do
          table.insert(lines, line)
        end
      end
    end

    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    -- Set up keybindings
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
    vim.keymap.set("n", "s", function()
      M.send_message_prompt(space_id)
    end, opts)
    vim.keymap.set("n", "r", function()
      M.open_space(space_id)
    end, opts)
  end) -- End of list_messages callback
  end) -- End of list_members callback
end

-- Prompt to send a message
function M.send_message_prompt(space_id)
  vim.ui.input({
    prompt = "Message: ",
  }, function(text)
    if not text or text == "" then
      return
    end
    
    M.send_message(space_id, text)
  end)
end

-- Send a message
function M.send_message(space_id, text)
  api.create_message(space_id, text, function(data, err)
    if err then
      vim.notify("Failed to send message: " .. err, vim.log.levels.ERROR)
      return
    end

    vim.notify("Message sent!", vim.log.levels.INFO)
    
    -- Refresh messages
    if M.state.current_space == space_id then
      M.open_space(space_id)
    end
  end)
end

return M
