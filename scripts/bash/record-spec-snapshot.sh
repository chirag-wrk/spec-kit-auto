#!/usr/bin/env bash
# Record a deterministic snapshot (hashes + metadata) of spec.md for reproducibility.
# Run from repository root after spec.md exists.
set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

_paths_output=$(get_feature_paths) || {
    echo "ERROR: Failed to resolve feature paths" >&2
    exit 1
}
eval "$_paths_output"
unset _paths_output

if [[ ! -f "$FEATURE_SPEC" ]]; then
    echo "ERROR: spec.md not found at $FEATURE_SPEC" >&2
    exit 1
fi

slug="$(basename "$FEATURE_DIR")"
out_dir="$REPO_ROOT/.specify/spec-snapshots"
mkdir -p "$out_dir"
out_file="$out_dir/${slug}.json"

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
commit=""
if has_git; then
    commit="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
fi

spec_sha256="$(sha256sum "$FEATURE_SPEC" | awk '{print $1}')"
req_file="$FEATURE_DIR/checklists/requirements.md"
req_sha256=""
if [[ -f "$req_file" ]]; then
    req_sha256="$(sha256sum "$req_file" | awk '{print $1}')"
fi

if has_jq; then
    jq -cn \
        --arg feature_dir "$FEATURE_DIR" \
        --arg spec_path "$FEATURE_SPEC" \
        --arg spec_sha256 "$spec_sha256" \
        --arg requirements_path "$req_file" \
        --arg requirements_sha256 "$req_sha256" \
        --arg recorded_at "$ts" \
        --arg git_commit "$commit" \
        '{
            feature_dir: $feature_dir,
            spec_path: $spec_path,
            spec_sha256: $spec_sha256,
            requirements_path: (if ($requirements_sha256 | length) > 0 then $requirements_path else null end),
            requirements_sha256: (if ($requirements_sha256 | length) > 0 then $requirements_sha256 else null end),
            recorded_at: $recorded_at,
            git_commit: (if ($git_commit | length) > 0 then $git_commit else null end)
        }' >"$out_file"
else
    printf '{"feature_dir":"%s","spec_path":"%s","spec_sha256":"%s","requirements_sha256":%s,"recorded_at":"%s","git_commit":%s}\n' \
        "$(json_escape "$FEATURE_DIR")" \
        "$(json_escape "$FEATURE_SPEC")" \
        "$(json_escape "$spec_sha256")" \
        "$(if [[ -n "$req_sha256" ]]; then printf '"%s"' "$(json_escape "$req_sha256")"; else printf 'null'; fi)" \
        "$(json_escape "$ts")" \
        "$(if [[ -n "$commit" ]]; then printf '"%s"' "$(json_escape "$commit")"; else printf 'null'; fi)" \
        >"$out_file"
fi

echo "Wrote $out_file"
