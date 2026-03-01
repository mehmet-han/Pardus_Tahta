# /server/app/main.py
import base64
from fastapi import FastAPI, Request, Header, Depends, HTTPException, status, Form
from fastapi.responses import PlainTextResponse, JSONResponse
from typing import Optional, Annotated
from . import storage

app = FastAPI()

# --- Authentication and Header Processing ---

EXPECTED_USERNAME = "hcrKd_r"
EXPECTED_PASSWORD = "B1Mu?WjG!Ga6"
print("\n\n\nSERVER VERSION 2.0 IS RUNNING!")
print("This server mimics the PHP server behavior for testing!")
print("All function codes and data formats match the C# client exactly!\n\n\n")


def reverse_cFnc(obfuscated_string: str) -> str:
    """Reverse the cFnc obfuscation to get the original function code"""
    if not obfuscated_string: 
        return ""
    
    # The original replacement map from C# Tools.cFnc()
    reverse_map = {
        "!g": "0", "gt": "1", "_a": "2", "me": "3", "?b": "4",
        "_z": "5", "fi": "6", "+d": "7", "da": "8", "|k": "9",
        "kz": " ", "?u": ".", "wa": ":"
    }
    
    # Extract the core part before the timestamp
    if '?' in obfuscated_string:
        core_part = obfuscated_string.split('?')[0]
    else:
        core_part = obfuscated_string
    
    # Reverse the replacements (longest keys first to avoid conflicts)
    for key in sorted(reverse_map.keys(), key=len, reverse=True):
        core_part = core_part.replace(key, reverse_map[key])
    
    return core_part

async def verify_auth(authorization: Annotated[str, Header()]):
    """Dependency to verify HTTP Basic Auth credentials - EXACTLY like C# client"""
    print(f"=== AUTH DEBUG ===")
    print(f"Authorization header received: '{authorization}'")
    try:
        auth_type, credentials_b64 = authorization.split()
        print(f"Auth type: '{auth_type}', Credentials (base64): '{credentials_b64}'")
        if auth_type.lower() == 'basic':
            credentials = base64.b64decode(credentials_b64).decode('utf-8')
            username, password = credentials.split(':', 1)
            print(f"Decoded credentials - Username: '{username}', Password: '{password}'")
            print(f"Expected - Username: '{EXPECTED_USERNAME}', Password: '{EXPECTED_PASSWORD}'")
            if username == EXPECTED_USERNAME and password == EXPECTED_PASSWORD:
                print("Authentication successful!")
                return
            else:
                print("Authentication failed - credentials don't match")
        else:
            print(f"Wrong auth type: '{auth_type}' (expected 'basic')")
    except Exception as e:
        print(f"Authentication error: {e}")
        pass
    print("Raising 401 Unauthorized")
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Basic"},
    )

# --- The Single API Endpoint (EXACTLY like PHP server) ---

@app.post("/v4/s_brt.php")
@app.post("/") # Also accept requests to root for easier testing
async def handle_request(
    request: Request,
    user_agent: Annotated[Optional[str], Header(alias="user-agent")] = None,
    user_key: Annotated[Optional[str], Header(alias="user-key")] = None,
    user_core: Annotated[Optional[str], Header(alias="usercore")] = None,
    auth: None = Depends(verify_auth)
):
    # Debug: Print all headers received
    print(f"\n=== ALL HEADERS RECEIVED ===")
    for header_name, header_value in request.headers.items():
        print(f"{header_name}: {header_value}")
    print(f"=== END HEADERS ===\n")
    
    print(f"User-Agent header received: '{user_agent}'")
    print(f"User-Key header received: '{user_key}'")
    print(f"UserCore header received: '{user_core}'")
    
    # Verify User-Agent EXACTLY like C# client expects
    if user_agent != "agent_SmartBoart":
        print(f"User-Agent mismatch! Expected: 'agent_SmartBoart', Got: '{user_agent}'")
        raise HTTPException(status_code=403, detail="Invalid User-Agent")

    # Get form data (EXACTLY like C# NameValueCollection)
    form_data = await request.form()
    
    # Decode the UserCore function code
    decoded_core = reverse_cFnc(user_core)
    
    # Extract key data fields (EXACTLY like C# client)
    corporate_code = form_data.get("corporate_code", "0")
    board_id = form_data.get("t_n", "0")
    board_name = form_data.get("t_na", "Unknown Board")

    print(f"\n--- Request Received ---")
    print(f"UserCore: {user_core} (Decoded: {decoded_core})")
    print(f"Corporate Code: {corporate_code}, Board ID: {board_id}, Board Name: {board_name}")
    print(f"Form Data: {dict(form_data)}")

    # --- Routing based on decoded UserCore (EXACTLY like C# client) ---

    # 5567: Main Polling & Get Commands (CtrlPost function)
    if decoded_core == "5567":
        print(f"Function 5567: Main polling request from board {board_id}")
        board = storage.get_board_data(corporate_code, board_id)
        
        # Response format EXACTLY like C# client expects
        response_str = (
            f"{board['tahtaLock']},"
            f"{board['message'] or '0'},"
            f"{board['shutDown']},"
            f"{board['systemRemove']},"
            f"{board['logSend']}"
        )
        print(f"Responding with commands: {response_str}")
        return PlainTextResponse(content=response_str)

    # 5563: Get Configuration & Schedule (GetValues function)
    elif decoded_core == "5563":
        print(f"Function 5563: Get configuration for board {board_id}")
        board = storage.get_board_data(corporate_code, board_id)
        
        # Response format EXACTLY like C# client expects (JSON)
        response_data = [{
            "id": int(board_id),
            "Name": board['name'],
            "hours": board['hours']
        }]
        print(f"Responding with configuration: {response_data}")
        return JSONResponse(content=response_data)

    # 5566: Acknowledge a Command (SetValue function)
    elif decoded_core == "5566":
        print(f"Function 5566: Command acknowledgment")
        column = form_data.get("c_l")
        value = form_data.get("value")
        if column and value is not None:
            storage.set_board_value(corporate_code, board_id, column, value)
            print(f"Updated {column} = {value} for board {board_id}")
        return PlainTextResponse(content="OK")

    # 5571: Upload Logs (save function)
    elif decoded_core == "5571":
        print(f"Function 5571: Log upload request")
        log_content = form_data.get("log")
        log_type = form_data.get("vog")
        print(f"--- LOG RECEIVED ({log_type}) ---")
        print(log_content)
        print("--- END LOG ---")
        
        # Acknowledge log receipt (like C# client expects)
        storage.set_board_value(corporate_code, board_id, "logSend", 0)
        return PlainTextResponse(content="OK")

    # 5574: Log Request (logRequest function)
    elif decoded_core == "5574":
        print(f"Function 5574: Log request")
        # Just acknowledge the request
        return PlainTextResponse(content="OK")

    # 5573: Get Inspection Data (GetInspc function)
    elif decoded_core == "5573":
        print(f"Function 5573: Get inspection data")
        s_t = form_data.get("s_t", "0")
        g_n = form_data.get("g_n", "0")
        print(f"Inspection request: s_t={s_t}, g_n={g_n}")
        # Return some sample inspection data
        return PlainTextResponse(content="Inspection data for period")

    # 5570: Version Check (vck function)
    elif decoded_core == "5570":
        print(f"Function 5570: Version check request")
        # Return same or newer version than C# client
        return PlainTextResponse(content="V2.13")

    # Unknown function codes
    else:
        print(f"Unknown UserCore value: {decoded_core}")
        raise HTTPException(status_code=400, detail=f"Unknown UserCore value: {decoded_core}")

