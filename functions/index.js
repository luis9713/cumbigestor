const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

async function sendNotification(toUserId, title, body) {
  try {
    console.log(`Intentando enviar notificación a ${toUserId}`);
    const userDoc = await getFirestore().collection('users').doc(toUserId).get();
    if (!userDoc.exists) {
      console.log(`Usuario ${toUserId} no encontrado`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`Token FCM no encontrado para el usuario ${toUserId}`);
      return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
    };

    await getMessaging().send(message);
    console.log(`Notificación enviada a ${toUserId}`);
  } catch (error) {
    console.error('Error enviando notificación:', error);
  }
}

exports.notifyAdminOnSolicitudCreated = onDocumentCreated(
  'solicitudes_educacion/{solicitudId}',
  async (event) => {
    console.log('Nueva solicitud creada en solicitudes_educacion');
    const solicitud = event.data.data();
    const userId = solicitud.uid;
    const adminId = getAdminIdForCollection('solicitudes_educacion');

    console.log(`Usuario creador: ${userId}, Administrador asignado: ${adminId}`);

    const userDoc = await getFirestore().collection('users').doc(userId).get();
    const userName = userDoc.exists ? userDoc.data().name || 'Un usuario' : 'Un usuario';

    await sendNotification(
      adminId,
      'Nueva solicitud recibida',
      `${userName} ha enviado una solicitud en Educación.`
    );
  }
);

exports.notifyAdminOnSolicitudDeporteCreated = onDocumentCreated(
  'solicitudes_deporte/{solicitudId}',
  async (event) => {
    console.log('Nueva solicitud creada en solicitudes_deporte');
    const solicitud = event.data.data();
    const userId = solicitud.uid;
    const adminId = getAdminIdForCollection('solicitudes_deporte');

    console.log(`Usuario creador: ${userId}, Administrador asignado: ${adminId}`);

    const userDoc = await getFirestore().collection('users').doc(userId).get();
    const userName = userDoc.exists ? userDoc.data().name || 'Un usuario' : 'Un usuario';

    await sendNotification(
      adminId,
      'Nueva solicitud recibida',
      `${userName} ha enviado una solicitud en Deporte.`
    );
  }
);

exports.notifyAdminOnSolicitudCulturaCreated = onDocumentCreated(
  'solicitudes_cultura/{solicitudId}',
  async (event) => {
    console.log('Nueva solicitud creada en solicitudes_cultura');
    const solicitud = event.data.data();
    const userId = solicitud.uid;
    const adminId = getAdminIdForCollection('solicitudes_cultura');

    console.log(`Usuario creador: ${userId}, Administrador asignado: ${adminId}`);

    const userDoc = await getFirestore().collection('users').doc(userId).get();
    const userName = userDoc.exists ? userDoc.data().name || 'Un usuario' : 'Un usuario';

    await sendNotification(
      adminId,
      'Nueva solicitud recibida',
      `${userName} ha enviado una solicitud en Cultura.`
    );
  }
);

exports.notifyUserOnSolicitudStatusChange = onDocumentUpdated(
  'solicitudes_educacion/{solicitudId}',
  async (event) => {
    console.log('Cambio de estado detectado en solicitudes_educacion');
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (newData.estado !== oldData.estado) {
      const userId = newData.uid;
      console.log(`Enviando notificación a usuario ${userId} por cambio de estado a ${newData.estado}`);
      await sendNotification(
        userId,
        'Actualización de solicitud',
        `El estado de tu solicitud ha cambiado a: ${newData.estado}`
      );
    }
  }
);

exports.notifyUserOnSolicitudDeporteStatusChange = onDocumentUpdated(
  'solicitudes_deporte/{solicitudId}',
  async (event) => {
    console.log('Cambio de estado detectado en solicitudes_deporte');
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (newData.estado !== oldData.estado) {
      const userId = newData.uid;
      console.log(`Enviando notificación a usuario ${userId} por cambio de estado a ${newData.estado}`);
      await sendNotification(
        userId,
        'Actualización de solicitud',
        `El estado de tu solicitud ha cambiado a: ${newData.estado}`
      );
    }
  }
);

exports.notifyUserOnSolicitudCulturaStatusChange = onDocumentUpdated(
  'solicitudes_cultura/{solicitudId}',
  async (event) => {
    console.log('Cambio de estado detectado en solicitudes_cultura');
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (newData.estado !== oldData.estado) {
      const userId = newData.uid;
      console.log(`Enviando notificación a usuario ${userId} por cambio de estado a ${newData.estado}`);
      await sendNotification(
        userId,
        'Actualización de solicitud',
        `El estado de tu solicitud ha cambiado a: ${newData.estado}`
      );
    }
  }
);

function getAdminIdForCollection(collectionName) {
  const adminMapping = {
    'solicitudes_educacion': 'A3zwu7ksPzZQ0BLoYHSO46jUFy03',
    'solicitudes_deporte': 'QCYtuiLFcnTAYLSPtUAolgVCQBg2',
    'solicitudes_cultura': 'uid_admin_cultura',
  };
  return adminMapping[collectionName] || 'default_admin_id';
}