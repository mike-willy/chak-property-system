import React from "react";
import DashboardLayout from "../components/DashboardLayout";
import StatsGrid from "../components/dashboard/StatsGrid";

const Dashboard = () => {
  return (
    <DashboardLayout>
      <h1>Welcome back, Admin 👋</h1>
      <p>Here’s an overview of your property management system.</p>
      <StatsGrid />
    </DashboardLayout>
  );
};

export default Dashboard;
