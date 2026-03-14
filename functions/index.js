const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// ============================================================================
// 1. ROBOT DE NOTIFICACIONES PUSH (RESPETUOSO) 🔔🤫
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
        const mutedGroups = userData.mutedGroups || []; // <-- Lista de grupos silenciados

        // 1. REVISAMOS SI EL GRUPO ESTÁ SILENCIADO 🔇
        if (notificationData.groupId && mutedGroups.includes(notificationData.groupId)) {
            console.log(`Grupo ${notificationData.groupId} está silenciado. No molestaremos al usuario.`);
            return null; // Detenemos la notificación push
        }

        // 2. REVISAMOS EL MENÚ DE CONFIGURACIÓN ⚙️ (Todas las opciones)
        const type = notificationData.type;
        if (type === 'mention' && settings.mentions === false) return console.log("Menciones apagadas");
        if (type === 'newMember' && settings.newMembers === false) return console.log("Nuevos miembros apagados");
        if (type === 'taskCompleted' && settings.taskCompleted === false) return console.log("Tareas completadas apagadas");
        if (type === 'newTask' && settings.newTasks === false) return console.log("Nuevas tareas apagadas");
        if (type === 'newComment' && settings.newComments === false) return console.log("Nuevos comentarios apagados");
        if (type === 'taskExpiring' && settings.taskExpiring === false) return console.log("Vencimientos urgentes apagados");

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

// ============================================================================
// 3. ROBOT VIGILANTE DE TAREAS URGENTES (Queda 1 día) ⏳
// ============================================================================
exports.checkExpiringTasks = functions.pubsub.schedule('0 8 * * *') // Todos los días a las 8:00 AM
    .timeZone('America/Mexico_City')
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = new Date();
        
        // Calculamos la fecha de mañana
        const tomorrow = new Date(now);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(23, 59, 59, 999); // Hasta el final del día de mañana

        console.log("Buscando tareas que vencen pronto...");

        // Buscamos las tareas cuya fecha límite es antes de "mañana en la noche"
        // y que aún no estén marcadas como "isCompleted: true" a nivel general
        const snapshot = await db.collection("tasks")
            .where("deadline", "<=", tomorrow)
            .where("deadline", ">=", now) // Que no hayan caducado ya
            .get();

        if (snapshot.empty) {
            console.log("No hay tareas urgentes hoy.");
            return null;
        }

        const batch = db.batch();

        for (const doc of snapshot.docs) {
            const task = doc.data();
            const completedBy = task.completedBy || [];
            const groupId = task.groupId;
            const taskTitle = task.title;

            // Buscamos a los miembros del grupo
            const groupDoc = await db.collection("groups").doc(groupId).get();
            if (!groupDoc.exists) continue;

            const groupName = groupDoc.data().name || "un grupo";
            const members = groupDoc.data().members || [];

            // A cada miembro que NO haya completado la tarea, le mandamos alerta
            for (const memberId of members) {
                if (!completedBy.includes(memberId)) {
                    const notifRef = db.collection("users").doc(memberId).collection("notifications").doc();
                    batch.set(notifRef, {
                        type: 'taskExpiring',
                        title: `¡Se acaba el tiempo en ${groupName}! ⚠️`,
                        message: `La tarea "${taskTitle}" vence mañana y aún no la has marcado como lista.`,
                        taskId: doc.id,
                        groupId: groupId,
                        taskTitle: taskTitle,
                        groupName: groupName,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false
                    });
                }
            }
        }

        // Ejecutamos todos los envíos
        await batch.commit();
        console.log("¡Alertas de tareas urgentes enviadas! 🏃‍♀️💨");
        return null;
    });

// ============================================================================
// 4. ROBOT LIMPIADOR DE FOTOS (Borra fotos de tareas vencidas) 🧹📸
// ============================================================================
exports.cleanupExpiredPhotos = functions.pubsub.schedule('0 2 * * *') // Todos los días a las 2:00 AM
    .timeZone('America/Mexico_City')
    .onRun(async (context) => {
        const db = admin.firestore();
        const storage = admin.storage().bucket(); // Conectamos con Firebase Storage
        const now = new Date();

        console.log("Buscando tareas vencidas para limpiar sus fotos...");

        // Buscamos tareas cuya fecha límite ya pasó (ayer o antes)
        const snapshot = await db.collection("tasks")
            .where("deadline", "<", now)
            .get();

        if (snapshot.empty) {
            console.log("No hay tareas vencidas para limpiar hoy.");
            return null;
        }

        let photosDeletedCount = 0;

        for (const doc of snapshot.docs) {
            const task = doc.data();
            const imageUrls = task.imageUrls || [];

            // Si la tarea vencida aún tiene fotos guardadas...
            if (imageUrls.length > 0) {
                console.log(`Limpiando fotos de la tarea: ${task.title}`);
                
                for (const url of imageUrls) {
                    try {
                        // Magia para extraer la ruta exacta del archivo desde la URL larguísima
                        const decodedUrl = decodeURIComponent(url);
                        const startIndex = decodedUrl.indexOf('/o/') + 3;
                        const endIndex = decodedUrl.indexOf('?');
                        
                        if (startIndex > 2 && endIndex > -1) {
                            const filePath = decodedUrl.substring(startIndex, endIndex);
                            // ¡Borramos la foto físicamente del Storage para liberar espacio!
                            await storage.file(filePath).delete();
                            photosDeletedCount++;
                        }
                    } catch (error) {
                        console.error(`Error borrando foto ${url}:`, error);
                    }
                }

                // Actualizamos la tarea en la base de datos para quitarle las fotos visualmente
                await db.collection("tasks").doc(doc.id).update({
                    imageUrls: [] // Vaciamos la lista de fotos
                });
            }
        }

        console.log(`¡Limpieza completada! Se borraron ${photosDeletedCount} fotos de tareas vencidas. 🧹✨`);
        return null;
    });