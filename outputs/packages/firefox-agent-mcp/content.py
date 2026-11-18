import re
from dataclasses import dataclass

from bs4 import BeautifulSoup, NavigableString, Tag

from references import ElementReference


@dataclass
class RenderedContent:
    markdown: str
    references: list


@dataclass
class RenderState:
    next_ref: int = 1

    def add_ref(self, element, role, name):
        item = ElementReference(
            ref=f"r{self.next_ref}",
            selector=selector_for(element),
            role=role,
            name=name,
        )
        self.next_ref += 1
        return item


def text(element):
    return " ".join(element.get_text(" ", strip=True).split())


def label(element):
    for attribute in ("aria-label", "title", "placeholder", "alt"):
        if element.get(attribute):
            return " ".join(element[attribute].split())
    return ""


def selector_for(element):
    if element.get("id"):
        return f'#{element["id"]}'
    if element.get("name"):
        return f'{element.name}[name="{element["name"]}"]'
    if element.get("aria-label"):
        return f'{element.name}[aria-label="{element["aria-label"]}"]'

    parts = []
    current = element
    while isinstance(current, Tag) and current.name not in {"html", "[document]"}:
        index = 1
        sibling = current.previous_sibling
        while sibling is not None:
            if isinstance(sibling, Tag) and sibling.name == current.name:
                index += 1
            sibling = sibling.previous_sibling
        parts.append(f"{current.name}:nth-of-type({index})")
        current = current.parent
        if len(parts) == 6:
            break
    return " > ".join(reversed(parts))


def render_element(element, state):
    if element.name in {"script", "style", "noscript", "svg", "template"}:
        return []
    if element.has_attr("hidden") or element.get("aria-hidden") == "true":
        return []

    if element.name in {"h1", "h2", "h3", "h4", "h5", "h6"}:
        return [f"{'#' * int(element.name[1])} {text(element)}"]

    if element.name in {"input", "select", "textarea"}:
        name = label(element) or element.get("name") or element.name
        role = "combobox" if element.name == "select" else element.get("type", "textbox")
        ref = state.add_ref(element, role, name)
        if element.name == "select":
            selected = element.find("option", selected=True) or element.find("option")
            options = [text(option) for option in element.find_all("option")]
            lines = [f"- Select {name} [ref={ref.ref}]"]
            lines.append(f"  - Selected: {text(selected) if selected else 'empty'}")
            if options:
                lines.append("  - Options:")
                lines.extend(f"    - {option}" for option in options)
            return lines
        value = text(element) if element.name == "textarea" else element.get("value", "")
        lines = [
            f"- {role.title()} {name} [ref={ref.ref}]",
            f"  - Type: {element.get('type', element.name)}",
            f"  - Value: {value or 'empty'}",
        ]
        if element.has_attr("required"):
            lines.append("  - Required: yes")
        if element.get("placeholder"):
            lines.append(f"  - Placeholder: {element['placeholder']}")
        return lines

    if element.name == "button" or element.get("role") == "button":
        name = text(element) or label(element) or "Unnamed button"
        ref = state.add_ref(element, "button", name)
        return [f"[Button: {name}] [ref={ref.ref}]"]

    if element.name == "a":
        name = text(element) or label(element) or "Unnamed link"
        ref = state.add_ref(element, "link", name)
        return [f"[{name}]({element.get('href', '')}) [ref={ref.ref}]"]

    if element.name in {"ul", "ol"}:
        return [
            f"- {text(child)}"
            for child in element.find_all("li", recursive=False)
            if text(child)
        ]

    lines = []
    for child in element.children:
        if isinstance(child, Tag):
            lines.extend(render_element(child, state))
        elif isinstance(child, NavigableString):
            value = " ".join(str(child).split())
            if value:
                lines.append(value)
    return lines


def render_semantic(html, selector="body", max_chars=30000):
    soup = BeautifulSoup(html, "html.parser")
    root = soup.select_one(selector)
    if root is None:
        return RenderedContent(f"Selector not found: {selector}", [])

    state = RenderState()
    lines = []
    for child in root.children:
        if isinstance(child, Tag):
            lines.extend(render_element(child, state))
        elif isinstance(child, NavigableString):
            value = " ".join(str(child).split())
            if value:
                lines.append(value)

    compact = []
    previous = None
    for line in lines:
        line = re.sub(r" +", " ", line).strip()
        if line and line != previous:
            compact.append(line)
            previous = line

    markdown = "\\n".join(compact)
    if len(markdown) > max_chars:
        markdown = markdown[: max_chars - 22].rstrip() + "\\n\\n...[truncated]..."
    return RenderedContent(markdown, state.references)
