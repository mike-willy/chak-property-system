import React from "react";
import Sidebar from "./Sidebar";
import TopNavbar from "./TopNavbar";

const DashboardLayout = ({ children }) => {
  return (
    <div style={{ display: "flex" }}>
      <Sidebar />
      <div style={{ marginLeft: "250px", width: "100%" }}>
        <TopNavbar />
        <div style={{ padding: "20px" }}>{children}</div>
      </div>
    </div>
  );
};

export default DashboardLayout;
