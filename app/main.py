#!/usr/bin/env python3
from flask import Flask, jsonify
import socket, os, time, traceback, logging

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s: %(message)s')
app = Flask(__name__)

def op_result(name, func):
    start = time.time()
    try:
        res = func()
        return {"operation": name, "status": "ok", "message": str(res), "duration_ms": int((time.time()-start)*1000)}
    except Exception as e:
        return {
            "operation": name,
            "status": "failed",
            "message": f"{type(e).__name__}: {e}\n" + traceback.format_exc(),
            "duration_ms": int((time.time()-start)*1000)
        }

def try_bind_port_80():
    s = socket.socket()
    try:
        s.bind(("0.0.0.0", 80))
        return "bind_success"
    finally:
        s.close()

def try_write_tmp_file():
    p = "/tmp/project13_test.txt"
    with open(p, "w") as f:
        f.write("test\n")
    return f"file_written:{p}"

def try_chmod_file():
    p = "/tmp/project13_test.txt"
    os.chmod(p, 0o600)
    return "chmod_success"

def try_read_proc_status():
    with open("/proc/self/status") as f:
        first = f.readline().strip()
    return f"first_line:{first}"

def try_open_shadow():
    with open("/etc/shadow") as f:
        f.readline()
    return "opened_shadow"

def try_setuid_root():
    os.setuid(0)
    return "setuid_success"

@app.route("/health")
def health():
    return "ok", 200

@app.route("/check")
def check():
    ops = [
        op_result("bind_port_80", try_bind_port_80),
        op_result("write_tmp_file", try_write_tmp_file),
        op_result("chmod_tmp_file", try_chmod_file),
        op_result("read_proc_self_status", try_read_proc_status),
        op_result("open_etc_shadow", try_open_shadow),
        op_result("attempt_setuid_0", try_setuid_root)
    ]
    return jsonify({
        "timestamp": int(time.time()),
        "operations": ops
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))
