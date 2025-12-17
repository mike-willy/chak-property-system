import React from "react";
import "../../styles/statCard.css";

const StatCard = ({ title, value, subtitle }) => {
  return (
    <div className="stat-card">
      <p className="stat-title">{title}</p>
      <h2 className="stat-value">{value}</h2>
      {subtitle && <span className="stat-subtitle">{subtitle}</span>}
    </div>
  );
};

export default StatCard;
