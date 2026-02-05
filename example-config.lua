-- Example configuration for gchat.nvim
-- Copy this to your Neovim config and customize

-- Option 1: Using environment variables (recommended for security)
require("google-chat").setup({
  auth = {
    client_id = os.getenv("GOOGLE_CHAT_CLIENT_ID"),
    client_secret = os.getenv("GOOGLE_CHAT_CLIENT_SECRET"),
  },
})

-- Option 2: Direct configuration (not recommended for shared configs)
-- require("google-chat").setup({
--   auth = {
--     client_id = "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com",
--     client_secret = "YOUR_CLIENT_SECRET_HERE",
--   },
-- })

-- Option 3: Full configuration with all options
-- require("google-chat").setup({
--   auth = {
--     client_id = os.getenv("GOOGLE_CHAT_CLIENT_ID"),
--     client_secret = os.getenv("GOOGLE_CHAT_CLIENT_SECRET"),
--     redirect_uri = "http://localhost:8080",
--     token_file = vim.fn.stdpath("data") .. "/google-chat-tokens.json",
--   },
--   ui = {
--     split = "vertical",
--     width = 80,
--     height = 30,
--     date_format = "%Y-%m-%d %H:%M",
--   },
--   integrations = {
--     telescope = {
--       enabled = true,
--     },
--   },
--   logging = {
--     enabled = false,
--     level = "info",
--   },
-- })

-- Keybindings example
vim.keymap.set("n", "<leader>gcs", ":Telescope google_chat spaces<CR>", 
  { desc = "Google Chat: Browse Spaces" })
vim.keymap.set("n", "<leader>gca", ":GoogleChatAuth<CR>", 
  { desc = "Google Chat: Authenticate" })
vim.keymap.set("n", "<leader>gcl", ":GoogleChatSpaces<CR>", 
  { desc = "Google Chat: List Spaces" })
vim.keymap.set("n", "<leader>gct", ":GoogleChatStatus<CR>", 
  { desc = "Google Chat: Status" })

-- Load Telescope extension (if using Telescope)
local telescope = require("telescope")
telescope.load_extension("google_chat")
