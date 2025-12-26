// QuickActions.jsx - Final check
import React from "react";
import {
  FaHome,
  FaUserPlus,
  FaExclamationTriangle,
  FaEnvelope
} from "react-icons/fa";
import { Link } from "react-router-dom";
import "../../styles/quickActions.css";

const QuickActions = () => {
  const actions = [
    { 
      label: "New Property", 
      icon: <FaHome />,
      path: "/properties/add"
    },
    { 
      label: "Add Tenant", 
      icon: <FaUserPlus />,
      path: "/tenants/add"
    },
    { 
      label: "Add Landlord", 
      icon: <FaUserPlus />,
      path: "/landlords/add"  // ✅ This is correct!
    },
    { 
      label: "Message", 
      icon: <FaEnvelope />,
      path: "#",
      onClick: () => console.log("Open message modal")
    },
  ];

  return (
    <div className="quick-actions-card">
      <h3 className="quick-actions-title">QUICK ACTIONS</h3>
      <div className="quick-actions-grid">
        {actions.map((action, index) => {
          if (action.label === "Message") {
            return (
              <button 
                key={index} 
                className="quick-action-btn"
                onClick={action.onClick}
              >
                <span className="action-icon">{action.icon}</span>
                <span className="action-label">{action.label}</span>
              </button>
            );
          }
          
          return (
            <Link 
              key={index} 
              to={action.path}
              className="quick-action-link"
            >
              <div className="quick-action-btn">
                <span className="action-icon">{action.icon}</span>
                <span className="action-label">{action.label}</span>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
};

export default QuickActions;