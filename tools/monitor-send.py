# Sends a program (Intel HEX) to the board's monitor, then stays connected as a serial console.
#   monitor-send.py file.ihx    send the file, then console
#   monitor-send.py             console only
# Opening the port resets the board (DTR), so the console has to be this same process: another
# program opening the port afterwards (screen...) would reset the board and lose the program.
# Quit with Ctrl-].
import glob, os, select, serial, sys, termios, time, tty

names = glob.glob("/dev/cu.usbserial-*")
if not names:
    sys.exit("no /dev/cu.usbserial-* found: is the board plugged in?")
port = serial.Serial(names[0], 115200)
time.sleep(2)  # the board resets when the port opens: let the monitor start
print(port.read(port.in_waiting).decode("latin1"))
if len(sys.argv) > 1:
    port.write(open(sys.argv[1], "rb").read())

print("[console on %s, Ctrl-] to quit]" % names[0], flush=True)
fd = sys.stdin.fileno()
saved = termios.tcgetattr(fd)
tty.setraw(fd)  # every key goes to the board as is: Enter sends '\r'
try:
    while True:
        ready, _, _ = select.select([fd, port.fileno()], [], [])
        if port.fileno() in ready:
            os.write(sys.stdout.fileno(), port.read(port.in_waiting or 1))
        if fd in ready:
            key = os.read(fd, 1)
            if key == b"\x1d":  # Ctrl-]
                break
            port.write(key)
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, saved)
    print()
