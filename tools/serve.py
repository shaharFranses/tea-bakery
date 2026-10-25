#!/usr/bin/env python3
"""Static server for Godot web builds (single-thread exports need no COOP/COEP). usage: serve.py <dir> <port>"""
import functools, http.server, sys
d, port = sys.argv[1], int(sys.argv[2])
class H(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.js': 'text/javascript'}
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store'); super().end_headers()
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer.allow_reuse_address = True
http.server.ThreadingHTTPServer(('0.0.0.0', port), functools.partial(H, directory=d)).serve_forever()
