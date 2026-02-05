# gchat.nvim

A Neovim plugin for Google Chat integration, allowing you to read and send messages directly from your editor.

## Features (MVP)

- ✅ OAuth2 authentication with Google
- ✅ List and browse Google Chat spaces
- ✅ View messages in spaces
- ✅ Send messages
- ✅ Telescope integration for fuzzy finding spaces
- ✅ Secure token storage

## Requirements

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced UI)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "paulatcodescout/gchat.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("google-chat").setup({
      auth = {
        client_id = "YOUR_CLIENT_ID",
        client_secret = "YOUR_CLIENT_SECRET",
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "paulatcodescout/gchat.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("google-chat").setup({
      auth = {
        client_id = "YOUR_CLIENT_ID",
        client_secret = "YOUR_CLIENT_SECRET",
      },
    })
  end,
}
```

## Google Cloud Setup

Before using this plugin, you need to set up a Google Cloud project and obtain OAuth2 credentials:

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Chat API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Chat API"
   - Click "Enable"

### 2. Create OAuth2 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Desktop app" as the application type
4. Name it (e.g., "Neovim Google Chat")
5. Click "Create"
6. Copy the **Client ID** and **Client Secret**

**Note**: The plugin uses the loopback flow (http://127.0.0.1:8080) which starts a temporary local server to catch the OAuth redirect. This is the recommended method for desktop applications.

### 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" (unless you have a Google Workspace)
3. Fill in the required fields:
   - App name: "Neovim Google Chat"
   - User support email: your email
   - Developer contact: your email
4. Add the following scopes:
   - `https://www.googleapis.com/auth/chat.spaces.readonly`
   - `https://www.googleapis.com/auth/chat.messages.readonly`
   - `https://www.googleapis.com/auth/chat.messages.create`
   - `https://www.googleapis.com/auth/chat.memberships.readonly`
5. Add your email as a test user (for external apps)

## Configuration

```lua
require("google-chat").setup({
  -- OAuth2 settings (REQUIRED)
  auth = {
    client_id = "YOUR_CLIENT_ID",
    client_secret = "YOUR_CLIENT_SECRET",
    redirect_uri = "http://127.0.0.1:8080", -- default (loopback for desktop)
    loopback_port = 8080, -- port for OAuth server
    token_file = vim.fn.stdpath("data") .. "/google-chat-tokens.json", -- default
  },

  -- UI settings
  ui = {
    split = "vertical", -- "vertical" or "horizontal"
    width = 80,
    date_format = "%Y-%m-%d %H:%M",
  },

  -- Telescope integration
  integrations = {
    telescope = {
      enabled = true,
    },
  },

  -- Logging (optional, for debugging)
  logging = {
    enabled = false,
    level = "info",
  },
})
```

## Usage

### Authentication

First, authenticate with Google:

```vim
:GoogleChatAuth
```

This will:
1. Start a temporary local HTTP server on port 8080
2. Open your browser with the Google OAuth consent page
3. Sign in and authorize the app
4. Google redirects back to the local server automatically
5. The authorization code is captured automatically
6. Your tokens will be securely stored for future sessions

**Note**: The plugin uses the OAuth loopback flow. After you click "Allow" in the browser, you should see a success page and can close the browser tab. No manual code copying needed!

Check authentication status:

```vim
:GoogleChatStatus
```

Logout:

```vim
:GoogleChatLogout
```

### Basic Commands

**List all spaces:**
```vim
:GoogleChatSpaces
```

In the spaces list:
- `<Enter>` - Open selected space to view messages
- `r` - Refresh spaces list
- `q` - Close window

**View messages in a space:**
- Press `<Enter>` on a space in the spaces list, or:
```vim
:GoogleChatOpen spaces/SPACE_ID
```

In the messages view:
- `s` - Send a message
- `r` - Refresh messages
- `q` - Close window

### Telescope Integration

**Browse spaces with Telescope:**
```vim
:Telescope google_chat spaces
```

**Search spaces:**
```vim
:Telescope google_chat search_spaces
```

**View messages in a space:**
```vim
:Telescope google_chat messages space_id=spaces/SPACE_ID
```

In Telescope pickers:
- `<Enter>` - Open selected item
- `<C-v>` - Open in vertical split
- `<C-x>` - Open in horizontal split

### Lua API

You can also use the Lua API directly:

```lua
local gchat = require("google-chat")

-- Authenticate
gchat.authenticate()

-- Show spaces
gchat.show_spaces()

-- Open a specific space
gchat.open_space("spaces/SPACE_ID")

-- Send a message
gchat.send_message("spaces/SPACE_ID", "Hello from Neovim!")

-- Telescope pickers
gchat.telescope_spaces()
gchat.telescope_search()
gchat.telescope_messages("spaces/SPACE_ID")
```

## Keybindings Example

You can set up custom keybindings in your Neovim config:

```lua
vim.keymap.set("n", "<leader>gc", ":Telescope google_chat spaces<CR>", { desc = "Google Chat Spaces" })
vim.keymap.set("n", "<leader>gs", ":GoogleChatSpaces<CR>", { desc = "Google Chat Spaces List" })
vim.keymap.set("n", "<leader>ga", ":GoogleChatAuth<CR>", { desc = "Google Chat Auth" })
```

## Troubleshooting

### Authentication Issues

**"Not authenticated" error:**
- Run `:GoogleChatAuth` to authenticate
- Make sure your client_id and client_secret are correct
- Check that you've enabled the Google Chat API in your project

**Token expired:**
- The plugin automatically refreshes tokens
- If this fails, run `:GoogleChatLogout` and `:GoogleChatAuth` again

**Permission denied when saving tokens:**
- Check that the token file path is writable
- Default location: `~/.local/share/nvim/google-chat-tokens.json`

### API Issues

**Rate limit errors:**
- The Google Chat API has rate limits
- Wait a moment and try again
- Configure polling intervals if using real-time updates

**"Invalid credentials" error:**
- Double-check your OAuth2 credentials
- Ensure you've added the correct scopes
- Verify you're added as a test user (for external apps)

### Debug Mode

Enable debug logging to troubleshoot issues:

```lua
require("google-chat").setup({
  logging = {
    enabled = true,
    level = "debug",
    file = vim.fn.stdpath("cache") .. "/google-chat.log",
  },
})
```

Then check the log file:
```vim
:edit ~/.cache/nvim/google-chat.log
```

## Security

- Tokens are stored in `~/.local/share/nvim/google-chat-tokens.json` with `600` permissions
- Never commit your `client_id` and `client_secret` to version control
- Use environment variables or a separate config file:

```lua
require("google-chat").setup({
  auth = {
    client_id = os.getenv("GOOGLE_CHAT_CLIENT_ID"),
    client_secret = os.getenv("GOOGLE_CHAT_CLIENT_SECRET"),
  },
})
```

## Roadmap

### Phase 2 - Enhanced Functionality
- [ ] Thread support (replies)
- [ ] Message reactions
- [ ] FZF integration
- [ ] Message search across spaces
- [ ] Caching system
- [ ] Real-time message updates

### Phase 3 - Advanced Features
- [ ] File attachments
- [ ] User/member picker
- [ ] Advanced search filters
- [ ] Custom actions and commands
- [ ] Multi-account support
- [ ] Notifications

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License

## Acknowledgments

- Built with [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Telescope integration using [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Inspired by other Neovim chat plugins
