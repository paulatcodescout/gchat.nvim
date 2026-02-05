# Google Chat App Configuration Required

## Issue

Getting error: "Google chat app not found. To create a Chat app, you must turn on Chat API and configure the app in Google Cloud console"

## Why This Happens

Even when using **user authentication** (OAuth2), Google requires you to configure a Chat app in the Google Cloud Console. This is different from typical OAuth apps - the Chat API needs app configuration regardless of authentication method.

## Solution: Configure Your Chat App

### Step 1: Enable Google Chat API (Already Done)

You've already enabled the API, so this is complete.

### Step 2: Configure the Chat API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **"APIs & Services"** → **"Enabled APIs & services"**
4. Find and click on **"Google Chat API"**
5. Click **"Configuration"** tab (this is the key step!)

### Step 3: Configure Chat App Settings

On the Configuration page, fill in:

#### App Status
- **Status**: Set to "LIVE" (not draft)

#### App Name and Description
- **App name**: `Neovim Google Chat`
- **Avatar URL**: Leave blank or use any image URL
- **Description**: `Neovim plugin for Google Chat integration`

#### Functionality
- **Enable Interactive features**: UNCHECK this (we don't need it for read/write messages)
- **Enable Slash commands**: UNCHECK
- **Enable Link previews**: UNCHECK

#### Connection Settings
- **App URL**: Leave blank
- **Authentication Audience**: 
  - Select **"Domain-specific or HTTP audience"** 
  - This works fine for "Internal" apps

#### Visibility
- **Make this Chat app available to**: Select **"Specific people and groups in [Your Domain]"**
- Add your email address as a user who can install the app

### Step 4: OAuth Scopes (Already Configured)

Your OAuth consent screen already has the correct scopes:
- `https://www.googleapis.com/auth/chat.spaces.readonly`
- `https://www.googleapis.com/auth/chat.messages.readonly`
- `https://www.googleapis.com/auth/chat.messages.create`
- `https://www.googleapis.com/auth/chat.memberships.readonly`

### Step 5: Save Configuration

Click **"Save"** at the bottom of the page.

## Internal vs External

**"Internal" audience is fine** for your use case. This means:
- Only users in your Google Workspace organization can use the app
- No external verification required
- Faster setup
- More appropriate for personal/team use

## What This Enables

Once configured, your Chat app will:
- Be recognized by the Chat API
- Allow user authentication (OAuth2) to work
- Let you list spaces, read messages, and send messages
- Work with your existing OAuth credentials

## Common Misconceptions

- ❌ "I'm not building a bot, so I don't need a Chat app"
- ✅ **Reality**: Chat API requires app configuration even for user auth

- ❌ "Chat apps are only for service accounts"
- ✅ **Reality**: Chat apps support both service account AND user OAuth authentication

- ❌ "Internal apps don't need configuration"
- ✅ **Reality**: All apps need the Configuration tab completed

## After Configuration

1. Wait a few minutes for changes to propagate
2. Re-run `:GoogleChatAuth` if needed
3. Try `:GoogleChatSpaces` again
4. Should work now!

## Verification

After configuring, you can verify by:
1. Going to Google Chat (chat.google.com)
2. Click the "+" button to create a space
3. You should be able to add your app (though we're using user auth, so this isn't necessary)

## References

- [Authenticate as a Google Chat user](https://developers.google.com/workspace/chat/authenticate-authorize-chat-user)
- [Google Chat API Configuration](https://developers.google.com/workspace/chat/quickstart/gcf-app)

---

**Important**: The Chat API requires app configuration in all cases. This is a one-time setup that takes about 2 minutes.
