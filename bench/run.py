#!/usr/bin/env python3
"""The modification benchmark: ask a model to change the bar, then see whether
the changed bar still builds, still runs, and does what was asked.

    bench/run.py --model claude-sonnet-5 --trials 3 [--tasks 01-bottom,02-taller] [--langs almide,qml]
    bench/run.py --verify-refs          # check the checks: baseline fails, reference passes

Each attempt is judged in a fresh Hyprland session in Docker (verify.sh): the
bar is built from what the model returned, started, the task's check.sh runs
against what is on screen, and the bar must still be alive afterwards. A task
that fails gets one retry with what went wrong (the build errors, or the
check's output) — the headline number is the first attempt: a change that
works the first time it is asked for.

The model sees the whole bar and the request, and nothing else from this
machine: no tools, no CLAUDE.md or settings (--safe-mode, project settings
only, an empty working directory). The Almide prompt carries the language's
reference (docs/CHEATSHEET.md), which is what Almide ships for models to read;
QML, which models already know, gets none.
"""
import argparse, datetime, json, os, re, shutil, subprocess, sys, tempfile

BENCH = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BENCH)
TASKS = os.path.join(BENCH, "tasks")
DOCKER = ["docker", "--context", os.environ.get("BENCH_CONTEXT", "colima-bench")]
LANG_NAME = {"almide": "Almide", "qml": "QML (Quickshell)"}
SOURCE_EXT = {"almide": (".almd",), "qml": (".qml", ".js")}


def baseline_files(lang):
    base = os.path.join(BENCH, "baseline", lang)
    out = {}
    for dirpath, _, names in os.walk(base):
        for n in sorted(names):
            if n.endswith(SOURCE_EXT[lang]):
                p = os.path.join(dirpath, n)
                out[os.path.relpath(p, base)] = open(p).read()
    return dict(sorted(out.items()))


def render_files(files):
    return "\n".join(f"=== {p} ===\n```\n{c.rstrip()}\n```\n" for p, c in files.items())


def prompt_for(lang, files, request, reference):
    ref = ""
    if lang == "almide" and reference:
        ref = "\n\nThe Almide language reference:\n\n" + reference
    return f"""This is my desktop bar for Hyprland, written in {LANG_NAME[lang]}. Its complete source:

{render_files(files)}
Change it so that: {request}

Reply with the complete new contents of every file you change, each as a line `=== path ===` followed by one fenced code block. Leave out files you do not change. No explanations.{ref}"""


def retry_prompt(first_prompt, reply, problem):
    return f"""{first_prompt}

You replied:

{reply}

That did not work:

{problem}

Fix it. Reply the same way: every file you change, complete."""


SYSTEM = "You change code as asked. You reply only with the changed files, in the format asked for."


def ask(model, prompt):
    with tempfile.TemporaryDirectory() as empty:
        r = subprocess.run(
            ["claude", "-p", "--safe-mode", "--setting-sources", "project", "--model", model,
             "--tools", "", "--no-session-persistence", "--system-prompt", SYSTEM],
            input=prompt, capture_output=True, text=True, cwd=empty, timeout=900)
    if r.returncode != 0:
        raise RuntimeError(f"model call failed: {r.stderr[-2000:]}")
    return r.stdout


FILE_RE = re.compile(r"^=== *(.+?) *===\s*\n```[\w-]*\n(.*?)\n```", re.S | re.M)


def apply_reply(workdir, lang, reply):
    changed = []
    for path, content in FILE_RE.findall(reply):
        path = path.strip().strip("`")
        if os.path.isabs(path) or ".." in path.split("/") or not path.endswith(SOURCE_EXT[lang]):
            continue
        dest = os.path.join(workdir, path)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        open(dest, "w").write(content + "\n")
        changed.append(path)
    return changed


