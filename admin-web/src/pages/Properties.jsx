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
  FaMapMarkerAlt,
  FaDoorClosed,
  FaCheckCircle,
  FaTools,
  FaUsers
} from "react-icons/fa";

const Properties = () => {
  const navigate = useNavigate();
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Helper function to get unit counts consistently
  const getUnitCounts = (property) => {
    const unitDetails = property.unitDetails || {};
    const totalUnits = property.units || unitDetails.totalUnits || 1;
    
    return {
      totalUnits: totalUnits,
      vacantCount: unitDetails.vacantCount || totalUnits,
      leasedCount: unitDetails.leasedCount || 0,
      maintenanceCount: unitDetails.maintenanceCount || 0
    };
  };

  // Helper function to check if property has multiple units
  const isMultiUnitProperty = (property) => {
    const { totalUnits } = getUnitCounts(property);
    return totalUnits > 1;
  };

  // Calculate occupancy rate consistently
  const calculateOccupancyRate = (property) => {
    const { totalUnits, leasedCount } = getUnitCounts(property);
    if (!totalUnits || totalUnits === 0) return 0;
    return Math.round((leasedCount / totalUnits) * 100);
  };

  // Get status badge class
  const getStatusClass = (status) => {
    const statusLower = (status || 'available').toLowerCase();
    switch(statusLower) {
      case "leased": return "status-leased";
      case "vacant": return "status-vacant";
      case "maintenance": return "status-maintenance";
      default: return "status-available";
    }
  };

  // Get status text
  const getStatusText = (status) => {
    const statusLower = (status || 'available').toLowerCase();
    switch(statusLower) {
      case "leased": return "Leased";
      case "vacant": return "Vacant";
      case "maintenance": return "Maintenance";
      case "available": return "Available";
      default: return "Available";
    }
  };

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
        
        // Normalize unit details
        const totalUnits = data.units || data.unitDetails?.totalUnits || 1;
        const unitDetails = data.unitDetails || {};
        
        // Ensure all properties have consistent unitDetails structure
        const normalizedUnitDetails = {
          totalUnits: totalUnits,
          vacantCount: unitDetails.vacantCount || (totalUnits - (unitDetails.leasedCount || 0) - (unitDetails.maintenanceCount || 0)),
          leasedCount: unitDetails.leasedCount || 0,
          maintenanceCount: unitDetails.maintenanceCount || 0,
          occupancyRate: unitDetails.occupancyRate || 0,
          units: unitDetails.units || []
        };
        
        const property = {
          id: doc.id,
          ...data,
          // Always store units count at root level for consistency
          units: totalUnits,
          // Always have unitDetails with consistent structure
          unitDetails: normalizedUnitDetails,
          createdAt: data.createdAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
          // Ensure status has a default value and is lowercase
          status: (data.status || 'available').toLowerCase()
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

  // Handle status update for entire property
  const handleStatusUpdate = async (propertyId, newStatus) => {
    try {
      const propertyRef = doc(db, "properties", propertyId);
      await updateDoc(propertyRef, {
        status: newStatus.toLowerCase(),
        updatedAt: new Date()
      });
      
      // Update local state
      setProperties(prev => prev.map(prop => 
        prop.id === propertyId ? { ...prop, status: newStatus.toLowerCase() } : prop
      ));
      
      alert(`Property status updated to ${newStatus}`);
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Failed to update status");
    }
  };

  // Handle view property units
  const handleViewProperty = (propertyId) => {
    navigate(`/property/${propertyId}/units`);
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

  // Optional: Data normalization function
  const normalizeAllProperties = async () => {
    if (!window.confirm("This will update all properties in the database to use a consistent structure. Continue?")) {
      return;
    }
    
    try {
      const querySnapshot = await getDocs(collection(db, "properties"));
      const updatePromises = [];

      querySnapshot.forEach((doc) => {
        const data = doc.data();
        const totalUnits = data.units || data.unitDetails?.totalUnits || 1;
        
        const updates = {
          units: totalUnits,
          unitDetails: {
            totalUnits: totalUnits,
            vacantCount: data.unitDetails?.vacantCount || totalUnits,
            leasedCount: data.unitDetails?.leasedCount || 0,
            maintenanceCount: data.unitDetails?.maintenanceCount || 0,
            occupancyRate: data.unitDetails?.occupancyRate || 0,
            units: data.unitDetails?.units || []
          },
          status: (data.status || 'available').toLowerCase(),
          updatedAt: new Date()
        };

        updatePromises.push(updateDoc(doc.ref, updates));
      });

      await Promise.all(updatePromises);
      alert(`Successfully normalized ${updatePromises.length} properties`);
      fetchProperties(); // Refresh the data
    } catch (error) {
      console.error("Error normalizing properties:", error);
      alert("Failed to normalize properties");
    }
  };

  return (
    <div className="properties-container">
      {/* Header */}
      <div className="properties-header">
        <div>
          <h1>Properties</h1>
          <p className="subtitle">Manage all your rental properties and units</p>
        </div>
        <button className="add-property-btn" onClick={handleAddProperty}>
          <FaPlus /> Add New Property
        </button>
      </div>

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
            {filteredProperties.map((property) => {
              const { totalUnits, vacantCount, leasedCount, maintenanceCount } = getUnitCounts(property);
              const occupancyRate = calculateOccupancyRate(property);
              
              return (
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
                    
                    {/* Occupancy Badge - Show only for multi-unit properties */}
                    {isMultiUnitProperty(property) && (
                      <div className="property-occupancy-badge">
                        {occupancyRate}% Occupied
                      </div>
                    )}
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
                        <span>
                          {totalUnits} Unit{totalUnits !== 1 ? 's' : ''}
                        </span>
                      </div>
                      {property.size && (
                        <div className="property-spec">
                          <FaRulerCombined />
                          <span>{property.size} sq ft</span>
                        </div>
                      )}
                    </div>
                    
                    {/* Unit Statistics - Unified Approach */}
                    {isMultiUnitProperty(property) ? (
                      // Multi-unit properties: Show detailed statistics
                      <div className="property-unit-stats">
                        <div className="unit-stats-header">
                          <span className="unit-stats-title">Unit Status:</span>
                          <div className="unit-stats-container">
                            {/* Vacant Units - Always show */}
                            <div className="unit-stat-item vacant">
                              <FaDoorClosed className="unit-stat-icon" />
                              <span className="unit-stat-count">{vacantCount}</span>
                              <span className="unit-stat-label">Vacant</span>
                            </div>
                            
                            {/* Leased Units - Show if any */}
                            {leasedCount > 0 && (
                              <div className="unit-stat-item leased">
                                <FaCheckCircle className="unit-stat-icon" />
                                <span className="unit-stat-count">{leasedCount}</span>
                                <span className="unit-stat-label">Leased</span>
                              </div>
                            )}
                            
                            {/* Maintenance Units - Show if any */}
                            {maintenanceCount > 0 && (
                              <div className="unit-stat-item maintenance">
                                <FaTools className="unit-stat-icon" />
                                <span className="unit-stat-count">{maintenanceCount}</span>
                                <span className="unit-stat-label">Maintenance</span>
                              </div>
                            )}
                          </div>
                        </div>
                        
                        {/* Vacancy Alert - Show if there are vacant units */}
                        {vacantCount > 0 && (
                          <div className="vacancy-alert">
                            <div className="vacancy-alert-content">
                              <FaDoorClosed className="vacancy-icon" />
                              <div className="vacancy-text">
                                <strong>{vacantCount} units available</strong> for rent
                              </div>
                            </div>
                          </div>
                        )}
                        
                        {/* Occupancy Summary */}
                        <div className="occupancy-summary">
                          <div className="occupancy-bar">
                            <div 
                              className="occupancy-fill"
                              style={{ width: `${occupancyRate}%` }}
                            ></div>
                          </div>
                          <div className="occupancy-info">
                            <span className="occupancy-text">
                              {occupancyRate}% Occupancy Rate
                            </span>
                            <span className="tenants-count">
                              <FaUsers /> {leasedCount} {leasedCount === 1 ? 'Tenant' : 'Tenants'}
                            </span>
                          </div>
                        </div>
                      </div>
                    ) : (
                      // Single-unit properties: Show simplified status
                      <div className="single-unit-status">
                        <div className="single-unit-badge">
                          <span className="single-unit-label">Single Unit Property</span>
                          <span className={`single-unit-status-badge ${property.status}`}>
                            {getStatusText(property.status)}
                          </span>
                        </div>
                        {property.status?.toLowerCase() === 'vacant' && (
                          <div className="single-unit-vacant">
                            <FaDoorClosed /> Available for immediate occupancy
                          </div>
                        )}
                      </div>
                    )}
                    
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
                        <span className="property-label">Property Status:</span>
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
                          <FaEye /> View Units
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
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default Properties;