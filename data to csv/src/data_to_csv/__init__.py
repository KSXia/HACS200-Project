import csv
import re
from collections import Counter
from datetime import datetime
from pathlib import Path

# Anchored to MITM's own log prefix so text an attacker typed can't look like one of these lines
LOG_PREFIX = r"^\S+ \S+ - (?:\[[^\]]+\] )*"
COMMAND_LINE = re.compile(
    LOG_PREFIX
    + r"[^:]*?(?:line from reader|Non-interactive command|Noninteractive mode attacker command): ?(.*)$"
)
CLOSED_LINE = re.compile(LOG_PREFIX + r"Attacker closed connection\s*$")

# Shell words that only give structure to a command list and aren't commands themselves
SHELL_KEYWORDS = {"do", "done", "then", "else", "fi", "esac", "!"}


def split_commands(command_line):
    """Split a shell line into its separate commands.

    Splits on ; && || | |& & and newlines, but only outside quotes, $(...), `...`, ${...},
    and [[ ... ]]. A comment ends the line. Redirections like 2>&1, &>file and >|file don't split.
    """
    segments = []
    current = []
    stack = []  # quotes and substitutions that are still open
    i = 0
    n = len(command_line)

    def end_segment():
        segments.append("".join(current))
        current.clear()

    while i < n:
        c = command_line[i]
        top = stack[-1] if stack else None
        two = command_line[i : i + 2]

        if c == "\\":
            current.append(command_line[i : i + 2])
            i += 2
        elif c == "'" and top != '"':
            end = command_line.find("'", i + 1)
            end = n if end == -1 else end + 1
            current.append(command_line[i:end])
            i = end
        elif c in ('"', "`"):
            if top == c:
                stack.pop()
            else:
                stack.append(c)
            current.append(c)
            i += 1
        elif two in ("$(", "${"):
            stack.append(two)
            current.append(two)
            i += 2
        elif top == '"':
            current.append(c)
            i += 1
        elif c == "(" and stack:
            stack.append("(")
            current.append(c)
            i += 1
        elif c == ")" and top in ("$(", "("):
            stack.pop()
            current.append(c)
            i += 1
        elif c == "}" and top == "${":
            stack.pop()
            current.append(c)
            i += 1
        elif two == "]]" and top == "[[":
            stack.pop()
            current.append(two)
            i += 2
        elif stack:
            current.append(c)
            i += 1
        elif two == "[[" and (i == 0 or command_line[i - 1] in " \t;&|("):
            stack.append("[[")
            current.append(two)
            i += 2
        elif c == "#" and (i == 0 or command_line[i - 1] in " \t;&|()"):
            break
        elif c in ";\n\r":
            end_segment()
            i += 1
        elif two in ("&&", "||", "|&"):
            end_segment()
            i += 2
        elif c == "|" and command_line[i - 1 : i] != ">":
            end_segment()
            i += 1
        elif c == "&" and command_line[i - 1 : i] not in ("<", ">") and command_line[i + 1 : i + 2] != ">":
            end_segment()
            i += 1
        else:
            current.append(c)
            i += 1

    end_segment()
    return [segment.strip() for segment in segments if _is_command(segment)]


def _is_command(segment):
    words = [word.strip("(){}") for word in segment.split()]
    return any(word and word not in SHELL_KEYWORDS for word in words)


def count_commands(command_line):
    return len(split_commands(command_line))


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
                    command = COMMAND_LINE.match(line)
                    if command or CLOSED_LINE.match(line):
                        if command:
                            commands += count_commands(command.group(1))

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
