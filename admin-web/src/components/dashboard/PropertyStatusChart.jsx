import React from "react";
import { PieChart, Pie, Cell, ResponsiveContainer } from "recharts";
import "../../styles/propertyStatusChart.css";

const PropertyStatusChart = () => {
  const data = [
    { name: "Leased", value: 13, color: "#4361ee" },
    { name: "Vacant", value: 4, color: "#4cc9f0" },
    { name: "Maintenance", value: 4, color: "#f72585" },
  ];

  const total = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className="property-status-card">
      <h3 className="status-title">Status</h3>
      
      <div className="status-content">
        <div className="chart-container">
          <ResponsiveContainer width="100%" height={140}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={35}
                outerRadius={60}
                paddingAngle={2}
                dataKey="value"
              >
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
          <div className="chart-center-text">
            <div className="center-total">{total}</div>
            <div className="center-label">Total</div>
          </div>
        </div>

        {/* Legend */}
        <div className="status-legend">
          {data.map((item, index) => (
            <div key={index} className="legend-item">
              <div 
                className="legend-color" 
                style={{ backgroundColor: item.color }}
              ></div>
              <div className="legend-text">
                <span className="legend-label">{item.name}</span>
                <span className="legend-value">({item.value})</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default PropertyStatusChart;