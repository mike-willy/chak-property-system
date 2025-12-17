import React from "react";
import { FaBell, FaSearch } from "react-icons/fa";
import "../styles/topNavbar.css";

const TopNavbar = () => {
  return (
    <div className="top-navbar">
      <div className="search-box">
        <FaSearch />
        <input type="text" placeholder="Search properties, tenants..." />
      </div>

      <div className="navbar-actions">
        <FaBell className="icon" />
        <div className="admin-profile">
          <span>Admin</span>
        </div>
      </div>
    </div>
  );
};

export default TopNavbar;
