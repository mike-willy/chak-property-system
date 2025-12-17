import React from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid
} from "recharts";
import "../../styles/chart.css";

const data = [
  { month: "Jan", amount: 400000 },
  { month: "Feb", amount: 520000 },
  { month: "Mar", amount: 610000 },
  { month: "Apr", amount: 750000 },
  { month: "May", amount: 900000 },
];

const FinancialChart = () => {
  return (
    <div className="chart-card">
      <h3>Monthly Rent Collection</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="month" />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey="amount" strokeWidth={3} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default FinancialChart;
