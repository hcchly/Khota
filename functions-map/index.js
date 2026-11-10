const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { syncMapReport } = require('./map_report');

const db = getFirestore(initializeApp());

exports.syncKhotaMapReport = onDocumentWritten(
  { document: 'reports/{reportId}', retry: true },
  (event) => syncMapReport(db, event.params.reportId),
);
