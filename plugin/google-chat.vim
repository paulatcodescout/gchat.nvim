" google-chat.vim - Google Chat integration for Neovim
" Maintainer: Paul
" Version: 0.1.0

if exists('g:loaded_google_chat')
  finish
endif
let g:loaded_google_chat = 1

" Commands
command! GoogleChatSetup lua require('google-chat').setup()
command! GoogleChatAuth lua require('google-chat').authenticate()
command! GoogleChatLogout lua require('google-chat').logout()
command! GoogleChatStatus lua require('google-chat').status()
command! GoogleChatSpaces lua require('google-chat').show_spaces()
command! -nargs=1 GoogleChatOpen lua require('google-chat').open_space(<f-args>)

" Telescope commands
command! GoogleChatTelescopeSpaces lua require('google-chat').telescope_spaces()
command! GoogleChatTelescopeSearch lua require('google-chat').telescope_search()
command! -nargs=1 GoogleChatTelescopeMessages lua require('google-chat').telescope_messages(<f-args>)

" Shorter aliases
command! GCAuth GoogleChatAuth
command! GCSpaces GoogleChatSpaces
command! GCStatus GoogleChatStatus
command! GCTelescope GoogleChatTelescopeSpaces
