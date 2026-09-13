# MercurySandbox

Home Assistant add-on for [MercurySandbox](https://github.com/benkelly/MercurySandbox),
a safe playground for autonomous coding agents, running the controller image
`ghcr.io/benkelly/mercury`.

It runs one LLM gateway that holds your model API keys and spawns throwaway
[opencode](https://opencode.ai) sandboxes that hold none. A sandbox clones a
repo, does the task you give it, pushes a branch and is destroyed. You review
the branch. Licensed MIT.

Supported architectures: `amd64`, `aarch64`.

See [DOCS.md](./DOCS.md) for setup, what `docker_api` means for you, and the
full option reference.

## Quick start

1. Read the security section of [DOCS.md](./DOCS.md). This add-on controls
   Docker on the host, which is not a small thing.
2. Install the add-on and, on its **Info** tab, switch **Protection mode**
   off: that is what lets the Supervisor hand it the Docker socket.
3. Put at least one provider key in the configuration (`anthropic_api_key`
   or `openrouter_api_key`) and a `git_token` scoped to the repositories
   agents may push to.
4. Start it. The first start pulls the LiteLLM and sandbox images, which takes
   a few minutes.
5. Open the **MercurySandbox** panel in the sidebar, paste a repository URL
   and a task, and press **Spawn**. Watch the logs, then review the branch it
   pushes.

## Where this fits

The add-on is the "hands". The "brain", a persistent
[Hermes agent](https://github.com/NousResearch/hermes-agent) with memory, is
meant to run natively somewhere you back up, pointed at this gateway. Without
Hermes the add-on is still useful on its own: a private model gateway plus a
web page for firing off one-task coding sandboxes.

## Note on what it starts

The gateway and every sandbox run as ordinary containers on the Home Assistant
host, beside the add-on rather than inside it. They do not appear in the
add-on list and are not part of add-on backups. DOCS.md has the cleanup
commands for when you uninstall.
