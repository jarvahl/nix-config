from mcp.server.fastmcp import FastMCP

from bridge import FirefoxBridge
from content import render_semantic
from references import ReferenceStore


mcp = FastMCP("firefox-agent-mcp")
bridge = FirefoxBridge()
references = ReferenceStore()


def tab_id_or_active(tab_id):
    return tab_id if tab_id is not None else bridge.active_tab_id()


@mcp.tool()
def browser_tabs():
    """List Firefox windows and tabs."""
    return bridge.call("listTabs", {})


@mcp.tool()
def browser_content(tabId=None, selector="body", maxChars=30000):
    """Read semantic Markdown and replace refs for this tab."""
    tab_id = tab_id_or_active(tabId)
    rendered = render_semantic(bridge.get_content(tab_id), selector, maxChars)
    references.replace_for_tab(tab_id, rendered.references)
    return rendered.markdown


@mcp.tool()
def browser_click(tabId, ref):
    """Click a ref from the latest browser_content snapshot."""
    return bridge.click(tabId, references.get(tabId, ref).selector)


@mcp.tool()
def browser_type(tabId, ref, text, submit=False):
    """Type into a ref from the latest browser_content snapshot."""
    return bridge.type(tabId, references.get(tabId, ref).selector, text, submit)


@mcp.tool()
def browser_fill_form(tabId, fields):
    """Fill form fields using refs from the latest browser_content snapshot."""
    translated = []
    for field in fields:
        item = references.get(tabId, field["ref"])
        translated.append({"selector": item.selector, "value": field["value"]})
    return bridge.fill_form(tabId, translated)


@mcp.tool()
def browser_interactables(tabId=None):
    """List clickable links, buttons and input controls."""
    params = {} if tabId is None else {"tabId": tabId}
    return bridge.call("getInteractables", params)


@mcp.tool()
def browser_evaluate(script, tabId=None, maxChars=8000):
    """Evaluate JavaScript in a Firefox tab."""
    params = {"script": script}
    if tabId is not None:
        params["tabId"] = tabId
    result = bridge.call("evaluate", params)
    return result if len(result) <= maxChars else result[:maxChars] + "\\n...[truncated]..."


@mcp.tool()
def browser_screenshot(tabId=None):
    """Capture a Firefox tab screenshot."""
    params = {} if tabId is None else {"tabId": tabId}
    return bridge.call("screenshot", params)


@mcp.tool()
def browser_navigate(url, tabId=None):
    """Navigate a Firefox tab. On LinkedIn, prefer visible controls instead."""
    params = {"url": url}
    if tabId is not None:
        params["tabId"] = tabId
        references.clear_tab(tabId)
    else:
        references.clear_all()
    return bridge.call("navigate", params)


@mcp.tool()
def browser_new_tab(url=None):
    """Open a new Firefox tab."""
    return bridge.call("newSession", {"url": url} if url else {})


if __name__ == "__main__":
    mcp.run(transport="stdio")
