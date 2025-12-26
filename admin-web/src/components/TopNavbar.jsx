import React from "react";
import { FaBell, FaSearch, FaSignOutAlt } from "react-icons/fa";
import { useNavigate } from "react-router-dom";
import { auth } from "../pages/firebase/firebase";
import { signOut } from "firebase/auth";
import "../styles/topNavbar.css";

const TopNavbar = () => {
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      console.log("Logged out successfully");
      navigate("/login");
    } catch (error) {
      console.error("Logout error:", error);
    }
  };

  return (
    <div className="top-navbar">
      {/* ADDED: Brand/Logo on left */}
      <div className="navbar-brand">
        <h2>CHAK Estates</h2>
      </div>

      <div className="search-box">
        <FaSearch />
        <input type="text" placeholder="Search properties, tenants..." />
      </div>

      <div className="navbar-actions">
        <FaBell className="icon" />
        
        <div className="admin-profile">
          <span>Admin</span>
        </div>

        <button onClick={handleLogout} className="logout-btn">
          <FaSignOutAlt />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

export default TopNavbar;