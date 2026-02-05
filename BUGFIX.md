# Bug Fixes

## Fix 1: OAuth URL Generation

### Issue

The `get_auth_url()` function in `lua/google-chat/auth/init.lua` was using `vim.fn.shellescape()` for URL parameter encoding, which is incorrect. `shellescape` is for shell command escaping, not URL encoding.

### Problem Code (Line 87)
```lua
table.insert(query, string.format("%s=%s", k, vim.fn.shellescape(v)))
```

This would generate malformed OAuth URLs like:
```
https://accounts.google.com/o/oauth2/v2/auth?client_id='YOUR_ID'&scope='scope1 scope2'
```

Instead of:
```
https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_ID&scope=scope1+scope2
```

## Fix Applied

Added a proper `url_encode()` helper function and used it for OAuth URL generation:

```lua
-- URL encode helper
local function url_encode(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end
```

Now using:
```lua
table.insert(query, string.format("%s=%s", k, url_encode(v)))
```

## Impact

This fix resolves authentication errors when running `:GoogleChatAuth`. The OAuth URL will now be correctly formatted and Google's OAuth server will accept it.

## Note

The use of `vim.fn.shellescape()` on line 64 for the `chmod` command is correct and was not changed, as that's passing a filename to a shell command.

## Testing

After this fix, `:GoogleChatAuth` should:
1. Generate a valid OAuth URL
2. Open the browser successfully
3. Allow the user to authenticate with Google
4. Accept the authorization code without errors

---

## Fix 2: Invalid OAuth2 Scopes

### Issue

The initial configuration used an invalid scope `https://www.googleapis.com/auth/chat.messages` which doesn't exist in the Google Chat API. This caused the OAuth consent screen to show an error:

> "You are receiving this error either because your input OAuth2 scope name is invalid or it refers to a newer scope that is outside the domain of this legacy API."

### Problem Scopes
```lua
scopes = {
  "https://www.googleapis.com/auth/chat.spaces.readonly",
  "https://www.googleapis.com/auth/chat.messages", -- INVALID
  "https://www.googleapis.com/auth/chat.messages.create",
}
```

### Fix Applied

Updated to use only valid Google Chat API scopes as documented at https://developers.google.com/identity/protocols/oauth2/scopes:

```lua
scopes = {
  "https://www.googleapis.com/auth/chat.spaces.readonly",
  "https://www.googleapis.com/auth/chat.messages.readonly", -- Read messages
  "https://www.googleapis.com/auth/chat.messages.create",   -- Send messages
  "https://www.googleapis.com/auth/chat.memberships.readonly", -- View members
}
```

### Valid Scopes for MVP

- `chat.spaces.readonly` - View spaces
- `chat.messages.readonly` - Read messages (not `chat.messages`)
- `chat.messages.create` - Send new messages
- `chat.memberships.readonly` - View space members

### Impact

Users must now add the correct scopes to their OAuth consent screen in Google Cloud Console. The updated scopes provide the same functionality with proper API compliance.

### Files Modified
- `lua/google-chat/config/init.lua`
- `README.md`
- `QUICKSTART.md`

---

## Fix 3: Invalid Redirect URI (Localhost Not Working)

### Issue

The initial configuration used `http://localhost:8080` as the redirect URI. When users authenticated, Google would redirect to localhost, but there was no server running to catch the redirect, resulting in a "This site can't be reached" error in the browser.

### Problem Configuration
```lua
redirect_uri = "http://localhost:8080"
```

### Fix Applied

Changed to use the **out-of-band (OOB)** OAuth flow, which is the standard approach for desktop applications:

```lua
redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
```

### How OOB Flow Works

1. User clicks authorize in the browser
2. Instead of redirecting, Google displays the authorization code directly on a page
3. User copies the code from the browser
4. User pastes it into Neovim when prompted
5. Plugin exchanges the code for tokens

This is the recommended approach for desktop/CLI applications that can't run a web server.

### User Experience

After clicking "Allow" in the browser, users will see a page that says:
- "Sign in to continue to Neovim Google Chat"
- A text box with the authorization code
- A "Copy" button to copy the code

Simply copy the code and paste it into Neovim.

### Alternative Approaches Not Used

We didn't implement:
- **Local HTTP server** - Would require additional dependencies and complexity
- **Loopback flow** - Requires running a server on a specific port
- **Device flow** - More steps and polling required

The OOB flow is simpler and more reliable for a Neovim plugin.

### Files Modified
- `lua/google-chat/config/init.lua`
- `README.md`
- `QUICKSTART.md`
- `doc/google-chat.txt`

---

**Fixed**: February 5, 2026
**Files Modified**: 
- `lua/google-chat/auth/init.lua` (URL encoding)
- `lua/google-chat/config/init.lua` (OAuth scopes, redirect URI)
- Documentation files
