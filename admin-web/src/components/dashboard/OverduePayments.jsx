import React from "react";
import "../../styles/overduePayments.css";

const overduePayments = [
  {
    tenant: "James Mwangi",
    property: "Greenview A12",
    dueDate: "10 Jun 2025",
    amount: "KSh 25,000",
    status: "Overdue",
  },
  {
    tenant: "Mary Wanjiru",
    property: "Sunrise B04",
    dueDate: "05 Jun 2025",
    amount: "KSh 18,000",
    status: "Overdue",
  },
  {
    tenant: "Peter Otieno",
    property: "Palm Court C07",
    dueDate: "08 Jun 2025",
    amount: "KSh 30,000",
    status: "Overdue",
  },
];

const OverduePayments = () => {
  return (
    <div className="overdue-card">
      <div className="overdue-header">
        <h3>Overdue Payments</h3>
        <span className="view-all">View All</span>
      </div>

      <table className="overdue-table">
        <thead>
          <tr>
            <th>Tenant</th>
            <th>Property</th>
            <th>Due Date</th>
            <th>Amount</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>

        <tbody>
          {overduePayments.map((item, index) => (
            <tr key={index}>
              <td>{item.tenant}</td>
              <td>{item.property}</td>
              <td>{item.dueDate}</td>
              <td className="amount">{item.amount}</td>
              <td>
                <span className="status overdue">{item.status}</span>
              </td>
              <td>
                <button className="reminder-btn">Remind</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default OverduePayments;
