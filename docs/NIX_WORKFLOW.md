# Nix validation and failure reporting

## Validation

After changes, run `./scripts/agent-validate.sh`. Read the script before running it for platform/host selection and side effects. It formats all Nix files, not just changed files.

## Build failure reports

Include all of the following when diagnosing or reporting a build failure:

- The full command that was run.
- Complete error output, or the last 20 to 30 lines if verbose.
- The host or installable being built.
- Recent changes made.
