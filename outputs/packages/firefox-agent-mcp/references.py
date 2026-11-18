from dataclasses import dataclass


@dataclass(frozen=True)
class ElementReference:
    ref: str
    selector: str
    role: str
    name: str


class ReferenceStore:
    def __init__(self):
        self._by_tab = {}

    def replace_for_tab(self, tab_id, references):
        self._by_tab[tab_id] = {item.ref: item for item in references}

    def get(self, tab_id, ref):
        try:
            return self._by_tab[tab_id][ref]
        except KeyError as error:
            raise ValueError(
                f"Reference {ref!r} is stale or unknown for tab {tab_id}; "
                f"call browser_content(tabId={tab_id}) again"
            ) from error

    def clear_tab(self, tab_id):
        self._by_tab.pop(tab_id, None)

    def clear_all(self):
        self._by_tab.clear()
