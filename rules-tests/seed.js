// Loads DEMO data into the LOCAL Firestore emulator only (never the real project).
// Run while the emulators are running:
//   npm --prefix rules-tests run seed
//
// All service details marked [To be confirmed] are placeholders: replace them
// with information confirmed by each UCU service. Resource texts are demo
// content for testing, not approved UCU material.
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set.');
  process.exit(1);
}

initializeApp({ projectId: 'ucu-wellbeing' });
const db = getFirestore();
const TBC = '[To be confirmed with the service]';

const categories = {
  'mental-health': { name: 'Mental health and counselling', appliesTo: 'both', description: 'Emotional wellbeing and talking to someone', status: 'active' },
  'spiritual-life': { name: 'Spiritual life', appliesTo: 'both', description: 'Faith, meaning and pastoral care', status: 'active' },
  'study-life': { name: 'Study and student life', appliesTo: 'both', description: 'Exams, workload, sleep and settling in', status: 'active' },
  'peer-support': { name: 'Peer support', appliesTo: 'both', description: 'Support from trained fellow students', status: 'active' },
};

const services = {
  counselling: {
    name: 'Counselling',
    description: 'Talk privately with a trained counsellor about anything affecting your wellbeing.',
    categoryId: 'mental-health',
    location: TBC, operatingHours: TBC, contactMethod: TBC,
    accessMethod: 'Walk in during opening hours, or send a request in the app.',
    eligibility: 'Registered UCU students',
    whatToExpect: TBC,
    appointmentRequired: false,
    expectedResponseTime: TBC,
    status: 'published',
  },
  peer_counselling: {
    name: 'Peer counselling',
    description: 'Talk with a trained fellow student who will listen and help you find support.',
    categoryId: 'peer-support',
    location: TBC, operatingHours: TBC, contactMethod: TBC,
    accessMethod: TBC, eligibility: 'Registered UCU students', whatToExpect: TBC,
    appointmentRequired: false, expectedResponseTime: TBC,
    status: 'published',
  },
  chaplaincy: {
    name: 'Chaplaincy',
    description: 'Spiritual care, guidance and someone to talk to.',
    categoryId: 'spiritual-life',
    location: TBC, operatingHours: TBC, contactMethod: TBC,
    accessMethod: TBC, eligibility: 'All students and staff', whatToExpect: TBC,
    appointmentRequired: false, expectedResponseTime: TBC,
    status: 'published',
  },
  workshops: {
    name: 'Workshops and talks',
    description: 'Wellbeing sessions held on campus during the semester.',
    categoryId: 'study-life',
    location: TBC, operatingHours: TBC, contactMethod: TBC,
    accessMethod: TBC, eligibility: 'Registered UCU students', whatToExpect: TBC,
    appointmentRequired: false, expectedResponseTime: TBC,
    status: 'draft', // a draft on purpose: students must NOT see it (review check)
  },
};

const resources = {
  'demo-exam-stress': {
    title: 'Managing exam stress',
    summary: 'Demo content - replace with approved UCU material.',
    content: 'Exams can feel overwhelming. Break revision into small blocks, take short breaks, and keep regular meals and sleep. If stress starts to affect your daily life, the Counselling service is there to talk it through.',
    resourceType: 'article', categoryId: 'study-life', status: 'published',
  },
  'demo-sleep': {
    title: 'Sleep and rest',
    summary: 'Demo content - replace with approved UCU material.',
    content: 'Regular sleep helps concentration and mood. Try to keep similar sleep and wake times, and put your phone away before bed.',
    resourceType: 'article', categoryId: 'study-life', status: 'published',
  },
  'demo-first-steps': {
    title: 'Talking to someone: first steps',
    summary: 'Demo content - replace with approved UCU material.',
    content: 'You do not need a crisis to talk to someone. You can contact Counselling, Peer counselling or the Chaplaincy for a first conversation about whatever is on your mind.',
    resourceType: 'guide', categoryId: 'mental-health', status: 'published',
  },
  'demo-draft': {
    title: 'Settling in at university (draft)',
    summary: 'Demo draft - students must not see this.',
    content: 'Draft text.',
    resourceType: 'article', categoryId: 'study-life', status: 'draft',
  },
};

(async () => {
  const batch = db.batch();
  for (const [id, c] of Object.entries(categories)) batch.set(db.doc(`categories/${id}`), c);
  for (const [id, s] of Object.entries(services)) {
    batch.set(db.doc(`services/${id}`), { ...s, updatedAt: FieldValue.serverTimestamp(), updatedBy: 'seed' });
  }
  for (const [id, r] of Object.entries(resources)) {
    batch.set(db.doc(`resources/${id}`), {
      ...r, createdBy: 'seed', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      ...(r.status === 'published' ? { publishedAt: FieldValue.serverTimestamp() } : {}),
    });
  }
  await batch.commit();
  console.log(`Seeded ${Object.keys(categories).length} categories, ${Object.keys(services).length} services, ${Object.keys(resources).length} resources into the emulator.`);
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
