# Mock Portfolio API — Implementation Kickoff Guide

This guide initializes the repository and provides staged prompts for an AI coding agent. It assumes the accepted `openapi/`, `data/`, `docs/`, and `openspec/` artifacts have been copied into the repository root.

The implementation target is the current OpenSpec baseline. The active `require-complete-allocation-totals` change remains future work until the baseline has been implemented, verified, and checkpointed.

## 1. Recommended working sequence

Use this order:

1. Create the Git and Node.js project.
2. Commit the accepted design artifacts before generating code.
3. Add the permanent agent instructions below.
4. Ask the agent to inspect and plan without editing.
5. Implement one bounded slice at a time.
6. Review the diff and run verification after every slice.
7. Commit each accepted slice manually.
8. Tag the working baseline before implementing the aggregate-total change.

Do not give the agent one prompt asking it to implement the entire service. The project is small, but the unusual adverse-data requirements are easy to lose in a large undifferentiated change.

## 2. Prerequisites

Use Node.js 24 and npm. Confirm the tools in Git Bash, a Linux shell, or the equivalent terminal:

```bash
node --version
npm --version
git --version
npm config get registry
```

`node --version` must report `v24.x.x`. The registry check is important on the corporate machine: use the approved internal registry when required, but never put credentials or authentication tokens in this repository.

Useful official references:

