// notificationService.js - CORRECT VERSION
import { db } from '../pages/firebase/firebase';
import { 
  collection, 
  query, 
  where, 
  onSnapshot,
  addDoc,
  updateDoc,
  doc,
  Timestamp,
  getDocs
} from 'firebase/firestore';

// Listen for new tenant applications (for admin)
export const listenForNewApplications = (callback) => {
  const q = query(
    collection(db, 'tenantApplications'),
    where('status', '==', 'pending')
  );
  
  // This listens in REAL-TIME
  const unsubscribe = onSnapshot(q, (snapshot) => {
    const newApplications = [];
    snapshot.forEach((doc) => {
      newApplications.push({
        id: doc.id,
        ...doc.data(),
        // Convert Firestore timestamp to Date
        appliedDate: doc.data().appliedDate?.toDate()
      });
    });
    
    // Send to callback
    callback(newApplications);
  });
  
  return unsubscribe; // To stop listening later
};

// Create a notification (when someone applies)
export const createNotification = async (notificationData) => {
  try {
    const notification = {
      ...notificationData,
      read: false,
      createdAt: Timestamp.now(),
    };
    
    const docRef = await addDoc(collection(db, 'notifications'), notification);
    return { id: docRef.id, ...notification };
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

// Mark notification as read
export const markAsRead = async (notificationId) => {
  try {
    await updateDoc(doc(db, 'notifications', notificationId), {
      read: true,
      readAt: Timestamp.now(),
    });
    return true;
  } catch (error) {
    console.error('Error marking as read:', error);
    throw error;
  }
};

// Get pending applications count
export const getPendingApplicationsCount = async () => {
  try {
    const q = query(
      collection(db, 'tenantApplications'),
      where('status', '==', 'pending')
    );
    
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error getting count:', error);
    return 0;
  }
};