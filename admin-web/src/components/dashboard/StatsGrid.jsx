import React from "react";
import StatCard from "./StatCard";
import "../../styles/statsGrid.css";

const StatsGrid = () => {
  return (
    <div className="stats-grid">
      <StatCard title="Total Properties" value="120" />
      <StatCard title="Occupancy Rate" value="92%" />
      <StatCard title="Rent Collected (MTD)" value="KSh 1,250,000" />
      <StatCard title="Active Maintenance" value="8" />
    </div>
  );
};

export default StatsGrid;
