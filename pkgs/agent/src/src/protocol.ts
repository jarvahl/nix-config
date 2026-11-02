export type Image = {
  type: "image";
  data: string;
  mimeType: string;
};

export type InputRequest = {
  type: "input";
  requestId?: string;
  conversation?: string;
  text: string;
  images?: Image[];
};

export type OutputEvent =
  | { type: "started"; requestId: string }
  | { type: "text_delta"; requestId: string; text: string }
  | { type: "tool_start"; requestId: string; name: string }
  | { type: "done"; requestId: string; text: string }
  | { type: "error"; requestId: string; message: string };
