-- Simple HTTP server for OAuth loopback flow
local M = {}

-- Start a temporary HTTP server to catch OAuth redirect
function M.start_oauth_server(port, callback)
  local uv = vim.loop
  
  -- Create TCP server
  local server = uv.new_tcp()
  
  server:bind("127.0.0.1", port)
  
  server:listen(128, function(err)
    if err then
      vim.schedule(function()
        vim.notify("Failed to start OAuth server: " .. err, vim.log.levels.ERROR)
        if callback then callback(nil) end
      end)
      return
    end
    
    local client = uv.new_tcp()
    server:accept(client)
    
    client:read_start(function(read_err, chunk)
      if read_err then
        vim.schedule(function()
          vim.notify("Error reading OAuth response", vim.log.levels.ERROR)
        end)
        client:close()
        server:close()
        if callback then callback(nil) end
        return
      end
      
      if chunk then
        -- Parse the HTTP request to extract the authorization code
        local code = chunk:match("code=([^&%s]+)")
        
        if code then
          -- Send success response to browser
          local response = table.concat({
            "HTTP/1.1 200 OK",
            "Content-Type: text/html; charset=utf-8",
            "",
            "<html><body>",
            "<h1>Authentication Successful!</h1>",
            "<p>You can close this window and return to Neovim.</p>",
            "<script>window.close();</script>",
            "</body></html>",
          }, "\r\n")
          
          client:write(response, function()
            client:close()
            server:close()
            
            vim.schedule(function()
              if callback then callback(code) end
            end)
          end)
        else
          -- Send error response
          local response = table.concat({
            "HTTP/1.1 400 Bad Request",
            "Content-Type: text/html; charset=utf-8",
            "",
            "<html><body>",
            "<h1>Authentication Failed</h1>",
            "<p>No authorization code received. Please try again.</p>",
            "</body></html>",
          }, "\r\n")
          
          client:write(response, function()
            client:close()
            server:close()
            
            vim.schedule(function()
              vim.notify("No authorization code received", vim.log.levels.ERROR)
              if callback then callback(nil) end
            end)
          end)
        end
      end
    end)
  end)
  
  return server
end

return M
