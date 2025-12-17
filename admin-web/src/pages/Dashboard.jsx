import React from "react";
import DashboardLayout from "../components/DashboardLayout";
import DashboardHeader from "../components/dashboard/DashboardHeader";
import StatsGrid from "../components/dashboard/StatsGrid";
import FinancialChart from "../components/dashboard/FinancialChart";
import PropertyStatusChart from "../components/dashboard/PropertyStatusChart";
import QuickActions from "../components/dashboard/QuickActions";
import OverduePayments from "../components/dashboard/OverduePayments";
import "../styles/dashboard.css";

const Dashboard = () => {
  return (
    <DashboardLayout>
      <DashboardHeader />

      <StatsGrid />
      
      {/* Charts Section */}
      <div className="dashboard-charts-layout">
        {/* LEFT: Financial Chart */}
        <div className="charts-left">
          <FinancialChart />
          <OverduePayments />

        </div>

        {/* RIGHT: Quick Actions + Status */}
        <div className="charts-right">
          <QuickActions />
          <PropertyStatusChart />
        </div>
        
      </div>
    </DashboardLayout>
  );
};

export default Dashboard;
