import React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid
} from "recharts";
import "../../styles/financialChart.css";

const FinancialChart = () => {
  const data = [
    // { month: "Jan", amount: 30 },
    // { month: "Feb", amount: 50 },
    // { month: "Mar", amount: 80 },
    // { month: "Apr", amount: 60 },
    // { month: "May", amount: 90 },
    // { month: "Jun", amount: 70 },
  ];

  return (
    <div className="financial-chart-card">
      <div className="chart-header">
        <h3 className="chart-title">Financial Performance</h3>
        <div className="chart-filter">
          <button className="filter-btn active">Last 6 Months</button>
        </div>
      </div>
      
      <div className="chart-wrapper">
        <ResponsiveContainer width="100%" height={350}>
          <BarChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 20 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} />
            <XAxis 
              dataKey="month" 
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#6c757d', fontSize: 12 }}
            />
            <YAxis 
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#6c757d', fontSize: 11 }}
              tickFormatter={(value) => `£${value}K`}
              domain={[0, 100]}
            />
            <Tooltip 
              formatter={(value) => [`£${value}K`, 'Amount']}
              labelFormatter={(label) => `Month: ${label}`}
            />
            <Bar 
              dataKey="amount" 
              fill="url(#colorGradient)"
              radius={[6, 6, 0, 0]}
              barSize={40}
            />
            <defs>
              <linearGradient id="colorGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#4361ee" />
                <stop offset="100%" stopColor="#3a56d4" />
              </linearGradient>
            </defs>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default FinancialChart;