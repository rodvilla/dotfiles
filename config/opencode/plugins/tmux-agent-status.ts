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

export const TmuxAgentStatusPlugin: Plugin = async ({ $ }) => {
	if (!process.env.TMUX) return {}

	const paneId = process.env.TMUX_PANE || ""
	if (!paneId) return {}

	const renameWindow = async (icon: string): Promise<void> => {
		try {
			const current = (await $`tmux display-message -t ${paneId} -p '#{window_name}'`.text()).trim()
			const clean = current.replace(/^[⚡✓❓] /, "")
			await $`tmux rename-window -t ${paneId} ${icon} ${clean}`.quiet()
		} catch {}
	}

	const playSound = async (type: "done" | "ask"): Promise<void> => {
		try {
			let sound = (await $`tmux show-option -gqv @agent-sound`.text()).trim() || "Glass"
			if (type === "ask") {
				const askSound = (await $`tmux show-option -gqv @agent-ask-sound`.text()).trim()
				if (askSound) sound = askSound
			}
			if (sound !== "none") {
				await $`afplay /System/Library/Sounds/${sound}.aiff`.quiet()
			}
		} catch {}
	}

	let waitingForHuman = false

	return {
		event: async ({ event }) => {
			if (event.type === "session.idle") {
				if (!waitingForHuman) {
					await renameWindow("✓")
					await playSound("done")
				}
			}
			if (event.type === "session.error") {
				waitingForHuman = false
				await renameWindow("✓")
				await playSound("done")
			}
		},
		"tool.execute.before": async (input) => {
			if (input.tool === "question") {
				waitingForHuman = true
				await renameWindow("❓")
				await playSound("ask")
			} else {
				waitingForHuman = false
				await renameWindow("⚡")
			}
		},
		"permission.ask": async () => {
			waitingForHuman = true
			await renameWindow("❓")
			await playSound("ask")
		},
	}
}

export default TmuxAgentStatusPlugin
