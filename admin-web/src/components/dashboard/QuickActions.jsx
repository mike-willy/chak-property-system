import React from "react";
import {
  FaPlus,
  FaUserPlus,
  FaMoneyCheckAlt,
  FaTools
} from "react-icons/fa";
import "../../styles/quickActions.css";

const QuickActions = () => {
  return (
    <div className="quick-actions">
      <h3>Quick Actions</h3>

      <button className="quick-btn">
        <FaPlus /> Add Property
      </button>

      <button className="quick-btn">
        <FaUserPlus /> Add Tenant
      </button>

      <button className="quick-btn">
        <FaMoneyCheckAlt /> Record Payment
      </button>

      <button className="quick-btn">
        <FaTools /> Maintenance Request
      </button>
    </div>
  );
};

export default QuickActions;
