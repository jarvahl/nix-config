import assert from "node:assert/strict";
import test from "node:test";
import {
  extractFinalAssistantText,
  invitedRoomIds,
  matrixPath,
  matrixTypingPath,
  normalizeHomeserver,
} from "./index.ts";

test("normalizes homeserver URLs without duplicating the scheme", () => {
  assert.equal(normalizeHomeserver("matrix.tailbf412b.ts.net"), "https://matrix.tailbf412b.ts.net");
  assert.equal(normalizeHomeserver("https://matrix.example/"), "https://matrix.example");
});

test("finds only invites addressed to the logged-in Matrix user", () => {
  assert.deepEqual(invitedRoomIds({
    "!direct:matrix.example": {
      invite_state: { events: [{ type: "m.room.member", state_key: "@gaia:matrix.example", content: { membership: "invite" } }] },
    },
    "!someone-else:matrix.example": {
      invite_state: { events: [{ type: "m.room.member", state_key: "@other:matrix.example", content: { membership: "invite" } }] },
    },
    "!joined:matrix.example": {
      invite_state: { events: [{ type: "m.room.member", state_key: "@gaia:matrix.example", content: { membership: "join" } }] },
    },
  }, "@gaia:matrix.example"), ["!direct:matrix.example"]);
});

test("builds encoded Matrix room API paths", () => {
  assert.equal(
    matrixPath("!room:matrix.example", "send/m.room.message/txn"),
    "/_matrix/client/v3/rooms/!room%3Amatrix.example/send/m.room.message/txn",
  );
});

test("builds the Matrix typing notification path", () => {
  assert.equal(
    matrixTypingPath("!room:matrix.example", "@gaia:matrix.example"),
    "/_matrix/client/v3/rooms/!room%3Amatrix.example/typing/%40gaia%3Amatrix.example",
  );
});

test("extracts the last assistant text response", () => {
  assert.equal(extractFinalAssistantText([
    { role: "assistant", content: [{ type: "text", text: "first" }] },
    { role: "user", content: [{ type: "text", text: "ignored" }] },
    { role: "assistant", content: [{ type: "text", text: "final" }, { type: "image" }] },
  ]), "final");
  assert.equal(extractFinalAssistantText([]), "");
});
