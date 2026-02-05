-- Google Directory API integration for fetching user display names
local config = require("google-chat.config")
local auth = require("google-chat.auth")
local curl = require("plenary.curl")

local M = {}

-- Fetch user information from Directory API
function M.batch_get_users(user_ids, callback)
  if not user_ids or #user_ids == 0 then
    callback({}, nil)
    return
  end
  
  auth.get_access_token(function(token)
    if not token then
      callback(nil, "Not authenticated")
      return
    end
    
    local user_map = {}
    local completed = 0
    local total = #user_ids
    
    -- Fetch each user individually (Directory API doesn't have batch endpoint)
    for _, user_id in ipairs(user_ids) do
      -- Extract numeric ID from "users/123456" format
      local numeric_id = user_id:match("users/(%d+)")
      
      if numeric_id then
        local url = string.format("https://admin.googleapis.com/admin/directory/v1/users/%s?projection=basic", numeric_id)
        
        curl.get(url, {
          headers = {
            ["Authorization"] = "Bearer " .. token,
          },
          callback = vim.schedule_wrap(function(response)
            completed = completed + 1
            
            if response.status == 200 then
              local ok, data = pcall(vim.fn.json_decode, response.body)
              if ok and data.name and data.name.fullName then
                user_map[user_id] = data.name.fullName
              end
            end
            
            -- When all requests complete, call callback
            if completed == total then
              vim.notify(string.format("Fetched %d/%d user names from Directory API", vim.tbl_count(user_map), total), vim.log.levels.INFO)
              callback(user_map, nil)
            end
          end),
        })
      else
        completed = completed + 1
        if completed == total then
          callback(user_map, nil)
        end
      end
    end
  end)
end

return M
