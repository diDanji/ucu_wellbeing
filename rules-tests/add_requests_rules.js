// Sprint 3 Task 1 - adds the "requests" rules to ../firestore.rules
// WITHOUT touching anything that is already there.
// Run from the project folder:  node rules-tests/add_requests_rules.js
const fs = require('fs');
const path = require('path');

const rulesPath = path.join(__dirname, '..', 'firestore.rules');
const blockPath = path.join(__dirname, 'requests_rules_block.rules');

let rules = fs.readFileSync(rulesPath, 'utf8');
const block = fs.readFileSync(blockPath, 'utf8');

if (rules.includes('match /requests/{requestId}')) {
  console.log('Nothing to do: the requests rules are already in firestore.rules.');
  process.exit(0);
}

// The file ends with two closing braces:  "  }"  (documents)  and  "}"  (service).
// Put the new block just above them.
const trimmed = rules.replace(/\s+$/, '');
const m = trimmed.match(/\}\s*\}$/);
if (!m) {
  console.error('Could not find the end of firestore.rules. Nothing was changed.');
  process.exit(1);
}
const cut = m.index;
fs.writeFileSync(rulesPath + '.bak', rules);
const updated = trimmed.slice(0, cut).replace(/\s+$/, '') + '\n\n' + block.replace(/\s+$/, '') + '\n  }\n}\n';
fs.writeFileSync(rulesPath, updated);
console.log('Done. Added the requests rules to firestore.rules (backup saved as firestore.rules.bak).');
