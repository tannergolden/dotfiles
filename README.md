<!--
title: '🛤️ GOLDEN PATH (PRIVATE)'
description: 'A private scaffold with no imposed structure, inheriting its community health files from the account .github repository.'
tags: [template, scaffold, private, engineering-standards]
category: docs
-->


<div align="center">

# 🛤️ GOLDEN PATH (PRIVATE)

<a name="top"></a>

**The paved road, with the paving stones left for you to place.**

_Standards wired. Structure yours to invent._

</div>

---

## 💡 What This Is

**A standards-wired empty room.** Every guardrail is already connected -
continuous integration, secret scanning, static analysis, workflow linting,
governance, pull request validation - and the structure those guardrails will
eventually protect does not exist yet, because you are going to invent it.

That is the whole difference between this and its public counterpart:

|                    | [`tannergolden/path`](https://github.com/tannergolden/path) (public) | This one (private)                               |
| :----------------- | :------------------------------------------------------------------- | :----------------------------------------------- |
| **Purpose**        | A boilerplate. A working shape, already decided                      | A foundation. Build the shape from scratch       |
| **Standards**      | By link, from the standards repository                               | Identical - by link, same pins                   |
| **Structure**      | Ships `src/`, `tests/`, `packages/`, `benchmarks/`, `assets/`        | Ships none of it                                 |
| **Seed documents** | `docs/`, in plain sight                                              | `.github/docs/`, in with the other scaffolding   |
| **Health files**   | Copied in, so any owner gets a complete repository                   | Inherited from the account's `.github`           |
| **Licence**        | MIT                                                                  | Proprietary and confidential                     |
| **Ownership**      | CODEOWNERS rules all commented, owner unknown                        | One live rule: `@tannergolden`                   |
| **For**            | Anyone, including you, starting a conventional project               | You, starting something whose shape is the point |

Reach for the public one when the project fits a normal shape and you would
rather not think about it. Reach for this one when the structure **is** the
design work - a monorepo that is not laid out like anyone else's, a research
tree, a service with an unusual topology - and an imposed `src/` would be the
first thing you delete.

---

## 🔀 Fork, Or "Use This Template"

Both buttons hand you every file in this repository. They differ in exactly one
thing: whether your copy keeps a **link back to this one**.

**Fork it** when you want to pull later changes to the scaffold back down. A
fork remembers where it came from, so `Sync fork` and `git pull upstream` both
work.

**Click "Use this template"** when you want the current version as a starting
point and nothing more. You get a clean repository with a single
`Initial commit`, no parent, and no sync button. It is the route this template
is built for, and the one **🚀 The First Five Minutes** assumes further down.

|                              | Fork                                               | "Use this template"  |
| :--------------------------- | :------------------------------------------------- | :------------------- |
| **Link back to here**        | Kept - `Sync fork` works                           | None                 |
| **History**                  | Every commit this repository has                   | One `Initial commit` |
| **Actions**                  | **Disabled until you enable them**, per GitHub     | On from the start    |
| **Issues**                   | Off by default                                     | On                   |
| **A new pull request**       | Defaults to targeting **this** repository          | Targets yours        |
| **Visibility**               | Private, and a fork's visibility cannot be changed | Yours to choose      |
| **Your contributions graph** | Commits to a fork do not count                     | They count           |

### What a fork actually buys you

Less than it looks, and it is worth knowing why before choosing it. **The
standards reach both routes identically** - by link, same pins, as the table
above says. Every `uses:` here points at `tannergolden/standards@v1`, a moving
major tag, so every fix in the v1 line arrives the moment it is published
whether you forked or generated. Forking does not make you more current; that
part is already free.

What a fork does sync is the **scaffold**: the twelve stub workflows and the
seeded documents in `.github/docs/`. Real, but thin, and changed rarely - and
this template ships no structure to sync in the first place, which is the whole
of difference one.

> [!IMPORTANT]
> **Initialisation and `Sync fork` want opposite things.** Once Actions are
> running, the `init` job claims the repository and **force-pushes the default
> branch** - here it is mostly rewriting the bare "Initial commit" into a
> Conventional Commit, but the force-push is the same. That is the moment your
> history stops being a fast-forward of this one's, so `Sync fork` begins
> offering to discard your commits rather than catch you up.
>
> Neither is misbehaving: a fork wants a shared history, and initialisation
> deliberately rewrites one. If you want the fork **and** the shared history,
> delete `.github/TEMPLATE_INIT` before enabling Actions. That skips
> initialisation entirely.

> [!WARNING]
> **What follows your copy down both routes - and what does not.**
>
> The **licence propagates** either way - difference four, covered in full under
> 🔒 Licence below. Anything you fork or generate from here starts proprietary.
>
> The **parity check stays behind, and is yours to delete.** 📐 Template Parity
> carries the inverted guard (`if: is_template`, as **Exactly Five Differences**
> explains), so it runs here and nowhere else: neither route inherits that flag,
> so it will never fire in your copy or measure your tree against
> `tannergolden/path`. Inert rather than dangerous - but still four files
> enforcing a contract that is not yours, so delete
> `.github/template-parity.yml`, its two scripts, and its workflow.
>
> The **community health files do not follow at all.** Difference three inherits
> them from [`tannergolden/.github`](https://github.com/tannergolden/.github),
> and that inheritance is per account. A copy landing outside `tannergolden` has
> no code of conduct, contributing guide, security policy, issue forms or pull
> request template until you provide them - see **⚠️ Three Things About
> Inheritance** below.

> [!TIP]
> **There is a third route, and it is usually the better one.** Generate with
> "Use this template", then add this repository as a second remote:
>
> ```bash
> git remote add template https://github.com/tannergolden/repo
> git fetch template
> ```
>
> Cherry-pick whatever you want from it, whenever you want it, with none of the
> fork's costs - no disabled Actions, no force-push collision, and no pull
> request that opens against the template by mistake.

> [!NOTE]
> **Neither route carries the template flag over.** All twelve stubs are guarded
> by `!github.event.repository.is_template`, and the parity check by its
> inverse - which is what keeps the twelve silent here and the parity check
> silent everywhere else. A fork inherits that flag no more than a generated
> repository does, so your copy lands on the right side of both guards.

---

## 📐 Exactly Five Differences

This is a **contract, not a description**. These five are the only ways this
repository is permitted to differ from
[`tannergolden/path`](https://github.com/tannergolden/path). Everything else -
all twelve trigger workflows (the stub ceiling check among them), `.editorconfig`,
`.gitignore`, `.markdownlint.json`, `.env.example`, `.devcontainer`, and `.vscode` -
is byte-identical,
and every seeded document is identical but for the licence footer that
difference four requires.

**Any difference outside these five is drift, and drift is a defect.** Fix it,
do not document it.

> [!IMPORTANT]
> **The contract is enforced, not just asserted.** It lives as data in
> [`.github/template-parity.yml`](.github/template-parity.yml), and
> [`📐 Template Parity`](.github/workflows/template-parity.yml) compares the two
> trees against it on every push and once a day. That file is the contract; this
> section describes it.
>
> It was prose alone for a long time, and prose does not fail a check. Eight
> seeded documents had quietly diverged by the time anybody diffed the trees -
> each one carrying an absolute cross-link that encoded its own depth. The
> standards are explicit that [a rule and its gate change
> together](https://github.com/tannergolden/standards/blob/Development/README.md);
> this was the rule that had no gate.

### 1. No imposed structure

No `src/`, `tests/`, `packages/`, `benchmarks/`, or `assets/`. The public
template ships those as empty homes so somebody arriving cold has an obvious
place for a first file. You do not need telling; you need the tree left alone so
the shape can follow the project.

### 2. Seed documents live in `.github/docs/`

Not `docs/` at the root, and not a dot-directory of its own. `.github` is
already where repository scaffolding lives, so putting the seeds inside it keeps
them clear of your structure **and** lets them keep a plain name. One hidden
directory instead of two.

Everything the template seeds therefore sits outside the tree you are building,
and the first visible directory in this repository will be one you created. Copy
what you want out into whatever shape you decide on.

> [!NOTE]
> `.github/docs/` is not a path GitHub treats specially. Only particular
> **filenames** under `.github` carry meaning - the workflows directory,
> CODEOWNERS, the health files - and an arbitrary subdirectory beside them is
> just files. Nothing collides.

### 3. No community health files

Inherited from [`tannergolden/.github`](https://github.com/tannergolden/.github)
instead: code of conduct, contributing guide, governance charter, security
policy, support guide, funding target, issue forms, discussion forms, and pull
request template. One copy, edited in one place, reaching every repository on
the account at once. The conditions this depends on are below.

### 4. A proprietary licence

Not MIT. Details in the licence section further down, including the part that
matters most - it propagates to everything generated from here.

### 5. A named owner in CODEOWNERS

The public template ships every ownership rule commented out, because it cannot
know who will generate from it and a rule naming an owner without write access
is a GitHub error rather than a warning. This one knows: it is private and
single-maintainer, so it names `@tannergolden` in a single live rule and drops
the placeholders entirely.

That does not block your own pull requests. The shipped rulesets require zero
approvals and do not require code-owner review, so a solo maintainer cannot
deadlock on being unable to approve their own work. What it buys is an
automatic review request on anything opened by somebody else - Dependabot, or an
agent acting on your behalf.

### What follows from these, and is not a sixth difference

`.gitattributes` differs only because difference two moved the seeds:
it classifies `.github/docs/**` as well as `docs/**`, which stays for the tree
you instantiate the seeds into. Every seeded document
differs by its licence footer, because difference four requires it. The two
index documents differ further, because they name the seed path **in prose**:
`.github/docs/templates/README.md` where it says where instantiated documents
go, and `.github/docs/README.md` by one paragraph more, since the sentence
explaining that the seeds sit outside the tree you are building is only true on
this side. `README.md` differs because it is this file. `.github/TEMPLATE_INIT` differs
because differences one, two and three shaped what initialisation has to say here:
the public copy names `assets/README.md` and a `git grep` recipe over paths this
tree does not have, and the funding target and issue chooser its initialisation
rewrites are inherited rather than local. The parity contract and
the workflow enforcing it exist only here because this repository is the one
defined as a delta - the baseline cannot check parity against itself. None of
these is an independent decision, and none needs one.

**Cross-links between seeded documents are relative, and that is load-bearing.**
A relative link resolves the same at either depth, so it is the same string on
both sides; an absolute one encodes the depth and reintroduces a difference in
every file that carries a link. That is exactly how the eight documents above
drifted. Relative is also the convention the [Standards
Index](https://github.com/tannergolden/standards/blob/Development/docs/README.md)
uses throughout, so seeds and standards now link the same way.

---

## ⚠️ Three Things About Inheritance

**1. The `.github` repository must stay public.** GitHub will not serve default
community health files from a private one. It can be public while every
repository inheriting from it stays private - that part is fine.

**2. `ISSUE_TEMPLATE` is all-or-nothing.** The moment this repository contains
_any_ file in its own `.github/ISSUE_TEMPLATE/`, GitHub stops using **every**
inherited issue form, not just the one you added. Adding a single
project-specific template means copying the whole set down first.

**3. Three files are never inherited**, which is why they are still here:

| File             | Why it must be local                 |
| :--------------- | :----------------------------------- |
| `CODEOWNERS`     | Read only from the repository itself |
| `dependabot.yml` | Same                                 |
| `release.yml`    | Same                                 |

`LICENSE`, `.gitignore`, `.gitattributes`, and `.editorconfig` are not GitHub
features at all and are likewise always local.

---

## 🔒 Licence

**Proprietary and confidential. All rights reserved.** Not MIT, not open source,
and not available under any public licence - unlike
[`tannergolden/path`](https://github.com/tannergolden/path), which is MIT and
stays that way.

> [!IMPORTANT]
> **The licence propagates.** Every repository generated from this template
> inherits `LICENSE` verbatim, so anything built here starts proprietary by
> default. That is the intent - but if you ever generate something you mean to
> open source, replace `LICENSE` and the document footers **before** the first
> public push, not after.

The shared workflows and actions this repository calls are published separately
under their own licence and are unaffected by this one.

---

## ⚠️ CI Is Green, And Only Half Configured

The `ci` job in `checks.yml` runs the commands **you** give it, and **fails when every stage resolves
to nothing** rather than reporting a green check that checked nothing. An empty
room has no source code to lint - but that is not the same as nothing to
validate.

So `lint-command` starts out pointing at
[`.github/scripts/validate-repository.py`](.github/scripts/validate-repository.py),
which checks what exists from the first commit: every YAML and JSON file parses,
every workflow `uses:` is pinned to a tag or a commit rather than a branch, no
CRLF or stray whitespace. It lives under `.github/` so the root stays yours.

Nothing is testing or building anything yet, because there is nothing there yet.
Replace the command when that changes:

```yaml
jobs:
  ci:
    uses: tannergolden/standards/.github/workflows/ci.yml@v1
    with:
      lint-command: 'golangci-lint run'
      test-command: 'go test ./...'
      build-command: 'go build ./...'
```

| Stack  | `lint-command`                      | `test-command`  | `build-command`         |
| :----- | :---------------------------------- | :-------------- | :---------------------- |
| Go     | `golangci-lint run`                 | `go test ./...` | `go build ./...`        |
| Rust   | `cargo clippy -- -D warnings`       | `cargo test`    | `cargo build --release` |
| Python | `ruff check .`                      | `pytest`        | `python -m build`       |
| Node   | `npm run lint`                      | `npm test`      | `npm run build`         |
| .NET   | `dotnet format --verify-no-changes` | `dotnet test`   | `dotnet build`          |

One real command is enough. A `Makefile` with `lint`, `test`, `build`, and `docs`
targets works too - delete the `with:` block and the `ci` job falls back to
`make <target>`. That would put a file in the root, which is yours to decide.

---

## 🤖 No AI Infrastructure, On Purpose

This template ships **no agent instruction files and no agent configuration**.
That is a decision, not an omission.

Agent instructions are **always loaded**. Every byte is paid on every session, in
every repository, forever. They also carry conventions that belong to a project
rather than to a scaffold: how you write commits, what must never be touched by
hand, which commands actually build the thing. Shipping a default set makes that
choice on your behalf, invisibly, and the usual result is a file nobody wrote and
nobody trusts.

**Nothing here depends on them.** Initialisation, CI, the rulesets, the release
flow and every workflow behave identically with none of it present. Adding it is
additive, and so is taking it away.

When you do want it, there are two supported routes and no wrong answer:

| Route                                                       | You commit                  | Updates arrive by                            |
| :----------------------------------------------------------- | :-------------------------- | :------------------------------------------- |
| **By hand**                                                 | the instructions themselves | you editing them                             |
| **[`tannergolden/intelligence`](https://github.com/tannergolden/intelligence)** | one workflow stub | a release moving a tag, with no pull request |

Writing them by hand suits conventions that are specific to one project. The
publisher suits several repositories that share one set, for the same reason the
workflows here are called rather than copied: the law lives in one place, and a
fix reaches everything pinned to it. Its README carries the stub to copy and the
version to pin.

> [!IMPORTANT]
> **Whichever route you take, confirm the tools you actually use load what you
> wrote.** They do not agree on which filename to read, and some will not find a
> shared file at all unless a small per-tool file points them at it. Instructions
> nothing loads are worse than none, because they look finished.

> [!TIP]
> **Either route stays reversible.** What you write by hand is yours to delete.
> What the publisher delivers is listed with digests in a lockfile, so the
> inventory of what arrived is also the manifest for removing it.

---

## 🎉 What Happens On Its Own

The `init` job in `lifecycle.yml` runs once and deletes `.github/TEMPLATE_INIT` so it never
runs again. Because you own both this template and whatever it generates, the
identity substitution has almost nothing to do - the real work it does here is
**rewriting GitHub's bare "Initial commit" into a proper Conventional Commit**,
so a new repository's history is compliant from its first entry rather than its
second.

> [!NOTE]
> GitHub does not reliably fire an event when a repository is created from a
> template. If nothing happens within a minute or two, run it from the Actions
> tab. Running it twice is harmless.

---

## 🚀 The First Five Minutes

> [!TIP]
> Every step below, plus signing and the token, is kept as one canonical
> checklist in the standards:
> [🙋 What You Do By Hand](https://github.com/tannergolden/standards/blob/Development/docs/introduction/What-You-Do-By-Hand.md).

1. **Check that init ran** - `.github/TEMPLATE_INIT` should be gone and the
   first commit should read as a Conventional Commit rather than GitHub's bare
   "Initial commit". If not, dispatch **🎯 Standards Lifecycle** from the
   Actions tab; the `init` job is the one that claims the repository.
2. **Sign your commits off.** `git commit -s` adds the `Signed-off-by` trailer
   the DCO check requires. Once branch protection is on, a commit without it
   blocks the merge. `git config alias.ci 'commit -s'` and forget about it.
3. **Configure the `ci` job in `checks.yml`**, as above, once you have
   something to build. Until then it runs the repository validator and passes
   honestly - the job fails only when every stage resolves to nothing, and
   `lint-command` never does.
4. **Apply the settings, then the protection** - run **🎯 Apply Standards**
   from the Actions tab. `apply-settings` writes the repository settings
   (squash-only merges, head branches deleted on merge, auto-merge, the
   security features); `apply-rulesets` writes branch protection. Both preview
   by default and change nothing until you turn `dry-run` off. Do settings
   first: they are checkboxes, while a wrong ruleset blocks every merge.
5. **Confirm `.github/CODEOWNERS` names the right owner.** Unlike the public
   template this ships one live rule rather than commented placeholders, and
   initialisation rewrites it. It never blocks your own work: the shipped
   rulesets require zero approvals and no code-owner review, so a solo
   maintainer cannot deadlock on approving their own pull request.
6. **Enable ecosystems in `.github/dependabot.yml`** as you add manifests. Only
   `github-actions` is on, because it is the only one guaranteed to apply.
7. **Replace this README.** Everything above describes the template, not your
   project. Nothing rewrites it for you, because only you know what this
   repository is for. The sections worth keeping are the workflow table and
   the licence note; the rest is scaffolding that has done its job.

> [!IMPORTANT]
> **🎯 Apply Standards needs a token for two of its three jobs.** Applying the
> label taxonomy needs nothing. **Writing the settings and the rulesets** each
> need a token with administration write as `ADMIN_TOKEN`. Without it, those
> jobs stop with a sentence naming the missing token instead of a bare `403`.
>
> A fine-grained token scoped to your repositories generated from the
> templates, with **Administration: Read and write** and nothing else, is all
> it needs. Step-by-step:
> [Creating the ADMIN_TOKEN](https://github.com/tannergolden/standards/blob/Development/docs/operations/Branch-Protection.md#-creating-the-admin_token).
> You can skip it entirely by applying the settings and rulesets yourself,
> where your own rights are already enough.

> [!NOTE]
> **CodeQL skipping is expected here, not a failure.** Code scanning cannot
> accept results from a private repository without GitHub Advanced Security,
> so the job checks visibility and skips with a notice rather than erroring.
> A repository with Advanced Security can analyse privately through GitHub's
> built-in default setup instead.

---

## 📦 What's Inside

| Path                         | Purpose                                                          |
| :--------------------------- | :--------------------------------------------------------------- |
| `.github/workflows/`         | Twelve trigger workflows, plus the parity check local to this template |
| `.github/`                   | CODEOWNERS, Dependabot, release notes config - the uninheritable |
| `.github/docs/`              | Seed documents, kept with the scaffolding and out of your way    |
| `.github/scripts/`           | The repository validator the `ci` job runs until you point it at yours |
| `.devcontainer/`, `.vscode/` | A language-neutral development container and editor defaults     |

Nothing else. The root carries only what a tool discovers there by mechanism.

---

## 🌿 The Workflows

| Workflow                   | Gives you                                             |
| :------------------------- | :---------------------------------------------------- |
| `checks.yml`               | Lint/test/build, secret scan, CodeQL, workflow lint   |
| `governance.yml`           | PR title and DCO checks, triage, stale sweep, slash commands |
| `release.yml`              | Draft notes, publish assets, prune superseded releases |
| `maintenance.yml`          | Prunes stale deployments and draft releases           |
| `lifecycle.yml`            | Claims this repository once; flags a new major        |
| `dependabot-automerge.yml` | Approves and queues patch and minor updates           |
| `ci-failure-alert.yml`     | Opens an issue when a watched workflow fails          |
| `apply-standards.yml`      | Dispatch-only. The label taxonomy and branch protection |
| `auto-format.yml`          | Formats what a push touched                           |
| `preview-deploy.yml`       | Deploys pushes to a preview target, once configured   |
| `prune-runs.yml`           | Deletes old workflow runs, with their logs and artifacts |
| `verify-stubs.yml`         | Proves every ceiling matches its called workflow      |
| `template-parity.yml`      | Enforces the five-differences contract. Runs only in this template |

**Do not rename the job ids** `ci` and `secrets` (in `checks.yml`) or `pr`
(in `governance.yml`) - branch protection depends on them; the file a job
lives in does not matter, but its id does. Only `preview-deploy.yml` names a
branch, because `Preview` is a promotion branch rather than your default one;
everywhere else a pull request always runs and a push runs only on the default
branch, whatever it happens to be called.

Every workflow ships installed, and most carry an `is_template` guard, so they
are silent here and come alive in every repository generated from this one.
**Two do not, and run in the template as well:** `prune-runs.yml`, because a
template accumulates run history like any repository and nothing else would
ever clear it, and `verify-stubs.yml`, because a stub with a wrong ceiling is
broken wherever it sits. `template-parity.yml` inverts the guard instead - it
runs *only* here. Delete any file that does not fit; each one is yours.

> [!IMPORTANT]
> **🎯 Apply Standards previews by default and changes nothing** until you turn
> `dry-run` off - a wrong ruleset blocks every merge here. Labels need no
> token; writing rulesets needs `ADMIN_TOKEN`.

**Sign your commits off.** `git commit -s` - the DCO check is a required status
check once the rulesets are on, and a commit without the trailer blocks the
merge.

> [!NOTE]
> Nothing here pins a third-party action; every `uses:` points at
> `tannergolden/standards`, so the pins that need maintaining are maintained
> once, there. The one caveat to leaving a repository alone: **GitHub disables
> scheduled workflows in a public repository after 60 days of inactivity** -
> not an issue for this private one, but it applies to anything public you
> generate from it. Dependabot is exempt from that rule and still surfaces a
> new major, so a dormant repository finds out either way.

> [!IMPORTANT]
> **CodeQL needs a public repository or GitHub Advanced Security.** On a private
> repository without it, that job skips rather than failing - so it will not
> redden anything, and it will not analyse anything either.

---

## 📚 The Standards

Everything about how to branch, review, release, and secure a repository lives
in the [Standards Index](https://github.com/tannergolden/standards/blob/Development/docs/README.md).
Follow it **by link**. A standard copied into your repository is a standard that
starts going stale the moment you paste it.

The one exception is [`.github/docs/templates/`](.github/docs/templates/README.md),
which is meant to be copied: those are fill-in documents that become _your_
project's decisions. A fill-in document's destination mirrors its path minus
`templates/`, and where you put it is yours to choose.

---

<div align="center">

**Same road. Your paving stones.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by [@tannergolden](https://github.com/tannergolden). Proprietary and confidential; all rights reserved.

</div>
