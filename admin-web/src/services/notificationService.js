// services/notificationService.js
import { db } from "../pages/firebase/firebase";
import { 
  collection, 
  addDoc, 
  query, 
  where, 
  orderBy,
  onSnapshot,
  updateDoc,
  doc,
  Timestamp,
  deleteDoc,
  getDocs
} from "firebase/firestore";

// Notification types for your system
export const NOTIFICATION_TYPES = {
  TENANT_APPLICATION: "tenant_application",
  MAINTENANCE_REQUEST: "maintenance_request",
  RENT_PAYMENT: "rent_payment",
  LEASE_EXPIRY: "lease_expiry",
  SYSTEM_ALERT: "system_alert",
  TENANT_MESSAGE: "tenant_message",
  INVOICE_DUE: "invoice_due",
  PROPERTY_ALERT: "property_alert"
};

// Priority levels
export const PRIORITY_LEVELS = {
  HIGH: "high",
  MEDIUM: "medium",
  LOW: "low"
};

// ====================
// CREATE NOTIFICATIONS
// ====================

/**
 * Create a new tenant application notification
 */
export const createTenantApplicationNotification = async (applicationData) => {
  try {
    const notification = {
      type: NOTIFICATION_TYPES.TENANT_APPLICATION,
      title: "New Tenant Application",
      message: `${applicationData.fullName} applied for ${applicationData.propertyName || "a property"}`,
      recipientId: "admin", // Or get from user session
      recipientType: "admin",
      read: false,
      priority: PRIORITY_LEVELS.HIGH,
      metadata: {
        applicationId: applicationData.id || applicationData.applicationId,
        propertyId: applicationData.propertyId,
        unitId: applicationData.unitId,
        applicantName: applicationData.fullName,
        applicantEmail: applicationData.email
      },
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)) // 30 days
    };

    const docRef = await addDoc(collection(db, "notifications"), notification);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error("Error creating tenant application notification:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Create a maintenance request notification
 */
export const createMaintenanceNotification = async (requestData) => {
  try {
    const notification = {
      type: NOTIFICATION_TYPES.MAINTENANCE_REQUEST,
      title: "New Maintenance Request",
      message: `${requestData.reportedBy || "Tenant"} reported: ${requestData.issue}`,
      recipientId: "admin",
      recipientType: "admin",
      read: false,
      priority: requestData.urgency === "emergency" ? PRIORITY_LEVELS.HIGH : PRIORITY_LEVELS.MEDIUM,
      metadata: {
        requestId: requestData.id,
        propertyId: requestData.propertyId,
        unitId: requestData.unitId,
        issue: requestData.issue,
        urgency: requestData.urgency || "normal"
      },
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)) // 14 days
    };

    await addDoc(collection(db, "notifications"), notification);
    return { success: true };
  } catch (error) {
    console.error("Error creating maintenance notification:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Create a rent payment notification
 */
export const createPaymentNotification = async (paymentData) => {
  try {
    const notification = {
      type: NOTIFICATION_TYPES.RENT_PAYMENT,
      title: "Rent Payment Received",
      message: `${paymentData.tenantName} paid KSh ${paymentData.amount?.toLocaleString()} for ${paymentData.month}`,
      recipientId: "admin",
      recipientType: "admin",
      read: false,
      priority: PRIORITY_LEVELS.LOW,
      metadata: {
        paymentId: paymentData.id,
        tenantId: paymentData.tenantId,
        amount: paymentData.amount,
        month: paymentData.month,
        propertyId: paymentData.propertyId
      },
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)) // 7 days
    };

    await addDoc(collection(db, "notifications"), notification);
    return { success: true };
  } catch (error) {
    console.error("Error creating payment notification:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Create a lease expiry warning notification
 */
export const createLeaseExpiryNotification = async (leaseData) => {
  try {
    const daysRemaining = leaseData.daysRemaining || 7;
    
    const notification = {
      type: NOTIFICATION_TYPES.LEASE_EXPIRY,
      title: "Lease Expiring Soon",
      message: `${leaseData.tenantName}'s lease expires in ${daysRemaining} day${daysRemaining === 1 ? '' : 's'}`,
      recipientId: "admin",
      recipientType: "admin",
      read: false,
      priority: daysRemaining <= 3 ? PRIORITY_LEVELS.HIGH : PRIORITY_LEVELS.MEDIUM,
      metadata: {
        tenantId: leaseData.tenantId,
        propertyId: leaseData.propertyId,
        unitId: leaseData.unitId,
        expiryDate: leaseData.expiryDate,
        daysRemaining: daysRemaining
      },
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)) // 30 days
    };

    await addDoc(collection(db, "notifications"), notification);
    return { success: true };
  } catch (error) {
    console.error("Error creating lease expiry notification:", error);
    return { success: false, error: error.message };
  }
};

// ====================
// NOTIFICATION QUERIES
// ====================

/**
 * Listen for real-time notifications
 */
export const listenForNotifications = (userId, callback) => {
  if (!userId) {
    console.error("No user ID provided for notification listener");
    return () => {};
  }

  const q = query(
    collection(db, "notifications"),
    where("recipientId", "==", userId),
    orderBy("createdAt", "desc")
  );

  const unsubscribe = onSnapshot(q, (snapshot) => {
    const notifications = [];
    snapshot.forEach((doc) => {
      notifications.push({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate?.() || new Date()
      });
    });
    callback(notifications);
  }, (error) => {
    console.error("Error listening to notifications:", error);
  });

  return unsubscribe;
};

/**
 * Get unread notification count
 */
export const getUnreadCount = async (userId) => {
  try {
    const q = query(
      collection(db, "notifications"),
      where("recipientId", "==", userId),
      where("read", "==", false)
    );
    
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error("Error getting unread count:", error);
    return 0;
  }
};

/**
 * Mark notification as read
 */
export const markAsRead = async (notificationId) => {
  try {
    await updateDoc(doc(db, "notifications", notificationId), {
      read: true,
      readAt: Timestamp.now()
    });
    return { success: true };
  } catch (error) {
    console.error("Error marking notification as read:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Mark all notifications as read
 */
export const markAllAsRead = async (userId) => {
  try {
    const q = query(
      collection(db, "notifications"),
      where("recipientId", "==", userId),
      where("read", "==", false)
    );
    
    const snapshot = await getDocs(q);
    const updates = snapshot.docs.map(docSnapshot => 
      updateDoc(doc(db, "notifications", docSnapshot.id), {
        read: true,
        readAt: Timestamp.now()
      })
    );
    
    await Promise.all(updates);
    return { success: true, count: snapshot.size };
  } catch (error) {
    console.error("Error marking all as read:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Delete old notifications (cleanup)
 */
export const deleteExpiredNotifications = async () => {
  try {
    const q = query(
      collection(db, "notifications"),
      where("expiresAt", "<", Timestamp.now())
    );
    
    const snapshot = await getDocs(q);
    const deletions = snapshot.docs.map(docSnapshot => 
      deleteDoc(doc(db, "notifications", docSnapshot.id))
    );
    
    await Promise.all(deletions);
    return { success: true, deleted: snapshot.size };
  } catch (error) {
    console.error("Error deleting expired notifications:", error);
    return { success: false, error: error.message };
  }
};