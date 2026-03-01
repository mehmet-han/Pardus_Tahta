# Configuration Guide

This document explains the configuration variables used in the Fatih Client Python version, which are based on the original C# `ClassVariable.cs` implementation.

## Configuration File Location

The configuration file is located at:
- **Production**: `/etc/fatih-client/config.ini`
- **Development**: `./config.ini` (fallback)

## Configuration Variables

### Server API Configuration

#### `api_url`
- **Purpose**: The main API endpoint for server communication
- **Value**: `https://api.mebre.com.tr/v4/s_brt.php`
- **Source**: `ClassVariable.ApiUrl` in C# code
- **Usage**: All server communication (polling every 5 seconds, commands, acknowledgments)

### Authentication Credentials

#### `wb_user`
- **Purpose**: Username for server authentication
- **Value**: `hcrKd_r`
- **Source**: `ClassVariable.wbUser` in C# code
- **Usage**: HTTP Basic Authentication for all API requests

#### `wb_pass`
- **Purpose**: Password for server authentication
- **Value**: `B1Mu?WjG!Ga6`
- **Source**: `ClassVariable.wbPass` in C# code
- **Usage**: HTTP Basic Authentication for all API requests

### User Agent

#### `user_agent`
- **Purpose**: HTTP User-Agent header for API requests
- **Value**: `agent_SmartBoart`
- **Source**: `ClassVariable.userAgent` in C# code
- **Usage**: Identifies the client to the server

### Board Identification

#### `corporate_code`
- **Purpose**: Corporate/company identifier for the board
- **Value**: `1001` (example)
- **Usage**: Identifies which organization the board belongs to

#### `board_id`
- **Purpose**: Unique identifier for this specific board
- **Value**: `1` (example)
- **Usage**: Identifies the specific board to the server

#### `board_name`
- **Purpose**: Human-readable name for the board
- **Value**: `Pardus Board` (example)
- **Usage**: Display name sent to server

### Version Information

#### `version`
- **Purpose**: Main version number
- **Value**: `V2.13`
- **Source**: `ClassVariable.Vercion` in C# code
- **Usage**: Version identification and logging

#### `sub_version`
- **Purpose**: Sub-version number
- **Value**: `1`
- **Source**: `ClassVariable.SubVersiyon` in C# code
- **Usage**: Detailed version tracking

### Timing Configuration

#### `polling_interval`
- **Purpose**: How often to poll the server (in seconds)
- **Value**: `5`
- **Usage**: Controls server communication frequency
- **Note**: This matches the C# implementation's 5-second polling

#### `usb_check_interval`
- **Purpose**: How often to check USB status (in seconds)
- **Value**: `3`
- **Usage**: Controls USB monitoring frequency
- **Note**: This matches the C# implementation's 3-second USB checks

### Network Time Servers

#### `ntp_servers`
- **Purpose**: List of NTP servers for time synchronization
- **Value**: `time.windows.com,time.google.com,time.cloudflare.com,time.apple.com`
- **Source**: `ClassVariable.SattUrls` in C# code
- **Usage**: Network time synchronization when system is locked

## Example Configuration

```ini
[settings]
# Server API Configuration
api_url = https://api.mebre.com.tr/v4/s_brt.php

# Authentication credentials
wb_user = hcrKd_r
wb_pass = B1Mu?WjG!Ga6

# User agent
user_agent = agent_SmartBoart

# Board identification
corporate_code = 1001
board_id = 1
board_name = Pardus Board

# Version information
version = V2.13
sub_version = 1

# Network time servers
ntp_servers = time.windows.com,time.google.com,time.cloudflare.com,time.apple.com

# Timing configuration
polling_interval = 5
usb_check_interval = 3
```

## Configuration Validation

The client automatically validates the configuration on startup and will exit with an error if any required variables are missing. Required variables include:

- `api_url`
- `wb_user`
- `wb_pass`
- `user_agent`
- `corporate_code`
- `board_id`
- `version`
- `sub_version`

## Server Communication

### Polling Frequency
- **Main Server Poll**: Every 5 seconds (configurable via `polling_interval`)
- **USB Status Check**: Every 3 seconds (configurable via `usb_check_interval`)

### API Endpoints
All communication goes through the single API endpoint specified in `api_url`:
- **Function Code 5567**: Main polling and command reception
- **Function Code 5566**: Command acknowledgment
- **Function Code 3480**: Various operations

### Authentication
All requests use HTTP Basic Authentication with:
- Username: `wb_user`
- Password: `wb_pass`

## Security Notes

- **Credentials**: The `wb_user` and `wb_pass` values are hardcoded in the original C# application
- **API URL**: Uses HTTPS for secure communication
- **User Agent**: Identifies the client type to the server
- **Version Tracking**: Server can identify client versions for compatibility

## Troubleshooting

### Common Issues

1. **Configuration Error**: Check that all required variables are present in `config.ini`
2. **Authentication Failed**: Verify `wb_user` and `wb_pass` are correct
3. **Server Unreachable**: Check `api_url` and network connectivity
4. **Polling Issues**: Verify `polling_interval` is set correctly

### Logs

Configuration validation and server communication are logged to `~/fatih_client.log`. Check for:
- "Configuration validation passed" - Config loaded successfully
- "Server polling timer started" - Polling initialized
- "Successfully polled server" - Server communication working
- "Network exception" - Connection problems

## Migration from C#

When migrating from the C# version, ensure these mappings are correct:

| C# Variable | Python Config | Purpose |
|-------------|---------------|---------|
| `ClassVariable.ApiUrl` | `api_url` | Server endpoint |
| `ClassVariable.wbUser` | `wb_user` | Username |
| `ClassVariable.wbPass` | `wb_pass` | Password |
| `ClassVariable.userAgent` | `user_agent` | User agent |
| `ClassVariable.Vercion` | `version` | Main version |
| `ClassVariable.SubVersiyon` | `sub_version` | Sub version |
| `ClassVariable.SattUrls` | `ntp_servers` | Time servers |
