// Sprint 3 Task 1 - tests for the "requests" rules (FR4, FR5, FR8, NFR1).
// Run (emulators stopped):  firebase emulators:exec --only firestore "npm --prefix rules-tests test"
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, getDocs,
  serverTimestamp, writeBatch, Timestamp,
} = require('firebase/firestore');

describe('Requests (Sprint 3)', function () {
  let testEnv;

  const db = (uid) => testEnv.authenticatedContext(uid).firestore();
  const anon = () => testEnv.unauthenticatedContext().firestore();

  // A valid new request from student1 to counselling.
  const newRequest = (over = {}) => ({
    studentId: 'student1',
    studentName: 'Student One',
    serviceId: 'counselling',
    requestType: 'appointment',
    preferredContact: 'sms',
    contactValue: '0700 000 000',
    status: 'submitted',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    lastUpdatedBy: 'student1',
    ...over,
  });

  // An existing request written with the rules switched off.
  async function existingRequest(id, over = {}) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'requests', id), {
        studentId: 'student1',
        studentName: 'Student One',
        serviceId: 'counselling',
        requestType: 'talk_to_someone',
        preferredContact: 'call',
        contactValue: '0700 000 000',
        status: 'submitted',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        lastUpdatedBy: 'student1',
        ...over,
      });
    });
  }

  const statusChange = (uid, status) => ({
    status, updatedAt: serverTimestamp(), lastUpdatedBy: uid,
  });

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-ucu-wellbeing-requests',
      firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const f = ctx.firestore();
      const now = Timestamp.now();
      const user = (fullName, role, serviceId) => ({
        fullName, email: `${fullName.toLowerCase().replace(/ /g, '')}@example.test`, role,
        createdAt: now, ...(serviceId ? { serviceId } : {}),
      });
      await setDoc(doc(f, 'users', 'student1'), user('Student One', 'student'));
      await setDoc(doc(f, 'users', 'student2'), user('Student Two', 'student'));
      await setDoc(doc(f, 'users', 'counsellor'), user('Staff Counselling', 'staff', 'counselling'));
      await setDoc(doc(f, 'users', 'chaplain'), user('Staff Chaplaincy', 'staff', 'chaplaincy'));
      await setDoc(doc(f, 'users', 'admin1'), user('Admin One', 'admin'));
      await setDoc(doc(f, 'services', 'counselling'), { name: 'Counselling', status: 'published', appointmentRequired: true });
      await setDoc(doc(f, 'services', 'chaplaincy'), { name: 'Chaplaincy', status: 'published', appointmentRequired: false });
      await setDoc(doc(f, 'services', 'workshops'), { name: 'Workshops', status: 'draft', appointmentRequired: false });
    });
  });

  // ---------------- sending a request ----------------
  describe('sending a request', () => {
    it('a student can send a request to a published service', async () => {
      await assertSucceeds(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest()));
    });

    it('a student can add a short optional note', async () => {
      await assertSucceeds(setDoc(doc(db('student1'), 'requests', 'r1'),
        newRequest({ note: 'Afternoons are better for me.' })));
    });

    it('the request and its first history entry can be saved together', async () => {
      const f = db('student1');
      const batch = writeBatch(f);
      batch.set(doc(f, 'requests', 'r1'), newRequest());
      batch.set(doc(f, 'requests', 'r1', 'updates', 'u1'), {
        authorId: 'student1', authorRole: 'student', newStatus: 'submitted', createdAt: serverTimestamp(),
      });
      await assertSucceeds(batch.commit());
    });

    it('a student cannot send a request in someone else\'s name', async () => {
      await assertFails(setDoc(doc(db('student2'), 'requests', 'r1'), newRequest()));
    });

    it('the student\'s name must match their profile', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ studentName: 'Someone Else' })));
    });

    it('a new request must start as "submitted"', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ status: 'contacted' })));
    });

    it('cannot send a request to a draft (hidden) service', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ serviceId: 'workshops' })));
    });

    it('cannot send a request to a service that does not exist', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ serviceId: 'gym' })));
    });

    it('the contact method must be call, sms or email', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ preferredContact: 'whatsapp' })));
    });

    it('the note is limited to 500 characters', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ note: 'x'.repeat(501) })));
    });

    it('extra fields are refused', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'), newRequest({ diagnosis: 'anything' })));
    });

    it('the time must come from the server, not the phone', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1'),
        newRequest({ createdAt: Timestamp.fromDate(new Date('2020-01-01')) })));
    });

    it('staff cannot send requests', async () => {
      await assertFails(setDoc(doc(db('counsellor'), 'requests', 'r1'),
        newRequest({ studentId: 'counsellor', studentName: 'Staff Counselling', lastUpdatedBy: 'counsellor' })));
    });

    it('a signed-out visitor cannot send requests', async () => {
      await assertFails(setDoc(doc(anon(), 'requests', 'r1'), newRequest()));
    });
  });

  // ---------------- who can see a request ----------------
  describe('who can see a request', () => {
    beforeEach(() => existingRequest('r1'));

    it('the student who sent it can read it', async () => {
      await assertSucceeds(getDoc(doc(db('student1'), 'requests', 'r1')));
    });

    it('another student cannot read it', async () => {
      await assertFails(getDoc(doc(db('student2'), 'requests', 'r1')));
    });

    it('staff of that service can read it', async () => {
      await assertSucceeds(getDoc(doc(db('counsellor'), 'requests', 'r1')));
    });

    it('staff of a different service cannot read it', async () => {
      await assertFails(getDoc(doc(db('chaplain'), 'requests', 'r1')));
    });

    it('an admin cannot read it (admins manage accounts, not requests)', async () => {
      await assertFails(getDoc(doc(db('admin1'), 'requests', 'r1')));
    });

    it('a student can list THEIR OWN requests', async () => {
      const f = db('student1');
      await assertSucceeds(getDocs(query(collection(f, 'requests'), where('studentId', '==', 'student1'))));
    });

    it('a student cannot list all requests', async () => {
      await assertFails(getDocs(collection(db('student1'), 'requests')));
    });

    it('staff can list the requests for THEIR service', async () => {
      const f = db('counsellor');
      await assertSucceeds(getDocs(query(collection(f, 'requests'), where('serviceId', '==', 'counselling'))));
    });

    it('staff cannot list another service\'s requests', async () => {
      const f = db('counsellor');
      await assertFails(getDocs(query(collection(f, 'requests'), where('serviceId', '==', 'chaplaincy'))));
    });
  });

  // ---------------- moving a request along ----------------
  describe('changing the status', () => {
    beforeEach(() => existingRequest('r1'));

    it('staff of that service can mark it "under review"', async () => {
      await assertSucceeds(updateDoc(doc(db('counsellor'), 'requests', 'r1'), statusChange('counsellor', 'under_review')));
    });

    it('staff of a different service cannot change it', async () => {
      await assertFails(updateDoc(doc(db('chaplain'), 'requests', 'r1'), statusChange('chaplain', 'under_review')));
    });

    it('staff cannot change what the student wrote', async () => {
      await assertFails(updateDoc(doc(db('counsellor'), 'requests', 'r1'),
        { ...statusChange('counsellor', 'contacted'), contactValue: '0711 111 111' }));
    });

    it('staff cannot set it back to "submitted"', async () => {
      await existingRequest('r2', { status: 'under_review' });
      await assertFails(updateDoc(doc(db('counsellor'), 'requests', 'r2'), statusChange('counsellor', 'submitted')));
    });

    it('the student can withdraw their request', async () => {
      await assertSucceeds(updateDoc(doc(db('student1'), 'requests', 'r1'), statusChange('student1', 'withdrawn')));
    });

    it('the student cannot mark it "contacted"', async () => {
      await assertFails(updateDoc(doc(db('student1'), 'requests', 'r1'), statusChange('student1', 'contacted')));
    });

    it('after staff ask for more information, the student can send it back for review', async () => {
      await existingRequest('r2', { status: 'info_requested' });
      await assertSucceeds(updateDoc(doc(db('student1'), 'requests', 'r2'), statusChange('student1', 'under_review')));
    });

    it('a closed request cannot be changed', async () => {
      await existingRequest('r2', { status: 'closed' });
      await assertFails(updateDoc(doc(db('counsellor'), 'requests', 'r2'), statusChange('counsellor', 'under_review')));
    });

    it('an admin cannot change a request', async () => {
      await assertFails(updateDoc(doc(db('admin1'), 'requests', 'r1'), statusChange('admin1', 'closed')));
    });

    it('nobody can delete a request', async () => {
      await assertFails(deleteDoc(doc(db('student1'), 'requests', 'r1')));
      await assertFails(deleteDoc(doc(db('counsellor'), 'requests', 'r1')));
      await assertFails(deleteDoc(doc(db('admin1'), 'requests', 'r1')));
    });
  });

  // ---------------- history ----------------
  describe('request history', () => {
    beforeEach(() => existingRequest('r1'));

    it('staff can change the status and record it in the history together', async () => {
      const f = db('counsellor');
      const batch = writeBatch(f);
      batch.update(doc(f, 'requests', 'r1'), statusChange('counsellor', 'info_requested'));
      batch.set(doc(f, 'requests', 'r1', 'updates', 'u1'), {
        authorId: 'counsellor', authorRole: 'staff', newStatus: 'info_requested',
        message: 'Which days are you free this week?', createdAt: serverTimestamp(),
      });
      await assertSucceeds(batch.commit());
    });

    it('the student can add a message to their own request', async () => {
      await assertSucceeds(setDoc(doc(db('student1'), 'requests', 'r1', 'updates', 'u1'), {
        authorId: 'student1', authorRole: 'student', message: 'Tuesday works.', createdAt: serverTimestamp(),
      }));
    });

    it('another student cannot add to it', async () => {
      await assertFails(setDoc(doc(db('student2'), 'requests', 'r1', 'updates', 'u1'), {
        authorId: 'student2', authorRole: 'student', message: 'Hi', createdAt: serverTimestamp(),
      }));
    });

    it('nobody can write a history entry in someone else\'s name', async () => {
      await assertFails(setDoc(doc(db('student1'), 'requests', 'r1', 'updates', 'u1'), {
        authorId: 'counsellor', authorRole: 'staff', message: 'Closed', createdAt: serverTimestamp(),
      }));
    });

    it('the student and the service staff can read the history; other staff cannot', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'requests', 'r1', 'updates', 'u1'), {
          authorId: 'counsellor', authorRole: 'staff', message: 'Hello', createdAt: Timestamp.now(),
        });
      });
      await assertSucceeds(getDocs(collection(db('student1'), 'requests', 'r1', 'updates')));
      await assertSucceeds(getDocs(collection(db('counsellor'), 'requests', 'r1', 'updates')));
      await assertFails(getDocs(collection(db('chaplain'), 'requests', 'r1', 'updates')));
      await assertFails(getDocs(collection(db('student2'), 'requests', 'r1', 'updates')));
    });

    it('history entries cannot be edited or deleted', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'requests', 'r1', 'updates', 'u1'), {
          authorId: 'student1', authorRole: 'student', message: 'Hello', createdAt: Timestamp.now(),
        });
      });
      await assertFails(updateDoc(doc(db('student1'), 'requests', 'r1', 'updates', 'u1'), { message: 'Changed' }));
      await assertFails(deleteDoc(doc(db('student1'), 'requests', 'r1', 'updates', 'u1')));
    });

    it('nothing can be added to a closed request', async () => {
      await existingRequest('r2', { status: 'closed' });
      await assertFails(setDoc(doc(db('counsellor'), 'requests', 'r2', 'updates', 'u1'), {
        authorId: 'counsellor', authorRole: 'staff', message: 'One more thing', createdAt: serverTimestamp(),
      }));
    });
  });
});
