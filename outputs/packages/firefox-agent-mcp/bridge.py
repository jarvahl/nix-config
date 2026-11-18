import json
import os
import subprocess
import tempfile
from pathlib import Path


def extract_content(raw):
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return raw

    queue = [value]
    while queue:
        item = queue.pop(0)
        if isinstance(item, str) and "<" in item:
            return item
        if isinstance(item, dict):
            queue[0:0] = [
                item[key] for key in ("content", "html", "text") if key in item
            ]
        elif isinstance(item, list):
            queue.extend(item)
    return raw


class FirefoxBridge:
    def __init__(self, browser_path=None, timeout=30):
        self.browser_path = browser_path or os.environ.get(
            "FIREFOX_AGENT_BRIDGE_BROWSER", "browser"
        )
        self.timeout = timeout

    def call(self, action, params):
        with tempfile.TemporaryDirectory(prefix="firefox-mcp-") as directory:
            path = Path(directory) / "params.json"
            path.write_text(json.dumps(params), encoding="utf-8")
            try:
                result = subprocess.run(
                    [self.browser_path, action, f"@{path}"],
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=self.timeout,
                )
            except subprocess.TimeoutExpired as error:
                raise RuntimeError(
                    f"Firefox bridge timed out during {action}"
                ) from error

        if result.returncode:
            detail = result.stderr.strip() or result.stdout.strip() or "unknown error"
            raise RuntimeError(
                f"Firefox bridge action {action!r} failed "
                f"(exit code {result.returncode}): {detail}"
            )
        return result.stdout.strip()

    def get_content(self, tab_id=None):
        params = {"format": "html"}
        if tab_id is not None:
            params["tabId"] = tab_id
        return extract_content(self.call("getContent", params))

    def click(self, tab_id, selector):
        return self.call("click", {"tabId": tab_id, "selector": selector})

    def type(self, tab_id, selector, text, submit=False):
        return self.call("type", {
            "tabId": tab_id,
            "selector": selector,
            "text": text,
            "submit": submit,
        })

    def fill_form(self, tab_id, fields):
        return self.call("fillForm", {"tabId": tab_id, "fields": fields})

    def active_tab_id(self):
        value = json.loads(self.call("getActiveTab", {}))
        result = value.get("result", value) if isinstance(value, dict) else value
        if not isinstance(result, dict) or not isinstance(result.get("tabId"), int):
            raise RuntimeError("Firefox bridge did not return an active tab id")
        return result["tabId"]
