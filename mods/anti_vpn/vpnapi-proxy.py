#!/usr/bin/env python3

'''Small mock HTTP web server for testing with.'''

'''The real https://vpnapi.io/ service limits use to 1,000 request per day
   for the 'free-tier' api key.  To conserve this precious resource during
   testing / development, we can use this small python http server.'''

from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import re
import argparse

hostName = "localhost"
serverPort = 48888
cache_dir = "testdata"

parser = argparse.ArgumentParser(
    prog='vpnapi-proxy',
    description='Simulates the real vpnapi.io api, for testing.')

parser.add_argument('-d', '--delay', action='store', default=0.0, type=float)

args = parser.parse_args()

def slurp(filename):
    try:
        with open(filename, 'r') as f:
            return f.read()
    except FileNotFoundError:
        return None

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        print('request:', self.path)
        # Expected URL format:
        # /api/8.8.8.8/key=xxxxxxxxxxxxxx
        m = re.search(r'/api/([\d\.]+)[\?]key=', self.path)
        ip = m.group(1)

        time.sleep(args.delay)

        # Do we already have the result cached?
        fname = cache_dir + "/" + ip + ".json"
        content = slurp(fname)

        if content:
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(bytes(content, "utf-8"))
            return

        # TODO: Make a real HTTP call to the real https://vpnapi.io/....

        self.send_response(404)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(bytes('', "utf-8"))

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))
    print("delay = ", args.delay)

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
