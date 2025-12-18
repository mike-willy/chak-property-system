import React from "react";
import DashboardLayout from "../components/DashboardLayout";
import DashboardHeader from "../components/dashboard/DashboardHeader";
import StatsGrid from "../components/dashboard/StatsGrid";
import FinancialChart from "../components/dashboard/FinancialChart";
import PropertyStatusChart from "../components/dashboard/PropertyStatusChart";
import QuickActions from "../components/dashboard/QuickActions";
import OverduePayments from "../components/dashboard/OverduePayments";
import RecentActivity from "../components/dashboard/RecentActivity";
import "../styles/dashboard.css";

const Dashboard = () => {
  return (
    <DashboardLayout>
      <DashboardHeader />
      <StatsGrid />

      {/* Charts & Tables Section */}
      <div className="dashboard-charts-layout">
        {/* ROW 1 - Financial Chart */}
        <div className="charts-left">
          <FinancialChart />
        </div>

        {/* ROW 1 - Quick Actions + Status */}
        <div className="charts-right">
          <QuickActions />
          <PropertyStatusChart />
        </div>

        {/* ROW 2 - Overdue Payments */}
        <div className="charts-left">
          <OverduePayments />
        </div>

        {/* ROW 2 - Recent Activity */}
        <div className="charts-right">
          <RecentActivity />
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Dashboard;
