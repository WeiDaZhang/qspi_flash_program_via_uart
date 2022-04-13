import time
import os
import serial
def write_to_uart():
    s = serial.Serial(port="COM5", baudrate=115200, bytesize=8, timeout=2, stopbits=serial.STOPBITS_ONE)
    res = b'';
    while 1:
        if s.in_waiting > 0:
            res = s.readline()
            print(res.decode("Ascii"))
        if res != b'5: Read Quad SPI flash\r\n' :
            continue

        res = input()
        s.write(res.encode("Ascii"))
        if res != '4' :
            continue

        while 1:
            print('Enter bitstream (*.bin) file name and path:')
            res = input()
            try:
                f = open(res, "rb")
                break
            except FileNotFoundError :
                print("File not found.")
        f.seek(0, os.SEEK_END)
        num_byte = f.tell()
        print(num_byte)
        f.seek(0)
        
        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                #print(res.decode("Ascii"))
                if res == b'4' :
                    res = b'\r'
                    s.write(res)
                    break

        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                if res == b'Start Address in HEX:' :
                    print(res.decode("Ascii"))
                    break

        addr = input()
        addr_len = len(addr)
        for idx in range(0, addr_len, 1):
            s.write(addr[idx].encode("Ascii"))
            time.sleep(0.001)
        s.write(b'\r')
        
        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                if res == (addr.encode("Ascii") + b'\r\n'):
                    break

        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                if res == b'Total Data Length (byte) in HEX:' :
                    print(res.decode("Ascii"))
                    break

        num_byte_hex = hex(num_byte)
        num_byte_hex = num_byte_hex[2: : ]
        num_byte_hex_len = len(num_byte_hex)
        print(num_byte_hex)
        for idx in range(0, num_byte_hex_len, 1):
            s.write(num_byte_hex[idx].encode("Ascii"))
            time.sleep(0.001)
        s.write(b'\r')

        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                if res == (num_byte_hex.encode("Ascii") + b'\r\n'):

                    break

        while 1:
            if s.in_waiting > 0:
                res = s.readline()
                if res == b'Send *.bin File in 4096-byte Packages:' :
                    break

        num_byte_left = num_byte
        read_ack = 0
        while 1 :
            if num_byte_left >= 4096 :
                bitstream_data = f.read(4096)
                s.write(bitstream_data)
                while 1:
                    if s.in_waiting > 0:
                        res = s.readline()
                        print(res.decode("Ascii"))
                        if res[0:30] == b'Number of 4kByte Packages Left' :
                            read_ack = 1
                            num_byte_left = num_byte_left - 4096
                            break
                if read_ack == 0 :
                    break
            elif num_byte_left != 0 :
                bitstream_bytearray = bytearray()
                bitstream_bytearray += f.read(num_byte_left)
                for idx in range(0, 4096-num_byte_left, 1) :
                    bitstream_bytearray += bytes.fromhex('FF')
                s.write(bitstream_bytearray)
                while 1:
                    if s.in_waiting > 0:
                        res = s.readline()
                        print(res.decode("Ascii"))
                        if res[0:30] == b'Number of 4kByte Packages Left' :
                            read_ack = 1
                            num_byte_left = num_byte_left - 4096
                            break
                if read_ack == 0 :
                    break
                
def byte_try():
    res = input()
    while 1:
        try:
            f = open(res, "rb")
            break
        except FileNotFoundError :
            print("File not found.")

    bitstream_bytearray = bytearray()
    bitstream_bytearray += f.read(128)
    num_byte_left = len(bitstream_bytearray)
    for idx in range(0, 4096-num_byte_left, 1) :
        bitstream_bytearray += bytes.fromhex('FF')
    s = serial.Serial(port="COM5", baudrate=115200, bytesize=8, timeout=2, stopbits=serial.STOPBITS_ONE)
    s.write(bitstream_bytearray)

def main():
    #byte_try()
    write_to_uart()
        

if __name__ == '__main__':
    main()
