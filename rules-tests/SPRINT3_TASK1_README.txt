Sprint 3 Task 1 - requests: data, rules and tests

Files (all go into the rules-tests folder):
  requests_rules_block.rules  the new rules for requests and their history
  add_requests_rules.js       adds that block to firestore.rules (keeps everything already there)
  requests.test.js            40 tests for the new rules
  package.json                now also runs requests.test.js

Steps (PowerShell, in C:\dev\ucu_wellbeing):
  1. Expand-Archive C:\dev\sprint3_task1_requests_rules.zip -DestinationPath . -Force
  2. node rules-tests/add_requests_rules.js
  3. firebase emulators:exec --only firestore "npm --prefix rules-tests test"
     expect: 107 passing
  4. firebase deploy --only firestore:rules
  5. git add . ; git commit -m "Sprint 3 Task 1: requests rules and tests" ; git push
