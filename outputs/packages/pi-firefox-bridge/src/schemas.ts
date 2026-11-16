import { Type, type Static } from "typebox";

export const TabParams = Type.Object({
  tabId: Type.Optional(Type.Number({ description: "Firefox tab ID" })),
});

export const NewTabParams = Type.Object({
  url: Type.Optional(Type.String({ description: "URL to open" })),
});

export const NavigateParams = Type.Object({
  tabId: Type.Optional(Type.Number({ description: "Firefox tab ID" })),
  url: Type.String({ description: "URL to open" }),
});

export const ContentParams = Type.Object({
  format: Type.Optional(Type.Union([
    Type.Literal("annotated"),
    Type.Literal("text"),
    Type.Literal("html"),
  ])),
  tabId: Type.Optional(Type.Number({ description: "Firefox tab ID" })),
});

export const EvaluateParams = Type.Object({
  maxChars: Type.Optional(Type.Integer({ minimum: 1000, maximum: 20000 })),
  script: Type.String({ description: "JavaScript expression producing a compact JSON value; use an IIFE for multi-step code, do not include a top-level return" }),
  tabId: Type.Optional(Type.Number({ description: "Firefox tab ID" })),
});

export type ContentInput = Static<typeof ContentParams>;
export type EvaluateInput = Static<typeof EvaluateParams>;
export type NavigateInput = Static<typeof NavigateParams>;
export type NewTabInput = Static<typeof NewTabParams>;
export type TabInput = Static<typeof TabParams>;
