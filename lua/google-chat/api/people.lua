-- Google People API integration for fetching user display names
local config = require("google-chat.config")
local auth = require("google-chat.auth")
local curl = require("plenary.curl")

local M = {}

-- Batch fetch user information from People API
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
    
    -- Build resource names for People API
    local resource_names = {}
    for _, user_id in ipairs(user_ids) do
      -- Extract numeric ID from "users/123456" format
      local numeric_id = user_id:match("users/(%d+)")
      if numeric_id then
        table.insert(resource_names, "people/" .. numeric_id)
      end
    end
    
    if #resource_names == 0 then
      callback({}, nil)
      return
    end
    
    -- People API endpoint
    local url = "https://people.googleapis.com/v1/people:batchGet"
    local query_parts = {
      "personFields=names",
    }
    
    -- Add each resource name
    for _, name in ipairs(resource_names) do
      table.insert(query_parts, "resourceNames=" .. vim.uri_encode(name))
    end
    
    url = url .. "?" .. table.concat(query_parts, "&")
    
    curl.get(url, {
      headers = {
        ["Authorization"] = "Bearer " .. token,
      },
      callback = vim.schedule_wrap(function(response)
        if response.status ~= 200 then
          callback(nil, "People API error: " .. response.status)
          return
        end
        
        local ok, data = pcall(vim.fn.json_decode, response.body)
        if not ok then
          callback(nil, "Invalid JSON response")
          return
        end
        
        -- Build user ID to display name map
        local user_map = {}
        if data.responses then
          for _, person_response in ipairs(data.responses) do
            if person_response.person and person_response.person.resourceName then
              local numeric_id = person_response.person.resourceName:match("people/(%d+)")
              if numeric_id and person_response.person.names and person_response.person.names[1] then
                local display_name = person_response.person.names[1].displayName
                if display_name then
                  user_map["users/" .. numeric_id] = display_name
                end
              end
            end
          end
        end
        
        callback(user_map, nil)
      end),
    })
  end)
end

return M
