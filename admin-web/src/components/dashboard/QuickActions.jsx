import React from "react";
import {
  FaHome,
  FaUserPlus,
  FaExclamationTriangle,
  FaEnvelope
} from "react-icons/fa";
import "../../styles/quickActions.css";

const QuickActions = () => {
  const actions = [
    { label: "New Property", icon: <FaHome /> },
    { label: "Add Tenant", icon: <FaUserPlus /> },
    { label: "Log Issue", icon: <FaExclamationTriangle /> },
    { label: "Message", icon: <FaEnvelope /> },
  ];

  return (
    <div className="quick-actions-card">
      <h3 className="quick-actions-title">QUICK ACTIONS</h3>
      <div className="quick-actions-grid">
        {actions.map((action, index) => (
          <button key={index} className="quick-action-btn">
            <span className="action-icon">{action.icon}</span>
            <span className="action-label">{action.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default QuickActions;