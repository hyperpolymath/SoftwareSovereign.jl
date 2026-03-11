<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# SoftwareSovereign.jl — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │          SYSTEM PACKAGE MANAGERS        │
                        ├─────────────────────────────────────────┤
                        │  ┌────────────┐      ┌────────────┐     │
                        │  │ DNF / APT  │ ◀──▶ │  Flatpak   │     │
                        │  │ (Native)   │      │ (Sandboxed)│     │
                        │  └─────▲──────┘      └─────▲──────┘     │
                        │        │                   │            │
                        │  ┌─────┴──────┐      ┌─────┴──────┐     │
                        │  │    ASDF    │      │  Nix/Guix  │     │
                        │  │ (Versioned)│      │ (Declara.) │     │
                        │  └─────▲──────┘      └─────▲──────┘     │
                        │        │                   │            │
                        └────────┼───────────────────┼────────────┘
                                 │                   │
                                 ▼                   │
                        ┌────────────────────────────┼────────────┐
                        │           CONTROL LAYER                 │
                        ├─────────────────────────────────────────┤
                        │  ┌──────────────────┐      ┌──────────┐ │
                        │  │ Policy Engine    │      │ System   │ │
                        │  │ (SoftwarePolicy) │ ───▶ │  Audit   │ │
                        │  └────────┬─────────┘      └─────┬────┘ │
                        │           │                      │      │
                        │  ┌────────▼─────────┐      ┌─────▼────┐ │
                        │  │   Enforcement    │      │ License  │ │
                        │  │    Logic         │ ◀──▶ │ Database │ │
                        │  └────────┬─────────┘      └─────┬────┘ │
                        │           │                      │      │
                        │  ┌────────▼─────────┐      ┌─────▼────┐ │
                        │  │   GNOME / TUI    │      │ Sentinel │ │
                        │  │   Interfaces     │ ───▶ │ (Service)│ │
                        │  └──────────────────┘      └──────────┘ │
                        └──────────────────────┬──────────────────┘
                                               │
                        ┌──────────────────────▼──────────────────┐
                        │         REPO INFRASTRUCTURE             │
                        │  systemd/ (Sentinel Service)            │
                        │  gnome-extension/                       │
                        │  Project.toml                           │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE ENGINE
  Policy Engine                     ████████░░  80%    SoftwarePolicy struct defined
  System Audit                      ██████░░░░  60%    Basic scan logic
  Enforcement Logic                 ████░░░░░░  40%    Package manager bridges

INTERFACES
  TUI Interface                     ██████░░░░  60%    tui.jl basics
  GNOME Extension                   ██████░░░░  60%    JS bridge implemented
  Sentinel Service                  ██████████ 100%    systemd unit file complete

DATA & TOOLS
  License Database                  ██████░░░░  60%    OSI mapping in progress
  Cache System                      ██████████ 100%    Fast lookup implemented
  Redundancy Logic                  ██████░░░░  60%    Conflict resolution

REPO INFRASTRUCTURE
  Project.toml                      ██████████ 100%    Metadata complete
  ABI/FFI Standards                 ██░░░░░░░░  20%    Placeholder folders

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████░░░░░  ~50%   Functional Policy Framework
```

## Key Dependencies

```
License DB ──────────► Policy Engine ──────────► System Audit
                                                   │
Package Managers ────► Enforcement ──────────────┤
                                                   │
Sentinel Service ────► User Interfaces ────────► COMPLETE
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
