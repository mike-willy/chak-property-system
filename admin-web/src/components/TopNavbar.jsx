import React, { useState, useEffect, useRef } from "react";
import { FaBell, FaSearch, FaSignOutAlt, FaEye, FaChevronRight } from "react-icons/fa";
import { useNavigate } from "react-router-dom";
import { auth } from "../pages/firebase/firebase";
import { signOut } from "firebase/auth";
import { listenForNotifications, markAllAsRead } from "../services/notificationService";
import "../styles/topNavbar.css";

const TopNavbar = () => {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const user = auth.currentUser;
    if (!user) return;

    const unsubscribe = listenForNotifications(user.uid, (notifs) => {
      setNotifications(notifs);
      const unread = notifs.filter(n => !n.read).length;
      setUnreadCount(unread);
    });

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

  const handleMarkAllAsRead = async () => {
    const user = auth.currentUser;
    if (!user) return;
    
    await markAllAsRead(user.uid);
    // Refresh notifications
    const updatedNotifications = notifications.map(n => ({ ...n, read: true }));
    setNotifications(updatedNotifications);
    setUnreadCount(0);
  };

  const handleViewAllNotifications = () => {
    navigate('/notifications');
    setShowDropdown(false);
  };

  const handleNotificationClick = (notification) => {
    // Navigate to applications page for tenant applications
    if (notification.type === "tenant_application") {
      navigate('/admin/applications');
    } else {
      // For other types, go to notifications page
      navigate('/notifications');
    }
    setShowDropdown(false);
  };

  // Format time
  const formatTime = (date) => {
    if (!date) return "";
    const now = new Date();
    const diffMs = now - new Date(date);
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    
    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    return new Date(date).toLocaleDateString();
  };

  // Get notification icon based on type
  const getNotificationIcon = (type) => {
    switch (type) {
      case "tenant_application":
        return <span className="notification-icon app">📋</span>;
      case "maintenance_request":
        return <span className="notification-icon maintenance">🔧</span>;
      case "rent_payment":
        return <span className="notification-icon payment">💰</span>;
      case "lease_expiry":
        return <span className="notification-icon lease">📄</span>;
      default:
        return <span className="notification-icon default">🔔</span>;
    }
  };

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
            {unreadCount > 0 && (
              <span className="notification-badge">
                {unreadCount > 9 ? '9+' : unreadCount}
              </span>
            )}
          </div>

          {/* CLEAN NOTIFICATION DROPDOWN */}
          {showDropdown && (
            <div className="notifications-dropdown">
              {/* Header */}
              <div className="notifications-header">
                <div className="header-top">
                  <h3>Notifications</h3>
                  {unreadCount > 0 && (
                    <button 
                      className="mark-all-read-btn"
                      onClick={handleMarkAllAsRead}
                    >
                      Mark all as read
                    </button>
                  )}
                </div>
                <div className="unread-count">
                  {unreadCount} unread • {notifications.length} total
                </div>
              </div>
              
              {/* Notifications List */}
              <div className="notifications-list">
                {notifications.length === 0 ? (
                  <div className="empty-notifications">
                    <div className="empty-icon">🔔</div>
                    <p>No notifications yet</p>
                    <small>All caught up!</small>
                  </div>
                ) : (
                  notifications.slice(0, 5).map((notification) => (
                    <div 
                      key={notification.id}
                      className={`notification-item ${notification.read ? "" : "unread"}`}
                      onClick={() => handleNotificationClick(notification)}
                    >
                      <div className="notification-icon-container">
                        {getNotificationIcon(notification.type)}
                      </div>
                      
                      <div className="notification-content">
                        <div className="notification-title-row">
                          <h4 className="notification-title">{notification.title}</h4>
                          <span className="notification-time">
                            {formatTime(notification.createdAt)}
                          </span>
                        </div>
                        <p className="notification-message">{notification.message}</p>
                      </div>
                      
                      <FaChevronRight className="chevron-icon" />
                    </div>
                  ))
                )}
              </div>
              
              {/* Footer - View All Button */}
              <div className="notifications-footer">
                <button 
                  className="view-all-notifications-btn"
                  onClick={handleViewAllNotifications}
                >
                  <FaEye /> View All Notifications
                </button>
              </div>
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