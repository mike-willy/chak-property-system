// src/pages/Properties.jsx
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { 
  collection, 
  getDocs, 
  updateDoc, 
  doc 
} from "firebase/firestore";
import { db } from "../pages/firebase/firebase";
import "../styles/Properties.css";
import { 
  FaHome, 
  FaBed, 
  FaBath, 
  FaRulerCombined, 
  FaEdit, 
  FaEye,
  FaPlus,
  FaSearch,
  FaMapMarkerAlt
} from "react-icons/fa";

const Properties = () => {
  const navigate = useNavigate();
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Fetch properties from Firestore
  useEffect(() => {
    fetchProperties();
  }, []);

  const fetchProperties = async () => {
    try {
      setLoading(true);
      const querySnapshot = await getDocs(collection(db, "properties"));
      const propertiesData = [];

      querySnapshot.forEach((doc) => {
        const data = doc.data();
        const property = {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date()
        };
        
        propertiesData.push(property);
      });

      setProperties(propertiesData);
      
    } catch (error) {
      console.error("Error fetching properties:", error);
      alert("Failed to load properties");
    } finally {
      setLoading(false);
    }
  };

  // Filter properties based on search and status
  const filteredProperties = properties.filter(property => {
    const matchesSearch = 
      property.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      property.address?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      property.city?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      property.landlordName?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = 
      filterStatus === "all" || 
      property.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  // Handle status update
  const handleStatusUpdate = async (propertyId, newStatus) => {
    try {
      const propertyRef = doc(db, "properties", propertyId);
      await updateDoc(propertyRef, {
        status: newStatus,
        updatedAt: new Date()
      });
      
      // Update local state
      setProperties(prev => prev.map(prop => 
        prop.id === propertyId ? { ...prop, status: newStatus } : prop
      ));
      
      alert(`Status updated to ${newStatus}`);
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Failed to update status");
    }
  };

  // Handle view property details
  const handleViewProperty = (propertyId) => {
    navigate(`/property/${propertyId}`);
  };

  // Handle edit property
  const handleEditProperty = (propertyId) => {
    navigate(`/properties/edit/${propertyId}`);
  };

  // Handle add new property
  const handleAddProperty = () => {
    navigate("/properties/add");
  };

  // Clear search
  const handleClearSearch = () => {
    setSearchTerm("");
  };

  // Get status badge class
  const getStatusClass = (status) => {
    switch(status?.toLowerCase()) {
      case "leased": return "status-leased";
      case "vacant": return "status-vacant";
      case "maintenance": return "status-maintenance";
      default: return "status-available";
    }
  };

  // Get status text
  const getStatusText = (status) => {
    switch(status?.toLowerCase()) {
      case "leased": return "Leased";
      case "vacant": return "Vacant";
      case "maintenance": return "Maintenance";
      case "available": return "Available";
      default: return "Available";
    }
  };

  // Format currency
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-KE', {
      style: 'currency',
      currency: 'KES',
      minimumFractionDigits: 0
    }).format(amount || 0);
  };

  // Format date
  const formatDate = (date) => {
    if (!date) return "N/A";
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <div className="properties-container">
      {/* Header */}
      <div className="properties-header">
        <div>
          <h1>Properties</h1>
          <p className="subtitle">Manage all your rental properties</p>
        </div>
        <button className="add-property-btn" onClick={handleAddProperty}>
          <FaPlus /> Add New Property
        </button>
      </div>

      {/* REMOVED: <StatsGrid /> */}

      {/* Filters and Search */}
      <div className="properties-filters-section">
        <div className="properties-search-box">
          <FaSearch className="properties-search-icon" />
          <input
            type="text"
            placeholder="Search properties by name, address, city, or landlord..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="properties-search-input"
          />
          {searchTerm && (
            <button 
              className="properties-search-clear"
              onClick={handleClearSearch}
              type="button"
            >
              ×
            </button>
          )}
        </div>
        
        <div className="properties-filter-buttons">
          <button 
            className={`properties-filter-btn ${filterStatus === 'all' ? 'active' : ''}`}
            onClick={() => setFilterStatus('all')}
          >
            All Properties
          </button>
          <button 
            className={`properties-filter-btn ${filterStatus === 'leased' ? 'active' : ''}`}
            onClick={() => setFilterStatus('leased')}
          >
            Leased
          </button>
          <button 
            className={`properties-filter-btn ${filterStatus === 'vacant' ? 'active' : ''}`}
            onClick={() => setFilterStatus('vacant')}
          >
            Vacant
          </button>
          <button 
            className={`properties-filter-btn ${filterStatus === 'maintenance' ? 'active' : ''}`}
            onClick={() => setFilterStatus('maintenance')}
          >
            Maintenance
          </button>
        </div>
      </div>

      {/* Properties List */}
      <div className="properties-list">
        {loading ? (
          <div className="properties-loading-container">
            <div className="properties-spinner"></div>
            <p>Loading properties...</p>
          </div>
        ) : filteredProperties.length === 0 ? (
          <div className="properties-empty-state">
            <FaHome className="properties-empty-icon" />
            <h3>No properties found</h3>
            <p>{searchTerm || filterStatus !== 'all' ? 'Try changing your search or filter' : 'Add your first property to get started'}</p>
            {!searchTerm && filterStatus === 'all' && (
              <button className="add-property-btn" onClick={handleAddProperty}>
                <FaPlus /> Add New Property
              </button>
            )}
          </div>
        ) : (
          <div className="properties-grid">
            {filteredProperties.map((property) => (
              <div key={property.id} className="property-card">
                {/* Property Image */}
                <div className="property-image">
                  {property.images && property.images.length > 0 ? (
                    <img src={property.images[0]} alt={property.name} />
                  ) : (
                    <div className="property-no-image">
                      <FaHome />
                      <p>No Image</p>
                    </div>
                  )}
                  <div className={`property-status-badge ${getStatusClass(property.status)}`}>
                    {getStatusText(property.status)}
                  </div>
                </div>

                {/* Property Details */}
                <div className="property-details">
                  <div className="property-header">
                    <h3>{property.name || "Unnamed Property"}</h3>
                    <div className="property-price">
                      {formatCurrency(property.rentAmount)}/month
                    </div>
                  </div>
                  
                  <div className="property-location">
                    <FaMapMarkerAlt />
                    <span>{property.address || "No address"}, {property.city || "Unknown city"}</span>
                  </div>
                  
                  <div className="property-specs">
                    <div className="property-spec">
                      <FaBed />
                      <span>{property.bedrooms || 1} Bed</span>
                    </div>
                    <div className="property-spec">
                      <FaBath />
                      <span>{property.bathrooms || 1} Bath</span>
                    </div>
                    <div className="property-spec">
                      <FaHome />
                      <span>{property.units || 1} Unit{property.units !== 1 ? 's' : ''}</span>
                    </div>
                    {property.size && (
                      <div className="property-spec">
                        <FaRulerCombined />
                        <span>{property.size} sq ft</span>
                      </div>
                    )}
                  </div>
                  
                  <div className="property-info">
                    <div className="property-info-row">
                      <span className="property-label">Type:</span>
                      <span className="property-value">
                        {property.propertyType || property.type || "Apartment"}
                      </span>
                    </div>
                    <div className="property-info-row">
                      <span className="property-label">Landlord:</span>
                      <span className="property-value">{property.landlordName || "Unknown"}</span>
                    </div>
                    <div className="property-info-row">
                      <span className="property-label">Added:</span>
                      <span className="property-value">
                        {formatDate(property.createdAt)}
                      </span>
                    </div>
                  </div>
                  
                  {/* Action Buttons */}
                  <div className="property-actions">
                    <div className="property-status-selector">
                      <span className="property-label">Status:</span>
                      <select
                        value={property.status || "available"}
                        onChange={(e) => handleStatusUpdate(property.id, e.target.value)}
                        className={`property-status-select ${getStatusClass(property.status)}`}
                      >
                        <option value="available">Available</option>
                        <option value="leased">Leased</option>
                        <option value="vacant">Vacant</option>
                        <option value="maintenance">Maintenance</option>
                      </select>
                    </div>
                    
                    <div className="property-action-buttons">
                      <button 
                        className="property-action-btn view-btn"
                        onClick={() => handleViewProperty(property.id)}
                      >
                        <FaEye /> View
                      </button>
                      <button 
                        className="property-action-btn edit-btn"
                        onClick={() => handleEditProperty(property.id)}
                      >
                        <FaEdit /> Edit
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Properties;