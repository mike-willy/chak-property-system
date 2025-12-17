import React from "react";
import {
  FaTachometerAlt,
  FaHome,
  FaUsers,
  FaUserTie,
  FaTools,
  FaMoneyBillWave,
  FaCog,
  FaLifeRing
} from "react-icons/fa";
import "../styles/sidebar.css";

const Sidebar = () => {
  return (
    <div className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <h2>CHAK Estates</h2>
      </div>

      {/* Menu */}
      <ul className="sidebar-menu">
        <li className="active">
          <FaTachometerAlt /> Dashboard
        </li>
        <li>
          <FaHome /> Properties
        </li>
        <li>
          <FaUsers /> Tenants
        </li>
        <li>
          <FaUserTie /> Landlords
        </li>
        <li>
          <FaTools /> Maintenance 
        </li>
        <li>
          <FaMoneyBillWave /> Finance
        </li>
      </ul>

      {/* Bottom Menu */}
      <ul className="sidebar-bottom">
        <li>
          <FaCog /> Settings
        </li>
        <li>
          <FaLifeRing /> Support
        </li>
      </ul>
    </div>
  );
};

export default Sidebar;
