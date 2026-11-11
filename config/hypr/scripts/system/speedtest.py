#!/usr/bin/env python3
import http.client
import socket
import json
import os
import ssl
import statistics
import sys
import threading
import time

HOST = "speed.cloudflare.com"
STREAMS = int(os.environ.get("SPEED_STREAMS", "6"))
DL_SECS = float(os.environ.get("SPEED_DL", "10"))
UL_SECS = float(os.environ.get("SPEED_UL", "10"))
WARMUP = 1.5
TICK = 0.1
CTX = ssl.create_default_context()
CHUNK = 65536
lock = threading.Lock()

def emit(**kw):
    with lock:
        sys.stdout.write(json.dumps(kw, separators=(",", ":")) + "\n")
        sys.stdout.flush()

def conn():
    return http.client.HTTPSConnection(HOST, timeout=8, context=CTX)

def trace():
    try:
        c = conn()
        c.request("GET", "/cdn-cgi/trace")
        body = c.getresponse().read().decode()
        c.close()
        d = dict(l.split("=", 1) for l in body.splitlines() if "=" in l)
        return {"ip": d.get("ip", ""), "colo": d.get("colo", ""), "loc": d.get("loc", "")}
    except Exception:
        return {}

def rtt(addr):
    t0 = time.perf_counter()
    s = socket.create_connection(addr, timeout=3)
    v = (time.perf_counter() - t0) * 1000
    s.close()
    return v

def resolve():
    return socket.getaddrinfo(HOST, 443, socket.AF_INET, socket.SOCK_STREAM)[0][4]

def jitter(xs):
    if len(xs) < 2:
        return 0.0
    return statistics.fmean(abs(a - b) for a, b in zip(xs, xs[1:]))

def idle_ping(addr, n=20):
    rtt(addr)
    xs = []
    for i in range(n):
        try:
            v = rtt(addr)
        except Exception:
            continue
        xs.append(v)
        emit(t="ping", v=round(v, 2), p=round((i + 1) / n, 3))
        time.sleep(0.08)
    return xs

class Loaded(threading.Thread):
    def __init__(self, stop, addr):
        super().__init__(daemon=True)
        self.stop = stop
        self.addr = addr
        self.xs = []

    def run(self):
        self.stop.wait(1.0)
        while not self.stop.is_set():
            try:
                self.xs.append(rtt(self.addr))
            except Exception:
                pass
            self.stop.wait(0.3)

def download_worker(stop, count):
    while not stop.is_set():
        try:
            c = conn()
            c.request("GET", "/__down?bytes=50000000")
            r = c.getresponse()
            while not stop.is_set():
                b = r.read(CHUNK)
                if not b:
                    break
                count[0] += len(b)
            c.close()
        except Exception:
            time.sleep(0.2)

def upload_worker(stop, count):
    blob = os.urandom(CHUNK)
    size = 25_000_000
    while not stop.is_set():
        try:
            c = conn()
            c.putrequest("POST", "/__up")
            c.putheader("Content-Type", "application/octet-stream")
            c.putheader("Content-Length", str(size))
            c.endheaders()
            sent = 0
            while sent < size and not stop.is_set():
                n = min(CHUNK, size - sent)
                c.send(blob[:n])
                sent += n
                count[0] += n
            if not stop.is_set():
                c.getresponse().read()
            c.close()
        except Exception:
            time.sleep(0.2)

def transfer(kind, worker, secs, addr):
    stop = threading.Event()
    counts = [[0] for _ in range(STREAMS)]
    probe = Loaded(stop, addr)
    probe.start()
    for cnt in counts:
        threading.Thread(target=worker, args=(stop, cnt), daemon=True).start()

    t0 = time.perf_counter()
    hist = [(t0, 0)]
    base = None
    peak = 0.0
    while True:
        time.sleep(TICK)
        now = time.perf_counter()
        total = sum(c[0] for c in counts)
        hist.append((now, total))
        while len(hist) > 2 and now - hist[0][0] > 1.2:
            hist.pop(0)
        dt = now - hist[0][0]
        live = (total - hist[0][1]) * 8 / dt / 1e6 if dt > 0 else 0.0
        if base is None and now - t0 >= WARMUP:
            base = (now, total)
        peak = max(peak, live)
        emit(t=kind, v=round(live, 2), p=round(min(1.0, (now - t0) / secs), 3))
        if now - t0 >= secs:
            break
    stop.set()
    end = time.perf_counter()
    total = sum(c[0] for c in counts)
    if base and end > base[0]:
        avg = (total - base[1]) * 8 / (end - base[0]) / 1e6
    else:
        avg = total * 8 / (end - t0) / 1e6
    return avg, peak, probe.xs, total

def main():
    emit(t="phase", v="meta")
    m = trace()
    emit(t="meta", **m)

    emit(t="phase", v="ping")
    try:
        addr = resolve()
        xs = idle_ping(addr)
    except Exception as e:
        emit(t="error", v=str(e))
        return 1
    if not xs:
        emit(t="error", v="no response")
        return 1
    ping = statistics.median(xs)
    jit = jitter(xs)
    emit(t="pingDone", ping=round(ping, 1), jitter=round(jit, 1), min=round(min(xs), 1))

    emit(t="phase", v="down")
    dl, dlPeak, dlLat, dlBytes = transfer("down", download_worker, DL_SECS, addr)
    emit(t="downDone", v=round(dl, 2), peak=round(dlPeak, 2), bytes=dlBytes,
         loaded=round(statistics.median(dlLat), 1) if dlLat else None)

    emit(t="phase", v="up")
    ul, ulPeak, ulLat, ulBytes = transfer("up", upload_worker, UL_SECS, addr)
    emit(t="upDone", v=round(ul, 2), peak=round(ulPeak, 2), bytes=ulBytes,
         loaded=round(statistics.median(ulLat), 1) if ulLat else None)

    emit(t="done", down=round(dl, 2), up=round(ul, 2), ping=round(ping, 1), jitter=round(jit, 1),
         ts=int(time.time()))
    sys.stdout.flush()
    os._exit(0)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        os._exit(130)
