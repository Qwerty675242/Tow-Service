# Tow Service v0.11 (Experemental Release) — Native Script & UI App

This is the initial stable release of the **Tow Service** gameplay script, developed natively for **BeamNG.drive v0.39**. The project is designed as an ultra-lightweight, high-performance UI Application and Lua extension that injects a parking enforcement game loop without altering core game files or requiring heavy map modifications.

---

## 🛠 Detailed Feature Breakdown

### 1. Procedural Spawning Architecture
* **Coordinate Matrix:** Implements a database of 30 distinct vector positions across the **West Coast USA** map, specifically curated to present varying levels of physics-based towing difficulty (narrow alleys, tight parallel parking, and obstacle-blocked spaces).
* **Dynamic Entity Management:** Cars are spawned dynamically via the GE Lua layer on runtime. The script listens for the initialization trigger, selects a random coordinate, and spawns the target vehicle instantly without stutter or frame drops.
* **Garbage Collection & Cleanup:** Built-in memory protection routines ensure that when a mission is canceled or completed, the spawned vehicle and its associated memory pointers are completely wiped from the scene, preventing RAM leaks and physics engine bloat.

### 2. UI App & State Machine Integration
* **Custom User Interface:** Includes a fully integrated UI app with an intuitive layout featuring two core interactive controls:
  * `START ORDER` — Compiles the script state, fetches coordinates, spawns the violator vehicle, and initializes the tracking nodes.
  * `CANCEL ORDER` — Terminates the active script cycle, removes all spawned elements, clears markers, and safely resets the UI state back to idle.
* **Session Lifecycle Control:** The script uses a strict state machine logic to prevent accidental double-spawning or overlapping missions. Once an order is active, the initialization hooks are locked until the vehicle is delivered or the session is aborted.

### 3. Primitive Engine Rendering & Navigation Markers
* **Visual Telemetry:** Uses native engine primitives to render 3D space indicators directly into the game world, ensuring high visibility without performance overhead:
  * `White Cylinder Node` — Projects a constant vertical ray directly over the target vehicle violating parking regulations.
  * `Green Cylinder Node` — Marks the boundaries of the designated secure impound lot area.
* **Dynamic Visibility:** Markers are tied directly to the state machine. They activate instantly upon order acceptance and vanish completely the exact millisecond the mission criteria are met.

### 4. Physics Engine Triggers & Validation
* **Proximity Tracking:** Implements real-time spatial checks to monitor the exact distance between the towed vehicle and the target impound zone.
* **Delivery Validation:** The script uses a rigid trigger zone check. The mission is marked as successful only when the tracked vehicle's bounding box intersects with the designated green radius at the impound lot while separated from the player's towing apparatus (if unhooked) or stopped inside the zone.
* **Lua Extension Isolation:** The code runs in its own isolated GE extension sandbox. This guarantees 100% compatibility with vanilla traffic AI, custom vehicle configurations, and default game scenarios.

---

## 📦 Technical Specification

* **Asset Footprint:** ~15 KB pure source text (expands to ~2.1 MB inside the distribution package due to high-resolution metadata and interface iconography).
* **Performance Impact:** 0% CPU/GPU overhead. Uses native Lua-to-C++ engine hooks.
* **Dependencies:** None. Completely standalone.
* **Map Support:** West Coast USA (Exclusive for v0.11 alpha).

---

## 📝 Installation Instructions

1. Download the production archive `TowService.zip` from this release or the official BeamNG Repository.
2. Transfer the archive directly into your game's local mod directory:
   `AppData/Local/BeamNG.drive/0.39/mods/`
3. Launch the game, open the UI Apps menu, search for **Tow Service**, and add the widget to your screen overlay.

---

## 🔐 Licensing, Copyright & Terms of Use

**Copyright (c) 2026 C1rcle.**

* **Distribution Control:** Mirroring or re-uploading this asset to third-party file-sharing sites, scraping platforms, or pirate repositories (e.g., ModLand, WorldOfMods, TopMods) is explicitly forbidden. Authorized distribution is restricted to the official BeamNG Repository and this GitHub page.

---
