import { createConnection } from "node:net";
import { randomUUID } from "node:crypto";
import { createInterface } from "node:readline";

const [socketPath, conversation, ...parts] = process.argv.slice(2);
const text = parts.join(" ");

if (!socketPath || !conversation || !text) {
  console.error("Usage: node send.mjs SOCKET CONVERSATION TEXT");
  process.exit(2);
}

const requestId = randomUUID();
const socket = createConnection(socketPath);
const lines = createInterface({ input: socket });

socket.on("connect", () => socket.write(`${JSON.stringify({
  type: "send",
  requestId,
  conversation,
  text,
})}\n`));

for await (const line of lines) {
  const response = JSON.parse(line);
  if (response.requestId !== requestId) continue;
  if (response.type === "sent") {
    socket.end();
    break;
  }
  if (response.type === "error") {
    console.error(response.message);
    process.exitCode = 1;
    socket.end();
    break;
  }
}
