// Sprint 2 rules tests: categories, service directory, wellbeing resources.
// Review check: "students see only published content".
// Run from the project root:
//   firebase emulators:exec --only firestore "npm --prefix rules-tests test"
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, serverTimestamp,
} = require('firebase/firestore');

describe('Sprint 2: categories, services and resources', () => {
  let env;

  const STUDENT = { uid: 's2-student', email: 'student@student.test' };
  const COUNSELLOR = { uid: 's2-counsellor', email: 'counsellor@student.test' };
  const CHAPLAIN = { uid: 's2-chaplain', email: 'chaplain@student.test' };
  const ADMIN = { uid: 's2-admin', email: 'admin@student.test' };

  const as = (u) => env.authenticatedContext(u.uid, { email: u.email }).firestore();
  const anon = () => env.unauthenticatedContext().firestore();

  const service = (extra = {}) => ({
    name: 'Counselling',
    description: 'Talk privately with a trained counsellor.',
    categoryId: 'mental-health',
    location: '[To be confirmed]',
    operatingHours: '[To be confirmed]',
    contactMethod: '[To be confirmed]',
    accessMethod: 'Walk in or send a request',
    eligibility: 'All registered students',
    whatToExpect: 'A first conversation about what would help.',
    appointmentRequired: false,
    expectedResponseTime: '[To be confirmed]',
    status: 'published',
    updatedBy: 'seed',
    ...extra,
  });

  const resource = (extra = {}) => ({
    title: 'Managing exam stress',
    summary: 'Demo content',
    content: 'Demo content for testing.',
    resourceType: 'article',
    categoryId: 'study-life',
    status: 'published',
    createdBy: COUNSELLOR.uid,
    ...extra,
  });

  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'demo-ucu-wellbeing-rules',
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => { await env.cleanup(); });

  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users', STUDENT.uid), { fullName: 'Student', email: STUDENT.email, role: 'student' });
      await setDoc(doc(db, 'users', COUNSELLOR.uid), { fullName: 'Counsellor', email: COUNSELLOR.email, role: 'staff', serviceId: 'counselling' });
      await setDoc(doc(db, 'users', CHAPLAIN.uid), { fullName: 'Chaplain', email: CHAPLAIN.email, role: 'staff', serviceId: 'chaplaincy' });
      await setDoc(doc(db, 'users', ADMIN.uid), { fullName: 'Admin', email: ADMIN.email, role: 'admin' });

      await setDoc(doc(db, 'categories', 'mental-health'), { name: 'Mental health and counselling', appliesTo: 'both', description: '', status: 'active' });

      await setDoc(doc(db, 'services', 'counselling'), service());
      await setDoc(doc(db, 'services', 'chaplaincy'), service({ name: 'Chaplaincy', status: 'draft' }));

      await setDoc(doc(db, 'resources', 'r-published'), resource());
      await setDoc(doc(db, 'resources', 'r-draft'), resource({ title: 'Draft article', status: 'draft' }));
    });
  });

  describe('Categories', () => {
    it('a student can read categories', async () => {
      await assertSucceeds(getDoc(doc(as(STUDENT), 'categories', 'mental-health')));
    });
    it('a signed-out visitor cannot read categories', async () => {
      await assertFails(getDoc(doc(anon(), 'categories', 'mental-health')));
    });
    it('a student cannot create a category', async () => {
      await assertFails(setDoc(doc(as(STUDENT), 'categories', 'x'), { name: 'X', appliesTo: 'both', description: '', status: 'active' }));
    });
    it('staff cannot create a category', async () => {
      await assertFails(setDoc(doc(as(COUNSELLOR), 'categories', 'x'), { name: 'X', appliesTo: 'both', description: '', status: 'active' }));
    });
    it('an admin can create a valid category', async () => {
      await assertSucceeds(setDoc(doc(as(ADMIN), 'categories', 'x'), { name: 'X', appliesTo: 'resource', description: '', status: 'active' }));
    });
    it('an admin cannot create a category with an invalid type', async () => {
      await assertFails(setDoc(doc(as(ADMIN), 'categories', 'x'), { name: 'X', appliesTo: 'everything', description: '', status: 'active' }));
    });
  });

  describe('Service directory (FR3)', () => {
    it('a student can open a published service', async () => {
      await assertSucceeds(getDoc(doc(as(STUDENT), 'services', 'counselling')));
    });
    it('a student cannot open a draft service', async () => {
      await assertFails(getDoc(doc(as(STUDENT), 'services', 'chaplaincy')));
    });
    it('a student can list published services', async () => {
      await assertSucceeds(getDocs(query(collection(as(STUDENT), 'services'), where('status', '==', 'published'))));
    });
    it('a student cannot list all services including drafts', async () => {
      await assertFails(getDocs(collection(as(STUDENT), 'services')));
    });
    it('a signed-out visitor cannot see services', async () => {
      await assertFails(getDoc(doc(anon(), 'services', 'counselling')));
    });
    it('staff can open their own draft service', async () => {
      await assertSucceeds(getDoc(doc(as(CHAPLAIN), 'services', 'chaplaincy')));
    });
    it("staff cannot open another service's draft", async () => {
      await assertFails(getDoc(doc(as(COUNSELLOR), 'services', 'chaplaincy')));
    });
    it('an admin can list all services', async () => {
      await assertSucceeds(getDocs(collection(as(ADMIN), 'services')));
    });
  });

  describe('Staff keep service information up to date (FR6)', () => {
    it('staff can update their own service', async () => {
      await assertSucceeds(updateDoc(doc(as(COUNSELLOR), 'services', 'counselling'),
        { operatingHours: 'Updated hours', updatedBy: COUNSELLOR.uid, updatedAt: serverTimestamp() }));
    });
    it('staff can publish their own service', async () => {
      await assertSucceeds(updateDoc(doc(as(CHAPLAIN), 'services', 'chaplaincy'),
        { status: 'published', updatedBy: CHAPLAIN.uid, updatedAt: serverTimestamp() }));
    });
    it("staff cannot update another service", async () => {
      await assertFails(updateDoc(doc(as(COUNSELLOR), 'services', 'chaplaincy'),
        { operatingHours: 'x', updatedBy: COUNSELLOR.uid, updatedAt: serverTimestamp() }));
    });
    it('staff must record themselves as the editor', async () => {
      await assertFails(updateDoc(doc(as(COUNSELLOR), 'services', 'counselling'),
        { operatingHours: 'x', updatedBy: 'someone-else', updatedAt: serverTimestamp() }));
    });
    it('staff cannot add unknown fields to a service', async () => {
      await assertFails(updateDoc(doc(as(COUNSELLOR), 'services', 'counselling'),
        { secretNotes: 'x', updatedBy: COUNSELLOR.uid, updatedAt: serverTimestamp() }));
    });
    it('a student cannot edit a service', async () => {
      await assertFails(updateDoc(doc(as(STUDENT), 'services', 'counselling'),
        { operatingHours: 'x', updatedBy: STUDENT.uid, updatedAt: serverTimestamp() }));
    });
    it('staff cannot create a new service', async () => {
      await assertFails(setDoc(doc(as(COUNSELLOR), 'services', 'workshops'), service({ name: 'Workshops', updatedBy: COUNSELLOR.uid })));
    });
    it('an admin can create one of the four known services', async () => {
      await assertSucceeds(setDoc(doc(as(ADMIN), 'services', 'workshops'), service({ name: 'Workshops', updatedBy: ADMIN.uid })));
    });
    it('an admin cannot create an unknown service', async () => {
      await assertFails(setDoc(doc(as(ADMIN), 'services', 'made_up'), service({ name: 'Made up', updatedBy: ADMIN.uid })));
    });
    it('nobody can delete a service', async () => {
      await assertFails(deleteDoc(doc(as(ADMIN), 'services', 'counselling')));
    });
  });

  describe('Wellbeing resources (FR2, FR6)', () => {
    it('a student can list published resources', async () => {
      await assertSucceeds(getDocs(query(collection(as(STUDENT), 'resources'), where('status', '==', 'published'))));
    });
    it('a student cannot open a draft resource', async () => {
      await assertFails(getDoc(doc(as(STUDENT), 'resources', 'r-draft')));
    });
    it('a student cannot list all resources including drafts', async () => {
      await assertFails(getDocs(collection(as(STUDENT), 'resources')));
    });
    it('staff can see drafts', async () => {
      await assertSucceeds(getDoc(doc(as(CHAPLAIN), 'resources', 'r-draft')));
    });
    it('staff can create a draft resource as themselves', async () => {
      await assertSucceeds(setDoc(doc(as(CHAPLAIN), 'resources', 'r-new'),
        resource({ title: 'New', status: 'draft', createdBy: CHAPLAIN.uid, createdAt: serverTimestamp() })));
    });
    it('staff cannot create a resource in someone else\'s name', async () => {
      await assertFails(setDoc(doc(as(CHAPLAIN), 'resources', 'r-new'), resource({ createdBy: COUNSELLOR.uid })));
    });
    it('a student cannot create a resource', async () => {
      await assertFails(setDoc(doc(as(STUDENT), 'resources', 'r-new'), resource({ createdBy: STUDENT.uid })));
    });
    it('staff can publish their own resource', async () => {
      await assertSucceeds(updateDoc(doc(as(COUNSELLOR), 'resources', 'r-draft'),
        { status: 'published', updatedAt: serverTimestamp(), publishedAt: serverTimestamp() }));
    });
    it("staff cannot edit another staff member's resource", async () => {
      await assertFails(updateDoc(doc(as(CHAPLAIN), 'resources', 'r-draft'), { title: 'Changed' }));
    });
    it('an admin can edit any resource', async () => {
      await assertSucceeds(updateDoc(doc(as(ADMIN), 'resources', 'r-draft'), { title: 'Edited by admin' }));
    });
    it('nobody can change who created a resource', async () => {
      await assertFails(updateDoc(doc(as(ADMIN), 'resources', 'r-draft'), { createdBy: ADMIN.uid }));
    });
    it('a resource cannot have an unknown status', async () => {
      await assertFails(updateDoc(doc(as(COUNSELLOR), 'resources', 'r-draft'), { status: 'live' }));
    });
    it('resources are archived, never deleted', async () => {
      await assertSucceeds(updateDoc(doc(as(COUNSELLOR), 'resources', 'r-published'), { status: 'archived' }));
      await assertFails(deleteDoc(doc(as(ADMIN), 'resources', 'r-published')));
    });
  });
});
