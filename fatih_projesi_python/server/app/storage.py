# /server/app/storage.py
import json
from typing import Dict, Any

# In-memory "database" to store the state of each smartboard.
# In a real application, this would be a real database like PostgreSQL or Redis.
# Structure: { corporate_code: { board_id: { board_data } } }
db: Dict[str, Dict[str, Dict[str, Any]]] = {}

def get_board_data(corporate_code: str, board_id: str) -> Dict[str, Any]:
    """Gets the data for a specific board, creating it if it doesn't exist."""
    if corporate_code not in db:
        db[corporate_code] = {}
    
    if board_id not in db[corporate_code]:
        # Default state for a new board - matches C# client expectations
        db[corporate_code][board_id] = {
            "name": f"Board {board_id}",  # Default board name
            "tahtaLock": 1,  # Start locked by default (like C# client)
            "message": "Sistem Yöneticisi Tarafından Yönetilmektedir.",
            "shutDown": 0,
            "systemRemove": 0,
            "logSend": 0,
            "hours": get_default_schedule()  # A default schedule matching C# structure
        }
    return db[corporate_code][board_id]

def set_board_value(corporate_code: str, board_id: str, column: str, value: Any):
    """Updates a specific value for a board."""
    board = get_board_data(corporate_code, board_id)
    
    # Handle special cases for specific columns
    if column == "t_na" or column == "board_name":
        # Update board name
        board["name"] = str(value)
    elif column in ["tahtaLock", "shutDown", "systemRemove", "logSend"]:
        # Convert integer fields
        try:
            value = int(value)
        except (ValueError, TypeError):
            value = 0
        board[column] = value
    else:
        # Store other values as-is
        board[column] = value
    
    print(f"DB Update: [{corporate_code}/{board_id}] set {column} = {value}")

def get_default_schedule():
    """Create a default schedule matching the C# client structure"""
    try:
        # Try to load existing schedule file
        with open("default_schedule.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        # Create default schedule if file doesn't exist
        # C# structure: hours[8, 19, 3] - 8 days (0-7), 19 hours (0-18), 3 properties
        schedule = [[["" for _ in range(3)] for _ in range(19)] for _ in range(8)]
        
        # Set some example times for Monday (day 1)
        # Period 1: 09:00 - 09:40
        schedule[1][1][1] = "09:00"  # Start time
        schedule[1][1][2] = "09:40"  # End time
        
        # Period 2: 09:50 - 10:30
        schedule[1][2][1] = "09:50"
        schedule[1][2][2] = "10:30"
        
        # Period 3: 10:40 - 11:20
        schedule[1][3][1] = "10:40"
        schedule[1][3][2] = "11:20"
        
        # Period 4: 11:30 - 12:10
        schedule[1][4][1] = "11:30"
        schedule[1][4][2] = "12:10"
        
        # Period 5: 12:20 - 13:00
        schedule[1][5][1] = "12:20"
        schedule[1][5][2] = "13:00"
        
        # Period 6: 13:10 - 13:50
        schedule[1][6][1] = "13:10"
        schedule[1][6][2] = "13:50"
        
        # Period 7: 14:00 - 14:40
        schedule[1][7][1] = "14:00"
        schedule[1][7][2] = "14:40"
        
        # Period 8: 14:50 - 15:30
        schedule[1][8][1] = "14:50"
        schedule[1][8][2] = "15:30"
        
        # Save the default schedule
        try:
            with open("default_schedule.json", "w") as f:
                json.dump(schedule, f, indent=2)
        except Exception as e:
            print(f"Warning: Could not save default schedule: {e}")
        
        return schedule

def get_board_status(corporate_code: str, board_id: str) -> Dict[str, Any]:
    """Get a summary of board status for monitoring"""
    board = get_board_data(corporate_code, board_id)
    return {
        "corporate_code": corporate_code,
        "board_id": board_id,
        "name": board["name"],
        "status": "locked" if board["tahtaLock"] == 1 else "unlocked",
        "message": board["message"],
        "shutdown_requested": board["shutDown"] == 1,
        "system_remove_requested": board["systemRemove"] == 1,
        "log_requested": board["logSend"] == 1
    }

def list_all_boards() -> Dict[str, Any]:
    """List all boards in the system"""
    result = {}
    for corp_code in db:
        result[corp_code] = {}
        for board_id in db[corp_code]:
            result[corp_code][board_id] = get_board_status(corp_code, board_id)
    return result