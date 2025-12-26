import React from "react";
import Sidebar from "./Sidebar";
import TopNavbar from "./TopNavbar";

const DashboardLayout = ({ children }) => {
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <div style={{ flex: 1, marginLeft: "250px", position: "relative" }}>
        <TopNavbar />
        <div style={{ 
          padding: "24px", 
          backgroundColor: "#f9fafb",
          marginTop: "60px", // Add this - navbar height
          minHeight: "calc(100vh - 60px)"
        }}>
          {children}
        </div>
      </div>
    </div>
  );
};

export default DashboardLayout;