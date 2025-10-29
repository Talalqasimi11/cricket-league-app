# 🚀 GITHUB COPILOT — ITERATIVE PROJECT REVIEW & IMPROVEMENT TASK

## ROLE
Act as a **senior software engineer and QA lead** doing a structured, multi-phase review of my project.  
You will fix issues **iteratively** — phase by phase — improving reliability, performance, and design consistency.

---

## 🎯 GOAL
Systematically review and improve the project in *multiple focused passes*, not all at once.

---

## 🔄 PHASES

### 🧩 Phase 1: Core Stability & Errors
- Scan all files for **syntax, logic, and build errors**.
- Fix missing imports, undefined variables, widget mismatches.
- Remove dead code, unused variables, or duplicated logic.

### 🌐 Phase 2: Connectivity & Data Handling
- Review all **API/network calls** (e.g., PlanetScale, Render, REST endpoints).
- Add **error handling**, **timeouts**, and **loading states**.
- Ensure async safety (e.g., await usage, setState after unmount, null checks).

### 🎨 Phase 3: UI & UX Consistency
- Enforce consistent fonts, paddings, button styles, and colors.
- Identify **inconsistent widgets/layouts** and propose reusable components.
- Fix navigation issues, missing routes, or misplaced screens.

### ⚡ Phase 4: Performance & Architecture
- Optimize rebuilds (for Flutter) or re-renders (for React).
- Simplify heavy widgets/components.
- Ensure clean architecture (separation of concerns, DRY principle).

### 🧠 Phase 5: Review & Refactor
- Summarize all applied changes and remaining issues.
- Suggest **refactor plans** for scalability.
- Identify opportunities for **unit tests**, **state management cleanup**, or **theme unification**.

---

## 🛠 RULES
- Proceed **one phase at a time**.
- At the end of each phase, show:
  - ✅ What was fixed
  - ⚠️ What still needs manual review
  - 💡 Suggested next steps
- Always explain *why* each change improves the system.

---

## 💬 CONTEXT
Framework: **Flutter**
Backend: **Render + PlanetScale**
Goal: **Cricket League Management App with Live Scoring**
Focus: **UI consistency, network stability, maintainable code structure**

---

## 🚦 INSTRUCTION
Start with:  
> “Phase 1: Core Stability & Errors — analyze and fix everything you find in this phase.”

After each phase, I’ll respond with:
> “next"

Continue this loop until Phase 5 is complete.
