/**
 * tmux-agent-status
 * Prepends agent status icons (⚡/✓/❓) to tmux window titles
 * and plays notification sounds on done/ask events.
 *
 * Sound config via tmux options:
 *   set -g @agent-sound "Glass"       # macOS sound name, or "none"
 *   set -g @agent-ask-sound "Ping"    # optional separate sound for ask
 */

import type { Plugin } from "@opencode-ai/plugin"
import { appendFile } from "node:fs/promises"

const logFile = "/tmp/tmux-agent-status.txt"

export const TmuxAgentStatusPlugin: Plugin = async ({ $, client }) => {
	if (!process.env.TMUX) return {}

	const paneId = process.env.TMUX_PANE || ""
	if (!paneId) return {}

	let logQueue: Promise<void> = Promise.resolve()
	let lastSoundAt = 0
	let waitingForHuman = false

	const timestamp = (): string => new Date().toISOString()

	const appendLog = async (line: string): Promise<void> => {
		logQueue = logQueue
			.then(async () => {
				await appendFile(logFile, `${line}\n`)
			})
			.catch(() => {})
		await logQueue
	}

	await appendLog(`[${timestamp()}] --- startup paneId=${paneId} ---`)

	const describeError = (error: unknown): string => {
		if (error instanceof Error) return error.message
		return String(error)
	}

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
		} catch (error) {
			await appendLog(`[${timestamp()}] ERROR scope=session.check sessionID=${sessionID} caught=${JSON.stringify(describeError(error))}`)
			return false
		}
	}

	const isWindowActive = async (): Promise<boolean> => {
		try {
			const active = (await $`tmux display-message -t ${paneId} -p '#{window_active}'`.text()).trim()
			return active === "1"
		} catch {
			return false
		}
	}

	const colorForIcon: Record<string, string> = {
		"✓": "fg=colour82,bg=colour235",
		"❓": "fg=colour196,bg=colour235",
	}

	const setWindowColor = async (icon: string): Promise<void> => {
		try {
			const style = colorForIcon[icon]
			if (style) {
				await $`tmux set-window-option -t ${paneId} window-status-style ${style}`.quiet()
			} else {
				await $`tmux set-window-option -t ${paneId} -u window-status-style`.quiet()
			}
		} catch {}
	}

	const renameWindow = async (icon: string): Promise<void> => {
		try {
			const current = (await $`tmux display-message -t ${paneId} -p '#{window_name}'`.text()).trim()
			const clean = current.replace(/^[⚡✓❓] /, "")
			await $`tmux rename-window -t ${paneId} ${icon} ${clean}`.quiet()
			await setWindowColor(icon)
		} catch (error) {
			await appendLog(`[${timestamp()}] ERROR scope=renameWindow caught=${JSON.stringify(describeError(error))}`)
		}
	}

	const playSound = async (type: "done" | "ask", sessionID: string): Promise<boolean> => {
		try {
			if (type === "done" && Date.now() - lastSoundAt < 3000) {
				return false
			}
			let sound = (await $`tmux show-option -gqv @agent-sound`.text()).trim() || "Glass"
			if (type === "ask") {
				const askSound = (await $`tmux show-option -gqv @agent-ask-sound`.text()).trim()
				if (askSound) sound = askSound
			}
			if (sound !== "none") {
				await $`afplay /System/Library/Sounds/${sound}.aiff`.quiet()
			}
			if (type === "done") {
				lastSoundAt = Date.now()
			}
			return true
		} catch (error) {
			await appendLog(
				`[${timestamp()}] ERROR scope=playSound type=${type} sessionID=${sessionID} caught=${JSON.stringify(describeError(error))}`,
			)
			return false
		}
	}

	return {
			event: async ({ event }) => {
				const sessionID = getSessionID(event.properties)
				const waitingAtStart = waitingForHuman
				let action = "skipped:ignored"
				try {
					const isSubagent = await isSubagentSession(sessionID)
					if (isSubagent) {
						action = "skipped:subagent"
					} else if (event.type === "session.idle") {
						if (waitingForHuman) {
							action = "skipped:waitingForHuman"
						} else if (await isWindowActive()) {
							action = "skipped:windowActive"
						} else {
							await renameWindow("✓")
							const played = await playSound("done", sessionID)
							action = played ? "rename:✓ sound:done" : "skipped:debounce"
						}
					} else if (event.type === "session.error") {
						waitingForHuman = false
						if (await isWindowActive()) {
							action = "skipped:windowActive"
						} else {
							await renameWindow("✓")
							const played = await playSound("done", sessionID)
							action = played ? "rename:✓ sound:done" : "skipped:debounce"
						}
					}
				} catch (error) {
					action = `error:${describeError(error)}`
				} finally {
				await appendLog(
					`[${timestamp()}] EVENT type=${event.type} sessionID=${sessionID || ""} waitingForHuman=${waitingAtStart} action=${action}`,
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
					} else if (input.tool === "question") {
						if (await isWindowActive()) {
							action = "skipped:windowActive"
						} else {
							waitingForHuman = true
							await renameWindow("❓")
							await playSound("ask", sessionID)
							action = "rename:❓ sound:ask"
						}
					} else {
						waitingForHuman = false
						await renameWindow("⚡")
						action = "rename:⚡"
					}
				} catch (error) {
					action = `error:${describeError(error)}`
				} finally {
				await appendLog(`[${timestamp()}] TOOL tool=${input.tool} sessionID=${sessionID} action=${action}`)
			}
		},
		"permission.ask": async () => {
			if (await isWindowActive()) return
			waitingForHuman = true
			await renameWindow("❓")
			await playSound("ask", "")
		},
	}
}

export default TmuxAgentStatusPlugin
