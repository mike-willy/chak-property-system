import React, { useState, useEffect } from "react";
import { db } from "../pages/firebase/firebase";
import { 
  collection, 
  getDocs, 
  updateDoc, 
  doc,
  query,
  where,
  Timestamp
} from "firebase/firestore";
import { FaUser, FaHome, FaPhone, FaEnvelope, FaCheck, FaTimes, FaEye } from "react-icons/fa";
import "../styles/applications.css";

const Applications = () => {
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedApp, setSelectedApp] = useState(null);

  // Fetch pending applications
  useEffect(() => {
    fetchApplications();
  }, []);

  const fetchApplications = async () => {
    try {
      setLoading(true);
      const q = query(
        collection(db, "tenantApplications"),
        where("status", "==", "pending")
      );
      
      const snapshot = await getDocs(q);
      const apps = [];
      
      snapshot.forEach((doc) => {
        apps.push({
          id: doc.id,
          ...doc.data(),
          // Convert Firestore timestamp
          appliedDate: doc.data().appliedDate?.toDate()
        });
      });
      
      setApplications(apps);
    } catch (error) {
      console.error("Error fetching applications:", error);
    } finally {
      setLoading(false);
    }
  };

  // Approve an application
  const approveApplication = async (application) => {
    try {
      // Update application status
      await updateDoc(doc(db, "tenantApplications", application.id), {
        status: "approved",
        reviewedBy: "admin", // You'll replace with actual admin ID
        reviewedAt: Timestamp.now()
      });

      // Remove from list
      setApplications(prev => prev.filter(app => app.id !== application.id));
      
      alert(`Application approved! Now you can add ${application.fullName} as a tenant.`);
      
    } catch (error) {
      console.error("Error approving application:", error);
      alert("Failed to approve application");
    }
  };

  // Reject an application
  const rejectApplication = async (application) => {
    if (!window.confirm(`Reject ${application.fullName}'s application?`)) return;
    
    try {
      await updateDoc(doc(db, "tenantApplications", application.id), {
        status: "rejected",
        reviewedBy: "admin",
        reviewedAt: Timestamp.now(),
        rejectionReason: "Application rejected by admin"
      });

      setApplications(prev => prev.filter(app => app.id !== application.id));
      alert("Application rejected");
      
    } catch (error) {
      console.error("Error rejecting application:", error);
      alert("Failed to reject application");
    }
  };

  // View application details
  const viewApplicationDetails = (application) => {
    setSelectedApp(application);
  };

  if (loading) {
    return (
      <div className="app-container">
        <div className="app-loading">Loading applications...</div>
      </div>
    );
  }

  return (
    <div className="app-container">
      <div className="app-header">
        <h1>Tenant Applications</h1>
        <p>Review and approve tenant registration requests</p>
      </div>

      {applications.length === 0 ? (
        <div className="app-no-applications">
          <FaUser className="app-no-apps-icon" />
          <h3>No pending applications</h3>
          <p>When tenants register via mobile app, they'll appear here.</p>
        </div>
      ) : (
        <div className="app-grid">
          {applications.map((app) => (
            <div key={app.id} className="app-card">
              <div className="app-card-header">
                <div className="app-avatar">
                  <FaUser />
                </div>
                <div className="app-info">
                  <h3>{app.fullName}</h3>
                  <p>
                    <FaEnvelope /> {app.email}
                  </p>
                  <p>
                    <FaPhone /> {app.phone}
                  </p>
                </div>
              </div>

              <div className="app-details">
                <div className="app-detail-row">
                  <span className="app-label">Applied For:</span>
                  <span className="app-value">
                    <FaHome /> Property {app.propertyId}, Unit {app.unitId}
                  </span>
                </div>
                
                <div className="app-detail-row">
                  <span className="app-label">Applied Date:</span>
                  <span className="app-value">
                    {app.appliedDate?.toLocaleDateString() || "N/A"}
                  </span>
                </div>
                
                <div className="app-detail-row">
                  <span className="app-label">Status:</span>
                  <span className="app-status-badge pending">Pending Review</span>
                </div>
              </div>

              <div className="app-actions">
                <button 
                  className="app-btn-view"
                  onClick={() => viewApplicationDetails(app)}
                >
                  <FaEye /> View Details
                </button>
                
                <button 
                  className="app-btn-approve"
                  onClick={() => approveApplication(app)}
                >
                  <FaCheck /> Approve
                </button>
                
                <button 
                  className="app-btn-reject"
                  onClick={() => rejectApplication(app)}
                >
                  <FaTimes /> Reject
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* View Details Modal */}
      {selectedApp && (
        <div className="app-modal-overlay" onClick={() => setSelectedApp(null)}>
          <div className="app-modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="app-modal-header">
              <h2>Application Details</h2>
              <button className="app-close-btn" onClick={() => setSelectedApp(null)}>
                ×
              </button>
            </div>
            
            <div className="app-modal-body">
              <div className="app-detail-section">
                <h3>Personal Information</h3>
                <p><strong>Full Name:</strong> {selectedApp.fullName}</p>
                <p><strong>Email:</strong> {selectedApp.email}</p>
                <p><strong>Phone:</strong> {selectedApp.phone}</p>
                {selectedApp.idNumber && (
                  <p><strong>ID Number:</strong> {selectedApp.idNumber}</p>
                )}
              </div>
              
              <div className="app-detail-section">
                <h3>Property Information</h3>
                <p><strong>Property ID:</strong> {selectedApp.propertyId}</p>
                <p><strong>Unit ID:</strong> {selectedApp.unitId}</p>
                {selectedApp.monthlyRent && (
                  <p><strong>Monthly Rent:</strong> KSh {selectedApp.monthlyRent.toLocaleString()}</p>
                )}
              </div>
              
              <div className="app-detail-section">
                <h3>Application Status</h3>
                <p><strong>Applied:</strong> {selectedApp.appliedDate?.toLocaleDateString()}</p>
                <p><strong>Status:</strong> 
                  <span className="app-status-badge pending">Pending</span>
                </p>
              </div>
            </div>
            
            <div className="app-modal-footer">
              <button className="app-btn-secondary" onClick={() => setSelectedApp(null)}>
                Close
              </button>
              <button 
                className="app-btn-primary"
                onClick={() => {
                  approveApplication(selectedApp);
                  setSelectedApp(null);
                }}
              >
                Approve & Add Tenant
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Applications;