# --- Control Panel for Testing ---

@app.get("/control/{corporate_code}/{board_id}")
def get_control_panel(corporate_code: str, board_id: str):
    """Simple HTML control panel for testing - matches C# client behavior"""
    board = storage.get_board_data(corporate_code, board_id)
    return PlainTextResponse(f"""
    <html><body>
        <h1>Control Panel for Board {corporate_code}/{board_id}</h1>
        <h2>Current Status</h2>
        <p><strong>Board Name:</strong> {board['name']}</p>
        <p><strong>Lock Status:</strong> {board['tahtaLock']} (1=Locked, 0=Unlocked)</p>
        <p><strong>Message:</strong> {board['message'] or 'None'}</p>
        <p><strong>Shutdown:</strong> {board['shutDown']} (1=Yes, 0=No)</p>
        <p><strong>System Remove:</strong> {board['systemRemove']} (1=Yes, 0=No)</p>
        <p><strong>Log Send:</strong> {board['logSend']} (1=Requested, 0=No)</p>
        
        <h2>Send Commands</h2>
        <form action="/control/{corporate_code}/{board_id}" method="post">
            <label>Lock Status (1=Lock, 0=Unlock):</label><br>
            <input name="tahtaLock" value="{board['tahtaLock']}"><br><br>
            
            <label>Message:</label><br>
            <input name="message" value="{board['message'] or ''}" size="50"><br><br>
            
            <label>Shutdown (1=Yes, 0=No):</label><br>
            <input name="shutDown" value="{board['shutDown']}"><br><br>
            
            <label>Remove System (1=Yes, 0=No):</label><br>
            <input name="systemRemove" value="{board['systemRemove']}"><br><br>
            
            <label>Request Logs (1=Yes, 0=No):</label><br>
            <input name="logSend" value="{board['logSend']}"><br><br>
            
            <input type="submit" value="Update Commands">
        </form>
        
        <h2>Test Function Codes</h2>
        <p>This server handles all the same function codes as the C# client:</p>
        <ul>
            <li><strong>5567:</strong> Main polling (CtrlPost)</li>
            <li><strong>5563:</strong> Get configuration (GetValues)</li>
            <li><strong>5566:</strong> Command acknowledgment (SetValue)</li>
            <li><strong>5571:</strong> Log upload (save)</li>
            <li><strong>5574:</strong> Log request (logRequest)</li>
            <li><strong>5573:</strong> Inspection data (GetInspc)</li>
            <li><strong>5570:</strong> Version check (vck)</li>
        </ul>
        
        <h2>Python Client Test</h2>
        <p>Your Python client should work EXACTLY like the C# client with this server!</p>
    </body></html>
    """, media_type="text/html")

@app.post("/control/{corporate_code}/{board_id}")
async def set_control_panel(request: Request, corporate_code: str, board_id: str):
    """Update board commands via control panel"""
    form = await request.form()
    print(f"Control panel update for board {corporate_code}/{board_id}: {dict(form)}")
    
    for key, value in form.items():
        storage.set_board_value(corporate_code, board_id, key, value)
    
    return PlainTextResponse("Commands updated successfully!")

# --- Health Check Endpoint ---

@app.get("/health")
def health_check():
    """Simple health check endpoint"""
    return {"status": "healthy", "server": "FastAPI Test Server v2.0", "compatible": "C# Client"}