import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { browser, browserJson, toolError, toolResult, truncate } from "./bridge.ts";
import {
  ContentParams,
  EvaluateParams,
  NavigateParams,
  NewTabParams,
  TabParams,
  type ContentInput,
  type EvaluateInput,
  type NavigateInput,
  type NewTabInput,
  type TabInput,
} from "./schemas.ts";

type Tab = { tabId: number; title: string; url: string };
type Tabs = { activeTabId: number | null; windows: { tabs: Tab[] }[] };

async function duplicateTab(tabId: number | undefined) {
  const tabs = await browserJson<Tabs>("listTabs", {});
  const sourceId = tabId ?? tabs.activeTabId;
  const source = tabs.windows.flatMap((window) => window.tabs).find((tab) => tab.tabId === sourceId);
  if (!source) throw new Error(`Tab ${sourceId ?? "(active)"} was not found`);
  return browserJson("newSession", { url: source.url });
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "browser-tabs",
    label: "Browser tabs",
    description: "List Firefox tabs and their IDs. Uses the Firefox Agent Bridge CLI.",
    parameters: Type.Object({}),
    async execute() {
      try { return toolResult(await browser("listTabs", {})); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-new-tab",
    label: "Browser new tab",
    description: "Open a new Firefox tab through the existing browser session.",
    parameters: NewTabParams,
    async execute(_toolCallId, input: NewTabInput) {
      try { return toolResult(await browser("newSession", input)); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-duplicate-tab",
    label: "Browser duplicate tab",
    description: "Duplicate a Firefox tab by opening its current URL in a new tab.",
    parameters: TabParams,
    async execute(_toolCallId, input: TabInput) {
      try { return toolResult(JSON.stringify(await duplicateTab(input.tabId))); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-set-active-tab",
    label: "Browser set active tab",
    description: "Make a Firefox tab active.",
    parameters: Type.Object({ tabId: Type.Number({ description: "Firefox tab ID" }) }),
    async execute(_toolCallId, input: { tabId: number }) {
      try { return toolResult(await browser("setActiveTab", input)); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-navigate",
    label: "Browser navigate",
    description: "Navigate a Firefox tab to a URL.",
    parameters: NavigateParams,
    async execute(_toolCallId, input: NavigateInput) {
      try { return toolResult(await browser("navigate", input)); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-content",
    label: "Browser content",
    description: "Read content from a Firefox page.",
    parameters: ContentParams,
    async execute(_toolCallId, input: ContentInput) {
      try { return toolResult(await browser("getContent", input)); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-interactables",
    label: "Browser interactables",
    description: "List clickable and input elements on a Firefox page.",
    parameters: TabParams,
    async execute(_toolCallId, input: TabInput) {
      try { return toolResult(await browser("getInteractables", input)); } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-evaluate",
    label: "Browser evaluate",
    description: "Evaluate a JavaScript expression in a Firefox tab and return its compact JSON-serializable result. Use an IIFE for multi-step code; do not include a top-level return.",
    parameters: EvaluateParams,
    async execute(_toolCallId, input: EvaluateInput) {
      try {
        return toolResult(truncate(await browser("evaluate", {
          ...input,
          script: `return (${input.script});`,
        }), input.maxChars ?? 8000));
      } catch (error) { return toolError(error); }
    },
  });

  pi.registerTool({
    name: "browser-screenshot",
    label: "Browser screenshot",
    description: "Capture a Firefox tab screenshot.",
    parameters: TabParams,
    async execute(_toolCallId, input: TabInput) {
      try { return toolResult(await browser("screenshot", input)); } catch (error) { return toolError(error); }
    },
  });
}
