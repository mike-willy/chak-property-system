// src/components/StatCard.jsx
import React from "react";
import "../../styles/statCard.css";

const StatCard = ({ 
  title, 
  value, 
  icon, 
  color = "blue", 
  description, 
  trend,
  alert = false 
}) => {
  const getTrendIcon = () => {
    switch(trend) {
      case "up": return "📈";
      case "down": return "📉";
      case "neutral": return "➡️";
      default: return null;
    }
  };

  return (
    <div className={`stat-card ${color} ${alert ? 'alert' : ''}`}>
      <div className="stat-header">
        <div className="stat-icon">
          {icon}
        </div>
        <div className="stat-trend">
          {getTrendIcon()}
          {alert && <span className="stat-alert">!</span>}
        </div>
      </div>
      <div className="stat-content">
        <div className="stat-value">{value}</div>
        <div className="stat-title">{title}</div>
        {description && (
          <div className="stat-description">{description}</div>
        )}
      </div>
    </div>
  );
};

export default StatCard;