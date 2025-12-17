import React from "react";
import { FaDownload, FaPlus } from "react-icons/fa";
import "../../styles/dashboardHeader.css";

const DashboardHeader = () => {
  return (
    <div className="dashboard-header">
      <div>
        <h1>Welcome back, Admin!</h1>
        <p>Here’s an overview of your property management system.</p>
      </div>

      <div className="dashboard-actions">
        <button className="btn-outline">
          <FaDownload /> Export Report
        </button>
        <button className="btn-primary">
          <FaPlus /> Add Property
        </button>
      </div>
    </div>
  );
};

export default DashboardHeader;
