import assert from "node:assert/strict";
import test from "node:test";
import {
  extractFinalAssistantText,
  invitedRoomIds,
  matrixPath,
  hasMentionOfAnotherMember,
  hasOwnMatrixMention,
  matrixFormattedBody,
  matrixMentionedUserIds,
  matrixRoomMetadata,
  matrixTypingPath,
  normalizeHomeserver,
  shouldRespond,
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

test("routes Matrix activation rules by room size, mentions, and replies", () => {
  const own = "@gaia:matrix.example";
  const other = "@nixos-agent:matrix.example";
  const members = ["@jarvahl:matrix.example", own, other];
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "hello" }, isReplyToAgent: false, memberIds: ["@jarvahl:matrix.example", own] }), false);
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "hello" }, isReplyToAgent: false, memberIds: members }), false);
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "@gaia check" }, isReplyToAgent: false, memberIds: members }), true);
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "reply @nixos-agent" }, isReplyToAgent: true, memberIds: members }), false);
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "reply" }, isReplyToAgent: true, memberIds: members }), true);
  assert.equal(shouldRespond({ agentUserId: own, event: { body: "reply" }, isReplyToAgent: true, memberIds: ["@jarvahl:matrix.example", own] }), true);
});

test("extracts Matrix and textual member mentions", () => {
  const own = "@gaia:matrix.example";
  const other = "@nixos-agent:matrix.example";
  const mentioned = matrixMentionedUserIds("@gaia @nixos-agent", {}, [own, other]);
  assert.equal(hasOwnMatrixMention(mentioned, own), true);
  assert.equal(hasMentionOfAnotherMember(mentioned, [own, other], own), true);
});

test("formats Matrix room name and topic metadata", () => {
  assert.equal(matrixRoomMetadata([
    { type: "m.room.name", content: { name: "Christmas 2026 - Preschool" } },
    { type: "m.room.topic", content: { topic: "Shopping plan" } },
  ]), `[Matrix room metadata]
Name: Christmas 2026 - Preschool
Topic: Shopping plan
[End room metadata]`);
});

test("formats Matrix messages as safe HTML", () => {
  const html = matrixFormattedBody("**bold**\n- item\n> quote\n```\n<code>\n```");
  assert.match(html, /<strong>bold<\/strong>/);
  assert.match(html, /<ul><li>item<\/li><\/ul>/);
  assert.match(html, /<blockquote><p>quote<\/p><\/blockquote>/);
  assert.match(html, /<pre><code>&lt;code&gt;<\/code><\/pre>/);
});

test("extracts the last assistant text response", () => {
  assert.equal(extractFinalAssistantText([
    { role: "assistant", content: [{ type: "text", text: "first" }] },
    { role: "user", content: [{ type: "text", text: "ignored" }] },
    { role: "assistant", content: [{ type: "text", text: "final" }, { type: "image" }] },
  ]), "final");
  assert.equal(extractFinalAssistantText([]), "");
});
