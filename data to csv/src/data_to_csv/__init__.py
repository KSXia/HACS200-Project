import csv
from collections import Counter
from datetime import datetime
from pathlib import Path


def parse_sessions(base_dir, output_file):
    rows = []
    leave_counts = Counter()

    for session_dir in Path(base_dir).rglob("*"):
        if not session_dir.is_dir():
            continue

        config_file = session_dir / "config"
        logins_file = session_dir / "logins.txt"
        mitm_file = session_dir / "mitm.log"
        leave_file = session_dir / "leave_reason"
        container = str(session_dir.parent.parent.name)

        if config_file.exists() and logins_file.exists() and mitm_file.exists():
            with open(logins_file, "r", errors="ignore") as f:
                login_line = f.readline().strip()

            if not login_line:
                continue

            parts = login_line.split(";")
            if len(parts) < 2:
                continue

            try:
                login_time = datetime.strptime(parts[0].strip(), "%Y-%m-%d %H:%M:%S.%f")
            except ValueError:
                print("val error")
                continue

            ip = parts[1].strip()
            if not ip:
                continue

            with open(config_file, "r", errors="ignore") as f:
                config = f.read().strip()

            leave_reason = "unknown"
            if leave_file.exists():
                with open(leave_file, "r", errors="ignore") as f:
                    leave_reason = f.read().strip()
            leave_counts[leave_reason] += 1

            commands = 0
            last_cmd_time = None

            with open(mitm_file, "r", errors="ignore") as f:
                for line in f:
                    if (
                        "line from reader:" in line
                        or "Non-interactive command:" in line
                        or "Noninteractive mode attacker command" in line
                        or "Attacker closed connection" in line
                    ):
                        commands += 1
                        ts_str = line.split(" - ")[0].strip()
                        try:
                            last_cmd_time = datetime.strptime(
                                ts_str, "%Y-%m-%d %H:%M:%S.%f"
                            )
                        except ValueError:
                            pass

            if not last_cmd_time:
                print("no last_cmd_time", mitm_file)
                continue

            duration = (last_cmd_time - login_time).total_seconds()

            if duration >= 300:
                continue

            print(container)
            rows.append((login_time, container, ip, config, duration, commands, leave_reason))

    rows.sort(key=lambda x: x[0])

    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["container", "ip", "config", "duration", "commands", "leave_reason"])
        for r in rows:
            writer.writerow(r[1:])

    print("Total valid attacks:", len(rows))
    print("Leave reasons:", dict(leave_counts))


def main() -> None:
    parse_sessions("data_4nov", "honeypot_data_4nov.csv")
    
main()
