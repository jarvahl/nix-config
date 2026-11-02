import { serve } from "./server.js";

if (process.argv[2] === "serve") await serve();
else {
  console.error("Usage: agent serve");
  process.exitCode = 2;
}
