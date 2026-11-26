# Sends a program (Intel HEX) to the board's monitor, then stays connected as a serial console.
#   monitor-send.py file.ihx    type "load", send the file, type "run", then console
#   monitor-send.py             console only
# Without a keyboard (stdin is not a terminal), it shows the output for $Z80_WAIT seconds (5), then
# quits instead of opening the console.
# Opening the port resets the board (DTR), so the console has to be this same process: another
# program opening the port afterwards (screen...) would reset the board and lose the program.
# Quit with Ctrl-].
#
# Port: $Z80_PORT, else tower:7023. The board is plugged into the NAS (tower), whose ser2net
# publishes the serial link as raw TCP over Tailscale (nixos-tower/modules/services/z80-serie.nix);
# ser2net opens the serial port when a client connects, so connecting resets the board too.
# Z80_PORT=/dev/cu.usbserial-XXXX when the board is plugged into the Mac.
# Standard library only.
import os, re, select, socket, sys, termios, time, tty

spec = os.environ.get("Z80_PORT") or "tower:7023"
tcp = re.fullmatch(r"(?:tcp://|socket://)?([^:/]+):(\d+)", spec)
if tcp:
    try:
        sock = socket.create_connection((tcp[1], int(tcp[2])), timeout=10)
    except OSError as e:
        sys.exit("cannot connect to %s (%s): Tailscale up? z80-serie running on the NAS?" % (spec, e))
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)  # no delay on the monitor's echo
    port = sock.fileno()
else:
    if not os.path.exists(spec):
        sys.exit("no %s: is the board plugged in?" % spec)
    port = os.open(spec, os.O_RDWR | os.O_NOCTTY)
    attr = termios.tcgetattr(port)
    attr[0] = attr[1] = attr[3] = 0  # raw
    attr[2] = termios.CS8 | termios.CREAD | termios.CLOCAL  # 8N1
    attr[4] = attr[5] = termios.B115200
    termios.tcsetattr(port, termios.TCSANOW, attr)
os.set_blocking(port, False)


def read_available():
    data = b""
    while select.select([port], [], [], 0)[0]:
        chunk = os.read(port, 4096)
        if not chunk:  # TCP: closed by ser2net (board unplugged, another client took over)
            raise EOFError
        data += chunk
    return data


def write_all(data):
    while data:
        try:
            data = data[os.write(port, data):]
        except BlockingIOError:
            select.select([], [port], [])


def expect(text, seconds):
    """Show what the board sends until text appears; False after the timeout."""
    seen = b""
    end = time.time() + seconds
    while time.time() < end:
        if select.select([port], [], [], 0.1)[0]:
            chunk = read_available()
            os.write(sys.stdout.fileno(), chunk)
            seen += chunk
            if text in seen:
                return True
    return False


if sys.stdin.isatty():  # first: everything the board sends from now on is shown
    print("[console on %s, Ctrl-] to quit]" % spec, flush=True)

# the board resets when the port opens: wait for the prompt (up to 6 s more without a CF card)
if not expect(b">", 10):
    print("\n[no prompt from the monitor]")
if len(sys.argv) > 1:
    write_all(b"load\r")
    if not expect(b"waiting for program", 3):
        sys.exit("\n[no answer to load]")
    # without the line end after the last record: it would be read as an empty command line
    write_all(open(sys.argv[1], "rb").read().rstrip(b"\r\n"))
    if not expect(b">", 30):
        sys.exit("\n[the monitor did not come back after load]")
    write_all(b"run\r")

if not sys.stdin.isatty():  # no keyboard (script, pipe): show the output for a while, then quit
    expect(b"\0", float(os.environ.get("Z80_WAIT", "5")))
    print()
    sys.exit()

fd = sys.stdin.fileno()
saved = termios.tcgetattr(fd)
tty.setraw(fd)  # every key goes to the board as is: Enter sends '\r'
try:
    while True:
        ready, _, _ = select.select([fd, port], [], [])
        if port in ready:
            os.write(sys.stdout.fileno(), read_available())
        if fd in ready:
            key = os.read(fd, 1)
            if key == b"\x1d":  # Ctrl-]
                break
            write_all(key)
except EOFError:
    print("\r\n[connection closed by the other end]", end="")
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, saved)
    print()
