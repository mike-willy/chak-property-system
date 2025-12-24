// src/pages/Landlords.jsx
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { 
  collection, 
  getDocs, 
  query, 
  where,
  orderBy 
} from "firebase/firestore";
import { db } from "../pages/firebase/firebase";
import "../styles/landlord.css"; // We'll create this CSS

const Landlords = () => {
  const [landlords, setLandlords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const navigate = useNavigate();

  // Fetch landlords from Firestore
  useEffect(() => {
    fetchLandlords();
  }, []);

  const fetchLandlords = async () => {
    try {
      // Create a query to get only users with role "landlord"
      const landlordsQuery = query(
        collection(db, "users"),
        where("role", "==", "landlord"),
        orderBy("createdAt", "desc")
      );

      const querySnapshot = await getDocs(landlordsQuery);
      const landlordsData = [];
      
      querySnapshot.forEach((doc) => {
        const data = doc.data();
        landlordsData.push({
          id: doc.id,
          name: data.name || "No Name",
          email: data.email || "No Email",
          phone: data.phone || "Not provided",
          propertiesCount: data.properties?.length || 0,
          totalProperties: data.totalProperties || 0,
          status: data.status || "active",
          createdAt: data.createdAt ? data.createdAt.toDate() : new Date(),
          isVerified: data.isVerified || false
        });
      });
      
      setLandlords(landlordsData);
    } catch (error) {
      console.error("Error fetching landlords:", error);
      alert("Failed to load landlords. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  // Filter landlords based on search term
  const filteredLandlords = landlords.filter(landlord =>
    landlord.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    landlord.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    landlord.phone.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Format date to readable string
  const formatDate = (date) => {
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  // Handle view landlord details
  const handleViewLandlord = (landlordId) => {
    navigate(`/landlords/${landlordId}`);
  };

  // Handle edit landlord
  const handleEditLandlord = (landlordId) => {
    navigate(`/landlords/edit/${landlordId}`);
  };

  // Refresh landlords list
  const handleRefresh = () => {
    setLoading(true);
    fetchLandlords();
  };

  return (
    <div className="landlords-container">
      {/* Header Section */}
      <div className="landlords-header">
        <div>
          <h1>Landlords</h1>
          <p className="page-subtitle">Manage property owners registered in the system</p>
        </div>
        <div className="header-actions">
          <button className="refresh-btn" onClick={handleRefresh} disabled={loading}>
            ↻ Refresh
          </button>
          <Link to="/landlords/add" className="add-landlord-btn">
            + Add New Landlord
          </Link>
        </div>
      </div>

      {/* Search and Stats Bar */}
      <div className="landlords-toolbar">
        <div className="search-box">
          <input
            type="text"
            placeholder="Search by name, email, or phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
          <span className="search-icon">🔍</span>
        </div>
        <div className="landlords-stats">
          <div className="stat-box">
            <span className="stat-number">{landlords.length}</span>
            <span className="stat-label">Total Landlords</span>
          </div>
          <div className="stat-box">
            <span className="stat-number">
              {landlords.filter(l => l.status === "active").length}
            </span>
            <span className="stat-label">Active</span>
          </div>
        </div>
      </div>

      {/* Loading State */}
      {loading ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading landlords...</p>
        </div>
      ) : (
        /* Landlords Table */
        <div className="landlords-table-container">
          {filteredLandlords.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">👤</div>
              <h3>No Landlords Found</h3>
              <p>{searchTerm ? 
                "No landlords match your search. Try different keywords." : 
                "No landlords have been registered yet."}
              </p>
              {!searchTerm && (
                <Link to="/landlords/add" className="empty-action-btn">
                  Add Your First Landlord
                </Link>
              )}
            </div>
          ) : (
            <>
              <table className="landlords-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Contact Information</th>
                    <th>Properties</th>
                    <th>Status</th>
                    <th>Registered Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLandlords.map((landlord) => (
                    <tr key={landlord.id}>
                      <td>
                        <div className="landlord-name-cell">
                          <span className="landlord-name">{landlord.name}</span>
                          {landlord.isVerified && (
                            <span className="verified-badge">✓ Verified</span>
                          )}
                        </div>
                      </td>
                      <td>
                        <div className="contact-info">
                          <div className="contact-email">{landlord.email}</div>
                          <div className="contact-phone">{landlord.phone}</div>
                        </div>
                      </td>
                      <td>
                        <div className="properties-count">
                          <span className="count-number">{landlord.propertiesCount}</span>
                          <span className="count-label">properties</span>
                        </div>
                      </td>
                      <td>
                        <span className={`status-badge status-${landlord.status}`}>
                          {landlord.status.charAt(0).toUpperCase() + landlord.status.slice(1)}
                        </span>
                      </td>
                      <td>
                        <span className="registered-date">
                          {formatDate(landlord.createdAt)}
                        </span>
                      </td>
                      <td>
                        <div className="action-buttons">
                          <button 
                            className="view-btn"
                            onClick={() => handleViewLandlord(landlord.id)}
                            title="View Details"
                          >
                            👁️ View
                          </button>
                          <button 
                            className="edit-btn"
                            onClick={() => handleEditLandlord(landlord.id)}
                            title="Edit Landlord"
                          >
                            ✏️ Edit
                          </button>
                          <button 
                            className="message-btn"
                            onClick={() => console.log("Message landlord:", landlord.id)}
                            title="Send Message"
                          >
                            💬 Message
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {/* Table Footer */}
              <div className="table-footer">
                <div className="results-count">
                  Showing {filteredLandlords.length} of {landlords.length} landlords
                </div>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default Landlords;