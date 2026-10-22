import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, getDocs, collection, writeBatch } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-wara',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'agencies/A'), { name: 'Alpha', managerUid: 'mA', joinKey: 'ALPHA-1234' });
    await setDoc(doc(db, 'agencies/B'), { name: 'Beta', managerUid: 'mB', joinKey: 'BETA-5678' });
    await setDoc(doc(db, 'joinKeys/ALPHA-1234'), { agencyId: 'A', agencyName: 'Alpha' });
    await setDoc(doc(db, 'users/mA'), { role: 'manager', agencyId: 'A', agencyJoinKey: 'ALPHA-1234' });
    await setDoc(doc(db, 'users/mB'), { role: 'manager', agencyId: 'B', agencyJoinKey: 'BETA-5678' });
    await setDoc(doc(db, 'users/eA'), { role: 'editor', agencyId: 'A', agencyJoinKey: 'ALPHA-1234' });
    await setDoc(doc(db, 'users/eB'), { role: 'editor', agencyId: 'B', agencyJoinKey: 'BETA-5678' });
    await setDoc(doc(db, 'users/new'), { role: 'editor' });
    await setDoc(doc(db, 'projects/p1'), { agencyId: 'A', title: 'P', status: 'open', budget: 100 });
    await setDoc(doc(db, 'projects/p1/private/finance'), { clientPrice: 500, currency: 'BDT' });
    await setDoc(doc(db, 'users/eA2'), { role: 'editor', agencyId: 'A', agencyJoinKey: 'ALPHA-1234' });
    await setDoc(doc(db, 'agencies/A/conversations/dm_mA_eA'), { type: 'dm', participantIds: ['mA', 'eA'] });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

test('editor cannot read private finance; manager can', async () => {
  await assertFails(getDoc(doc(as('eA'), 'projects/p1/private/finance')));
  await assertSucceeds(getDoc(doc(as('mA'), 'projects/p1/private/finance')));
});

test('editor cannot write private finance', async () => {
  await assertFails(setDoc(doc(as('eA'), 'projects/p1/private/finance'), { clientPrice: 1 }));
});

test('cross-agency manager blocked from finance and project', async () => {
  await assertFails(getDoc(doc(as('mB'), 'projects/p1/private/finance')));
  await assertFails(getDoc(doc(as('mB'), 'projects/p1')));
  await assertFails(getDoc(doc(as('eB'), 'projects/p1')));
});

test('agency docs private to members; joinKeys get-only', async () => {
  await assertFails(getDoc(doc(as('eB'), 'agencies/A')));
  await assertSucceeds(getDoc(doc(as('eA'), 'agencies/A')));
  await assertSucceeds(getDoc(doc(as('new'), 'joinKeys/ALPHA-1234')));
  await assertFails(getDocs(collection(as('new'), 'joinKeys')));
});

test('editor joins only with the current key', async () => {
  await assertFails(updateDoc(doc(as('new'), 'users/new'), { agencyId: 'A', agencyJoinKey: 'WRONG' }));
  await assertFails(updateDoc(doc(as('new'), 'users/new'), { agencyId: 'A' }));
  await assertSucceeds(updateDoc(doc(as('new'), 'users/new'), { agencyId: 'A', agencyJoinKey: 'ALPHA-1234' }));
});

test('agencyId and role are locked', async () => {
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { agencyId: 'B', agencyJoinKey: 'BETA-5678' }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { role: 'manager' }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { rating: 5 }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'users/eA'), { name: 'Ok' }));
});

test('cannot self-create as manager of someone else\'s agency', async () => {
  await assertFails(setDoc(doc(as('x'), 'users/x'), { role: 'manager', agencyId: 'A' }));
  await assertFails(setDoc(doc(as('x'), 'users/x'), { role: 'admin' }));
  await assertSucceeds(setDoc(doc(as('x'), 'users/x'), { role: 'editor' }));
});

test('manager creates agency + key, regenerates key', async () => {
  const db = as('mC');
  const b = writeBatch(db);
  b.set(doc(db, 'agencies/C'), { name: 'C', managerUid: 'mC', joinKey: 'C-1' });
  b.set(doc(db, 'joinKeys/C-1'), { agencyId: 'C', agencyName: 'C' });
  await assertSucceeds(b.commit());
  await assertSucceeds(setDoc(doc(db, 'users/mC'), { role: 'manager', agencyId: 'C', agencyJoinKey: 'C-1' }));
  // someone else cannot mint a key for C
  await assertFails(setDoc(doc(as('eA'), 'joinKeys/C-2'), { agencyId: 'C', agencyName: 'C' }));
  const r = writeBatch(db);
  r.update(doc(db, 'agencies/C'), { joinKey: 'C-2' });
  r.set(doc(db, 'joinKeys/C-2'), { agencyId: 'C', agencyName: 'C' });
  r.delete(doc(db, 'joinKeys/C-1'));
  await assertSucceeds(r.commit());
  // key not matching the agency's joinKey is rejected
  await assertFails(setDoc(doc(db, 'joinKeys/FAKE'), { agencyId: 'C', agencyName: 'C' }));
});

test('DM: only participants read', async () => {
  const p = 'agencies/A/conversations/dm_mA_eA';
  await assertSucceeds(getDoc(doc(as('eA'), p)));
  await assertFails(getDoc(doc(as('eA2'), p)));  // same agency, not a participant
  await assertFails(getDoc(doc(as('mB'), p)));   // other agency
});

test('submissionVersion: +1 on submit by the claimed editor only', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), 'projects/p1'), { status: 'claimed', claimedByEditorId: 'eA', submissionVersion: 1 }));
  await assertFails(updateDoc(doc(as('eA'), 'projects/p1'), { status: 'submitted', submissionVersion: 3 }));
  await assertFails(updateDoc(doc(as('eA2'), 'projects/p1'), { status: 'submitted', submissionVersion: 2 }));
  await assertFails(updateDoc(doc(as('eA'), 'projects/p1'), { status: 'claimed', submissionVersion: 2 }));
  await assertFails(updateDoc(doc(as('mA'), 'projects/p1'), { submissionVersion: 0 }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'projects/p1'), { status: 'submitted', submissionVersion: 2 }));
  await assertSucceeds(updateDoc(doc(as('mA'), 'projects/p1'), { status: 'approved' }));
});
