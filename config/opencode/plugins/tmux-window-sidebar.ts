/**
 * tmux-window-sidebar OpenCode Plugin
 *
 * Bridges OpenCode events to the tmux-window-sidebar Rust binary's hook subcommand.
 * Replaces tmux-agent-status.ts with full event coverage matching hiroppy's adapter layer.
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
import { execFile } from "node:child_process"
import { promisify } from "node:util"
import type { Plugin } from "@opencode-ai/plugin"

const execFileAsync = promisify(execFile)
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

/** Call the Rust binary's hook subcommand */
const hook = async (event: string, data: Record<string, unknown> = {}): Promise<void> => {
	try {
		const json = JSON.stringify(data)
		const { stdout } = await execFileAsync(SIDEBAR_BIN, ["hook", "opencode", event], {
			input: json,
			timeout: 5000,
		})
		await appendLog(`[${timestamp()}] HOOK event=${event} stdout=${stdout.trim()}`)
	} catch (error) {
		await appendLog(`[${timestamp()}] HOOK_ERROR event=${event} error=${describeError(error)}`)
	}
}

/** Play a sound from a comma-separated list, with debounce for done sounds */
let lastDoneSoundAt = 0

const playSound = async (type: "done" | "ask"): Promise<void> => {
	try {
		const paneId = process.env.TMUX_PANE || ""
		if (!paneId) return

		// Check if window is active (focused)
		const { stdout: activeOut } = await execFileAsync("tmux", [
			"display-message",
			"-t",
			paneId,
			"-p",
			"#{window_active}",
		])
		if (activeOut.trim() === "1") return // Don't play sound for focused window

		if (type === "done" && Date.now() - lastDoneSoundAt < 3000) return // 3s debounce

		let soundList = (
			await execFileAsync("tmux", ["show-option", "-g", "-q", "@agent-sound"])
		).stdout.trim()
		if (!soundList) soundList = "Blow"

		if (type === "ask") {
			const askList = (
				await execFileAsync("tmux", ["show-option", "-g", "-q", "@agent-ask-sound"])
			).stdout.trim()
			if (askList) soundList = askList
		}

		if (soundList === "none") return

		const sounds = soundList.split(",").map((s) => s.trim())
		const picked = sounds[Math.floor(Math.random() * sounds.length)]
		if (!picked) return

		// Resolve sound path: ~/.dotfiles/sounds/ → /System/Library/Sounds/ → absolute
		const homeDir = process.env.HOME || ""
		const extensions = ["mp3", "aiff", "wav", "m4a"]
		let soundPath = ""

		for (const ext of extensions) {
			const candidate = `${homeDir}/.dotfiles/sounds/${picked}.${ext}`
			try {
				const { stat } = await import("node:fs/promises")
				await stat(candidate)
				soundPath = candidate
				break
			} catch {}
		}

		if (!soundPath) {
			const systemPath = `/System/Library/Sounds/${picked}.aiff`
			try {
				const { stat } = await import("node:fs/promises")
				await stat(systemPath)
				soundPath = systemPath
			} catch {}
		}

		if (!soundPath && picked.startsWith("/")) {
			soundPath = picked
		}

		if (soundPath) {
			await execFileAsync("afplay", [soundPath])
			if (type === "done") lastDoneSoundAt = Date.now()
		}
	} catch (error) {
		await appendLog(`[${timestamp()}] SOUND_ERROR type=${type} error=${describeError(error)}`)
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
					await playSound("done")
					action = "hook:stop"
				} else if (event.type === "session.error") {
					await hook("stop-failure", { cwd, session_id: sessionID, error: "session error" })
					await playSound("done")
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
					await playSound("ask")
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
				await playSound("ask")
			} catch (error) {
				await appendLog(
					`[${timestamp()}] PERMISSION_ASK_ERROR error=${describeError(error)}`,
				)
			}
		},
	}
}

export default TmuxWindowSidebarPlugin