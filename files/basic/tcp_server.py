#!/bin/env python3

import socket

server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('0.0.0.0', 10000)
print("Starting server")
server_socket.bind(server_address)
server_socket.listen(1)

while True:
    connection, client_address = server_socket.accept()

    try:
        print("Connection from ", client_address)
        while True:
            data = connection.recv(128)
            if data:
                if b'flag' in data:
                    connection.sendall(b'Rreceived flag')
                    break
                else:
                    if b'exit' in data:
                        break
                    elif b'help' in data:
                        connection.sendall(b'flag:aaiN3qPY\r\n')
                        break
                    else:
                        connection.sendall(b'Welcome to the test server\r\n')
                        connection.sendall(b'Available commands:\r\n')
                        connection.sendall(b'exit - terminate connection\r\n')
                        connection.sendall(b'help\r\n')
            else:
                break
    finally:
        print("Closing connection to ", client_address)
        connection.close()