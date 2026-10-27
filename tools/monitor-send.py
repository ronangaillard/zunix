import glob, serial, sys, time

name = glob.glob("/dev/cu.usbserial-*")[0]
port = serial.Serial(name, 115200)
time.sleep(2)
print(port.read(port.in_waiting).decode("latin1"))
port.write(open(sys.argv[1], "rb").read())
while True:
    print(port.read(1).decode("latin1"), end="", flush=True)