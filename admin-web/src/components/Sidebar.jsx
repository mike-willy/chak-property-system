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

      {/* BRAND / LOGO */}
      <div className="sidebar-logo">
        <h2>CHAK Estates</h2>
      </div>

      {/* MENU SECTION */}
      <p className="sidebar-title">MENU</p>
      <ul className="sidebar-menu">
        <li className="active">
          <FaTachometerAlt /> <span>Dashboard</span>
        </li>
        <li>
          <FaHome /> <span>Properties</span>
        </li>
        <li>
          <FaUsers /> <span>Tenants</span>
        </li>
        <li>
          <FaUserTie /> <span>Landlords</span>
        </li>
        <li>
          <FaTools /> <span>Maintenance</span>
        </li>
        <li>
          <FaMoneyBillWave /> <span>Finance</span>
        </li>
      </ul>

      {/* SYSTEM SECTION */}
      <p className="sidebar-title system-title">SYSTEM</p>
      <ul className="sidebar-bottom">
        <li>
          <FaCog /> <span>Settings</span>
        </li>
        <li>
          <FaLifeRing /> <span>Support</span>
        </li>
      </ul>

    </div>
  );
};

export default Sidebar;
