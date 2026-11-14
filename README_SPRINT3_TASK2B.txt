Sprint 3 Task 2b - "never the only door": urgency + reach-the-service-now card
(replaces sprint3_task2_request_form.zip; it contains everything from Task 2)

  1. Expand-Archive C:\dev\sprint3_task2b_urgency.zip -DestinationPath . -Force
  2. node rules-tests/update_requests_rules.js
  3. firebase emulators:exec --only firestore "npm --prefix rules-tests test"     expect: 111 passing
  4. flutter analyze                                                               expect: No issues found!
  5. firebase deploy --only firestore:rules
  6. git add . ; git commit -m "Sprint 3 Task 2: request form with urgency and reach-now card" ; git push
