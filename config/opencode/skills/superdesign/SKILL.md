---
name: superdesign
description: Use when designing or implementing frontend interfaces that need a stronger visual direction, better typography, color systems, spacing, and motion.
---

# Superdesign

Structured guidance for high-quality frontend UI design.

## When To Use

- You are building a landing page, dashboard, or UI-heavy feature.
- The current interface feels generic or visually inconsistent.

## Workflow

1. Define layout and information hierarchy.
2. Define visual system (color, type, spacing, depth).
3. Define motion patterns for entry, hover, and feedback.
4. Implement and refine for responsiveness and accessibility.

## Design Guidelines

### Typography

- Choose intentional font pairings (display + body).
- Maintain clear type hierarchy and readable body text.

### Color

- Use semantic CSS variables for palette tokens.
- Avoid default bootstrap-style color choices.
- Keep contrast accessible and accent usage purposeful.

### Spacing And Depth

- Use consistent spacing scale.
- Keep shadows subtle and purposeful.

### Motion

- Entry transitions: roughly 300-500ms.
- Hover transitions: roughly 150-200ms.
- Favor meaningful choreography over noisy micro-effects.

### Responsive And Accessibility

- Build mobile-first and adapt at tablet/desktop breakpoints.
- Use semantic HTML, strong heading hierarchy, and keyboard-accessible interactions.
