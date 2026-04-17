---
name: terratest-module-tests
description: Designs and implements end-to-end integration tests for Terraform or OpenTofu modules using Terratest (Go), including layout, isolation, cleanup, timeouts, and OpenTofu binary configuration. Use when adding or refactoring Terratest tests, module test folders, CI for IaC tests, or when the user mentions Terratest, integration tests, or e2e tests for Terraform/OpenTofu modules.
---

# Terratest module integration tests

## When to use Terratest vs native tests

- **Terratest** — Real infrastructure in a cloud account; need Go helpers, retries, HTTP/SSH/API checks, or orchestration beyond pure Terraform assertions. Typical **integration / e2e** path.
- **Native `terraform test` / `tofu test`** — Faster feedback for **in-process** checks (plans, variables, mocks, `command` runs) without full cloud provisioning. Prefer for cheap unit-style coverage; combine with Terratest for critical paths.

Use both in a layered strategy when budget allows: native tests for fast loops; Terratest for deployment smoke tests.

## Layout

- Put tests in a **`test/`** directory (or `examples/*/`) with its own **`go.mod`**, or a monorepo root module that imports terratest once.
- One test file per major scenario is fine; share helpers in `test_helper_test.go` or `internal/testutil`.
- Point **`TerraformDir`** at the **module under test** or at a **thin wrapper** that calls the module with test inputs (recommended so prod defaults stay unchanged).

## Required patterns

1. **`defer terraform.Destroy(t, opts)`** immediately after building `terraform.Options` so failures still tear down (pair with retryable errors helper; see below).
2. **Unique names** — Use `random.UniqueId()` (or similar) in resource names / name prefixes so parallel runs and CI do not collide.
3. **Long timeouts** — Infrastructure exceeds Go’s default test timeout. Run with e.g. `go test -timeout 30m ./...` (adjust per cloud).
4. **Retryable errors** — Wrap options with `terraform.WithDefaultRetryableErrors(t, opts)` to absorb transient API errors.
5. **OpenTofu** — Set `TerraformBinary: "tofu"` on `terraform.Options` when tests should invoke OpenTufu instead of Terraform.

## Minimal Terratest flow

1. Build `terraform.Options` with `TerraformDir`, `Vars`, env vars if needed, and optional `EnvVars` / `BackendConfig`.
2. `defer terraform.Destroy(t, terraformOptions)` (after options are final).
3. `terraform.InitAndApply(t, terraformOptions)` (or `InitAndApplyAndIdempotent` when you need apply-twice checks).
4. Read **`terraform.Output`** / **`terraform.OutputMap`** and assert with `testify` or standard library.
5. Optionally verify **live resources** with cloud SDKs or HTTP clients (real integration assertion).

## Parallel tests

- Call **`t.Parallel()`** at the start of subtests or top-level tests only when each test uses **isolated** credentials, regions, or **unique** resource names (via `random.UniqueId()` in vars). Avoid parallel tests that share fixed names or a single static remote state bucket without locking.

## CI and credentials

- Inject credentials via environment (OIDC, short-lived keys); never commit secrets.
- Ensure teardown runs: failed tests should still hit `Destroy` via `defer`; consider cleanup jobs for leaked resources if the process is killed hard.
- Cache Go modules; pin Terratest to a **released** version compatible with your Go toolchain.

## What “good” assertions look like

- **Outputs** match expected shape (IDs, ARNs, URLs).
- **Idempotency** — Second `apply` produces no changes when using idempotent helpers, where applicable.
- **Behavior** — DNS resolves, HTTP returns 200, security group allows expected traffic, etc., using small targeted checks rather than re-implementing the whole provider in tests.

## Anti-patterns

- Fixed global resource names reused across test runs.
- No destroy path or relying on manual cleanup.
- Default `go test` timeout on slow applies.
- Testing production accounts without blast-radius controls (use dedicated test accounts/subscriptions/projects).

## Example skeleton (OpenTofu)

```go
package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestModule_EndToEnd(t *testing.T) {
	t.Parallel()

	unique := random.UniqueId()
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    "../",
		TerraformBinary: "tofu",
		Vars: map[string]interface{}{
			"name_prefix": fmt.Sprintf("terratest-%s", unique),
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	out := terraform.Output(t, terraformOptions, "example_id")
	require.NotEmpty(t, out)
}
```

Adapt `TerraformDir`, output keys, and variables to the module under test.
