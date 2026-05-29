#!/usr/bin/env bash
#
# fix-agent-service-url.sh
#
# Patches catalog-service-ai-enhanced/agent-service/src/app.js to handle the
# /v1/ suffix that Compose's `models: endpoint_var:` integration injects into
# MODEL_RUNNER_URL.
#
# Background:
#   Compose sets MODEL_RUNNER_URL=http://model-runner.docker.internal/v1/
#   The original code's URL-building logic then appended `engines/v1/chat/completions`,
#   producing a duplicate-v1 URL that 404'd:
#     http://model-runner.docker.internal/v1/engines/v1/chat/completions
#
# Fix:
#   Declare `normalizedUrl` at module scope as `modelRunnerUrl` with any trailing
#   `/v1` or `/v1/` stripped. Replace the references inside the URL-building
#   block so it sees the bare base URL and constructs the path correctly.
#
# Usage:
#   Run from the root of a catalog-service-ai-enhanced checkout:
#     ./fix-agent-service-url.sh
#
#   Or pass the repo path explicitly:
#     ./fix-agent-service-url.sh /path/to/catalog-service-ai-enhanced
#
# Safe to re-run: detects if the patch is already applied and exits cleanly.

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
export TARGET="$REPO_ROOT/agent-service/src/app.js"

# --- Validate target ---------------------------------------------------------

if [[ ! -f "$TARGET" ]]; then
  echo "✗ Cannot find $TARGET"
  echo "  Run this from the root of a catalog-service-ai-enhanced checkout,"
  echo "  or pass the repo path as an argument:"
  echo "    $0 /path/to/catalog-service-ai-enhanced"
  exit 1
fi

# --- Already patched? --------------------------------------------------------

if grep -q 'const normalizedUrl' "$TARGET"; then
  echo "✓ Patch already applied to $TARGET — nothing to do."
  exit 0
fi

# --- Need node for the edit and for syntax verification ---------------------

if ! command -v node >/dev/null 2>&1; then
  echo "✗ This script needs node. Install Node.js or run from a shell that has it."
  exit 1
fi

# --- Backup ------------------------------------------------------------------

BACKUP="$TARGET.bak.$(date +%Y%m%d_%H%M%S)"
cp "$TARGET" "$BACKUP"
echo "→ Backed up original to $BACKUP"

# --- Apply patch via node (avoids sed regex-escape pain) --------------------

node <<'NODE_EOF'
const fs = require('fs');
const path = process.env.TARGET;
let src = fs.readFileSync(path, 'utf8');

// 1) Add module-scope `normalizedUrl` right after the `const modelRunnerUrl = ...` line.
const declRegex = /(const\s+modelRunnerUrl\s*=\s*process\.env\.MODEL_RUNNER_URL[^;]*;)/;
if (!declRegex.test(src)) {
  console.error('✗ Could not find `const modelRunnerUrl = process.env.MODEL_RUNNER_URL...` line');
  process.exit(1);
}
src = src.replace(
  declRegex,
  '$1\n' +
  '// Strip trailing /v1 or /v1/ that Compose `models: endpoint_var:` injects,\n' +
  '// so URL construction is robust regardless of which form Compose provides.\n' +
  'const normalizedUrl = modelRunnerUrl.replace(/\\/v1\\/?$/, "");'
);

// 2) Inside the API-URL-building block, swap `modelRunnerUrl` for `normalizedUrl`.
//    Bound the replacement between `let apiUrl;` and the next `Calling Docker Model Runner`
//    log line so we don't accidentally touch unrelated code below.
const blockStart = src.indexOf('let apiUrl;');
const blockEnd   = src.indexOf('Calling Docker Model Runner', blockStart);
if (blockStart === -1 || blockEnd === -1) {
  console.error('✗ Could not locate the apiUrl block to patch.');
  console.error('  The file structure may have changed since this script was written.');
  process.exit(1);
}
const before = src.slice(0, blockStart);
const block  = src.slice(blockStart, blockEnd);
const after  = src.slice(blockEnd);

const patchedBlock = block
  .replace(/modelRunnerUrl\.includes/g, 'normalizedUrl.includes')
  .replace(/modelRunnerUrl\.endsWith/g, 'normalizedUrl.endsWith')
  .replace(/\$\{modelRunnerUrl\}/g,     '${normalizedUrl}');

src = before + patchedBlock + after;

fs.writeFileSync(path, src);
console.log('→ Patch written');
NODE_EOF

# --- Verify ------------------------------------------------------------------

echo
echo "→ Verifying patch..."

if ! grep -q 'const normalizedUrl' "$TARGET"; then
  echo "✗ Verification failed: normalizedUrl declaration not found."
  echo "  Restoring backup from $BACKUP"
  mv "$BACKUP" "$TARGET"
  exit 1
fi
echo "  ✓ normalizedUrl declaration present"

if ! node --check "$TARGET" 2>/dev/null; then
  echo "✗ Patched file has a syntax error:"
  node --check "$TARGET" || true
  echo "  Restoring backup from $BACKUP"
  mv "$BACKUP" "$TARGET"
  exit 1
fi
echo "  ✓ Syntax check passed (node --check)"

echo
echo "✓ Patch applied successfully to $TARGET"
echo
echo "Next steps:"
echo "  1. Inspect the diff:    git diff agent-service/src/app.js"
echo "  2. Rebuild the service: docker compose up -d --build agent-service"
echo "  3. Submit a product and watch:"
echo "       docker compose logs -f agent-service"
echo "     The '🔗 API URL:' line should contain exactly one '/v1/'."
