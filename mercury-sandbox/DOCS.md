# MercurySandbox

Runs the `ghcr.io/benkelly/mercury` controller image, pinned to an exact
release, and drives the host's Docker to run the rest of the
[MercurySandbox](https://github.com/benkelly/MercurySandbox) stack beside it.

## Before you install: what `docker_api` means

This add-on asks for `docker_api`, which mounts the host's Docker socket into
it once you switch the add-on's protection mode off. That is full control of every container on the host, Home Assistant and
the Supervisor included. The add-on uses it for exactly two things, starting
the LLM gateway and starting sandboxes, but the grant itself cannot be made
narrower than root on the host. That is why the security rating is as low as
it is.

Install it only if you are comfortable with that, only on a host where a
mistake in an agent sandbox costing you model spend is acceptable, and only
from this repository.

What the sandboxes themselves can do is much narrower: read-only root
filesystem, no capabilities, memory and CPU caps, an isolated network with
the gateway as the only named neighbour, and no credentials beyond the
gateway key and a git token scoped to branch pushes on the repositories you
choose.

## Setup

1. Add this repository to Home Assistant, then install **MercurySandbox**.
2. On the add-on's **Info** tab, switch **Protection mode** off. The
   Supervisor mounts the host's Docker socket only while it is off; with it
   on, the add-on stops at start with a message saying so.
3. In the configuration, set at least one of `anthropic_api_key` and
   `openrouter_api_key`, and a `git_token`.
4. Start the add-on and watch the log. The first start pulls the LiteLLM
   image (about 1.5 GB) and the sandbox image, builds the gateway with your
   model routing, and starts both. The health check allows ten minutes for
   this.
5. Open the **MercurySandbox** panel in the sidebar. The three chips at the
   top should read `docker ok`, `gateway ok` and `0 running`.
6. Paste a repository URL and a task, choose a model, and press **Spawn**.
   Follow the logs. When the sandbox finishes it pushes a branch named
   `agent/<timestamp>` for you to review.

Repositories must be reachable from the host over `https://`. A fine-grained
GitHub token scoped to those repositories, with contents read and write, is
the right shape for `git_token`. Protect `main` in the repository settings so
the token can only ever add branches.

## Options

### `litellm_master_key`

The key every client uses to talk to the gateway. Leave it blank and the
add-on generates one on first start, keeps it in add-on storage, and prints it
to the log at every start so you can copy it into Hermes or opencode-manager.
Set it yourself if you would rather choose it.

### `anthropic_api_key`, `openrouter_api_key`, `openai_api_key`

Provider keys. Only the gateway container ever sees them; sandboxes get the
master key and nothing else. Set at least one. The built-in routing uses
Anthropic for `claude-sonnet` and OpenRouter for `cheap-default`; see
"Model routing" to change that.

### `git_token`

Token the sandboxes use to clone and push. Served to git through a credential
helper, never written into a URL or onto disk. Leave it empty and sandboxes
can still clone public repositories, but nothing they do can leave the
container.

### `git_name` and `git_email`

Author and committer identity on the commits sandboxes make.

### `default_model`

The model a sandbox uses when none is chosen, as a `model_name` from the
gateway routing. Defaults to `cheap-default`.

### `sandbox_image`

The opencode image to pull. Leave it blank and the add-on uses
`ghcr.io/benkelly/mercury-sandbox` at the same release as itself, so an add-on
update carries the sandbox image with it. Set it to track something else, for
example `ghcr.io/benkelly/mercury-sandbox:edge` for the tip of that repository.

### `sandbox_memory` and `sandbox_cpus`

Caps applied to every sandbox, `2g` and `2.0` by default. Size them for the
host: a Raspberry Pi with 4 GB should not hand 2 GB to each of several
sandboxes at once.

### `sandbox_timeout`

Seconds a sandbox may spend in opencode before it is stopped, `3600` by
default. Whatever it managed by then is still committed and pushed, marked
as cut off in the log.

### `virtual_keys`

Off by default, which hands every sandbox the gateway master key. Turn it on
and the add-on starts a small Postgres beside the gateway (password
generated once into add-on storage) so LiteLLM can mint a key per sandbox:
one model, a spend cap of `sandbox_budget_usd`, valid for a day. The master
key then never enters a sandbox. The first start after turning it on pulls a
Postgres image and takes a little longer.

### `sandbox_budget_usd`

Spend cap for each sandbox's key when `virtual_keys` is on, `5` by default.

### `github_app_id` and `github_app_installation_id`

A GitHub App installed on the repositories agents may touch. With both set
and the App's private key saved as `/addon_configs/<slug>/github-app.pem`,
every sandbox gets a one-hour token for its one repository instead of
`git_token`, which then only serves repositories off GitHub.

To make one: create a GitHub App under your account with repository
permission **Contents: read and write** (and **Pull requests: read and
write** for the "open a pull request" box on the page), install it on
exactly the repositories agents may push to, and note the App ID, the
installation ID from the installation's URL, and the private key it
generates.

### `expose_gateway`

Off by default, which publishes the gateway on the host's loopback only,
where from Home Assistant's point of view nothing can reach it. Turn it on to
publish port `4000` on every host interface, for a Hermes or opencode-manager
on another machine. Do that only on a network you trust, or one you reach
over Tailscale, because the gateway is your model spend behind a single key.

### `api_token`

Leave it empty while you reach the add-on only through ingress. Home
Assistant has already signed you in and the add-on accepts requests from the
ingress proxy alone.

Set it if you map port `5004` in the **Network** section to call the API from
elsewhere (a Hermes tool, a script). Requests then need
`Authorization: Bearer <token>`. Whoever holds this token can start
containers on the host, so treat it like an SSH key.

### `cloudflare_tunnel_token`

Optional. Starts a `cloudflared` container on its own network for sharing a
UI beyond your LAN. Put a Cloudflare Access policy in front of every route,
and never route to the gateway or to port `5004`.

## Agent rules and context

Every sandbox reads a global `AGENTS.md` explaining the harness: the branch
exists, commit and push are handled, there is a time limit and a budget, read
the repository's own instructions, finish with a summary a reviewer can use.
The add-on writes the built-in one to `/addon_configs/<slug>/AGENTS.example.md`;
save your own as `AGENTS.md` in that folder and restart to replace it.

Per task, the **context** box on the page (or `context` in the API) appends
links, constraints and how to test, so the task itself stays short. Tick
**open a pull request** to have the run open the PR for you after pushing.

## Model routing

The gateway is [LiteLLM](https://docs.litellm.ai) and its routing lives in
one YAML file. The add-on writes the built-in one to
`/addon_configs/<slug>/litellm.example.yaml`. To change providers, models or
the cheap default, copy it to `litellm.yaml` in the same folder, edit, and
restart the add-on. Delete `litellm.yaml` to go back to the built-in routing.

Model names in that file are what appear in the **Model** menu on the page
and what `default_model` refers to.

## Using it from Hermes or scripts

Two ways in:

- **The gateway** at `http://<host>:4000/v1` with `expose_gateway` on: an
  OpenAI-compatible endpoint, use the master key as the API key and any
  `model_name` from the routing as the model.
- **The API** at `http://<host>:5004` with port `5004` mapped and
  `api_token` set:

```sh
curl -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"repo":"https://github.com/you/repo.git","task":"add a health endpoint"}' \
  http://homeassistant.local:5004/api/sandboxes
```

`GET /api/sandboxes` lists them, `GET /api/sandboxes/<name>/logs` follows
one, `DELETE /api/sandboxes/<name>` stops one.

## Data and persistence

- `/data/mercury.env`, the generated environment, rewritten from the options
  at every start. Readable by root only.
- `/data/master-key`, the generated gateway key when `litellm_master_key` is
  blank.
- `/data/db-password`, the generated Postgres password when `virtual_keys`
  is on. The database itself lives in a Docker volume on the host,
  `mercury_gateway-db`.
- `/addon_configs/<slug>/litellm.yaml`, your model routing if you made one;
  `AGENTS.md`, your agent rules; `github-app.pem`, the App's private key.

There is no database. Sandboxes keep nothing; their only output is the branch
they push.

## What runs beside the add-on

The add-on starts these on the host's Docker, all named so you can find them:

| Container | What |
| --- | --- |
| `mercury-gateway` | LiteLLM, built from a pinned release plus your routing |
| `mercury-gateway-db` | Postgres for virtual keys, only with `virtual_keys` on |
| `mercury-cloudflared` | only with a tunnel token |
| `mercury-<timestamp>-<id>` | one per sandbox, removed when it exits |

Plus the `agentnet`, `edge` and `mercury-gwdb` networks, the images
`mercury-gateway:local`, the pinned LiteLLM image and the sandbox image.

Stopping the add-on stops the gateway. Running sandboxes are left alone and
listed in the log; they will fail at their next model call. Stop them first
from the page if you care about what they are doing.

**Uninstalling the add-on removes none of this.** The Supervisor does not know
about these containers. To clean up afterwards, from a shell on the host (the
SSH add-on with protection mode off, or the console):

```sh
docker ps -aq --filter label=mercury.sandbox | xargs -r docker rm -f
docker rm -f mercury-gateway mercury-gateway-db mercury-cloudflared 2>/dev/null
docker network rm agentnet edge mercury-gwdb 2>/dev/null
docker volume rm mercury_gateway-db 2>/dev/null   # the virtual key database
docker image rm mercury-gateway:local
docker image prune   # then, for the LiteLLM and sandbox images
```

## Networking

Ingress serves the page, so nothing needs mapping for normal use. Port
`5004` is available to map for API access with `api_token`. The gateway port
`4000` is not in the add-on's port list because the gateway is a sibling
container: `expose_gateway` is what publishes it.

The container health check polls `/api/health` on port `5004` every 30
seconds, after a ten minute grace period for the first image pulls.

## Updates

Updates are manual tag bumps. The Dockerfile pins an exact release of the
controller image, and the sandbox image follows the add-on version unless
`sandbox_image` overrides it.

A scheduled workflow checks MercurySandbox for new releases daily and opens a
pull request bumping the pinned tag, the add-on version and the changelog.
Each bump is reviewed and merged by hand.

## Troubleshooting

**The log says there is no Docker socket.** Protection mode is on. The
Supervisor mounts the socket that `docker_api` asks for only while
protection mode is off for this add-on: **Info** tab, **Protection mode**,
off, then start again. Nothing else in this add-on works without it.

**The first start takes ages.** It is pulling a LiteLLM image of about 1.5 GB
and a node based sandbox image. The health check waits ten minutes. On a
slow link watch the log rather than the health status.

**`gateway unreachable` on the page.** Look at the gateway's own log:
`docker logs mercury-gateway` from a host shell. A typo in `litellm.yaml` is
the usual cause, and LiteLLM says which line.

**A sandbox exits immediately with an authentication error from git.** The
`git_token` cannot reach that repository. Check the token's repository scope
and that it has contents write permission.

**Every model call fails.** No provider key is set, or the key does not match
the provider named in the routing. `cheap-default` needs
`openrouter_api_key`, `claude-sonnet` needs `anthropic_api_key`.

**The page says `mercuryd: 401`.** You reached the add-on by its mapped port
rather than through ingress, without `api_token` set. Use the sidebar panel
or set a token.
