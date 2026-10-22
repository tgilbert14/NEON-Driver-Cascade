#!/usr/bin/env python3
"""Drive the deployed Cross-Product Response Atlas through ChromeDriver.

Ported from the NEON Plant Diversity post-deploy helper. It uses only Python's
standard library and the hosted runner's Chrome/ChromeDriver, and keeps real
wall-clock time so Shiny's websocket can connect and its outputs can settle.

The check is semantic, not an HTTP 200: it opens the About tab, opens the
"Snapshot and provenance" fold rendered by server.R output$aboutPanel, and
requires its text to carry the exact source-state timestamp
(readRDS("data/cascade.rds")$meta$built_when) of the commit just pushed to
master. A stale bundle that still serves the previous family therefore fails.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import ProxyHandler, Request, build_opener


DRIVER_OPENER = build_opener(ProxyHandler({}))
# arguments[0] is the expected built_when string. server.R renders it as
# "Its deterministic source-state timestamp is <code>BUILT_WHEN</code>." inside
# the about_fold("fingerprint", "Snapshot and provenance", ...) details element.
READINESS_SCRIPT = r"""
const expected = arguments[0];
const squash = (value) => (value || "").replace(/\s+/g, " ").trim();
const bodyText = squash(document.body?.innerText);
const tab = document.querySelector('#tabs a[data-value="about"], a[data-bs-toggle="tab"][data-value="about"]');
const shinyConnected = Boolean(window.Shiny?.shinyapp?.isConnected?.());
let aboutActive = Boolean(tab && tab.classList.contains("active"));
if (tab && shinyConnected && !aboutActive) {
  tab.click();
  aboutActive = tab.classList.contains("active");
}
const fold = Array.from(document.querySelectorAll("details.about-fold")).find(
  (node) => /Snapshot and provenance/.test(squash(node.querySelector("summary")?.textContent))
);
if (fold && !fold.open) fold.open = true;
const foldText = squash(fold?.textContent);
const outputErrors = Array.from(document.querySelectorAll(
  "#aboutPanel.shiny-output-error, #aboutPanel .shiny-output-error"
)).map((node) => node.id || node.className || node.tagName);
return {
  readyState: document.readyState,
  shinyConnected,
  tabPresent: Boolean(tab),
  aboutActive,
  foldPresent: Boolean(fold),
  builtWhenShown: Boolean(expected) &&
    foldText.includes("deterministic source-state timestamp is " + expected),
  foldExcerpt: foldText.slice(0, 400),
  outputErrors,
  connected: !document.getElementById("shiny-disconnected-overlay"),
  hostError: /startup error|application failed to start|application error|service unavailable/i.test(bodyText),
  title: document.title,
};
"""


class WebDriverError(RuntimeError):
    """A ChromeDriver transport or protocol failure."""


def request_json(
    method: str,
    url: str,
    payload: dict[str, Any] | None = None,
    timeout: float = 10,
) -> dict[str, Any]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = Request(url, data=data, method=method)
    if data is not None:
        request.add_header("Content-Type", "application/json; charset=utf-8")
    try:
        with DRIVER_OPENER.open(request, timeout=max(1, timeout)) as response:
            raw = response.read()
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise WebDriverError(f"ChromeDriver HTTP {error.code}: {detail[:1200]}") from error
    except (URLError, TimeoutError) as error:
        raise WebDriverError(f"ChromeDriver request failed: {error}") from error

    try:
        result = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise WebDriverError(f"ChromeDriver returned invalid JSON: {raw[:500]!r}") from error
    value = result.get("value")
    if isinstance(value, dict) and value.get("error"):
        raise WebDriverError(
            f"ChromeDriver {value.get('error')}: {value.get('message', 'unknown error')}"
        )
    return result


def available_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        return int(listener.getsockname()[1])


def wait_for_driver(base_url: str, process: subprocess.Popen[bytes], deadline: float) -> None:
    last_error = "no response"
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise WebDriverError(f"ChromeDriver exited during startup with {process.returncode}")
        try:
            response = request_json("GET", f"{base_url}/status", timeout=2)
            if isinstance(response.get("value"), dict) and response["value"].get("ready"):
                return
        except WebDriverError as error:
            last_error = str(error)
        time.sleep(0.2)
    raise WebDriverError(f"ChromeDriver did not become ready: {last_error}")


def create_session(base_url: str, remaining: float) -> str:
    chrome_options: dict[str, Any] = {
        "args": [
            "--headless=new",
            "--no-sandbox",
            "--disable-gpu",
            "--disable-dev-shm-usage",
            "--disable-background-timer-throttling",
            "--disable-backgrounding-occluded-windows",
            "--window-size=1440,1200",
        ]
    }
    if os.environ.get("CHROME_BIN"):
        chrome_options["binary"] = os.environ["CHROME_BIN"]
    payload = {
        "capabilities": {
            "alwaysMatch": {
                "browserName": "chrome",
                "pageLoadStrategy": "none",
                "goog:chromeOptions": chrome_options,
                "timeouts": {"implicit": 0, "pageLoad": 60000, "script": 15000},
            }
        }
    }
    response = request_json("POST", f"{base_url}/session", payload, timeout=min(30, remaining))
    value = response.get("value")
    session_id = value.get("sessionId") if isinstance(value, dict) else response.get("sessionId")
    if not session_id:
        raise WebDriverError(f"ChromeDriver did not return a session id: {response}")
    return str(session_id)


def execute(base_url: str, session_id: str, script: str, args: list[Any], timeout: float) -> Any:
    response = request_json(
        "POST",
        f"{base_url}/session/{session_id}/execute/sync",
        {"script": script, "args": args},
        timeout=timeout,
    )
    return response.get("value")


def source_excerpt(base_url: str, session_id: str) -> str:
    try:
        response = request_json("GET", f"{base_url}/session/{session_id}/source", timeout=5)
        source = response.get("value", "")
        if isinstance(source, str):
            return " ".join(source.split())[:2400]
    except WebDriverError as error:
        return f"unable to read page source: {error}"
    return "page source was unavailable"


def successful(state: dict[str, Any]) -> bool:
    return all(
        (
            state.get("shinyConnected") is True,
            state.get("tabPresent") is True,
            state.get("aboutActive") is True,
            state.get("foldPresent") is True,
            state.get("builtWhenShown") is True,
            not state.get("outputErrors"),
            state.get("connected") is True,
            state.get("hostError") is False,
        )
    )


def tail(path: Path, limit: int = 3000) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return "ChromeDriver log unavailable"
    return text[-limit:]


def fatal_webdriver_error(message: str) -> bool:
    normalized = message.lower()
    return any(
        marker in normalized
        for marker in (
            "invalid session id",
            "no such window",
            "chrome not reachable",
            "not connected to devtools",
            "session deleted because of page crash",
            "tab crashed",
        )
    )


def run(url: str, built_when: str, timeout: int, driver: str) -> int:
    deadline = time.monotonic() + timeout
    port = available_port()
    base_url = f"http://127.0.0.1:{port}"
    with tempfile.TemporaryDirectory(prefix="atlas-semantic-smoke-") as temp_dir:
        log_path = Path(temp_dir) / "chromedriver.log"
        process = subprocess.Popen(
            [driver, f"--port={port}", f"--log-path={log_path}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        session_id = ""
        last_state: Any = None
        good_samples = 0
        try:
            wait_for_driver(base_url, process, min(deadline, time.monotonic() + 15))
            session_id = create_session(base_url, max(1, deadline - time.monotonic()))
            request_json(
                "POST",
                f"{base_url}/session/{session_id}/url",
                {"url": url},
                timeout=min(15, max(1, deadline - time.monotonic())),
            )
            print(f"wait [Connect Cloud app] ChromeDriver opened {url}", flush=True)
            while time.monotonic() < deadline:
                try:
                    state = execute(
                        base_url,
                        session_id,
                        READINESS_SCRIPT,
                        [built_when],
                        timeout=min(10, max(1, deadline - time.monotonic())),
                    )
                    last_state = state
                    if isinstance(state, dict) and state.get("hostError"):
                        raise WebDriverError(f"browser reached a host error page: {state}")
                    if isinstance(state, dict) and successful(state):
                        good_samples += 1
                        if good_samples >= 2:
                            print(
                                "ok [Connect Cloud app] ChromeDriver confirmed two consecutive "
                                f"About-tab samples showing built_when {built_when}: "
                                f"{json.dumps(state, sort_keys=True)}",
                                flush=True,
                            )
                            return 0
                    else:
                        good_samples = 0
                except WebDriverError as error:
                    good_samples = 0
                    if process.poll() is not None:
                        raise WebDriverError(
                            f"ChromeDriver exited during readiness polling with {process.returncode}: {error}"
                        ) from error
                    if fatal_webdriver_error(str(error)):
                        raise
                    last_state = {"transientWebDriverError": str(error)}
                time.sleep(2)
            print(
                "DOWN [Connect Cloud app] semantic browser deadline elapsed; "
                f"last state: {json.dumps(last_state, sort_keys=True)}",
                file=sys.stderr,
            )
            if session_id:
                print(f"page source excerpt: {source_excerpt(base_url, session_id)}", file=sys.stderr)
            print(f"ChromeDriver log tail:\n{tail(log_path)}", file=sys.stderr)
            return 1
        except (OSError, WebDriverError) as error:
            print(f"DOWN [Connect Cloud app] ChromeDriver probe failed: {error}", file=sys.stderr)
            print(f"ChromeDriver log tail:\n{tail(log_path)}", file=sys.stderr)
            return 1
        finally:
            if session_id:
                try:
                    request_json("DELETE", f"{base_url}/session/{session_id}", timeout=5)
                except WebDriverError:
                    pass
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="deployed app URL")
    parser.add_argument("--built-when", required=True,
                        help="expected cascade.rds meta$built_when string")
    parser.add_argument("--timeout", type=int, default=150, help="wall-clock readiness budget")
    parser.add_argument("--driver", help="ChromeDriver executable (defaults to PATH)")
    args = parser.parse_args()
    args.driver = args.driver or shutil.which("chromedriver")
    if not args.driver:
        parser.error("chromedriver is required but was not found on PATH")
    if args.timeout < 10:
        parser.error("--timeout must be at least 10 seconds")
    if not args.built_when.strip():
        parser.error("--built-when must not be empty")
    return args


if __name__ == "__main__":
    arguments = parse_args()
    raise SystemExit(run(arguments.url, arguments.built_when, arguments.timeout, arguments.driver))