- [Node.js release schedule](https://nodejs.org/en/about/previous-releases) — https://nodejs.org/en/about/previous-releases
- [Node.js `node:sqlite`](https://nodejs.org/api/sqlite.html) — https://nodejs.org/api/sqlite.html
- [Fastify getting started](https://fastify.dev/docs/latest/Guides/Getting-Started/) — https://fastify.dev/docs/latest/Guides/Getting-Started/
- [TypeScript configuration reference](https://www.typescriptlang.org/tsconfig/) — https://www.typescriptlang.org/tsconfig/
- [Vitest guide](https://vitest.dev/guide/) — https://vitest.dev/guide/

## 3. Initialize the repository

Create an empty directory and initialize `main` explicitly:

```bash
mkdir ppm-portfolio-mock-api
cd ppm-portfolio-mock-api
git init -b main
git config core.autocrlf false
```

Copy the accepted artifacts into the repository so the root initially contains:

```text
data/
docs/
openapi/
openspec/
```

Do not copy the original architecture-thread handoff prompt or temporary upload directories into the repository.

Create the npm package:

```bash
npm init -y
npm pkg set name="ppm-portfolio-mock-api"
npm pkg set version="0.1.0"
npm pkg set private=true --json
npm pkg set type="module"
npm pkg set "engines.node=>=24 <25"
```

Install only the initial runtime and development foundations:

```bash
npm install fastify
npm install --save-dev typescript tsx vitest @types/node
```

This produces the first `package-lock.json`. Commit it. Additional packages for YAML/OpenAPI processing and independent contract validation should be selected by the agent in the scaffolding slice, with a reason for each dependency.

Do not install:

- `better-sqlite3` or another native SQLite add-on;
- a second HTTP framework;
- an ORM;
- a decimal arithmetic library merely to total two-decimal percentages; or
- Swagger UI/CDN packages during initial implementation.

## 4. Repository hygiene files

Create `.nvmrc`:

```text
24
```

Create `.node-version` with the same content for tools that do not read `.nvmrc`:

```text
24
```

Create `.gitignore`:

```gitignore
node_modules/
dist/
coverage/
.vitest/
*.log

.env
.env.*
!.env.example

*.db
*.db-journal
*.db-shm
*.db-wal
*.sqlite
*.sqlite3

tmp/
temp/
```

The SQL schema, JSON fixture files, profile manifests, and mutation scripts are source artifacts and must remain tracked.

Create `.gitattributes`:

```gitattributes
* text=auto eol=lf
*.cmd text eol=crlf
*.bat text eol=crlf
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.zip binary
*.db binary
*.sqlite binary
*.sqlite3 binary
```

Create `.editorconfig`:

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
```

## 5. Permanent agent guardrails

Create `AGENTS.md` in the repository root with the following content. Cursor can also be pointed to this file from its project rules; OpenCode and Codex can read it directly as repository guidance.

```markdown
# Mock Portfolio API implementation rules

## Mission

Implement the deterministic fictional Portfolio Mock API as a reusable system
under test for the PPM API Test Development Kit.

## Source precedence

When artifacts differ, use this order and report the conflict before guessing:

1. `openspec/specs/` for current behavioral requirements.
2. `openapi/*.yaml` for the public HTTP interface.
3. `data/schema/` and `data/fixtures/` for persistence and deterministic data.
4. `docs/system-architecture-and-implementation-design.md` for implementation design.
5. Other supporting documents.

`openspec/changes/require-complete-allocation-totals/` is an active future
change. Do not apply it to the baseline implementation, current specs, OpenAPI,
fixture validator, or tests unless the user explicitly starts that change.

## Non-negotiable constraints

- Use Node.js 24, TypeScript, npm, Fastify, and built-in `node:sqlite`.
- Do not add `better-sqlite3`, an ORM, authentication, pagination, or network services.
- Keep the runtime fully offline.
- Use composition and injected dependencies for the database, clock, and services.
- Validate incoming writes in the application; do not add business constraints to SQLite.
- Do not attach Fastify response schemas or schema-driven serializers to business routes.
- Preserve declared adverse stored values in serialized HTTP responses.
- Use prepared SQL statements and explicit documented ordering.
- Never choose an arbitrary row when a public identifier is duplicated.
- Keep route handlers thin and business behavior in application services.
- Do not use binary floating point for domain decimal validation.

## Baseline allocation rule

Validate every allocation percentage independently between `0.00` and `100.00`.
The baseline must still accept an otherwise valid order containing `60.00` and
`30.00`. Do not implement an aggregate-total check yet.

## Working method

- Inspect relevant artifacts before editing.
- Keep each change within the requested slice.
- Preserve unrelated user changes.
- Add or update tests with behavior changes.
- Run the relevant tests, type checking, and build before reporting completion.
- Report files changed, commands run, results, assumptions, and remaining risks.
- Do not commit, tag, push, or rewrite Git history unless explicitly requested.
```

## 6. Initial commits and branch

The cleanest history has the accepted contracts and design before generated implementation files:

```bash
git add openapi data docs openspec
git commit -m "docs: add mock API contracts and implementation design"

git add package.json package-lock.json .nvmrc .node-version .gitignore .gitattributes .editorconfig AGENTS.md
git commit -m "chore: initialize Node 24 TypeScript project"

git switch -c feat/implement-baseline-mock-api
```

Run these checks before invoking the coding agent:

```bash
git status --short
node --version
npm --version
npm ls --depth=0
```

The status should be clean. Do not create the baseline tag yet; tag only after the complete baseline API and tests pass.

## 7. How to use the prompts

Start with Prompt 0. It authorizes inspection but no modification. Review the agent's plan before giving Prompt 1.

After that, use one implementation prompt at a time. Continue in the same agent session when practical so it retains findings, but every prompt repeats the critical baseline constraint. Review and commit accepted work between slices.

If the agent finds a conflict among OpenSpec, OpenAPI, schema, fixtures, or architecture, it must stop and show the exact conflict. Do not allow it to silently “improve” one artifact.

## 8. Prompt 0 — Repository audit and implementation plan

```text
You are preparing to implement a deterministic fictional Portfolio Mock API.
For this task, inspect and plan only. Do not modify files, install packages,
generate code, or commit anything.

Read in this order:
1. AGENTS.md
2. openspec/README.md
3. openspec/specs/**/*.md
4. openapi/portfolio-api.yaml and openapi/operational-api.yaml
5. docs/sqlite-schema.md
6. docs/fixture-and-seeding.md
7. docs/system-architecture-and-implementation-design.md
8. data/schema/001-initial-schema.sql
9. data/fixtures/**

Treat openspec/changes/require-complete-allocation-totals as future work. The
baseline must accept an otherwise valid 60.00 + 30.00 allocation order. Do not
propose applying the active change now.

Produce:
- a concise understanding of the system and its unusual testing purpose;
- a source-of-truth and dependency map;
- proposed runtime and development dependencies, with a reason for each;
- the intended module/file structure;
- an implementation sequence split into reviewable vertical slices;
- verification commands for each slice;
- any concrete contradictions, underspecified behavior, or blockers, citing files;
- confirmation that no business route will use Fastify response serialization.

Do not invent TDK integration details. Do not start coding until I approve the plan.
```

## 9. Prompt 1 — Project scaffolding

```text
Implement only the Node.js 24/TypeScript project scaffolding described by the
accepted architecture and your approved plan.

Before editing, read AGENTS.md and recheck the relevant architecture sections.
The active complete-allocation-total change is future work and must not be
implemented or applied.

Scope:
- finalize package.json scripts and dependency choices;
- add strict TypeScript configuration for ESM/Node.js 24;
- add Vitest configuration and one non-business smoke test;
- create the agreed empty source/test directory structure;
- add configuration parsing types and placeholders only where necessary;
- add deterministic OpenAPI schema/type generation commands or scripts if the
  approved plan included them;
- add a CI-friendly verify script that runs formatting/linting only if those
  tools were explicitly selected, then type checking, tests, and build.

Constraints:
- do not implement business routes, repositories, seeding, or allocation rules;
- do not add unused speculative dependencies;
- keep generated artifacts clearly marked and reproducible;
- production execution must use compiled JavaScript, not tsx;
- do not commit.

Run and report npm install/ci as applicable, type checking, the smoke test, and
the build. Summarize changed files, dependency reasons, results, and remaining
work. Stop if an accepted artifact conflicts with the scaffolding plan.
```

Suggested commit after review:

```bash
git add .
git commit -m "chore: scaffold TypeScript mock API"
```

## 10. Prompt 2 — Database creation, seeding, and fixture validation

```text
Implement only the SQLite database tooling and fixture pipeline.

Read AGENTS.md, data/schema/001-initial-schema.sql,
docs/sqlite-schema.md, docs/fixture-and-seeding.md, the fixture profile schema,
and every baseline/adverse fixture file before editing.

The active complete-allocation-total change is future work. The fixture
validator must not check whether allocation percentages total 100.00.

Implement:
- database creation from ordered SQL migrations using built-in node:sqlite;
- both schema-version markers and strict compatibility checks;
- baseline fixture loading in the documented fixed order;
- profile inheritance and controlled adverse SQL mutations;
- explicit camelCase-to-column mapping;
- dataset metadata and deterministic seeded_at behavior;
- the complete documented fixture validator;
- exact expectedDataIssues comparison;
- safe refusal to overwrite an output database without an explicit flag;
- reusable temporary-database helpers for Vitest;
- unit and real-SQLite integration tests.

Do not implement the HTTP server or business repositories in this slice. Do not
add foreign keys, business CHECK constraints, public-ID uniqueness constraints,
or aggregate allocation validation.

Verify at minimum:
- clean baseline seed succeeds with zero undeclared issues;
- each adverse profile produces exactly its declared issues;
- a mismatched issue manifest rolls back and publishes no partial database;
- first allocation-order sequence value remains 5004;
- Node.js 24 can open the result with node:sqlite.

Run all relevant tests, type checking, and build. Report files changed,
commands/results, and any deviations. Do not commit.
```

Suggested commit after review:

```bash
git add .
git commit -m "feat: add deterministic SQLite fixture pipeline"
```

## 11. Prompt 3 — Runtime foundation and first vertical slice

```text
Implement the runtime foundation plus only these operations:
- GET /health
- GET /ready
- GET /api/v1/portfolios/{portfolioId}

Read AGENTS.md, both OpenAPI files, the portfolio-retrieval and
service-operation OpenSpec capabilities, and the architecture document.

Implement app.ts as an injectable Fastify factory and server.ts as the process
entry point. Add validated runtime configuration, existing-database checks,
schema compatibility, graceful shutdown, Problem Details mapping, a portfolio
repository/service/mapper, and tests using Fastify injection and real temporary
SQLite databases.

Critical constraints:
- no business route response schema or schema-driven serializer;
- /health must not access SQLite;
- /ready must check SQLite and both version markers;
- duplicate portfolio IDs produce generic 500, not an arbitrary result;
- missing portfolio produces 404 PORTFOLIO_NOT_FOUND;
- malformed path identifier produces 400 INVALID_IDENTIFIER_FORMAT;
- adverse stored scalar types/nulls must not be repaired;
- do not implement query or allocation-order routes yet;
- do not implement the active aggregate-total change;
- do not commit.

Run focused tests, the complete existing test suite, type checking, and build.
Report serialized HTTP evidence for the success, 400, 404, duplicate-ID 500,
health, and readiness cases.
```

Suggested commit after review:

```bash
git add .
git commit -m "feat: add runtime health readiness and portfolio retrieval"
```

## 12. Prompt 4 — POST query operations

```text
Implement the four POST query operations for positions, transactions,
strategies, and performance.

Read AGENTS.md, openspec/specs/portfolio-queries/spec.md, the corresponding
OpenAPI operations/schemas, SQLite ordering documentation, fixtures, and the
response-preservation architecture sections.

Implement request validation, filter semantics, fixed ordering, repositories,
batch master-data enrichment, services, response mappers, routes, Problem
Details mapping, and focused tests for all four operations.

Critical constraints:
- filters are combined exactly as specified;
- there is no pagination or client sorting input;
- empty valid results return 200 with items [] and totalCount 0;
- a missing related master retains the reference ID and omits its nested summary;
- duplicate related master IDs produce generic 500;
- wrong stored types and required nulls remain observable after HTTP serialization;
- do not attach Fastify response schemas to business routes;
- do not implement allocation-order writes or the active aggregate-total change;
- do not commit.

Run unit, repository, HTTP, baseline contract, and adverse-profile tests. Report
changed files, commands/results, fixed-order evidence, and unresolved issues.
```

Suggested commit after review:

```bash
git add .
git commit -m "feat: add deterministic portfolio data queries"
```

## 13. Prompt 5 — Baseline allocation-order lifecycle

```text
Implement the complete current-baseline allocation-order capability: create,
get, full draft replacement, submit, and cancel.

Read AGENTS.md, openspec/specs/allocation-orders/spec.md, the allocation-order
OpenAPI paths and schemas, schema/fixture documents, and the transaction and
validation sections of the architecture.

This is the controlled baseline. It MUST accept an otherwise valid order with
allocations 60.00 and 30.00. Do not read the active change as current behavior,
do not add INVALID_ALLOCATION_TOTAL, and do not total allocation percentages.

Implement:
- injected Clock with SystemClock and strict FixedClock;
- transactional AORD sequence allocation;
- create in DRAFT state with Location header;
- retrieval without revalidation or repair;
- complete atomic replacement of DRAFT orders;
- submission from DRAFT with current baseline revalidation;
- cancellation from DRAFT or SUBMITTED without content revalidation;
- all accepted reference, active-state, availability, duplicate-strategy,
  quantity, individual-percentage, and client-reference rules;
- exact status/error mappings, including accepted 409 responses;
- decimal canonicalization without binary floating-point domain logic;
- rollback, lifecycle, cardinality, and HTTP contract tests.

Prove with a named regression test that 60.00 + 30.00 is accepted in the
baseline. This test documents current behavior; it must not be presented as the
desired future business outcome.

Run focused and full verification. Report files changed, commands/results,
transaction rollback evidence, first ID AORD-5004, fixed-time evidence, and the
90.00-total baseline response. Do not commit.
```

Suggested commit after review:

```bash
git add .
git commit -m "feat: implement baseline allocation order lifecycle"
```

## 14. Prompt 6 — Complete baseline verification

```text
Complete the verification layer for the current baseline without adding new
business behavior.

Read AGENTS.md, all current OpenSpec capabilities, both OpenAPI files, fixture
manifests, and the architecture acceptance checklist.

Add or finish:
- independent serialized-HTTP OpenAPI contract validation;
- tests for every documented success and stable error response;
- adverse-profile tests proving declared violations survive HTTP serialization;
- duplicate public-ID ambiguity tests;
- transaction rollback and test-isolation checks;
- deterministic time, ID, sorting, and fixture checks;
- coverage/reporting configuration appropriate for this small project;
- one top-level npm verify command.

Create a machine-readable or Markdown verification matrix mapping operations,
requirements, acceptance criteria, fixtures, and test IDs. Do not fabricate TDK
configuration and do not implement the active complete-total change.

Run the full verification command from a clean install state where practical.
Report any requirement or operation without evidence. Do not weaken a test to
make it pass, and do not commit.
```

Suggested commit after review:

```bash
git add .
git commit -m "test: complete baseline contract and adverse verification"
```

## 15. Prompt 7 — Container and operating guide

```text
Package and document the verified baseline for offline Windows and Linux use.

Read AGENTS.md and the container, configuration, startup, shutdown, and offline
sections of the architecture. Preserve all current behavior.

Implement:
- a multi-stage Node.js 24 container build;
- compiled-JavaScript production execution;
- non-root runtime user and writable mounted /data location;
- local-only assets and no runtime downloads;
- readiness-based container health check;
- graceful SIGTERM/SIGINT handling;
- .dockerignore;
- README commands for install, build, seed, select fixture profile, start,
  health/readiness checks, reset, test, and container execution;
- an .env.example containing no secrets;
- an offline smoke-test procedure.

Do not add authentication, Swagger CDN assets, pagination, production
connectivity, or the active aggregate-total behavior. Do not silently seed or
migrate a database during API startup.

Build and run the container where the environment permits. Verify it as a
non-root user with outbound networking disabled and a mounted database. Report
commands/results and any check that could not be executed. Do not commit.
```

Suggested commit after review:

```bash
git add .
git commit -m "build: package baseline mock API for offline execution"
```

## 16. Baseline checkpoint

After all baseline prompts are accepted:

```bash
npm ci
npm run verify
git status --short
git log --oneline --decorate -8
git tag -a demo-baseline-v1 -m "Verified mock API baseline before complete-allocation-total rule"
```

Only create the tag if the verification command passes and the working tree is clean. If the repository is remote, pushing the branch or tag is a separate deliberate action.

At this checkpoint the baseline must visibly accept the `90.00` allocation total. The active OpenSpec change remains proposed and unapplied.

## 17. Future prompt — Apply the aggregate-total change

Do not use this prompt until the baseline checkpoint exists.

```text
Begin implementation of the active OpenSpec change
openspec/changes/require-complete-allocation-totals.

First read its proposal.md, specs/allocation-orders/spec.md, design.md, and
tasks.md, then compare them with the current baseline implementation and tests.
Do not edit files yet.

Report:
- the exact code, OpenAPI, fixture-validator, and test impact;
- the implementation order for TASK-ALLOC-TOTAL-001 through 017;
- how TC-ALLOC-TOTAL-002 changes from orphaned expectation to linked acceptance
  evidence without erasing its provenance;
- how basis-point arithmetic and validation short-circuiting will be tested;
- how GET and cancel continue to handle a stored incomplete order;
- which task and verification results are required before applying the delta to
  openspec/specs and archiving the change.

Wait for approval before implementing the active change.
```

## 18. Common review questions after every agent slice

Ask these before accepting the diff:

- Did the agent stay within the requested slice?
- Did it alter an accepted contract or requirement without stopping first?
- Did it accidentally implement the future aggregate-total rule?
- Did it add a business response schema to Fastify?
- Did it move validation into SQLite constraints?
- Does it preserve adverse data rather than normalize it?
- Are all SQL values parameterized and all collection orders explicit?
- Are new dependencies necessary, locked, and usable offline after installation?
- Did it run the tests it claims to have run?
- Is the next commit small enough to revert independently?

If any answer is uncertain, ask the agent for evidence or a correction before committing.
