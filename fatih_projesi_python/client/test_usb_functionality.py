#!/usr/bin/env python3
"""
Test script for USB functionality in Fatih Client
This script can be used to test the USB detection and removal logic
without running the full application.
"""

import os
import time
import logging
from client import check_usb_password, check_usb_remove, USB_PASSWORD, USB_REMOVE_PASSWORD

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def test_usb_detection():
    """Test USB password detection"""
    print("=== Testing USB Password Detection ===")
    print(f"Looking for USB drive with password: {USB_PASSWORD[:20]}...")
    
    while True:
        try:
            if check_usb_password():
                print("✅ USB drive with correct password detected!")
                print("   System should unlock now")
            else:
                print("❌ No USB drive with correct password found")
                print("   System should remain locked")
            
            print("\n--- Checking for remove command ---")
            if check_usb_remove():
                print("⚠️  USB remove command detected!")
                print("   System will be removed")
            else:
                print("✅ No remove command found")
            
            print("\n" + "="*50)
            time.sleep(3)
            
        except KeyboardInterrupt:
            print("\n\nTest stopped by user")
            break
        except Exception as e:
            print(f"Error during test: {e}")
            time.sleep(3)

def test_usb_unlock_logic():
    """Test the USB unlock flag logic"""
    print("=== Testing USB Unlock Flag Logic ===")
    print("This test demonstrates the new behavior:")
    print("- System only locks on USB removal if unlocked by USB")
    print("- System does NOT lock on USB removal if unlocked by other means")
    print()
    
    print("Scenario 1: USB unlocks system, then USB removed")
    print("✅ Expected: System locks back (because it was unlocked by USB)")
    print()
    
    print("Scenario 2: Server unlocks system, then USB removed")
    print("✅ Expected: System stays unlocked (because it was NOT unlocked by USB)")
    print()
    
    print("Scenario 3: USB unlocks system, server locks it, then USB removed")
    print("✅ Expected: System stays locked (USB flag was reset when server locked it)")
    print()
    
    print("The key improvement is that USB removal only affects the system")
    print("if that specific USB drive was responsible for unlocking it.")
    print()
    
    input("Press Enter to continue...")

def create_test_files():
    """Create test files for testing"""
    print("=== Creating Test Files ===")
    
    # Create a test directory
    test_dir = "/tmp/fatih_test_usb"
    os.makedirs(test_dir, exist_ok=True)
    
    # Create pass.txt
    pass_file = os.path.join(test_dir, "pass.txt")
    with open(pass_file, 'w') as f:
        f.write(USB_PASSWORD)
    print(f"✅ Created {pass_file}")
    
    # Create rmove.txt
    remove_file = os.path.join(test_dir, "rmove.txt")
    with open(remove_file, 'w') as f:
        f.write(USB_REMOVE_PASSWORD)
    print(f"✅ Created {remove_file}")
    
    print(f"\nTest files created in: {test_dir}")
    print("To test USB detection, you can:")
    print("1. Mount this directory as a USB drive")
    print("2. Or copy these files to an actual USB drive")
    print("3. Run the test: python3 test_usb_functionality.py")
    
    print("\n=== NEW BEHAVIOR EXPLAINED ===")
    print("The system now tracks HOW it was unlocked:")
    print("- If unlocked by USB: Removing USB will lock it back")
    print("- If unlocked by server/other means: Removing USB will NOT lock it")
    print("- This prevents unwanted locking when USB is removed after server unlock")

if __name__ == "__main__":
    print("Fatih Client USB Functionality Test")
    print("=" * 40)
    
    choice = input("Choose option:\n1. Create test files\n2. Run USB detection test\n3. Test USB unlock logic\nEnter choice (1, 2, or 3): ")
    
    if choice == "1":
        create_test_files()
    elif choice == "2":
        test_usb_detection()
    elif choice == "3":
        test_usb_unlock_logic()
    else:
        print("Invalid choice. Exiting.")
