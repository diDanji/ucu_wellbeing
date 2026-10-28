// Automated tests for firestore.rules (NFR2 evidence).
// Run from the project root:
//   firebase emulators:exec --only firestore "npm --prefix rules-tests test"
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, serverTimestamp } =
  require('firebase/firestore');

let env;

const STUDENT = { uid: 'stu1', email: 'student1@student.test' };
const OTHER = { uid: 'stu2', email: 'student2@student.test' };
const STAFF = { uid: 'staff1', email: 'staff1@student.test' };
const ADMIN = { uid: 'admin1', email: 'admin@student.test' };

// A Firestore client signed in as a given test user (or signed out).
const as = (u) => env.authenticatedContext(u.uid, { email: u.email }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const profile = (u, extra = {}) => ({
  fullName: 'Test ' + u.uid,
  email: u.email,
  role: 'student',
  createdAt: serverTimestamp(),
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

// Fresh data before every test: one student, another student, one staff, one admin.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', STUDENT.uid), { fullName: 'Student One', email: STUDENT.email, role: 'student' });
    await setDoc(doc(db, 'users', OTHER.uid), { fullName: 'Student Two', email: OTHER.email, role: 'student' });
    await setDoc(doc(db, 'users', STAFF.uid), { fullName: 'Staff One', email: STAFF.email, role: 'staff', serviceId: 'counselling' });
    await setDoc(doc(db, 'users', ADMIN.uid), { fullName: 'Admin One', email: ADMIN.email, role: 'admin' });
  });
});

describe('Registration (FR1)', () => {
  const NEW = { uid: 'new1', email: 'new1@student.test' };

  it('a new user can create their own profile as a student', async () => {
    await assertSucceeds(setDoc(doc(as(NEW), 'users', NEW.uid), profile(NEW)));
  });
  it('cannot register as admin', async () => {
    await assertFails(setDoc(doc(as(NEW), 'users', NEW.uid), profile(NEW, { role: 'admin' })));
  });
  it('cannot register as staff', async () => {
    await assertFails(setDoc(doc(as(NEW), 'users', NEW.uid), profile(NEW, { role: 'staff', serviceId: 'counselling' })));
  });
  it("cannot create someone else's profile", async () => {
    await assertFails(setDoc(doc(as(NEW), 'users', 'someone-else'), profile(NEW)));
  });
  it('cannot store extra fields (NFR1 minimal data)', async () => {
    await assertFails(setDoc(doc(as(NEW), 'users', NEW.uid), profile(NEW, { diagnosis: 'anything' })));
  });
  it('cannot use an email different from their sign-in email', async () => {
    await assertFails(setDoc(doc(as(NEW), 'users', NEW.uid), profile(NEW, { email: 'fake@student.test' })));
  });
  it('a signed-out visitor cannot create a profile', async () => {
    await assertFails(setDoc(doc(anon(), 'users', NEW.uid), profile(NEW)));
  });
});

describe('Reading profiles', () => {
  it('a student can read their own profile', async () => {
    await assertSucceeds(getDoc(doc(as(STUDENT), 'users', STUDENT.uid)));
  });
  it("a student cannot read another student's profile", async () => {
    await assertFails(getDoc(doc(as(STUDENT), 'users', OTHER.uid)));
  });
  it('a student cannot list all users', async () => {
    await assertFails(getDocs(collection(as(STUDENT), 'users')));
  });
  it('staff cannot list all users', async () => {
    await assertFails(getDocs(collection(as(STAFF), 'users')));
  });
  it('a signed-out visitor cannot read any profile', async () => {
    await assertFails(getDoc(doc(anon(), 'users', STUDENT.uid)));
  });
  it('an admin can list all users (FR9)', async () => {
    await assertSucceeds(getDocs(collection(as(ADMIN), 'users')));
  });
});

describe('Changing profiles and roles (FR9)', () => {
  it('a student can change their own name', async () => {
    await assertSucceeds(updateDoc(doc(as(STUDENT), 'users', STUDENT.uid), { fullName: 'New Name' }));
  });
  it('a student cannot make themselves admin', async () => {
    await assertFails(updateDoc(doc(as(STUDENT), 'users', STUDENT.uid), { role: 'admin' }));
  });
  it('a student cannot make themselves staff', async () => {
    await assertFails(updateDoc(doc(as(STUDENT), 'users', STUDENT.uid), { role: 'staff', serviceId: 'counselling' }));
  });
  it('a student cannot change their email', async () => {
    await assertFails(updateDoc(doc(as(STUDENT), 'users', STUDENT.uid), { email: 'x@student.test' }));
  });
  it("a student cannot change another student's name", async () => {
    await assertFails(updateDoc(doc(as(STUDENT), 'users', OTHER.uid), { fullName: 'Hacked' }));
  });
  it('staff cannot move themselves to another service', async () => {
    await assertFails(updateDoc(doc(as(STAFF), 'users', STAFF.uid), { serviceId: 'chaplaincy' }));
  });
  it('staff cannot change anyone\'s role', async () => {
    await assertFails(updateDoc(doc(as(STAFF), 'users', STUDENT.uid), { role: 'staff', serviceId: 'counselling' }));
  });
  it('an admin can make a student staff with a valid service', async () => {
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'users', STUDENT.uid), { role: 'staff', serviceId: 'counselling' }));
  });
  it('an admin cannot make someone staff without a service', async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'users', STUDENT.uid), { role: 'staff' }));
  });
  it('an admin cannot assign a service that does not exist', async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'users', STUDENT.uid), { role: 'staff', serviceId: 'made_up' }));
  });
  it('an admin cannot invent a new role', async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'users', STUDENT.uid), { role: 'superuser', serviceId: null }));
  });
  it('an admin can turn staff back into a student', async () => {
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'users', STAFF.uid), { role: 'student', serviceId: null }));
  });
  it('an admin cannot change their own role', async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'users', ADMIN.uid), { role: 'student', serviceId: null }));
  });
  it("an admin cannot edit a user's name or email", async () => {
    await assertFails(updateDoc(doc(as(ADMIN), 'users', STUDENT.uid), { fullName: 'Changed by admin' }));
  });
});

describe('Deleting and everything else', () => {
  it('nobody can delete a profile - not even an admin', async () => {
    await assertFails(deleteDoc(doc(as(STUDENT), 'users', STUDENT.uid)));
    await assertFails(deleteDoc(doc(as(ADMIN), 'users', STUDENT.uid)));
  });
  it('the old smoke_tests collection is now closed', async () => {
    await assertFails(setDoc(doc(as(STUDENT), 'smoke_tests', 't1'), { message: 'hi' }));
    await assertFails(getDoc(doc(anon(), 'smoke_tests', 't1')));
  });
  it('any collection without a rule is denied', async () => {
    await assertFails(setDoc(doc(as(ADMIN), 'anything', 'x'), { a: 1 }));
  });
});
