import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { randomUUID } from "node:crypto";

const instructions = "The trailing [Matrix event: ...] or [Matrix thread: ...] line is private routing metadata. Do not quote or echo it in replies.";

export const normalizeHomeserver = (value: string) => {
  const trimmed = value.trim();
  return /^https?:\/\//i.test(trimmed) ? trimmed.replace(/\/$/, "") : `https://${trimmed.replace(/\/$/, "")}`;
};

export const extractFinalAssistantText = (messages: any[]) => {
  const assistants = messages.filter((message: any) => message.role === "assistant");
  const message = assistants.at(-1);
  return (message?.content ?? [])
    .filter((part: any) => part.type === "text")
    .map((part: any) => part.text)
    .join("");
};

export const matrixPath = (roomId: string, suffix: string) =>
  `/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/${suffix}`;

export const matrixTypingPath = (roomId: string, userId: string) =>
  `${matrixPath(roomId, "typing")}/${encodeURIComponent(userId)}`;

export const invitedRoomIds = (rooms: Record<string, any> | undefined, userId: string) =>
  Object.entries(rooms ?? {})
    .filter(([, room]: [string, any]) =>
      room.invite_state?.events?.some((event: any) =>
        event.type === "m.room.member" && event.state_key === userId && event.content?.membership === "invite",
      ),
    )
    .map(([roomId]) => roomId);

type MatrixMessage = {
  body: string;
  content?: Record<string, any>;
};

type MatrixPrompt = {
  content: Array<Record<string, string>>;
  eventId: string;
  roomId: string;
  threadRootId?: string;
};

type MatrixResponseContext = {
  agentUserId: string;
  event: MatrixMessage;
  isReplyToAgent: boolean;
  memberIds: string[];
};

export const matrixMentionedUserIds = (
  body: string,
  content: Record<string, any> | undefined,
  memberIds: string[],
) => {
  const mentionedUserIds = new Set<string>(
    Array.isArray(content?.["m.mentions"]?.user_ids) ? content["m.mentions"].user_ids : [],
  );
  for (const userId of memberIds) {
    const localpart = userId.match(/^@([^:]+):/)?.[1];
    if (localpart && new RegExp(`(^|\\s)@${localpart}(?=$|[\\s:,.!?])`, "i").test(body)) {
      mentionedUserIds.add(userId);
    }
  }
  return mentionedUserIds;
};

export const hasOwnMatrixMention = (mentionedUserIds: Set<string>, ownUserId: string) =>
  mentionedUserIds.has(ownUserId);

export const hasMentionOfAnotherMember = (
  mentionedUserIds: Set<string>,
  memberIds: string[],
  ownUserId: string,
) => [...mentionedUserIds].some(
  (userId) => userId !== ownUserId && memberIds.includes(userId),
);

export const shouldRespond = ({
  agentUserId,
  event,
  isReplyToAgent,
  memberIds,
}: MatrixResponseContext) => {
  if (memberIds.length < 2 || !memberIds.includes(agentUserId) || !event.body.trim()) return false;
  const mentionedUserIds = matrixMentionedUserIds(event.body, event.content, memberIds);
  const directRoom = memberIds.length === 2;
  const ownMention = hasOwnMatrixMention(mentionedUserIds, agentUserId);
  const competingMention = hasMentionOfAnotherMember(mentionedUserIds, memberIds, agentUserId);
  return directRoom || ownMention || (isReplyToAgent && !competingMention);
};

