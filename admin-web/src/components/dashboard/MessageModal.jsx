// components/dashboard/MessageModal.jsx
import React, { useState, useEffect } from "react";
import { 
  FaBuilding, 
  FaUsers, 
  FaArrowLeft, 
  FaPaperPlane, 
  FaSpinner, 
  FaTimes,
  FaUserTie,
  FaUser
} from "react-icons/fa";
import { 
  collection, 
  getDocs, 
  addDoc, 
  serverTimestamp, 
  query, 
  where 
} from "firebase/firestore";
import { db } from "../../pages/firebase/firebase";
import "../../styles/messageModal.css";

const MessageModal = ({ isOpen, onClose }) => {
  const [step, setStep] = useState("selectType");
  const [messageType, setMessageType] = useState("");
  const [recipients, setRecipients] = useState([]);
  const [selectedRecipient, setSelectedRecipient] = useState("");
  const [message, setMessage] = useState("");
  const [subject, setSubject] = useState("");
  const [loading, setLoading] = useState(false);
  const [loadingRecipients, setLoadingRecipients] = useState(false);

  useEffect(() => {
    if (isOpen && messageType && step === "composeMessage") {
      fetchRecipients();
    }
  }, [isOpen, messageType, step]);

  const fetchRecipients = async () => {
    setLoadingRecipients(true);
    try {
      let recipientsList = [];
      
      if (messageType === 'landlord') {
        console.log("📋 Fetching landlords...");
        
        // Fetch from landlords collection
        const querySnapshot = await getDocs(collection(db, 'landlords'));
        console.log(`✅ Found ${querySnapshot.size} landlords`);
        
        recipientsList = querySnapshot.docs.map(doc => {
          const data = doc.data();
          const fullName = data.name || `${data.firstName || ''} ${data.lastName || ''}`.trim();
          
          return {
            id: doc.id,
            name: fullName || "Unnamed Landlord",
            email: data.email || "",
            phone: data.phone || "",
            type: "landlord",
            ...data
          };
        });
        
      } else if (messageType === 'tenant') {
        console.log("📋 Fetching tenants...");
        
        // Fetch from users collection where role = "tenant"
        const usersRef = collection(db, 'users');
        const q = query(usersRef, where("role", "==", "tenant"));
        const querySnapshot = await getDocs(q);
        
        console.log(`✅ Found ${querySnapshot.size} tenants`);
        
        recipientsList = querySnapshot.docs.map(doc => {
          const data = doc.data();
          const fullName = data.name || `${data.firstName || ''} ${data.lastName || ''}`.trim();
          
          return {
            id: doc.id,
            name: fullName || "Unnamed Tenant",
            email: data.email || "",
            phone: data.phone || "",
            type: "tenant",
            ...data
          };
        });
      }
      
      console.log("📊 Recipients list:", recipientsList);
      setRecipients(recipientsList);
      
    } catch (error) {
      console.error("❌ Error fetching recipients:", error);
      alert(`Failed to load recipients: ${error.message}\n\nCheck Firestore rules.`);
    } finally {
      setLoadingRecipients(false);
    }
  };

  const handleSelectType = (type) => {
    setMessageType(type);
    setStep("composeMessage");
  };

  const handleSendMessage = async () => {
    if (!selectedRecipient || !message.trim()) {
      alert("Please select a recipient and enter a message");
      return;
    }

    setLoading(true);
    try {
      const selectedRecipientData = recipients.find(r => r.id === selectedRecipient);
      
      const messageData = {
        recipientId: selectedRecipient,
        recipientType: messageType,
        recipientName: selectedRecipientData?.name || "Unknown",
        recipientEmail: selectedRecipientData?.email || "",
        recipientPhone: selectedRecipientData?.phone || "",
        subject: subject || `Message from Admin - ${new Date().toLocaleDateString()}`,
        message: message,
        sender: 'Admin',
        senderId: 'admin',
        status: 'sent',
        createdAt: serverTimestamp(),
        read: false
      };

      console.log("📤 Sending message:", messageData);

      // 1. Save to global messages collection
      const messageRef = await addDoc(collection(db, 'messages'), messageData);
      console.log("✅ Message saved to global collection:", messageRef.id);

      // 2. Also save to recipient's messages subcollection
      if (messageType === 'landlord') {
        // Save to landlord's messages subcollection
        await addDoc(
          collection(db, 'landlords', selectedRecipient, 'messages'),
          {
            ...messageData,
            messageId: messageRef.id,
            receivedAt: serverTimestamp()
          }
        );
        console.log("✅ Message saved to landlord's subcollection");
      } else {
        // Save to user's messages subcollection (for tenants)
        await addDoc(
          collection(db, 'users', selectedRecipient, 'messages'),
          {
            ...messageData,
            messageId: messageRef.id,
            receivedAt: serverTimestamp()
          }
        );
        console.log("✅ Message saved to user's subcollection");
      }

      alert('✅ Message sent successfully!');
      resetForm();
      onClose();
      
    } catch (error) {
      console.error("❌ Error sending message:", error);
      alert(`Failed to send message: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setStep("selectType");
    setMessageType("");
    setSelectedRecipient("");
    setMessage("");
    setSubject("");
    setRecipients([]);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={handleClose}>
      <div className="message-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Send Message</h2>
          <button className="close-btn" onClick={handleClose}>
            <FaTimes />
          </button>
        </div>
        
        <div className="modal-content">
          {step === "selectType" ? (
            <div className="recipient-type-selector">
              <h3>Who would you like to message?</h3>
              <div className="type-buttons">
                <button 
                  className="type-btn landlord-btn"
                  onClick={() => handleSelectType('landlord')}
                >
                  <div className="type-icon">
                    <FaBuilding size={32} />
                  </div>
                  <span className="type-label">Landlords</span>
                  <p className="type-description">Send message to property owners</p>
                  <div className="type-count">
                    {messageType === 'landlord' && recipients.length > 0 
                      ? `${recipients.length} available` 
                      : "Select to view"}
                  </div>
                </button>
                <button 
                  className="type-btn tenant-btn"
                  onClick={() => handleSelectType('tenant')}
                >
                  <div className="type-icon">
                    <FaUsers size={32} />
                  </div>
                  <span className="type-label">Tenants</span>
                  <p className="type-description">Send message to current tenants</p>
                  <div className="type-count">
                    {messageType === 'tenant' && recipients.length > 0 
                      ? `${recipients.length} available` 
                      : "Select to view"}
                  </div>
                </button>
              </div>
            </div>
          ) : (
            <div className="compose-message">
              <div className="breadcrumb">
                <button className="back-btn" onClick={() => setStep("selectType")}>
                  <FaArrowLeft /> Back
                </button>
                <span className="current-type">
                  <span className="type-icon-small">
                    {messageType === 'landlord' ? <FaBuilding /> : <FaUsers />}
                  </span>
                  Message {messageType === 'landlord' ? 'Landlords' : 'Tenants'}
                </span>
              </div>

              <div className="form-section">
                <div className="form-group">
                  <label>
                    Select {messageType === 'landlord' ? 'Landlord' : 'Tenant'}
                    <span className="recipient-count">
                      ({recipients.length} available)
                    </span>
                  </label>
                  {loadingRecipients ? (
                    <div className="loading-state">
                      <FaSpinner className="spinner" /> Loading {messageType}s...
                    </div>
                  ) : recipients.length === 0 ? (
                    <div className="empty-state">
                      <div className="empty-icon">
                        {messageType === 'landlord' ? <FaBuilding /> : <FaUsers />}
                      </div>
                      <p>No {messageType}s found in the system.</p>
                      <p className="empty-subtext">
                        {messageType === 'tenant' 
                          ? "Tenants will appear here after being approved by admin." 
                          : "Register landlords first to send them messages."}
                      </p>
                    </div>
                  ) : (
                    <select 
                      className="form-select"
                      value={selectedRecipient}
                      onChange={(e) => setSelectedRecipient(e.target.value)}
                      disabled={loading}
                    >
                      <option value="">Select a {messageType}...</option>
                      {recipients.map(recipient => (
                        <option key={recipient.id} value={recipient.id}>
                          {recipient.name} 
                          {recipient.email && ` - ${recipient.email}`}
                          {!recipient.email && recipient.phone && ` - ${recipient.phone}`}
                          {recipient.type && ` (${recipient.type})`}
                        </option>
                      ))}
                    </select>
                  )}
                </div>

                {selectedRecipient && (
                  <div className="recipient-info">
                    <div className="info-item">
                      <strong>Selected:</strong> {
                        recipients.find(r => r.id === selectedRecipient)?.name || "Unknown"
                      }
                    </div>
                    <div className="info-item">
                      <strong>Email:</strong> {
                        recipients.find(r => r.id === selectedRecipient)?.email || "Not provided"
                      }
                    </div>
                    <div className="info-item">
                      <strong>Phone:</strong> {
                        recipients.find(r => r.id === selectedRecipient)?.phone || "Not provided"
                      }
                    </div>
                  </div>
                )}

                <div className="form-group">
                  <label>Subject</label>
                  <input
                    type="text"
                    className="form-input"
                    value={subject}
                    onChange={(e) => setSubject(e.target.value)}
                    placeholder="Enter message subject"
                    disabled={loading}
                  />
                </div>

                <div className="form-group">
                  <label>Message</label>
                  <textarea
                    className="form-textarea"
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder={`Type your message to the ${messageType} here...`}
                    rows={6}
                    disabled={loading}
                  />
                </div>

                <div className="form-actions">
                  <button
                    className="cancel-btn"
                    onClick={handleClose}
                    disabled={loading}
                  >
                    Cancel
                  </button>
                  <button
                    className="send-btn"
                    onClick={handleSendMessage}
                    disabled={loading || !selectedRecipient || !message.trim()}
                  >
                    {loading ? (
                      <>
                        <FaSpinner className="spinner" /> Sending...
                      </>
                    ) : (
                      <>
                        <FaPaperPlane /> Send to {messageType}
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MessageModal;