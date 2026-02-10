# corry-logging

It essentially serves as a internal logging system without using Discord or other logging services. Not sure how resource heavy this is using json to store the data, but will likely add an option for sql or a browser option.

Feel free to star the repository and check out my portfolio and discord @ Discord: https://discord.gg/H7MVAeejPt & Portfolio: https://corry.io 
For support inquires please create a post in the support-forum channel on discord or create an issue here on Github.


### Video Preview


## Installation

1. Clone or download this resource.
2. Place it in the server's resource directory.
3. Add the resource to your server config, if needed.

## Usage

### Exports
Exports are exclusively available on the client and can't be called from server-side files.

**Client/Server**
- `AddLog(level, message, notify)`
   - `level`: The log "category".
   - `message`: The primary message of the log. Shouldn't contain any player information; that is already provided.
   - `notify`: Not Required; defaults to False. Alerts admins of the log. Good for Possible Cheating Triggers/Alerts

### Example Usage

Utilizing Exports
```lua
exports['corry-logging']:AddLog('INVENTORY', 'Received x10 Sandwich')

exports['corry-logging']:AddLog('CHEATING', 'Possible vehicle exploit', true)
```

### Contextual Example
```lua
AddEventHandler('QBCore:Client:OnPlayerUnloaded', function()
  exports['corry-logging']:AddLog('FRAMEWORK', 'Player left the server')
end)

-- Sent from client to display player information.
```

When clearing all logs, either delete the json file, or ctrl+a delete then type []