export function createMatrixExtension(pi: ExtensionAPI, Type: any, dependencies = { fetch: globalThis.fetch }) {
  const homeserverValue = process.env.MATRIX_HOMESERVER?.trim();
  const userId = process.env.MATRIX_USER_ID?.trim();
  const password = process.env.MATRIX_PASSWORD?.trim();
  const allowedInviteUsers = new Set(
    (process.env.MATRIX_ALLOWED_INVITE_USERS ?? "").split(",").map((value) => value.trim()).filter(Boolean),
  );
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  const cursorFile = join(agentDir, "tmp", "matrix-sync-cursor");
  const archivedRoomsFile = join(agentDir, "tmp", "matrix-archived-rooms.json");
  const archivedRooms = new Set<string>();
  const mediaDirectory = join(agentDir, "tmp", "matrix-media");

  type ActiveTurn = { eventId: string; roomId: string; threadRootId?: string };
  let token: string | undefined;
  let ownUserId = userId;
  let active: ActiveTurn | undefined;
  let promptRoomId: string | undefined;
  let typingRoomId: string | undefined;
  let typingTimer: ReturnType<typeof setInterval> | undefined;
  let stopping = false;
  let loop: Promise<void> | undefined;
  const queue: MatrixPrompt[] = [];

  const api = async (path: string, init: RequestInit = {}) => {
    if (!homeserverValue) throw new Error("MATRIX_HOMESERVER is not configured");
    const headers = new Headers(init.headers);
    headers.set("content-type", "application/json");
    if (token) headers.set("authorization", `Bearer ${token}`);
    const response = await dependencies.fetch(`${normalizeHomeserver(homeserverValue)}${path}`, { ...init, headers });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(`Matrix API ${path} failed (${response.status}): ${body?.errcode ?? "unknown error"}`);
    return body;
  };

  const saveCursor = async (cursor: string) => {
    await mkdir(dirname(cursorFile), { recursive: true, mode: 0o700 });
    await writeFile(cursorFile, cursor, { mode: 0o600 });
  };

  const loadArchivedRooms = async () => {
    try {
      const rooms = JSON.parse(await readFile(archivedRoomsFile, "utf8"));
      if (Array.isArray(rooms)) for (const roomId of rooms) if (typeof roomId === "string") archivedRooms.add(roomId);
    } catch {
      // No archive registry on first start.
    }
  };

  const saveArchivedRooms = async () => {
    await mkdir(dirname(archivedRoomsFile), { recursive: true, mode: 0o700 });
    await writeFile(archivedRoomsFile, JSON.stringify([...archivedRooms], null, 2), { mode: 0o600 });
  };

  const downloadMedia = async (mxc: string, fileName: string, mimeType: string) => {
    if (!token || !homeserverValue || !mxc.startsWith("mxc://")) throw new Error("Invalid Matrix media URL");
    const [server, ...mediaParts] = mxc.slice("mxc://".length).split("/");
    const mediaId = mediaParts.join("/");
    if (!server || !mediaId) throw new Error("Invalid Matrix media URL");
    const response = await dependencies.fetch(
      `${normalizeHomeserver(homeserverValue)}/_matrix/client/v1/media/download/${encodeURIComponent(server)}/${encodeURIComponent(mediaId)}`,
      { headers: { authorization: `Bearer ${token}` } },
    );
    if (!response.ok) throw new Error(`Matrix media download failed (${response.status})`);
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.byteLength > 10 * 1024 * 1024) throw new Error("Matrix media exceeds the 10 MiB limit");
    await mkdir(mediaDirectory, { recursive: true, mode: 0o700 });
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_") || "attachment";
    const path = join(mediaDirectory, `${randomUUID()}-${safeName}`);
    await writeFile(path, bytes, { mode: 0o600 });
    return { path, data: Buffer.from(bytes).toString("base64"), mimeType };
  };

  const updateTyping = async (roomId: string, typing: boolean) => {
    if (!token || !ownUserId) return;
    try {
      await api(matrixTypingPath(roomId, ownUserId), {
        method: "PUT",
        body: JSON.stringify(typing ? { typing: true, timeout: 30000 } : { typing: false }),
      });
    } catch (error) {
      console.error("pi-matrix-synapse: typing update failed", error instanceof Error ? error.message : String(error));
    }
  };

  const stopTyping = async () => {
    if (typingTimer) clearInterval(typingTimer);
    typingTimer = undefined;
    const roomId = typingRoomId;
    typingRoomId = undefined;
    if (roomId) await updateTyping(roomId, false);
  };

  const startTyping = async (roomId: string) => {
    if (typingRoomId === roomId) return;
    await stopTyping();
    typingRoomId = roomId;
    void updateTyping(roomId, true);
    typingTimer = setInterval(() => void updateTyping(roomId, true), 15000);
  };

  const uploadMedia = async (filePath: string, mimeType: string) => {
    if (!token || !homeserverValue) throw new Error("Matrix is not connected");
    const data = await readFile(filePath);
    if (data.byteLength > 10 * 1024 * 1024) throw new Error("Matrix media exceeds the 10 MiB limit");
    const fileName = filePath.split("/").pop() || "attachment";
    const response = await dependencies.fetch(
      `${normalizeHomeserver(homeserverValue)}/_matrix/media/v3/upload?filename=${encodeURIComponent(fileName)}`,
      { method: "POST", headers: { authorization: `Bearer ${token}`, "content-type": mimeType }, body: data },
    );
    const result = await response.json().catch(() => ({}));
    if (!response.ok || typeof result.content_uri !== "string") {
      throw new Error(`Matrix media upload failed (${response.status})`);
    }
    return { contentUri: result.content_uri, fileName, size: data.byteLength };
  };

  const sendMessage = async (roomId: string, text: string, replyTo?: string, threadRootId?: string) => {
    if (!token) throw new Error("Matrix is not connected");
    const txnId = randomUUID();
    const content: Record<string, unknown> = { msgtype: "m.text", body: text };
    if (threadRootId) {
      content["m.relates_to"] = {
        event_id: threadRootId,
        rel_type: "m.thread",
        ...(replyTo ? { "m.in_reply_to": { event_id: replyTo } } : {}),
      };
    } else if (replyTo) {
      content["m.relates_to"] = { "m.in_reply_to": { event_id: replyTo } };
    }
    return api(matrixPath(roomId, `send/m.room.message/${txnId}`), {
      method: "PUT",
      body: JSON.stringify(content),
    });
  };

  const joinInvitedRooms = async (rooms: Record<string, any> | undefined) => {
    if (!ownUserId) return;
    for (const roomId of invitedRoomIds(rooms, ownUserId)) {
      await api(matrixPath(roomId, "join"), { method: "POST", body: "{}" });
    }
  };

  const processEvent = async (roomId: string, event: any) => {
    if (event.type !== "m.room.message" || event.sender === ownUserId || archivedRooms.has(roomId)) return;
    const msgtype = event.content?.msgtype;
    if (!["m.text", "m.image", "m.file"].includes(msgtype)) return;
    if (typeof event.content?.body !== "string") event.content.body = "";
    const members = await api(`/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/joined_members`);
    const memberIds = Object.keys(members.joined ?? {});
    if (memberIds.length < 2 || !memberIds.includes(ownUserId!) || !memberIds.includes(event.sender)) return;
    const body = event.content.body.trim() || `[Matrix ${msgtype === "m.image" ? "image" : "file"}]`;
    const relatesTo = event.content?.["m.relates_to"] ?? {};
    const threadRootId = relatesTo.rel_type === "m.thread" ? relatesTo.event_id : undefined;
    const replyTo = relatesTo["m.in_reply_to"]?.event_id || threadRootId;
    let isReplyToAgent = false;
    if (replyTo) {
      try {
        const repliedEvent = await api(
          `/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/event/${encodeURIComponent(replyTo)}`,
        );
        isReplyToAgent = repliedEvent.sender === ownUserId;
      } catch {
        // An unavailable reply target cannot activate the agent.
      }
    }
    if (!shouldRespond({
      agentUserId: ownUserId!,
      event: { body, content: event.content },
      isReplyToAgent,
      memberIds,
    })) return;
    const threadHint = threadRootId
      ? `\n[Matrix thread: room_id=${roomId}; event_id=${event.event_id}; thread_root_id=${threadRootId}]`
      : `\n[Matrix event: room_id=${roomId}; event_id=${event.event_id}]`;
    const content: Array<Record<string, string>> = [{ type: "text", text: `${body}${threadHint}` }];
    const mediaUrl = event.content.url;
    if (typeof mediaUrl === "string") {
      try {
        const mimeType = event.content.info?.mimetype || (msgtype === "m.image" ? "image/*" : "application/octet-stream");
        const attachment = await downloadMedia(mediaUrl, event.content.body || "attachment", mimeType);
        if (msgtype === "m.image" && mimeType.startsWith("image/")) {
          content.push({ type: "image", data: attachment.data, mimeType: attachment.mimeType });
        } else {
          content[0].text += `\nAttachment saved at: ${attachment.path}`;
        }
      } catch (error) {
        content[0].text += `\nAttachment unavailable: ${error instanceof Error ? error.message : String(error)}`;
      }
    }
    queue.push({ content, eventId: event.event_id, roomId, threadRootId });
    processQueue();
  };

  const processQueue = () => {
    if (active || queue.length === 0) return;
    const next = queue.shift()!;
    active = { eventId: next.eventId, roomId: next.roomId, threadRootId: next.threadRootId };
    pi.sendUserMessage(next.content, { deliverAs: "followUp" });
  };

  const syncLoop = async () => {
    if (!homeserverValue || !userId || !password) {
      console.error("pi-matrix-synapse: homeserver, user, and password are required");
      return;
    }
    await loadArchivedRooms();
    const login = await api("/_matrix/client/v3/login", {
      method: "POST",
      body: JSON.stringify({
        identifier: { type: "m.id.user", user: userId },
        password,
        type: "m.login.password",
        initial_device_display_name: "Pi agent",
      }),
    });
    token = login.access_token;
    ownUserId = login.user_id;
    let since: string | undefined;
    try {
      since = (await readFile(cursorFile, "utf8")).trim() || undefined;
    } catch {
      // First sync establishes a cursor without replaying the existing room history.
    }

    let firstSync = since === undefined;
    while (!stopping) {
      try {
        const query = new URLSearchParams({ timeout: "30000" });
        if (since) query.set("since", since);
        const result = await api(`/_matrix/client/v3/sync?${query.toString()}`);
        await joinInvitedRooms(result.rooms?.invite);
        if (firstSync) {
          firstSync = false;
          since = result.next_batch;
          await saveCursor(since);
          continue;
        }
        for (const [roomId, room] of Object.entries<any>(result.rooms?.join ?? {})) {
          for (const event of room.timeline?.events ?? []) await processEvent(roomId, event);
        }
        since = result.next_batch;
        await saveCursor(since);
      } catch (error) {
        if (!stopping) {
          console.error("pi-matrix-synapse: sync failed", error instanceof Error ? error.message : String(error));
          await new Promise((resolve) => setTimeout(resolve, 3000));
        }
      }
    }
    token = undefined;
  };

  pi.registerTool({
    name: "matrix_create_room",
    label: "Create Matrix room",
    description: "Create a private Matrix topic room and invite explicitly allowed Matrix users or agents.",
    parameters: Type.Object({
      name: Type.String({ description: "Room name" }),
      topic: Type.Optional(Type.String({ description: "Optional room topic" })),
      inviteUserIds: Type.Array(Type.String({ description: "Full Matrix user IDs to invite" })),
    }),
    async execute(_id: string, params: { name?: string; topic?: string; inviteUserIds?: string[] }) {
      const name = params.name?.trim();
      const inviteUserIds = [...new Set((params.inviteUserIds ?? []).map((userId) => userId.trim()).filter(Boolean))];
      if (!name) throw new Error("name is required");
      if (!token) throw new Error("Matrix is not connected");
      if (!inviteUserIds.every((userId) => allowedInviteUsers.has(userId))) {
        throw new Error("One or more invited Matrix users are not on the configured allowlist");
      }
      const room = await api("/_matrix/client/v3/createRoom", {
        method: "POST",
        body: JSON.stringify({
          invite: inviteUserIds,
          is_direct: false,
          name,
          preset: "private_chat",
          ...(params.topic?.trim() ? { topic: params.topic.trim() } : {}),
        }),
      });
      return {
        content: [{ type: "text", text: `Created private Matrix room ${room.room_id}.` }],
        details: { roomId: room.room_id, invitedUserIds: inviteUserIds },
      };
    },
  });

  pi.registerTool({
    name: "matrix_archive_room",
    label: "Archive Matrix room",
    description: "Archive a private Matrix room by sending an agent-written notice and ignoring future messages. This does not purge server history.",
    parameters: Type.Object({
      notice: Type.String({ description: "Natural-language notice to send before leaving" }),
      roomId: Type.Optional(Type.String({ description: "Room to archive; defaults to the current Matrix room" })),
    }),
    async execute(_id: string, params: { notice?: string; roomId?: string }) {
      const destination = params.roomId?.trim() || active?.roomId;
      const notice = params.notice?.trim();
      if (!destination) throw new Error("No Matrix room to archive");
      if (!notice) throw new Error("notice is required");
      if (!token || !ownUserId) throw new Error("Matrix is not connected");
      const members = await api(`/_matrix/client/v3/rooms/${encodeURIComponent(destination)}/joined_members`);
      const memberIds = Object.keys(members.joined ?? {});
      if (!memberIds.includes(ownUserId)) throw new Error("This agent is not a member of that Matrix room");
      await sendMessage(destination, notice);
      await stopTyping();
      archivedRooms.add(destination);
      await saveArchivedRooms();
      if (active?.roomId === destination) active = undefined;
      return { content: [], details: { roomId: destination, archived: true } };
    },
  });

  pi.registerTool({
    name: "matrix_get_message",
    label: "Get Matrix message",
    description: "Fetch a specific Matrix event by room_id and event_id, including its media attachment when available.",
    parameters: Type.Object({
      eventId: Type.String({ description: "Matrix event ID" }),
      roomId: Type.String({ description: "Matrix room ID" }),
    }),
    async execute(_id: string, params: { eventId?: string; roomId?: string }) {
      const eventId = params.eventId?.trim();
      const roomId = params.roomId?.trim();
      if (!eventId || !roomId) throw new Error("roomId and eventId are required");
      const event = await api(`/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/event/${encodeURIComponent(eventId)}`);
      const eventContent = event.content ?? {};
      const body = typeof eventContent.body === "string" ? eventContent.body : "";
      const content: Array<Record<string, string>> = [{ type: "text", text: body }];
      if (typeof eventContent.url === "string") {
        const mimeType = eventContent.info?.mimetype || "application/octet-stream";
        const media = await downloadMedia(eventContent.url, body || "attachment", mimeType);
        if (eventContent.msgtype === "m.image" && mimeType.startsWith("image/")) {
          content.push({ type: "image", data: media.data, mimeType });
        } else {
          content[0].text += `\nAttachment saved at: ${media.path}`;
        }
      }
      return { content, details: { roomId, eventId, sender: event.sender } };
    },
  });

  pi.registerTool({
    name: "matrix_send_message",
    label: "Send Matrix message",
    description: "Send a text message or upload a file/image to a private Matrix room. Pass roomId from the originating Matrix prompt for scheduled messages.",
    parameters: Type.Object({
      filePath: Type.Optional(Type.String({ description: "Local path of an optional file or image to upload" })),
      mimeType: Type.Optional(Type.String({ description: "MIME type for filePath, for example image/png" })),
      replyToEventId: Type.Optional(Type.String({ description: "Optional event ID to use as the topic anchor" })),
      roomId: Type.Optional(Type.String({ description: "The originating Matrix room_id; required for scheduled messages" })),
      threadRootId: Type.Optional(Type.String({ description: "Optional thread root event ID" })),
      text: Type.Optional(Type.String({ description: "Optional message text or media caption" })),
    }),
    async execute(_id: string, params: { filePath?: string; mimeType?: string; replyToEventId?: string; roomId?: string; text?: string; threadRootId?: string }) {
      const text = params.text?.trim() ?? "";
      const filePath = params.filePath?.trim();
      const mimeType = params.mimeType?.trim();
      if (!text && !filePath) throw new Error("text or filePath is required");
      if (filePath && !mimeType) throw new Error("mimeType is required with filePath");
      const destination = params.roomId?.trim() || active?.roomId;
      if (!destination) throw new Error("No active Matrix room; scheduled messages must provide roomId");
      const members = await api(`/_matrix/client/v3/rooms/${encodeURIComponent(destination)}/joined_members`);
      const memberIds = Object.keys(members.joined ?? {});
      if (!ownUserId || memberIds.length < 2 || !memberIds.includes(ownUserId)) {
        throw new Error("Messages may only be sent to private Matrix rooms where this agent is a member");
      }
      if (filePath) {
        const media = await uploadMedia(filePath, mimeType!);
        const msgtype = mimeType!.startsWith("image/") ? "m.image" : "m.file";
        await api(matrixPath(destination, `send/${msgtype}/${randomUUID()}`), {
          method: "PUT",
          body: JSON.stringify({
            body: media.fileName,
            filename: media.fileName,
            info: { mimetype: mimeType, size: media.size },
            msgtype,
            url: media.contentUri,
            ...(params.threadRootId?.trim() ? {
              "m.relates_to": {
                event_id: params.threadRootId.trim(),
                rel_type: "m.thread",
                ...(params.replyToEventId?.trim() ? { "m.in_reply_to": { event_id: params.replyToEventId.trim() } } : {}),
              },
            } : params.replyToEventId?.trim() ? { "m.relates_to": { "m.in_reply_to": { event_id: params.replyToEventId.trim() } } } : {}),
            ...(text ? { caption: text } : {}),
          }),
        });
        return { content: [], details: { roomId: destination, contentUri: media.contentUri } };
      }
      await sendMessage(
        destination,
        text,
        params.replyToEventId?.trim() || undefined,
        params.threadRootId?.trim() || active?.threadRootId,
      );
      return { content: [], details: undefined };
    },
  });

  pi.on("session_start", () => {
    if (loop) return;
    stopping = false;
    loop = syncLoop().catch((error) => {
      console.error("pi-matrix-synapse: startup failed", error instanceof Error ? error.message : String(error));
    }).finally(() => { loop = undefined; });
  });
  pi.on("session_shutdown", async () => {
    stopping = true;
    active = undefined;
    promptRoomId = undefined;
    queue.length = 0;
    await stopTyping();
    await loop;
  });
  pi.on("before_agent_start", (event: any) => {
    event.systemPromptOptions.sections.matrix = instructions;
    const scheduledRoom = typeof event.prompt === "string"
      ? event.prompt.match(/\[Matrix room_id=([^\]\s]+)\]/)?.[1]
      : undefined;
    promptRoomId = active?.roomId ?? scheduledRoom;
  });
  pi.on("agent_start", async () => {
    const roomId = active?.roomId ?? promptRoomId;
    if (roomId) await startTyping(roomId);
  });
  pi.on("agent_settled", async () => {
    await stopTyping();
    promptRoomId = undefined;
  });
  pi.on("agent_end", async (event: any) => {
    if (!active) return;
    const turn = active;
    const text = extractFinalAssistantText(event.messages);
    try {
      if (text) await sendMessage(turn.roomId, text, turn.eventId, turn.threadRootId);
    } finally {
      active = undefined;
      processQueue();
    }
  });
}

export default async function (pi: ExtensionAPI) {
  const { Type } = await import("@earendil-works/pi-ai");
  createMatrixExtension(pi, Type);
}
