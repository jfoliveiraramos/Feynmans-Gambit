# Branches' Gambit

**Branches' Gambit** is a work-in-progress chess platform. This didactic project is designed to experiment with and maximise exposure to multiple languages and technology stacks. It combines live gameplay, real-time analytics, and a modern web interface.

## License

This project is released under the **GNU Affero General Public License v3.0 (AGPL-3.0) or later**.

Please see the [LICENSE](LICENSE) file for the full text of the license.

## Objective

Create a scalable chess system with:

- **Zig**: Chess engine, move generation, board state  
- **Rust**: TUI, local match orchestration, engine interface  
- **Gleam**: Web-facing API, event broker for analytics and game state  
- **Svelte**: Frontend UI, player interactions  
- **Go**: Data analytics microservice, metrics and player statistics  

## Architecture Overview

### 1. **Frontend (Svelte)**
- Displays board, moves, and analytics.
- Sends player moves to Gleam via API or WebSocket.
- Subscribes to game state updates from Gleam.

### 2. **Chess Engine (Zig)**
- Handles move generation, validation, and optional AI.
- Maintains consistent board state for matches.

### 3. **Local Match Orchestrator (Rust)**
- Directly calls Zig for move validation and AI responses.
- Holds live in-memory game state.
- Publishes move events to a message queue (e.g., NATS) for Gleam.

### 4. **Web Backend & Event Broker (Gleam)**
- Receives moves from Svelte and forwards them to Rust via queue.
- Subscribes to Rust move events to provide real-time API responses.
- Offloads analytics tasks to Go asynchronously.
- Provides APIs for frontend consumption (game state, analytics).

### 5. **Analytics Microservice (Go)**
- Subscribes to Gleam or queue events.
- Computes real-time metrics, player statistics, and performance trends.
- Stores aggregated analytics for frontend dashboards.

## Communication Flow

1. **Svelte UI** → **Gleam API** → sends player moves  
2. **Gleam** → publishes moves to **Rust** via message queue  
3. **Rust** ↔ **Zig** → validates moves, updates game state  
4. **Rust** → publishes move events → **Gleam** → **Svelte** updates UI  
5. **Gleam** → forwards events to **Go analytics service** for metrics/trends  

This design avoids persistent databases for live games, using **in-memory state + event-driven messaging** to keep everything real-time and decoupled.
