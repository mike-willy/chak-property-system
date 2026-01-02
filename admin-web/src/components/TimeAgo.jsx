import React, { useState, useEffect } from "react";

const TimeAgo = ({ date }) => {
  const [timeAgo, setTimeAgo] = useState("");

  useEffect(() => {
    const updateTime = () => {
      if (!date) return;
      
      const now = new Date();
      const dateObj = date instanceof Date ? date : new Date(date);
      const diffMs = now - dateObj;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);

      if (diffMins < 1) setTimeAgo("Just now");
      else if (diffMins < 60) setTimeAgo(`${diffMins}m ago`);
      else if (diffHours < 24) setTimeAgo(`${diffHours}h ago`);
      else if (diffDays < 7) setTimeAgo(`${diffDays}d ago`);
      else setTimeAgo(dateObj.toLocaleDateString());
    };

    updateTime();
    const interval = setInterval(updateTime, 60000);
    
    return () => clearInterval(interval);
  }, [date]);

  return <span className="time-ago">{timeAgo}</span>;
};

export default TimeAgo;