// QuickActions.jsx
import React, { useState } from "react";
import {
  FaHome,
  FaUserPlus,
  FaEnvelope
} from "react-icons/fa";
import { Link } from "react-router-dom";
import MessageModal from "./MessageModal"; // Import the modal component
import "../../styles/quickActions.css";

const QuickActions = () => {
  const [showMessageModal, setShowMessageModal] = useState(false);

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
      path: "/landlords/add"
    },
    { 
      label: "Message", 
      icon: <FaEnvelope />,
      onClick: () => setShowMessageModal(true) // This will open the modal
    },
  ];

  return (
    <>
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

      {/* Message Modal - This will appear when showMessageModal is true */}
      <MessageModal 
        isOpen={showMessageModal}
        onClose={() => setShowMessageModal(false)}
      />
    </>
  );
};

export default QuickActions;