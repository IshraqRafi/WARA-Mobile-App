import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import assert from 'node:assert/strict';
import { doc, getDoc, setDoc, updateDoc, getDocs, collection, writeBatch, serverTimestamp, deleteDoc, addDoc, query, orderBy, limit, where } from 'firebase/firestore';

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

test('revisionChecks: claimed editor or manager only', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), 'projects/p1'), { status: 'claimed', claimedByEditorId: 'eA' }));
  await assertFails(updateDoc(doc(as('eA2'), 'projects/p1'), { revisionChecks: [0] }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'projects/p1'), { revisionChecks: [0, 1] }));
  await assertSucceeds(updateDoc(doc(as('mA'), 'projects/p1'), { revisionNotes: 'x', revisionChecks: [] }));
});

test('availability: editor sets own to available/busy; nobody else', async () => {
  await assertSucceeds(updateDoc(doc(as('eA'), 'users/eA'), { availability: 'busy' }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'users/eA'), { availability: 'available' }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { availability: 'away' }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { availability: true }));
  await assertFails(updateDoc(doc(as('eA2'), 'users/eA'), { availability: 'busy' }));
  await assertFails(updateDoc(doc(as('mA'), 'users/eA'), { availability: 'busy' }));
  await assertFails(updateDoc(doc(as('mA'), 'users/mA'), { availability: 'busy' }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA'), { availability: 'busy', rating: 5 }));
});

const notif = (fromUid, extra = {}) => ({
  type: 'revision', projectId: 'p1', title: 'Revision requested', body: 'Fix audio',
  fromUid, createdAt: serverTimestamp(), read: false, ...extra,
});

test('notifications: manager -> own editor; editor -> own manager (message/submitted)', async () => {
  await assertSucceeds(setDoc(doc(as('mA'), 'users/eA/notifications/n1'), notif('mA')));
  await assertSucceeds(setDoc(doc(as('mA'), 'users/eA/notifications/n2'), notif('mA', { type: 'assigned' })));
  await assertSucceeds(setDoc(doc(as('eA'), 'users/mA/notifications/n3'), notif('eA', { type: 'submitted' })));
  await assertSucceeds(setDoc(doc(as('eA'), 'users/mA/notifications/n4'), notif('eA', { type: 'message', chatId: 'dm_mA_eA' })));
  // editors cannot send manager-only types, nor notify other editors
  await assertFails(setDoc(doc(as('eA'), 'users/mA/notifications/n5'), notif('eA', { type: 'approved' })));
  await assertFails(setDoc(doc(as('eA'), 'users/eA2/notifications/n6'), notif('eA', { type: 'message' })));
});

test('notifications: cross-agency write denied', async () => {
  await assertFails(setDoc(doc(as('mB'), 'users/eA/notifications/x'), notif('mB')));
  await assertFails(setDoc(doc(as('eB'), 'users/mA/notifications/x'), notif('eB', { type: 'message' })));
});

test('notifications: fromUid spoofing and bad fields denied', async () => {
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s1'), notif('mB')));
  await assertFails(setDoc(doc(as('eA2'), 'users/mA/notifications/s2'), notif('eA', { type: 'message' })));
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s3'), notif('mA', { type: 'spam' })));
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s4'), notif('mA', { read: true })));
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s5'), notif('mA', { extra: 1 })));
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s6'), notif('mA', { title: '' })));
  await assertFails(setDoc(doc(as('mA'), 'users/eA/notifications/s7'), notif('mA', { createdAt: new Date(0) })));
});

test('notifications: only the recipient reads, marks read, deletes', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/eA/notifications/r1'), { ...notif('mA'), createdAt: new Date() });
  });
  await assertSucceeds(getDoc(doc(as('eA'), 'users/eA/notifications/r1')));
  await assertFails(getDoc(doc(as('mA'), 'users/eA/notifications/r1')));
  await assertFails(getDoc(doc(as('eA2'), 'users/eA/notifications/r1')));
  await assertFails(getDocs(collection(as('eA2'), 'users/eA/notifications')));
  await assertFails(updateDoc(doc(as('mA'), 'users/eA/notifications/r1'), { read: true }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA/notifications/r1'), { title: 'x' }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'users/eA/notifications/r1'), { read: true }));
  await assertFails(deleteDoc(doc(as('mA'), 'users/eA/notifications/r1')));
  await assertSucceeds(deleteDoc(doc(as('eA'), 'users/eA/notifications/r1')));
});

test('legacy agency notifications are locked', async () => {
  await assertFails(getDocs(collection(as('eA'), 'agencies/A/notifications')));
  await assertFails(setDoc(doc(as('mA'), 'agencies/A/notifications/x'), { title: 't' }));
});

test('claim race: second editor cannot take a claimed project; no claiming for others', async () => {
  const claim = (uid) => ({ claimedByEditorId: uid, claimedByEditorName: uid, status: 'claimed' });
  await assertFails(updateDoc(doc(as('eA'), 'projects/p1'), claim('eA2')));
  await assertSucceeds(updateDoc(doc(as('eA'), 'projects/p1'), claim('eA')));
  await assertFails(updateDoc(doc(as('eA2'), 'projects/p1'), claim('eA2')));
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'projects/p2'), { agencyId: 'A', title: 'Q', status: 'approved' }));
  await assertFails(updateDoc(doc(as('eA2'), 'projects/p2'), claim('eA2')));
});

const payout = (over = {}) => ({ projectTitle: 'P', method: 'bkash', mode: 'test', trxId: 'BKA1B2C3D4E5', amount: 1200,
  editorId: 'eA', wallet: '017*****678', paidAt: serverTimestamp(), paidBy: 'mA', ...over });

test('payouts: agency manager creates once; editors and other agencies cannot write', async () => {
  await assertFails(setDoc(doc(as('eA'), 'agencies/A/payouts/p1'), payout({ paidBy: 'eA' })));
  await assertFails(setDoc(doc(as('mB'), 'agencies/A/payouts/p1'), payout({ paidBy: 'mB' })));
  await assertFails(setDoc(doc(as('mA'), 'agencies/A/payouts/p1'), payout({ mode: 'live' })));
  await assertFails(setDoc(doc(as('mA'), 'agencies/A/payouts/p1'), payout({ trxId: 'nope' })));
  await assertFails(setDoc(doc(as('mA'), 'agencies/A/payouts/p1'), payout({ paidBy: 'eA' })));
  await assertSucceeds(setDoc(doc(as('mA'), 'agencies/A/payouts/p1'), payout()));
  await assertFails(updateDoc(doc(as('mA'), 'agencies/A/payouts/p1'), { amount: 5 }));
  await assertFails(deleteDoc(doc(as('mA'), 'agencies/A/payouts/p1')));
});

test('payouts: manager and the paid editor read; other editors cannot', async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'agencies/A/payouts/p1'), payout({ paidAt: new Date() })));
  await assertSucceeds(getDoc(doc(as('mA'), 'agencies/A/payouts/p1')));
  await assertSucceeds(getDoc(doc(as('eA'), 'agencies/A/payouts/p1')));
  await assertFails(getDoc(doc(as('eA2'), 'agencies/A/payouts/p1')));
  await assertFails(getDoc(doc(as('mB'), 'agencies/A/payouts/p1')));
  const { query, where } = await import('firebase/firestore');
  await assertSucceeds(getDocs(query(collection(as('eA'), 'agencies/A/payouts'), where('editorId', '==', 'eA'))));
  await assertFails(getDocs(collection(as('eA'), 'agencies/A/payouts')));
});

test('notifications: manager may send payment to own editor; editor may not', async () => {
  const n = (from) => ({ type: 'payment', title: 'Payment received', body: 'x', fromUid: from, createdAt: serverTimestamp(), read: false });
  await assertSucceeds(setDoc(doc(as('mA'), 'users/eA/notifications/pay1'), n('mA')));
  await assertFails(setDoc(doc(as('eA'), 'users/mA/notifications/pay2'), n('eA')));
});

