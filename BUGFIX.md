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

## Fix 3: OAuth Redirect Flow (OOB Deprecated, Loopback Implemented)

### Issue 1: No Server Running

The initial configuration used `http://localhost:8080` as the redirect URI, but there was no server to catch the OAuth redirect, causing "This site can't be reached" errors.

### Issue 2: OOB Flow Deprecated

Attempted fix using `urn:ietf:wg:oauth:2.0:oob` (out-of-band flow) failed because Google has deprecated and blocked this method:

> "The out-of-band (OOB) flow has been blocked in order to keep users secure."

### Final Solution: OAuth Loopback Flow

Implemented a **proper loopback server** using Neovim's built-in libuv (vim.loop) to start a temporary HTTP server that catches the OAuth redirect.

```lua
redirect_uri = "http://127.0.0.1:8080"
loopback_port = 8080
```

### How It Works

1. Plugin starts a temporary TCP server on 127.0.0.1:8080
2. Browser opens with OAuth consent screen
3. User authorizes the app
4. Google redirects to http://127.0.0.1:8080/?code=...
5. Server catches the request and extracts the authorization code
6. Server sends success HTML to browser
7. Server closes automatically
8. Plugin exchanges code for tokens

### Implementation Details

Created `lua/google-chat/auth/server.lua`:
- Uses `vim.loop` (libuv) for TCP server
- Parses HTTP GET request to extract code
- Returns user-friendly HTML response
- Automatically closes after receiving redirect
- Handles errors gracefully

### User Experience

**Before (Manual)**: Copy/paste authorization codes
**After (Automatic)**: Click "Allow" and you're done!

The browser shows "Authentication Successful! You can close this window and return to Neovim."

### Why Loopback Instead of OOB

- **OOB**: Deprecated by Google in 2022, now blocked
- **Loopback**: Recommended method for desktop apps
- **Native Integration**: No external dependencies
- **Better UX**: Fully automatic, no copy/paste needed

### Files Modified
- `lua/google-chat/auth/server.lua` (NEW - OAuth loopback server)
- `lua/google-chat/auth/init.lua` (Updated to use loopback server)
- `lua/google-chat/config/init.lua` (Updated redirect URI and added port config)
- `README.md`
- `QUICKSTART.md`
- `doc/google-chat.txt`

---

**Fixed**: February 5, 2026

**Summary of All Fixes**:
1. **URL Encoding Bug** - Fixed `vim.fn.shellescape()` → proper URL encoding
2. **Invalid OAuth Scopes** - Fixed `chat.messages` → `chat.messages.readonly`
3. **OAuth Flow** - Implemented proper loopback server using vim.loop

**Files Created**:
- `lua/google-chat/auth/server.lua` - OAuth loopback HTTP server

**Files Modified**: 
- `lua/google-chat/auth/init.lua` - URL encoding fix + loopback integration
- `lua/google-chat/config/init.lua` - OAuth scopes + redirect URI
- Documentation files (README.md, QUICKSTART.md, doc/google-chat.txt)
