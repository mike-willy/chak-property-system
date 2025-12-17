import React from "react";
import { PieChart, Pie, Tooltip, ResponsiveContainer } from "recharts";
import "../../styles/chart.css";

const data = [
  { name: "Occupied", value: 92 },
  { name: "Vacant", value: 28 },
];

const PropertyStatusChart = () => {
  return (
    <div className="chart-card">
      <h3>Property Status</h3>
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={data}
            dataKey="value"
            innerRadius={60}
            outerRadius={100}
            paddingAngle={4}
          />
          <Tooltip />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
};

export default PropertyStatusChart;
