const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { projectMapReport, syncMapReport } = require('./map_report');

async function main() {
  const [projectId, flag, ...extra] = process.argv.slice(2);
  if (!projectId || (flag !== undefined && flag !== '--apply') || extra.length) {
    throw new Error('Usage: node backfill.js PROJECT_ID [--apply]');
  }

  const db = getFirestore(initializeApp({ projectId }));
  const apply = flag === '--apply';
  let eligible = 0;
  const reports = db.collection('reports').select('location', 'locationSource');

  for await (const report of reports.stream()) {
    if (projectMapReport(report.data()) === null) continue;
    if (apply) await syncMapReport(db, report.id);
    eligible += 1;
  }

  console.log(`${projectId}: ${eligible} eligible reports (${apply ? 'synced' : 'preview only'}).`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
