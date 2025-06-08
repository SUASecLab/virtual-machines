#/!bin/env python3
import random
import socket
import time

# Create flags array
flags = [b'FSe2GLGW', b'x5WdT8cZ', b'6y6GCdnz']

# Create a TCP/IP socket
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Server address
server_address = ('basic.suaseclab.de', 10000)

# Connect to server
client_socket.connect(server_address)

try:
    # Send data
    sent = client_socket.sendall(b'flag:' + random.choice(flags))

    # Receive data
    data = client_socket.recv(128)
    if data:
        print(data.decode('ascii'))
except Exception as e:
    print(e)
finally:
    client_socket.close()

# Mimick login

if time.localtime().tm_min % 15 == 2:
    import mechanize
    br = mechanize.Browser()
    br.set_handle_robots(False)
    br.open("http://basic.suaseclab.de/session/login")
    br.select_form(nr=0)
    br["login"] = "kfaber"
    br.form = br.global_form()
    br.form["password"] = "53VQR8TE"
    res = br.submit()