// Sprint 3 Task 2b - replaces the "requests" rules in ../firestore.rules with the
// new version (adds "urgency"). Everything above the requests section is untouched.
// Run from the project folder:  node rules-tests/update_requests_rules.js
const fs = require('fs');
const path = require('path');

const rulesPath = path.join(__dirname, '..', 'firestore.rules');
const block = fs.readFileSync(path.join(__dirname, 'requests_rules_block.rules'), 'utf8').replace(/\s+$/, '');
const rules = fs.readFileSync(rulesPath, 'utf8');

if (rules.includes("d.urgency in ['asap', 'this_week', 'no_rush']")) {
  console.log('Nothing to do: firestore.rules already has the new requests rules.');
  process.exit(0);
}

const marker = '// ---------- requests (FR4';
const at = rules.indexOf(marker);
let head;
if (at === -1) {
  // The requests rules were never added: put them above the last two closing braces.
  const trimmed = rules.replace(/\s+$/, '');
  const m = trimmed.match(/\}\s*\}$/);
  if (!m) { console.error('Could not find the end of firestore.rules. Nothing was changed.'); process.exit(1); }
  head = trimmed.slice(0, m.index);
} else {
  // The requests section is the last one in the file; make sure nothing else follows it.
  const tail = rules.slice(at);
  const other = tail.match(/\n    match \/(?!requests\/)/);
  if (other) {
    console.error('Another section comes after the requests rules, so I did not change anything. Tell Claude.');
    process.exit(1);
  }
  head = rules.slice(0, at);
}
fs.writeFileSync(rulesPath + '.bak', rules);
fs.writeFileSync(rulesPath, head.replace(/\s+$/, '') + '\n\n' + block + '\n  }\n}\n');
console.log('Done. firestore.rules now has the new requests rules (backup: firestore.rules.bak).');
