import React, { useState, useEffect, useRef } from "react";
import { FaBell, FaSearch, FaSignOutAlt, FaUserPlus } from "react-icons/fa";
import { useNavigate } from "react-router-dom";
import { auth } from "../pages/firebase/firebase";
import { signOut } from "firebase/auth";
import { listenForNewApplications, markAsRead } from "../services/notificationService";
import "../styles/topNavbar.css";

const TopNavbar = () => {
  const navigate = useNavigate();
  const [applications, setApplications] = useState([]); // Renamed from notifications
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const user = auth.currentUser;
    if (!user) return;

    // Listen for new applications (REAL-TIME)
    const unsubscribe = listenForNewApplications((apps) => {
      setApplications(apps);
    });

    // Clean up on unmount
    return () => unsubscribe();
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate("/login");
    } catch (error) {
      console.error("Logout error:", error);
    }
  };

  const handleNotificationClick = (application) => {
    // Navigate to applications page
    navigate('/admin/applications');
    
    // Close dropdown
    setShowDropdown(false);
  };

  // Count pending applications
  const pendingCount = applications.length;

  return (
    <div className="top-navbar">
      <div className="navbar-brand">
        <h2>CHAK Estates</h2>
      </div>

      <div className="navbar-search-box">
        <FaSearch />
        <input type="text" placeholder="Search properties, tenants..." />
      </div>

      <div className="navbar-actions">
        {/* NOTIFICATION BELL */}
        <div className="notification-container" ref={dropdownRef}>
          <div 
            className="notification-bell-wrapper"
            onClick={() => setShowDropdown(!showDropdown)}
          >
            <FaBell className="icon notification-bell" />
            {pendingCount > 0 && (
              <span className="notification-badge">
                {pendingCount > 9 ? '9+' : pendingCount}
              </span>
            )}
          </div>

          {/* DROPDOWN */}
          {showDropdown && (
            <div className="notifications-dropdown">
              <div className="notifications-header">
                <h3>Notifications</h3>
                <span className="notification-count">{pendingCount} pending</span>
              </div>
              
              <div className="notifications-list">
                {applications.length === 0 ? (
                  <div className="empty-notifications">
                    <p>No pending applications</p>
                  </div>
                ) : (
                  applications.map((application) => (
                    <div 
                      key={application.id}
                      className="notification-item unread"
                      onClick={() => handleNotificationClick(application)}
                    >
                      <FaUserPlus className="notification-icon" />
                      <div className="notification-content">
                        <h4>New Application</h4>
                        <p>{application.fullName} applied for a unit</p>
                        <span className="notification-time">
                          {application.propertyName || `Property ${application.propertyId}`}
                        </span>
                      </div>
                    </div>
                  ))
                )}
              </div>
              
              {applications.length > 0 && (
                <div 
                  className="notifications-footer"
                  onClick={() => {
                    navigate('/admin/applications');
                    setShowDropdown(false);
                  }}
                >
                  View All Applications
                </div>
              )}
            </div>
          )}
        </div>
        
        <div className="admin-profile">
          <span>Admin</span>
        </div>

        <button onClick={handleLogout} className="logout-btn">
          <FaSignOutAlt />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

export default TopNavbar;