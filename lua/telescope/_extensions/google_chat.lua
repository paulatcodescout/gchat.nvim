local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local api = require("google-chat.api")
local ui = require("google-chat.ui")

local M = {}

-- Spaces picker
M.spaces = function(opts)
  opts = opts or {}

  -- Fetch spaces
  api.list_spaces(function(data, err)
    if err then
      vim.notify("Failed to load spaces: " .. err, vim.log.levels.ERROR)
      return
    end

    local spaces = data.spaces or {}

    pickers
      .new(opts, {
        prompt_title = "Google Chat Spaces",
        finder = finders.new_table({
          results = spaces,
          entry_maker = function(entry)
            local display_name = entry.displayName or entry.name or "Unknown"
            local space_type = entry.spaceType or "SPACE"

            return {
              value = entry,
              display = string.format("[%s] %s", space_type, display_name),
              ordinal = display_name,
              space_id = entry.name,
              space_type = space_type,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
          title = "Space Info",
          define_preview = function(self, entry)
            local space = entry.value
            local lines = {
              "Space: " .. (space.displayName or "Unknown"),
              "Type: " .. (space.spaceType or "SPACE"),
              "Name: " .. (space.name or ""),
              "",
            }

            if space.spaceDetails then
              table.insert(lines, "Details:")
              if space.spaceDetails.description then
                table.insert(lines, "  Description: " .. space.spaceDetails.description)
              end
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            ui.open_space(selection.space_id)
          end)

          -- Open in vsplit
          map("i", "<C-v>", function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.cmd("vsplit")
            ui.open_space(selection.space_id)
          end)

          -- Open in split
          map("i", "<C-x>", function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.cmd("split")
            ui.open_space(selection.space_id)
          end)

          return true
        end,
      })
      :find()
  end)
end

-- Messages picker for a specific space
M.messages = function(opts)
  opts = opts or {}
  local space_id = opts.space_id

  if not space_id then
    vim.notify("space_id is required for messages picker", vim.log.levels.ERROR)
    return
  end

  api.list_messages(space_id, function(data, err)
    if err then
      vim.notify("Failed to load messages: " .. err, vim.log.levels.ERROR)
      return
    end

    local messages = data.messages or {}

    pickers
      .new(opts, {
        prompt_title = "Messages",
        finder = finders.new_table({
          results = messages,
          entry_maker = function(entry)
            local sender = entry.sender and entry.sender.displayName or "Unknown"
            local text = entry.text or ""
            local preview = text:gsub("\n", " "):sub(1, 50)
            
            if #text > 50 then
              preview = preview .. "..."
            end

            return {
              value = entry,
              display = string.format("%s: %s", sender, preview),
              ordinal = text,
              message_id = entry.name,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
          title = "Message Preview",
          define_preview = function(self, entry)
            local message = entry.value
            local lines = {
              "From: " .. (message.sender and message.sender.displayName or "Unknown"),
              "Time: " .. (message.createTime or ""),
              "",
              "Message:",
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
              "",
            }

            local text = message.text or ""
            for line in text:gmatch("[^\r\n]+") do
              table.insert(lines, line)
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            
            -- Copy message text to clipboard
            local text = selection.value.text or ""
            vim.fn.setreg("+", text)
            vim.notify("Message copied to clipboard", vim.log.levels.INFO)
          end)

          return true
        end,
      })
      :find()
  end)
end

-- Search all spaces
M.search_spaces = function(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "Search Google Chat Spaces",
      finder = finders.new_dynamic({
        fn = function(prompt)
          if prompt == "" then
            return {}
          end

          return vim.schedule_wrap(function(results_cb)
            api.search_spaces(prompt, function(data, err)
              if err then
                return
              end

              local spaces = data.spaces or {}
              for _, space in ipairs(spaces) do
                results_cb(space)
              end
              results_cb() -- Signal completion
            end)
          end)
        end,
        entry_maker = function(entry)
          local display_name = entry.displayName or entry.name or "Unknown"
          local space_type = entry.spaceType or "SPACE"

          return {
            value = entry,
            display = string.format("[%s] %s", space_type, display_name),
            ordinal = display_name,
            space_id = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          ui.open_space(selection.space_id)
        end)

        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  setup = function(ext_config)
    -- Extension configuration
  end,
  exports = {
    spaces = M.spaces,
    messages = M.messages,
    search_spaces = M.search_spaces,
  },
})
