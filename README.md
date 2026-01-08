# LuaU Utilities Module

A shared **LuaU utilities module** containing a wide range of general-purpose helpers for **both client and server** use.

This module acts as a **foundation layer** for common patterns that appear across almost every Roblox project — from formatting and math helpers to instance handling, execution flow, and environment checks.

---

## 🧰 Purpose

- Reduce boilerplate across systems
- Centralise commonly re-written logic
- Provide predictable, reusable helpers
- Safe for **Client**, **Server**, and **Shared** contexts

This is a **generalist module** by design — it solves the “small problems” cleanly so your systems stay focused.

---

## ✨ Example Utilities

> This list is representative, not exhaustive. The module is expected to grow organically over time.

---

## 🔄 Execution & Module Helpers

### `RunModules(container)`
Automatically requires and executes all ModuleScripts within a container.

**Use cases**
- Bootstrapping systems
- Initialising folders of logic
- Clean startup pipelines

---

## ⏱️ Performance & Timing

### `GetFPS()`
Returns the current client FPS.

### `BindUpdateToFPS(callback)`
Binds an update callback to render/heartbeat timing at FPS scale.

**Use cases**
- Frame-consistent animations
- Client-side simulation
- Interpolation and smoothing

---

## 🌍 Environment & Server Context

### `GetServerRegion()`
Returns the server’s geographic region (when available).

### `IsPrivateServer()`
Determines whether the current server is private or reserved.

### `GetUTCTime()`
Returns the current UTC timestamp.

---

## 🧱 Instance & World Utilities

### `GetChild(parent, name, timeout?)`
Safely retrieves a child instance with optional timeout support.

### `GetCFrame(instance)`
Extracts a reliable `CFrame` from a `BasePart` or `Model`.

### `WeldParts(partA, partB)`
Creates and manages welds between parts.

**Use cases**
- Tool construction
- Attachments
- Temporary assemblies

---

## 🎲 Math & Randomisation

### `WeightedRandom(table)`
Returns a value based on weighted probability.

**Use cases**
- Loot tables
- AI decisions
- Randomised events

### `Lerp(a, b, alpha)`
Custom interpolation helper for numbers  
(extensible for other types if required).

---

## 🧮 Formatting Helpers

### `FormatTime(seconds)`
Formats seconds into a human-readable time string.

### `FormatNumber(number)`
Formats numbers with separators or shorthand (e.g. `1.2K`, `3.4M`).

**Use cases**
- UI displays
- Leaderboards
- Timers

---

## 🖥️ UI & Client Feedback

### `SendStarterGuiNotification(data)`
Displays a notification via `StarterGui`.

**Use cases**
- Player feedback
- System alerts
- Onboarding messages

---

## 📦 Installation

Place the module somewhere shared, such as:

```text
ReplicatedStorage/
└─ Utilities.lua
