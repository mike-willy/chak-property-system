import React from "react";
import { 
  FaFileContract,
  FaMoneyCheckAlt,
  FaTools,
  FaCheckCircle,
  FaBell
} from "react-icons/fa";
import "../../styles/RecentActivity.css";

const RecentActivity = () => {
  const activities = [
    {
      id: 1,
      icon: <FaFileContract size={16} />,
      title: "Lease Signed",
      details: "New tenant for Apt 4B",
      time: "2 hours ago",
      color: "#4CAF50"
    },
    {
      id: 2,
      icon: <FaMoneyCheckAlt size={16} />,
      title: "Rent Received",
      details: "£1,200 received from Sarah Connor",
      time: "4 hours ago",
      color: "#2196F3"
    },
    {
      id: 3,
      icon: <FaTools size={16} />,
      title: "Maintenance Request",
      details: "Plumbing issue at Unit 3C",
      time: "1 day ago",
      color: "#FF9800"
    },
    {
      id: 4,
      icon: <FaCheckCircle size={16} />,
      title: "Issue Resolved",
      details: "Window repair completed at Flat 2A",
      time: "2 days ago",
      color: "#9C27B0"
    },
    {
      id: 5,
      icon: <FaBell size={16} />,
      title: "Rent Reminder",
      details: "Sent to 3 tenants for November",
      time: "3 days ago",
      color: "#F44336"
    }
  ];

  return (
    <div className="recent-activity-container">
      <div className="recent-activity-header">
        <h3>Recent Activity</h3>
        <button className="view-all-btn">View All</button>
      </div>
      
      <div className="activity-list">
        {activities.map((activity) => (
          <div key={activity.id} className="activity-item">
            <div 
              className="activity-icon-container"
              style={{ backgroundColor: `${activity.color}15` }}
            >
              <span style={{ color: activity.color }}>
                {activity.icon}
              </span>
            </div>
            
            <div className="activity-content">
              <div className="activity-title">
                <strong>{activity.title}</strong>
                {activity.details && <span> - {activity.details}</span>}
              </div>
              <div className="activity-time">{activity.time}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecentActivity;