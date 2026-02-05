# Troubleshooting GoogleChatAuth

## Common Errors and Solutions

### Error: "attempt to call field 'shellescape' (a nil value)"

**Cause**: The code is using `vim.fn.shellescape()` which may not work correctly in all contexts.

**Solution**: Update the auth module to fix URL encoding.

### Error: "Please configure client_id and client_secret"

**Cause**: Environment variables are not set or not being read correctly.

**Solution**:
1. Verify environment variables are set:
   ```vim
   :echo $GOOGLE_CHAT_CLIENT_ID
   :echo $GOOGLE_CHAT_CLIENT_SECRET
   ```
2. If empty, restart Neovim after setting them in your shell config
3. Or set them directly in your config (not recommended for security)

### Error: "module 'plenary.curl' not found"

**Cause**: plenary.nvim is not installed.

**Solution**:
```vim
:Lazy install plenary.nvim
```

### Browser doesn't open

**Cause**: The browser command detection may not work on your system.

**Solution**: Manually copy the URL from the notification and paste it in your browser.

### Other errors

Enable debug mode:
```lua
require("google-chat").setup({
  logging = {
    enabled = true,
    level = "debug",
  },
})
```

Then check: `:edit ~/.cache/nvim/google-chat.log`