def verify(workdir, lang, task):
    cmd = DOCKER + [
        "run", "--rm", "--privileged", "--hostname", "almide-box", "--dns", "1.1.1.1",
        "-v", "/dev/dri:/dev/dri", "-v", "/run/udev:/run/udev:ro",
        "-v", f"{workdir}:/work:ro", "-v", f"{os.path.join(TASKS, task)}:/task:ro",
        "-v", f"{BENCH}:/bench:ro", "-v", f"{os.path.join(ROOT, 'test', 'hyprland')}:/t:ro",
        "-v", f"{os.environ.get('SNAIDHM_SRC', os.path.join(os.path.dirname(ROOT), 'snaidhm'))}:/snaidhm:ro",
        "-v", "almide-build:/almide", "-v", "almide-cache:/root/.almide",
        "almide-shell-hypr", "bash", "/bench/verify.sh", lang, "/task"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    log = r.stdout + r.stderr
    m = re.search(r"RESULT build=(\w+) runs=(\w+) task=(\w+) alive=(\w+)", log)
    res = dict(zip(["build", "runs", "task", "alive"], m.groups())) if m else {"build": "?", "runs": "?", "task": "?", "alive": "?"}
    res["ok"] = res == {"build": "ok", "runs": "ok", "task": "pass", "alive": "ok"} or (
        res.get("build") == "ok" and res.get("runs") == "ok" and res.get("task") == "pass" and res.get("alive") == "ok")
    return res, log


def section(log, name):
    m = re.search(rf"--- {name}\n(.*?)(?=\n--- |\nRESULT|\Z)", log, re.S)
    return m.group(1).strip() if m else ""


def problem_of(res, log):
    if res["build"] != "ok":
        return "The build failed:\n\n" + section(log, "build")[-3000:]
    if res["runs"] != "ok":
        return "It built, but the bar did not start (no bar on screen). Its output:\n\n" + section(log, "shell log")[-3000:]
    if res["task"] != "pass":
        return "It runs, but the change is not there or does not work as asked. The check said:\n\n" + section(log, "check")[-2000:]
    return "It ran, but the bar crashed afterwards. Its output:\n\n" + section(log, "shell log")[-3000:]


def fresh_workdir(root, lang):
    shutil.copytree(os.path.join(BENCH, "baseline", lang), root)
    return root


def run(args):
    model_slug = re.sub(r"[^A-Za-z0-9_.-]", "_", args.model)
    out = os.path.join(BENCH, "results", args.date, model_slug)
    os.makedirs(out, exist_ok=True)
    reference = open(args.reference).read() if args.reference else ""
    tasks = args.tasks.split(",") if args.tasks else sorted(os.listdir(TASKS))
    results_path = os.path.join(out, "results.jsonl")
    done = set()
    if os.path.exists(results_path):
        for line in open(results_path):
            r = json.loads(line)
            done.add((r["task"], r["lang"], r["trial"]))
    for trial in range(1, args.trials + 1):
        for task in tasks:
            request = open(os.path.join(TASKS, task, "prompt.md")).read().strip()
            for lang in args.langs.split(","):
                if (task, lang, trial) in done:
                    continue
                base = os.path.join(out, "work", task, lang, str(trial))
                shutil.rmtree(base, ignore_errors=True)
                files = baseline_files(lang)
                p1 = prompt_for(lang, files, request, reference)
                record = {"task": task, "lang": lang, "trial": trial, "model": args.model}
                attempts = []
                prompt, reply = p1, None
                for n in (1, 2):
                    wd = fresh_workdir(os.path.join(base, f"attempt{n}"), lang)
                    try:
                        reply = ask(args.model, prompt)
                    except Exception as e:  # a failed call is recorded, not scored
                        attempts.append({"error": str(e)})
                        break
                    open(os.path.join(base, f"reply{n}.md"), "w").write(reply)
                    changed = apply_reply(wd, lang, reply)
                    res, log = verify(wd, lang, task)
                    open(os.path.join(base, f"verify{n}.log"), "w").write(log)
                    res["changed"] = changed
                    attempts.append(res)
                    print(f"{task} {lang} t{trial} a{n}: {'PASS' if res['ok'] else 'fail'} {res}", flush=True)
                    if res["ok"]:
                        break
                    prompt = retry_prompt(p1, reply, problem_of(res, log))
                record["attempts"] = attempts
                with open(results_path, "a") as f:
                    f.write(json.dumps(record) + "\n")
    summarize(out)


def summarize(out):
    rows = [json.loads(l) for l in open(os.path.join(out, "results.jsonl"))]
    rows = [r for r in rows if r["attempts"] and "error" not in r["attempts"][0]]
    langs = sorted({r["lang"] for r in rows})
    tasks = sorted({r["task"] for r in rows})
    lines = [f"# Modification benchmark — {rows[0]['model'] if rows else ''}", ""]
    lines.append("| | " + " | ".join(f"{LANG_NAME[l]}" for l in langs) + " |")
    lines.append("|---|" + "---|" * len(langs))

    def rate(pred, lang):
        rs = [r for r in rows if r["lang"] == lang]
        n = sum(1 for r in rs if pred(r))
        return f"{n}/{len(rs)} ({100 * n / max(1, len(rs)):.0f}%)"
    first = lambda r: r["attempts"][0]["ok"]
    either = lambda r: any(a.get("ok") for a in r["attempts"])
    builds = lambda r: r["attempts"][0]["build"] == "ok" and r["attempts"][0]["runs"] == "ok" and r["attempts"][0]["alive"] != "fail"
    lines.append("| **works on the first try** | " + " | ".join(rate(first, l) for l in langs) + " |")
    lines.append("| works after one retry | " + " | ".join(rate(either, l) for l in langs) + " |")
    lines.append("| first try builds and runs | " + " | ".join(rate(builds, l) for l in langs) + " |")
    lines += ["", "| task | " + " | ".join(langs) + " |", "|---|" + "---|" * len(langs)]
    for t in tasks:
        cells = []
        for l in langs:
            rs = [r for r in rows if r["task"] == t and r["lang"] == l]
            cells.append(" ".join("✓" if r["attempts"][0]["ok"] else ("↻" if either(r) else "✗") for r in sorted(rs, key=lambda r: r["trial"])))
        lines.append(f"| {t} | " + " | ".join(cells) + " |")
    lines += ["", "✓ first try · ↻ after one retry · ✗ neither"]
    open(os.path.join(out, "summary.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


def verify_refs(args):
    """Every check must fail on the unchanged bar and pass on the reference
    change, in both languages — else it does not measure the task."""
    tasks = args.tasks.split(",") if args.tasks else sorted(os.listdir(TASKS))
    bad = []
    for task in tasks:
        for lang in args.langs.split(","):
            for kind in ("baseline", "ref"):
                ref = os.path.join(TASKS, task, "ref", lang)
                if kind == "ref" and not os.path.isdir(ref):
                    bad.append(f"{task} {lang}: no reference")
                    continue
                with tempfile.TemporaryDirectory(dir=os.path.join(BENCH, "results")) as tmp:
                    wd = fresh_workdir(os.path.join(tmp, "w"), lang)
                    if kind == "ref":
                        shutil.copytree(ref, wd, dirs_exist_ok=True)
                    res, log = verify(wd, lang, task)
                want = kind == "ref"
                good = res["ok"] == want and (want or (res["build"] == "ok" and res["runs"] == "ok"))
                print(f"{task} {lang} {kind}: {'ok' if good else 'WRONG'} {res}", flush=True)
                if not good:
                    bad.append(f"{task} {lang} {kind}: {res}\n{section(log, 'check')}\n{section(log, 'build')[-1500:]}")
    print("\n".join(bad) if bad else "all checks discriminate")
    return 1 if bad else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="claude-sonnet-5")
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--tasks")
    ap.add_argument("--langs", default="almide,qml")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    ap.add_argument("--reference", default=os.path.join(os.path.dirname(os.path.dirname(ROOT)), "almide", "almide", "docs", "CHEATSHEET.md"))
    ap.add_argument("--verify-refs", action="store_true")
    a = ap.parse_args()
    os.makedirs(os.path.join(BENCH, "results"), exist_ok=True)
    sys.exit(verify_refs(a) if a.verify_refs else run(a))
