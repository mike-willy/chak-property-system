// src/components/StatsGrid.jsx
import React, { useState, useEffect } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../../pages/firebase/firebase";
import StatCard from "./StatCard";
import "../../styles/statsGrid.css";
import { 
  FaHome, 
  FaChartLine, 
  FaMoneyBillWave, 
  FaTools,
  FaBed,
  FaUser,
  FaBuilding
} from "react-icons/fa";

const StatsGrid = () => {
  const [stats, setStats] = useState({
    totalProperties: 0,
    occupancyRate: 0,
    monthlyRevenue: 0,
    activeMaintenance: 0,
    totalUnits: 0,
    occupiedUnits: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
    
    // Refresh stats every 30 seconds
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      
      // Fetch properties from Firestore
      const querySnapshot = await getDocs(collection(db, "properties"));
      const properties = [];
      
      let totalUnits = 0;
      let occupiedUnits = 0;
      let monthlyRevenue = 0;
      let activeMaintenance = 0;

      querySnapshot.forEach((doc) => {
        const property = doc.data();
        properties.push(property);
        
        // Calculate stats
        totalUnits += property.units || 0;
        occupiedUnits += property.occupiedUnits || (property.status === "leased" ? property.units || 0 : 0);
        monthlyRevenue += property.monthlyRevenue || (property.rentAmount || 0) * (property.units || 0);
        
        // Count properties under maintenance
        if (property.status === "maintenance") {
          activeMaintenance += 1;
        }
      });

      // Calculate occupancy rate
      const occupancyRate = totalUnits > 0 ? Math.round((occupiedUnits / totalUnits) * 100) : 0;

      setStats({
        totalProperties: properties.length,
        totalUnits,
        occupiedUnits,
        occupancyRate,
        monthlyRevenue,
        activeMaintenance
      });
      
    } catch (error) {
      console.error("Error fetching stats:", error);
    } finally {
      setLoading(false);
    }
  };

  // Format currency
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-KE', {
      style: 'currency',
      currency: 'KES',
      minimumFractionDigits: 0
    }).format(amount);
  };

  if (loading) {
    return (
      <div className="stats-grid">
        {[...Array(6)].map((_, index) => (
          <div key={index} className="stat-card loading">
            <div className="stat-icon shimmer"></div>
            <div className="stat-content">
              <div className="stat-value shimmer"></div>
              <div className="stat-title shimmer"></div>
              <div className="stat-description shimmer"></div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="stats-grid">
      <StatCard 
        title="Total Properties" 
        value={stats.totalProperties.toString()} 
        icon={<FaBuilding />}
        color="blue"
        description={`${stats.totalUnits} total units`}
      />
      
      <StatCard 
        title="Occupancy Rate" 
        value={`${stats.occupancyRate}%`}
        icon={<FaChartLine />}
        color="green"
        description={`${stats.occupiedUnits}/${stats.totalUnits} units occupied`}
        trend={stats.occupancyRate > 90 ? "up" : stats.occupancyRate < 70 ? "down" : "neutral"}
      />
      
      <StatCard 
        title="Monthly Revenue" 
        value={formatCurrency(stats.monthlyRevenue)}
        icon={<FaMoneyBillWave />}
        color="purple"
        description="Projected monthly income"
      />
      
      <StatCard 
        title="Active Maintenance" 
        value={stats.activeMaintenance.toString()}
        icon={<FaTools />}
        color="orange"
        description="Properties needing attention"
        alert={stats.activeMaintenance > 0}
      />
      
      <StatCard 
        title="Total Units" 
        value={stats.totalUnits.toString()}
        icon={<FaBed />}
        color="teal"
        description="All rental units"
      />
      
      <StatCard 
        title="Occupied Units" 
        value={stats.occupiedUnits.toString()}
        icon={<FaUser />}
        color="indigo"
        description={`${stats.occupancyRate}% occupancy`}
      />
    </div>
  );
};

export default StatsGrid;