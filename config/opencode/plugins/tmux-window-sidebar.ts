/**
 * tmux-window-sidebar OpenCode Plugin
 *
 * Bridges OpenCode events to the tmux-window-sidebar Rust binary's hook subcommand.
 * Replaces tmux-agent-status.ts with full event coverage matching hiroppy's adapter layer.
 *
 * Sound and window styling are handled entirely by the Rust binary (hook.rs).
 * This plugin only sends hook events — no direct sound playing or window renaming.
 *
 * Event mappings:
 *   session.created       → hook("session-start")
 *   session.idle          → hook("stop")
 *   session.error         → hook("stop-failure")
 *   session.status(busy)  → hook("user-prompt-submit")
 *   tool.execute.before   → hook("user-prompt-submit") or set status=running
 *   tool.execute.after    → hook("activity-log")
 *   permission.ask        → hook("notification")
 */

import { appendFile } from "node:fs/promises"
import { spawn } from "node:child_process"
import type { Plugin } from "@opencode-ai/plugin"

const logFile = "/tmp/tmux-window-sidebar.log"
const SIDEBAR_BIN = process.env.TMUX_WINDOW_SIDEBAR_BIN || `${process.env.HOME}/.local/bin/tmux-window-sidebar`

const timestamp = (): string => new Date().toISOString()

const appendLog = async (line: string): Promise<void> => {
	try {
		await appendFile(logFile, `${line}\n`)
	} catch {}
}

const describeError = (error: unknown): string => {
	if (error instanceof Error) return error.message
	return String(error)
}

/** Call the Rust binary's hook subcommand using spawn (execFileAsync with `input` hangs because stdin EOF isn't sent properly) */
const hook = async (event: string, data: Record<string, unknown> = {}): Promise<void> => {
	try {
		const json = JSON.stringify(data)
		const result = await new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
			const child = spawn(SIDEBAR_BIN, ["hook", "opencode", event], {
				env: { ...process.env, TMUX_PANE: process.env.TMUX_PANE || "" },
				stdio: ["pipe", "pipe", "pipe"],
			})
			let stdout = ""
			let stderr = ""
			child.stdout.on("data", (d: Buffer) => (stdout += d))
			child.stderr.on("data", (d: Buffer) => (stderr += d))
			child.on("close", (code: number | null) => {
				if (code === 0) resolve({ stdout, stderr })
				else reject(new Error(`hook exited with code ${code}: ${stderr.trim()}`))
			})
			child.on("error", reject)
			child.stdin.write(json)
			child.stdin.end()
			// Timeout safety: kill after 5s
			setTimeout(() => {
				child.kill("SIGTERM")
				reject(new Error("hook timed out after 5s"))
			}, 5000)
		})
		await appendLog(`[${timestamp()}] HOOK event=${event} stdout=${result.stdout.trim()}`)
	} catch (error) {
		await appendLog(`[${timestamp()}] HOOK_ERROR event=${event} error=${describeError(error)}`)
	}
}

export const TmuxWindowSidebarPlugin: Plugin = async ({ $, client }) => {
	if (!process.env.TMUX) return {}

	const paneId = process.env.TMUX_PANE || ""
	if (!paneId) return {}

	await appendLog(`[${timestamp()}] --- startup paneId=${paneId} ---`)

	const getSessionID = (properties: unknown): string => {
		const props = properties as Record<string, unknown> | undefined
		const sessionID = props?.sessionID
		return typeof sessionID === "string" ? sessionID : ""
	}

	const isSubagentSession = async (sessionID: string): Promise<boolean> => {
		if (!sessionID) return false
		try {
			const response = await client.session.get({ path: { id: sessionID } })
			return Boolean((response as { parentID?: unknown } | undefined)?.parentID)
		} catch {
			return false
		}
	}

	/** Resolve session name via OpenCode client and update tmux */
	const resolveSessionName = async (sessionID: string): Promise<void> => {
		try {
			const response = await client.session.get({ path: { id: sessionID } })
			const name = (response as { name?: string } | undefined)?.name
			if (name) {
				await $`tmux set-option -p -t ${paneId} @pane_name ${name}`.quiet()
				await $`tmux rename-window -t ${paneId} ${name}`.quiet()
			}
		} catch (error) {
			await appendLog(
				`[${timestamp()}] ERROR scope=resolveSessionName sessionID=${sessionID} error=${describeError(error)}`,
			)
		}
	}

	return {
		event: async ({ event }) => {
			const sessionID = getSessionID(event.properties)
			let action = "skipped:ignored"

			try {
				const isSubagent = await isSubagentSession(sessionID)
				if (isSubagent) {
					action = "skipped:subagent"
					return
				}

				const cwd = (event.properties as Record<string, unknown>)?.cwd?.toString() || ""

				if (event.type === "session.created") {
					await hook("session-start", {
						cwd,
						session_id: sessionID,
						source: "startup",
					})
					if (sessionID) {
						await resolveSessionName(sessionID)
					}
					action = "hook:session-start"
				} else if (event.type === "session.idle") {
					await hook("stop", { cwd, session_id: sessionID, last_message: "" })
					action = "hook:stop"
				} else if (event.type === "session.error") {
					await hook("stop-failure", { cwd, session_id: sessionID, error: "session error" })
					action = "hook:stop-failure"
				}
			} catch (error) {
				action = `error:${describeError(error)}`
			} finally {
				await appendLog(
					`[${timestamp()}] EVENT type=${event.type} sessionID=${sessionID} action=${action}`,
				)
			}
		},

		"tool.execute.before": async (input) => {
			const sessionID = input.sessionID || ""
			let action = "skipped:ignored"

			try {
				const isSubagent = await isSubagentSession(sessionID)
				if (isSubagent) {
					action = "skipped:subagent"
					return
				}

				if (input.tool === "question") {
					await hook("notification", {
						cwd: "",
						session_id: sessionID,
						wait_reason: "permission",
					})
					action = "hook:notification(question)"
				} else {
					await hook("user-prompt-submit", {
						cwd: "",
						session_id: sessionID,
						prompt: "",
					})
					action = "hook:user-prompt-submit"
				}
			} catch (error) {
				action = `error:${describeError(error)}`
			} finally {
				await appendLog(
					`[${timestamp()}] TOOL_BEFORE tool=${input.tool} sessionID=${sessionID} action=${action}`,
				)
			}
		},

		"tool.execute.after": async (input) => {
			const sessionID = input.sessionID || ""
			try {
				await hook("activity-log", {
					tool_name: input.tool,
					session_id: sessionID,
				})
			} catch (error) {
				await appendLog(
					`[${timestamp()}] TOOL_AFTER_ERROR tool=${input.tool} error=${describeError(error)}`,
				)
			}
		},

		"permission.ask": async () => {
			try {
				await hook("notification", {
					cwd: "",
					session_id: "",
					wait_reason: "permission",
				})
			} catch (error) {
				await appendLog(
					`[${timestamp()}] PERMISSION_ASK_ERROR error=${describeError(error)}`,
				)
			}
		},
	}
}

export default TmuxWindowSidebarPlugin