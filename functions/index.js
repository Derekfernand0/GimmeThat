const functions = require("firebase-functions/v1"); // <-- ¡ESTE ES EL CAMBIO MÁGICO! 🦋
const admin = require("firebase-admin");
admin.initializeApp();

// ============================================================================
// 1. ROBOT DE NOTIFICACIONES PUSH 🔔
// ============================================================================
exports.sendPushNotification = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
        const notificationData = snapshot.data();
        const userId = context.params.userId;

        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) return null;

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const settings = userData.notificationSettings || {};

        // REVISAMOS EL MENÚ DE CONFIGURACIÓN
        if (notificationData.type === 'mention' && settings.mentions === false) return console.log("Menciones apagadas");
        if (notificationData.type === 'newMember' && settings.newMembers === false) return console.log("Nuevos miembros apagados");
        if (notificationData.type === 'taskCompleted' && settings.taskCompleted === false) return console.log("Tareas completadas apagadas");

        if (!fcmToken) return console.log("El usuario no tiene token FCM");

        const message = {
            notification: {
                title: notificationData.title || "Nueva alerta",
                body: notificationData.message || "Tienes un mensaje nuevo 🦋",
            },
            token: fcmToken,
        };

        try {
            await admin.messaging().send(message);
            console.log("¡Notificación enviada con éxito!");
        } catch (error) {
            console.error("Error al enviar notificación:", error);
        }
        return null;
    });

// ============================================================================
// 2. ROBOT DE LIMPIEZA DE FOTOS (AHORRO DE ESPACIO) 🧹📸
// ============================================================================
exports.cleanupOldImages = functions.pubsub.schedule('0 3 * * *')
    .timeZone('America/Mexico_City')
    .onRun(async (context) => {
        const bucket = admin.storage().bucket();
        const now = Date.now();
        const thirtyDaysInMs = 30 * 24 * 60 * 60 * 1000; 

        console.log("Iniciando limpieza de fotos viejas...");

        const [files] = await bucket.getFiles();
        const deletePromises = [];

        files.forEach(file => {
            const metadata = file.metadata;
            const timeCreated = new Date(metadata.timeCreated).getTime();

            if (now - timeCreated > thirtyDaysInMs) {
                console.log(`Borrando foto caducada: ${file.name}`);
                deletePromises.push(file.delete());
            }
        });

        await Promise.all(deletePromises);
        console.log("¡Limpieza terminada con éxito! 🌸");
        return null;
    });