test('notifications: every type, both directions, as the app writes them (addDoc)', async () => {
  for (const type of ['revision', 'approved', 'message', 'assigned', 'payment']) {
    await assertSucceeds(addDoc(collection(as('mA'), 'users/eA/notifications'), notif('mA', { type })));
  }
  for (const type of ['message', 'submitted']) {
    await assertSucceeds(addDoc(collection(as('eA'), 'users/mA/notifications'), notif('eA', { type })));
  }
  // agency-room message from editor to manager (chatId = channel)
  await assertSucceeds(addDoc(collection(as('eA'), 'users/mA/notifications'),
    { type: 'message', chatId: 'agency_general', title: 'Message from E', body: 'hi', fromUid: 'eA', createdAt: serverTimestamp(), read: false }));
  // recipient's bell query (orderBy createdAt, limit 50) is allowed
  await assertSucceeds(getDocs(query(collection(as('mA'), 'users/mA/notifications'), orderBy('createdAt', 'desc'), limit(50))));
  await assertSucceeds(getDocs(query(collection(as('eA'), 'users/eA/notifications'), orderBy('createdAt', 'desc'), limit(50))));
});

test('notifications: manager logs own payment receipt; nothing else self-written', async () => {
  await assertSucceeds(addDoc(collection(as('mA'), 'users/mA/notifications'), notif('mA', { type: 'payment', title: 'Paid · Reel' })));
  await assertFails(addDoc(collection(as('mA'), 'users/mA/notifications'), notif('mA', { type: 'approved' })));
  await assertFails(addDoc(collection(as('eA'), 'users/eA/notifications'), notif('eA', { type: 'payment' })));
  await assertFails(addDoc(collection(as('mA'), 'users/mA/notifications'), notif('mB', { type: 'payment' })));
});

test('archive: only the agency manager may set the archived flag', async () => {
  const arch = { archived: true, archivedAt: serverTimestamp() };
  await assertFails(updateDoc(doc(as('eA'), 'projects/p1'), arch));
  await assertFails(updateDoc(doc(as('mB'), 'projects/p1'), arch));
  await assertFails(updateDoc(doc(as('mA'), 'projects/p1'), { archived: 'yes' }));
  await assertSucceeds(updateDoc(doc(as('mA'), 'projects/p1'), arch));
  await assertFails(updateDoc(doc(as('eA'), 'projects/p1'), { archived: false }));
  await assertSucceeds(getDoc(doc(as('mA'), 'projects/p1'))); // data kept
});

test('create: the exact app payload, project then finance (4th project)', async () => {
  const db = as('mA');
  for (let i = 0; i < 4; i++) {
    const id = `p_${1760000000000 + i}`;
    await assertSucceeds(setDoc(doc(db, `projects/${id}`), {
      agencyId: 'A', title: `T${i}`, clientName: 'Direct client', editorPayout: 1500,
      deadlineStr: '5 Days Left (120 Hours)', deadlineHoursLeft: 120, description: '',
      requiredSkills: ['Video Editing'], claimedByEditorId: null, claimedByEditorName: null,
      claimedAt: null, status: 'open', submissionLink: null, submissionNote: null,
      submittedAt: null, isOverdue: false, deadlineAt: new Date().toISOString(), postedAt: new Date().toISOString(),
    }));
    await assertSucceeds(setDoc(doc(db, `projects/${id}/private/finance`),
      { clientPrice: 5000, currency: 'BDT', updatedAt: serverTimestamp(), updatedBy: 'mA' }));
  }
  await assertFails(setDoc(doc(db, 'projects/p_arch'), { agencyId: 'A', title: 'x', archived: true }));
  const snap = await getDocs(query(collection(db, 'projects'), where('agencyId', '==', 'A')));
  assert.equal(snap.size, 5);
});

test('notifications: owner may delete own; others may not; update only read', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/eA/notifications/n1'), { type: 'revision', title: 't', body: '', fromUid: 'mA', createdAt: new Date(), read: false });
  });
  await assertFails(deleteDoc(doc(as('mA'), 'users/eA/notifications/n1')));
  await assertFails(deleteDoc(doc(as('eA2'), 'users/eA/notifications/n1')));
  await assertFails(updateDoc(doc(as('mA'), 'users/eA/notifications/n1'), { read: true }));
  await assertFails(updateDoc(doc(as('eA'), 'users/eA/notifications/n1'), { read: true, title: 'x' }));
  await assertSucceeds(updateDoc(doc(as('eA'), 'users/eA/notifications/n1'), { read: true }));
  // retention query used by the client purge
  await assertSucceeds(getDocs(query(collection(as('eA'), 'users/eA/notifications'), where('createdAt', '<', new Date()), limit(400))));
  const dbA = as('eA');
  const b = writeBatch(dbA);
  b.delete(doc(dbA, 'users/eA/notifications/n1'));
  await assertSucceeds(b.commit());
});
