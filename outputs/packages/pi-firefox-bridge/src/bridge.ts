import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { spawn } from "node:child_process";

export function browserPath() {
  const path = process.env.FIREFOX_AGENT_BRIDGE_BROWSER;
  if (!path) throw new Error("FIREFOX_AGENT_BRIDGE_BROWSER is not configured");
  return path;
}

export async function browser(action: string, params: unknown): Promise<string> {
  const directory = await mkdtemp(`${tmpdir()}/pi-firefox-bridge-`);
  const paramsPath = `${directory}/params.json`;

  try {
    await writeFile(paramsPath, JSON.stringify(params));
    const result = await new Promise<{ stdout: string; stderr: string; code: number }>((resolve, reject) => {
      const child = spawn(browserPath(), [action, `@${paramsPath}`], {
        stdio: ["ignore", "pipe", "pipe"],
      });
      let stdout = "";
      let stderr = "";
      child.stdout.on("data", (chunk) => { stdout += chunk; });
      child.stderr.on("data", (chunk) => { stderr += chunk; });
      child.on("error", reject);
      child.on("close", (code) => resolve({ stdout, stderr, code: code ?? 1 }));
    });

    if (result.code !== 0) {
      throw new Error(result.stderr.trim() || result.stdout.trim() || `${action} failed with exit code ${result.code}`);
    }
    return result.stdout.trim();
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export async function browserJson<T>(action: string, params: unknown): Promise<T> {
  return JSON.parse(await browser(action, params)) as T;
}

export function toolError(error: unknown) {
  return {
    content: [{ type: "text" as const, text: error instanceof Error ? error.message : String(error) }],
    details: {},
    isError: true,
  };
}

export function toolResult(output: string) {
  return { content: [{ type: "text" as const, text: output }], details: {} };
}

export function truncate(output: string, maxChars: number) {
  if (output.length <= maxChars) return output;
  const head = Math.floor(maxChars * 0.75);
  return `${output.slice(0, head)}\n...[truncated]...\n${output.slice(-(maxChars - head))}`;
}
