# gchat.nvim Quick Start Guide

Get up and running with Google Chat in Neovim in under 10 minutes.

## Prerequisites

- Neovim >= 0.8.0
- plenary.nvim installed
- A Google account
- 10 minutes

## Step 1: Install the Plugin (2 minutes)

### Using lazy.nvim

Add to your `~/.config/nvim/lua/plugins/gchat.lua`:

```lua
return {
  "paulatcodescout/gchat.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("google-chat").setup({
      auth = {
        client_id = os.getenv("GOOGLE_CHAT_CLIENT_ID"),
        client_secret = os.getenv("GOOGLE_CHAT_CLIENT_SECRET"),
      },
    })
  end,
}
```

Or add to your main config:

```lua
require("lazy").setup({
  {
    "paulatcodescout/gchat.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("google-chat").setup({
        auth = {
          client_id = os.getenv("GOOGLE_CHAT_CLIENT_ID"),
          client_secret = os.getenv("GOOGLE_CHAT_CLIENT_SECRET"),
        },
      })
    end,
  },
})
```

Restart Neovim or run `:Lazy sync`

## Step 2: Get Google OAuth Credentials (5 minutes)

### 2.1 Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it "Neovim Google Chat" and click "Create"
4. Wait for the project to be created

### 2.2 Enable Google Chat API

1. In the search bar, type "Google Chat API"
2. Click on it and click "Enable"
3. Wait for the API to be enabled

### 2.3 Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure the OAuth consent screen:
   - User Type: External
   - App name: "Neovim Google Chat"
   - User support email: your email
   - Developer contact: your email
   - Click "Save and Continue"
   - On the Scopes page, add these scopes:
     - `https://www.googleapis.com/auth/chat.spaces.readonly`
     - `https://www.googleapis.com/auth/chat.messages.readonly`
     - `https://www.googleapis.com/auth/chat.messages.create`
     - `https://www.googleapis.com/auth/chat.memberships.readonly`
   - Click "Save and Continue"
   - Add yourself as a test user
   - Click "Save and Continue"
4. Back to creating OAuth client ID:
   - Application type: "Desktop app"
   - Name: "Neovim"
   - Click "Create"
5. **Copy the Client ID and Client Secret** (you'll need these!)

### 2.4 Set Environment Variables

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`:

```bash
# Bash/Zsh
export GOOGLE_CHAT_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CHAT_CLIENT_SECRET="your-client-secret"
```

```fish
# Fish
set -Ux GOOGLE_CHAT_CLIENT_ID "your-client-id.apps.googleusercontent.com"
set -Ux GOOGLE_CHAT_CLIENT_SECRET "your-client-secret"
```

Reload your shell or run `source ~/.bashrc` (or equivalent).

## Step 3: Authenticate (2 minutes)

1. Open Neovim
2. Run: `:GoogleChatAuth`
3. The plugin starts a temporary local server on port 8080
4. Your browser opens with Google's consent screen
5. Sign in and click "Allow"
6. Google redirects back to localhost automatically
7. You'll see "Authentication Successful!" in the browser
8. Close the browser tab and return to Neovim

You should see: "Successfully authenticated with Google Chat!"

**That's it!** The OAuth loopback flow handles everything automatically - no need to copy/paste codes.

## Step 4: Start Using It (1 minute)

### List your spaces

```vim
:GoogleChatSpaces
```

Press `<Enter>` on a space to view messages.

### Use Telescope (if installed)

```vim
:Telescope google_chat spaces
```

Type to search, press `<Enter>` to open.

### Send a message

1. Open a space
2. Press `s` (for send)
3. Type your message and press Enter

### Check status

```vim
:GoogleChatStatus
```

## Quick Reference

### Commands

| Command | Description |
|---------|-------------|
| `:GoogleChatAuth` | Authenticate |
| `:GoogleChatStatus` | Check auth status |
| `:GoogleChatSpaces` | List spaces |
| `:Telescope google_chat spaces` | Browse with Telescope |

### Keybindings (in buffers)

| Key | Description |
|-----|-------------|
| `<Enter>` | Open selected space |
| `s` | Send message (in message view) |
| `r` | Refresh |
| `q` | Close window |

### Telescope Keybindings

| Key | Description |
|-----|-------------|
| `<Enter>` | Open selected |
| `<C-v>` | Open in vsplit |
| `<C-x>` | Open in split |

## Recommended Keybindings

Add to your Neovim config:

```lua
vim.keymap.set("n", "<leader>gc", ":Telescope google_chat spaces<CR>", 
  { desc = "Google Chat" })
vim.keymap.set("n", "<leader>ga", ":GoogleChatAuth<CR>", 
  { desc = "Google Chat Auth" })
```

Now use `<leader>gc` to quickly open Google Chat!

## Troubleshooting

### "Not authenticated" error

Run `:GoogleChatAuth` again.

### "Failed to exchange authorization code"

- Check your client_id and client_secret
- Make sure you've enabled the Google Chat API
- Verify environment variables are set: `:echo $GOOGLE_CHAT_CLIENT_ID`

### "Telescope not found"

Telescope is optional. Use `:GoogleChatSpaces` instead.

### Token expired

The plugin automatically refreshes tokens. If issues persist:
```vim
:GoogleChatLogout
:GoogleChatAuth
```

### Still having issues?

Enable debug logging:

```lua
require("google-chat").setup({
  auth = { ... },
  logging = {
    enabled = true,
    level = "debug",
  },
})
```

Check the log: `:edit ~/.cache/nvim/google-chat.log`

## Next Steps

- Read the [full README](README.md) for advanced features
- Check [IMPLEMENTATION.md](IMPLEMENTATION.md) for technical details
- Set up custom keybindings for your workflow
- Explore Telescope integration features

## Tips

1. **Use environment variables** for credentials (never commit them!)
2. **Add test users** in Google Cloud Console if using "External" app type
3. **Use Telescope** for the best experience (fuzzy search is fast!)
4. **Set up keybindings** for quick access
5. **Check status** with `:GoogleChatStatus` if something seems wrong

Enjoy chatting from Neovim! 🚀
