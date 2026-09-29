"""Compare tz.almd's UTC offsets with Python's zoneinfo, over many zones and
times from 1900 to 2100 (the far side of the files' last transitions is the
POSIX-rule footer).   python3 test/tz_oracle.py [ZONEINFO_DIR]"""
import os, random, subprocess, sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

root = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/zoneinfo"
zones = ["UTC", "Asia/Tokyo", "Europe/London", "Europe/Berlin", "America/New_York",
         "America/Los_Angeles", "America/Sao_Paulo", "Australia/Sydney", "Australia/Lord_Howe",
         "Asia/Kolkata", "Asia/Kathmandu", "Pacific/Chatham", "Africa/Casablanca",
         "America/St_Johns", "Europe/Dublin", "Pacific/Apia", "America/Santiago", "Asia/Tehran"]
random.seed(1)
times = sorted(random.randint(-2208988800, 4102444800) for _ in range(300))
# Around this year's changes too.
for y in (2026, 2031, 2047):
    for m in range(1, 13):
        for d in (1, 8, 15, 22, 29):
            try:
                times.append(int(datetime(y, m, d, 1, 30, tzinfo=timezone.utc).timestamp()))
            except ValueError:
                pass
exe = "/tmp/tz_dump"
subprocess.run(["almide", "build", "test/tz_dump.almd", "-o", exe], check=True, capture_output=True)
bad = 0
for z in zones:
    path = os.path.join(root, z)
    got = subprocess.run([exe, path] + [str(t) for t in times], capture_output=True, text=True, check=True).stdout.split()
    zi = ZoneInfo(z)
    for t, g in zip(times, got):
        want = int(datetime.fromtimestamp(t, tz=timezone.utc).astimezone(zi).utcoffset().total_seconds())
        if int(g) != want:
            bad += 1
            if bad <= 10:
                print(f"{z} {t} ({datetime.fromtimestamp(t, tz=timezone.utc)}): got {g} want {want}")
print(f"{len(zones)} zones x {len(times)} times, {bad} mismatches")
sys.exit(1 if bad else 0)
