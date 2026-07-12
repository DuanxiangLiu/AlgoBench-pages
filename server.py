#!/usr/bin/env python3
"""
AlgoBench Pages Server

A custom HTTP server with path rewriting for GitHub Pages deployment.
Handles repository path prefix and root redirection.

Usage:
    python server.py [port]

Example:
    python server.py 8000
"""

import http.server
import socketserver
import sys
import os
import re
from datetime import datetime
from functools import lru_cache


DEFAULT_PORT = 8000
REPO_NAME = os.environ.get('REPO_NAME', 'AlgoBench-pages')
LOG_STATUS_CODES = {'200', '201', '206', '301', '302', '304',
                    '400', '401', '403', '404', '500', '503'}

STATUS_CODE_PATTERN = re.compile(r'" (\d{3}) ')

@lru_cache(maxsize=10)
def get_log_level(status_code):
    """Get log level based on HTTP status code."""
    code = int(status_code)
    return 'ERROR' if code >= 400 else 'INFO'


class PathRewriteHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with path rewriting for GitHub Pages."""

    def translate_path(self, path):
        """Translate URL path to file system path, handling repo prefix."""
        path = path.split('?')[0].split('#')[0]

        if '..' in path:
            path = '/'

        if path == '/favicon.ico':
            return ''

        repo_prefix = f'/{REPO_NAME}'
        if path.startswith(f'{repo_prefix}/'):
            path = path[len(repo_prefix):]
        elif path == repo_prefix:
            path = '/'
        elif path == f'/{REPO_NAME}':
            self.send_response(301)
            self.send_header('Location', f'/{REPO_NAME}/')
            self.end_headers()
            return ''

        return super().translate_path(path)

    def do_GET(self):
        """Handle GET requests with root redirection."""
        path = self.path.split('?')[0].split('#')[0]
        if path == '/favicon.ico':
            self.send_response(204)
            self.end_headers()
            return
        if self.path == '/' or self.path == '':
            self.send_response(302)
            self.send_header('Location', f'/{REPO_NAME}/')
            self.end_headers()
            self.log_request(302)
            return
        try:
            super().do_GET()
        except (BrokenPipeError, ConnectionResetError):
            pass

    def finish(self, *args, **kwargs):
        """Handle connection errors gracefully."""
        try:
            super().finish(*args, **kwargs)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def log_message(self, format, *args):
        """Log HTTP messages with timestamp and log level."""
        message = format % args

        if any(code in message for code in LOG_STATUS_CODES):
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            match = STATUS_CODE_PATTERN.search(message)
            status_code = match.group(1) if match else '000'
            try:
                log_level = get_log_level(status_code)
            except (ValueError, IndexError):
                log_level = 'INFO'
            sys.stderr.write(f"[{timestamp}] [{log_level}] {self.address_string()} - {message}\n")
            sys.stderr.flush()


def validate_port(port_str):
    """Validate and convert port string to integer."""
    try:
        port = int(port_str)
        if not (1 <= port <= 65535):
            raise ValueError(f"Port must be between 1 and 65535, got {port}")
        return port
    except ValueError as e:
        raise ValueError(f"Invalid port number: {port_str}") from e


def log_startup_info(port):
    """Log server startup information."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    message = f"[{timestamp}] [INFO] Server starting on port {port}"
    sys.stderr.write(message + '\n')
    sys.stderr.flush()


def _port_conflict_hint(port):
    """Return a human-readable hint for resolving a port conflict.

    Uses `lsof` (when available) to identify the occupying process and
    suggests a ready-to-run kill command. Returns None if lsof is
    unavailable or finds nothing.
    """
    import subprocess
    try:
        full = subprocess.run(
            ['lsof', '-i', f':{port}'],
            capture_output=True, text=True, timeout=3,
        )
        pids = subprocess.run(
            ['lsof', '-i', f':{port}', '-t'],
            capture_output=True, text=True, timeout=3,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None

    lines = [ln for ln in full.stdout.splitlines() if ln.strip()]
    pid_list = [p for p in pids.stdout.split() if p]
    if not lines:
        return None

    hint_lines = ['占用进程信息：'] + lines[:20]
    if pid_list:
        unique_pids = sorted(set(pid_list))
        hint_lines.append('')
        hint_lines.append('建议执行以下命令终止占用进程：')
        hint_lines.append('  kill ' + ' '.join(unique_pids))
        hint_lines.append('（若无法终止，强制执行：kill -9 ' + ' '.join(unique_pids) + '）')
    return '\n'.join(hint_lines)


def main():
    """Main entry point for the server."""
    port = DEFAULT_PORT

    if len(sys.argv) > 1:
        try:
            port = validate_port(sys.argv[1])
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    try:
        with socketserver.TCPServer(('0.0.0.0', port), PathRewriteHandler) as httpd:
            log_startup_info(port)
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            sys.stderr.write(f"[{timestamp}] [INFO] AlgoBench server running on port {port}\n")
            sys.stderr.write(f"[{timestamp}] [INFO] Access at: http://localhost:{port}/\n")
            sys.stderr.write(f"[{timestamp}] [INFO] Press Ctrl+C to stop\n")
            sys.stderr.flush()
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                sys.stderr.write(f"[{timestamp}] [INFO] Server stopped\n")
                sys.stderr.write(f"[{timestamp}] [INFO] =========================================\n")
                sys.stderr.flush()
    except OSError as e:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if e.errno == 98:
            msg = f"[{timestamp}] [ERROR] Port {port} is already in use"
            hint = _port_conflict_hint(port)
            if hint:
                msg += '\n' + hint
        elif e.errno == 13:
            msg = f"[{timestamp}] [ERROR] Permission denied for port {port}"
        else:
            msg = f"[{timestamp}] [ERROR] {e}"
        sys.stderr.write(msg + '\n')
        sys.stderr.flush()
        sys.exit(1)


if __name__ == '__main__':
    main()
