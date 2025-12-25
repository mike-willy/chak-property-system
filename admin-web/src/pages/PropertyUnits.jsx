// src/pages/PropertyUnits.jsx
import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { doc, getDoc, updateDoc, arrayUnion } from "firebase/firestore";
import { addDoc, collection } from "firebase/firestore";
import { db } from "../pages/firebase/firebase";
import "../styles/PropertyUnits.css";
import { 
  FaArrowLeft, 
  FaHome, 
  FaUser, 
  FaPhone, 
  FaCalendar,
  FaEdit,
  FaTrash,
  FaPlus,
  FaFilter,
  FaDoorClosed,
  FaCheckCircle,
  FaTools,
  FaDollarSign,
  FaExpand,
  FaUserPlus,
  FaChartLine,
  FaBuilding
} from "react-icons/fa";

const PropertyUnits = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [property, setProperty] = useState(null);
  const [loading, setLoading] = useState(true);
  const [units, setUnits] = useState([]);
  const [filter, setFilter] = useState("all"); // all, vacant, leased, maintenance
  const [editingUnit, setEditingUnit] = useState(null);
  const [showAssignForm, setShowAssignForm] = useState(false);
  const [selectedUnitIndex, setSelectedUnitIndex] = useState(null);
  
  // Tenant assignment form
  const [tenantForm, setTenantForm] = useState({
    name: "",
    phone: "",
    email: "",
    leaseStart: "",
    leaseEnd: "",
    rentAmount: "",
    deposit: ""
  });

  // Fetch property and units
  useEffect(() => {
    fetchPropertyAndUnits();
  }, [id]);

  const fetchPropertyAndUnits = async () => {
    try {
      setLoading(true);
      const propertyRef = doc(db, "properties", id);
      const propertySnap = await getDoc(propertyRef);
      
      if (propertySnap.exists()) {
        const propertyData = propertySnap.data();
        
        // Ensure unitDetails exists with defaults
        const unitDetails = propertyData.unitDetails || {
          totalUnits: propertyData.units || 1,
          vacantCount: propertyData.units || 1,
          leasedCount: 0,
          maintenanceCount: 0,
          occupancyRate: 0,
          units: []
        };
        
        // If units array doesn't exist, create it
        if (!unitDetails.units || unitDetails.units.length === 0) {
          unitDetails.units = generateDefaultUnits(propertyData);
        }
        
        setProperty({
          id: propertySnap.id,
          ...propertyData,
          unitDetails: unitDetails
        });
        
        setUnits(unitDetails.units);
      } else {
        alert("Property not found");
        navigate("/properties");
      }
    } catch (error) {
      console.error("Error fetching property:", error);
      alert("Failed to load property details");
    } finally {
      setLoading(false);
    }
  };

  // Generate default units if none exist
  const generateDefaultUnits = (propertyData) => {
    const units = [];
    const propertyPrefix = propertyData.name 
      ? propertyData.name.replace(/\s+/g, '').substring(0, 3).toUpperCase() 
      : 'APT';
    
    const totalUnits = propertyData.units || 1;
    
    for (let i = 1; i <= totalUnits; i++) {
      const unitNumber = i.toString().padStart(3, '0');
      units.push({
        unitId: `${propertyPrefix}-${unitNumber}`,
        unitNumber: unitNumber,
        unitName: `${propertyData.name || 'Property'} - Unit ${unitNumber}`,
        status: "vacant",
        rentAmount: propertyData.rentAmount || 0,
        size: propertyData.size || "",
        amenities: propertyData.amenities || [],
        tenantId: null,
        tenantName: "",
        tenantPhone: "",
        tenantEmail: "",
        leaseStart: null,
        leaseEnd: null,
        rentPaidUntil: null,
        deposit: 0,
        notes: "",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    }
    
    return units;
  };

  // Update unit status
  const handleStatusUpdate = async (unitIndex, newStatus) => {
    try {
      const updatedUnits = [...units];
      const unit = updatedUnits[unitIndex];
      
      // Clear tenant info if changing from leased
      if (unit.status === "leased" && newStatus !== "leased") {
        unit.tenantId = null;
        unit.tenantName = "";
        unit.tenantPhone = "";
        unit.tenantEmail = "";
        unit.leaseStart = null;
        unit.leaseEnd = null;
      }
      
      // Update status
      unit.status = newStatus;
      unit.updatedAt = new Date().toISOString();
      
      // Recalculate counts
      const vacantCount = updatedUnits.filter(u => u.status === "vacant").length;
      const leasedCount = updatedUnits.filter(u => u.status === "leased").length;
      const maintenanceCount = updatedUnits.filter(u => u.status === "maintenance").length;
      const totalUnits = updatedUnits.length;
      const occupancyRate = totalUnits > 0 ? (leasedCount / totalUnits) * 100 : 0;
      
      // Calculate monthly revenue from leased units
      const monthlyRevenue = updatedUnits
        .filter(u => u.status === "leased")
        .reduce((total, u) => total + (u.rentAmount || 0), 0);
      
      // Update Firestore
      const propertyRef = doc(db, "properties", id);
      await updateDoc(propertyRef, {
        "unitDetails.units": updatedUnits,
        "unitDetails.vacantCount": vacantCount,
        "unitDetails.leasedCount": leasedCount,
        "unitDetails.maintenanceCount": maintenanceCount,
        "unitDetails.occupancyRate": occupancyRate,
        monthlyRevenue: monthlyRevenue,
        totalTenants: leasedCount,
        updatedAt: new Date()
      });
      
      // Update local state
      setUnits(updatedUnits);
      setProperty(prev => ({
        ...prev,
        unitDetails: {
          ...prev.unitDetails,
          units: updatedUnits,
          vacantCount,
          leasedCount,
          maintenanceCount,
          occupancyRate
        },
        monthlyRevenue,
        totalTenants: leasedCount
      }));
      
      alert(`Unit ${unit.unitNumber} status updated to ${newStatus}`);
    } catch (error) {
      console.error("Error updating unit status:", error);
      alert("Failed to update unit status");
    }
  };

  // Handle assign tenant
  const handleAssignTenant = (unitIndex) => {
    const unit = units[unitIndex];
    setSelectedUnitIndex(unitIndex);
    
    // Pre-fill form with unit rent amount
    setTenantForm({
      name: unit.tenantName || "",
      phone: unit.tenantPhone || "",
      email: unit.tenantEmail || "",
      leaseStart: unit.leaseStart || "",
      leaseEnd: unit.leaseEnd || "",
      rentAmount: unit.rentAmount || property?.rentAmount || "",
      deposit: unit.deposit || ""
    });
    
    setShowAssignForm(true);
  };

  // Handle tenant form submit
  const handleTenantSubmit = async (e) => {
    e.preventDefault();
    
    if (!tenantForm.name || !tenantForm.phone) {
      alert("Please fill in tenant name and phone number");
      return;
    }
    
    try {
      const updatedUnits = [...units];
      const unit = updatedUnits[selectedUnitIndex];
      
      // Update unit with tenant info
      unit.status = "leased";
      unit.tenantName = tenantForm.name;
      unit.tenantPhone = tenantForm.phone;
      unit.tenantEmail = tenantForm.email;
      unit.leaseStart = tenantForm.leaseStart;
      unit.leaseEnd = tenantForm.leaseEnd;
      unit.rentAmount = Number(tenantForm.rentAmount) || unit.rentAmount;
      unit.deposit = Number(tenantForm.deposit) || 0;
      unit.updatedAt = new Date().toISOString();
      
      // Recalculate counts
      const vacantCount = updatedUnits.filter(u => u.status === "vacant").length;
      const leasedCount = updatedUnits.filter(u => u.status === "leased").length;
      const maintenanceCount = updatedUnits.filter(u => u.status === "maintenance").length;
      const totalUnits = updatedUnits.length;
      const occupancyRate = totalUnits > 0 ? (leasedCount / totalUnits) * 100 : 0;
      
      // Calculate monthly revenue
      const monthlyRevenue = updatedUnits
        .filter(u => u.status === "leased")
        .reduce((total, u) => total + (u.rentAmount || 0), 0);
      
      // Update Firestore
      const propertyRef = doc(db, "properties", id);
      await updateDoc(propertyRef, {
        "unitDetails.units": updatedUnits,
        "unitDetails.vacantCount": vacantCount,
        "unitDetails.leasedCount": leasedCount,
        "unitDetails.maintenanceCount": maintenanceCount,
        "unitDetails.occupancyRate": occupancyRate,
        monthlyRevenue: monthlyRevenue,
        totalTenants: leasedCount,
        updatedAt: new Date()
      });
      
      // Also create tenant record in users collection
      try {
        const tenantData = {
          name: tenantForm.name,
          phone: tenantForm.phone,
          email: tenantForm.email || "",
          role: "tenant",
          propertyId: id,
          propertyName: property?.name,
          unitId: unit.unitId,
          unitNumber: unit.unitNumber,
          rentAmount: unit.rentAmount,
          leaseStart: tenantForm.leaseStart,
          leaseEnd: tenantForm.leaseEnd,
          status: "active",
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        
        // Add tenant to users collection
        const usersRef = collection(db, "users");
        const tenantRef = await addDoc(usersRef, tenantData);
        
        // Update unit with tenant ID
        unit.tenantId = tenantRef.id;
        
        // Update property again with tenant ID
        await updateDoc(propertyRef, {
          "unitDetails.units": updatedUnits
        });
        
        console.log("✅ Tenant created with ID:", tenantRef.id);
      } catch (tenantError) {
        console.log("⚠️ Could not create tenant record, continuing...", tenantError);
      }
      
      // Update local state
      setUnits(updatedUnits);
      setProperty(prev => ({
        ...prev,
        unitDetails: {
          ...prev.unitDetails,
          units: updatedUnits,
          vacantCount,
          leasedCount,
          maintenanceCount,
          occupancyRate
        },
        monthlyRevenue,
        totalTenants: leasedCount
      }));
      
      // Reset form
      setShowAssignForm(false);
      setTenantForm({
        name: "",
        phone: "",
        email: "",
        leaseStart: "",
        leaseEnd: "",
        rentAmount: "",
        deposit: ""
      });
      
      alert(`✅ Tenant ${tenantForm.name} assigned to Unit ${unit.unitNumber}`);
    } catch (error) {
      console.error("Error assigning tenant:", error);
      alert("Failed to assign tenant");
    }
  };

  // Handle edit unit
  const handleEditUnit = (unitIndex) => {
    setEditingUnit(unitIndex);
    // You can implement a modal or inline editing here
    alert("Edit feature coming soon! For now, use the status dropdown.");
  };

  // Filter units based on status
  const filteredUnits = units.filter(unit => {
    if (filter === "all") return true;
    return unit.status === filter;
  });

  // Get status icon
  const getStatusIcon = (status) => {
    switch(status) {
      case "vacant": return <FaDoorClosed />;
      case "leased": return <FaCheckCircle />;
      case "maintenance": return <FaTools />;
      default: return <FaHome />;
    }
  };

  // Get status color class
  const getStatusClass = (status) => {
    switch(status) {
      case "vacant": return "vacant";
      case "leased": return "leased";
      case "maintenance": return "maintenance";
      default: return "";
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
    if (!date) return "Not set";
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading units...</p>
      </div>
    );
  }

  if (!property) {
    return (
      <div className="error-container">
        <h2>Property not found</h2>
        <button onClick={() => navigate("/properties")}>
          Back to Properties
        </button>
      </div>
    );
  }

  return (
    <div className="property-units-container">
      {/* Header */}
      <div className="units-header">
        <button className="back-button" onClick={() => navigate("/properties")}>
          <FaArrowLeft /> Back to Properties
        </button>
        <div className="header-content">
          <h1>{property.name} - Units Management</h1>
          <p className="property-address">
            <FaBuilding /> {property.address}, {property.city}
          </p>
        </div>
      </div>

      {/* Stats Summary */}
      <div className="units-summary">
        <div className="summary-card total">
          <h3>{property.units || 1}</h3>
          <p>Total Units</p>
        </div>
        <div className="summary-card vacant">
          <h3>{property.unitDetails?.vacantCount || 0}</h3>
          <p>Vacant Units</p>
        </div>
        <div className="summary-card leased">
          <h3>{property.unitDetails?.leasedCount || 0}</h3>
          <p>Leased Units</p>
        </div>
        <div className="summary-card maintenance">
          <h3>{property.unitDetails?.maintenanceCount || 0}</h3>
          <p>Under Maintenance</p>
        </div>
        <div className="summary-card revenue">
          <h3>{formatCurrency(property.monthlyRevenue || 0)}</h3>
          <p>Monthly Revenue</p>
        </div>
        <div className="summary-card occupancy">
          <h3>{property.unitDetails?.occupancyRate?.toFixed(1) || 0}%</h3>
          <p>Occupancy Rate</p>
        </div>
      </div>

      {/* Filter Controls */}
      <div className="filter-controls">
        <div className="filter-buttons">
          <button 
            className={`filter-btn ${filter === 'all' ? 'active' : ''}`}
            onClick={() => setFilter('all')}
          >
            <FaFilter /> All Units ({units.length})
          </button>
          <button 
            className={`filter-btn ${filter === 'vacant' ? 'active' : ''}`}
            onClick={() => setFilter('vacant')}
          >
            <FaDoorClosed /> Vacant ({property.unitDetails?.vacantCount || 0})
          </button>
          <button 
            className={`filter-btn ${filter === 'leased' ? 'active' : ''}`}
            onClick={() => setFilter('leased')}
          >
            <FaCheckCircle /> Leased ({property.unitDetails?.leasedCount || 0})
          </button>
          <button 
            className={`filter-btn ${filter === 'maintenance' ? 'active' : ''}`}
            onClick={() => setFilter('maintenance')}
          >
            <FaTools /> Maintenance ({property.unitDetails?.maintenanceCount || 0})
          </button>
        </div>
        
        {/* Mobile App Notice */}
        <div className="mobile-app-notice">
          <span className="notice-icon">📱</span>
          <span className="notice-text">
            <strong>{property.unitDetails?.vacantCount || 0} units</strong> are visible to mobile app users
          </span>
        </div>
      </div>

      {/* Tenant Assignment Modal */}
      {showAssignForm && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>Assign Tenant to Unit {units[selectedUnitIndex]?.unitNumber}</h3>
              <button className="close-modal" onClick={() => setShowAssignForm(false)}>
                ×
              </button>
            </div>
            <form onSubmit={handleTenantSubmit} className="tenant-form">
              <div className="form-group">
                <label>Tenant Name *</label>
                <input
                  type="text"
                  value={tenantForm.name}
                  onChange={(e) => setTenantForm({...tenantForm, name: e.target.value})}
                  placeholder="Full name"
                  required
                />
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label>Phone Number *</label>
                  <input
                    type="tel"
                    value={tenantForm.phone}
                    onChange={(e) => setTenantForm({...tenantForm, phone: e.target.value})}
                    placeholder="0712345678"
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Email</label>
                  <input
                    type="email"
                    value={tenantForm.email}
                    onChange={(e) => setTenantForm({...tenantForm, email: e.target.value})}
                    placeholder="tenant@email.com"
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label>Lease Start Date</label>
                  <input
                    type="date"
                    value={tenantForm.leaseStart}
                    onChange={(e) => setTenantForm({...tenantForm, leaseStart: e.target.value})}
                  />
                </div>
                <div className="form-group">
                  <label>Lease End Date</label>
                  <input
                    type="date"
                    value={tenantForm.leaseEnd}
                    onChange={(e) => setTenantForm({...tenantForm, leaseEnd: e.target.value})}
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label>Monthly Rent (KSh)</label>
                  <input
                    type="number"
                    value={tenantForm.rentAmount}
                    onChange={(e) => setTenantForm({...tenantForm, rentAmount: e.target.value})}
                    placeholder="e.g., 15000"
                  />
                </div>
                <div className="form-group">
                  <label>Security Deposit (KSh)</label>
                  <input
                    type="number"
                    value={tenantForm.deposit}
                    onChange={(e) => setTenantForm({...tenantForm, deposit: e.target.value})}
                    placeholder="e.g., 30000"
                  />
                </div>
              </div>
              
              <div className="modal-actions">
                <button 
                  type="button" 
                  className="cancel-btn"
                  onClick={() => setShowAssignForm(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="submit-btn">
                  <FaUserPlus /> Assign Tenant
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Units Grid */}
      <div className="units-grid">
        {filteredUnits.length === 0 ? (
          <div className="no-units">
            <FaHome className="empty-icon" />
            <h3>No units found</h3>
            <p>Try changing your filter</p>
          </div>
        ) : (
          filteredUnits.map((unit, index) => (
            <div key={index} className={`unit-card ${getStatusClass(unit.status)}`}>
              <div className="unit-header">
                <div className="unit-title-section">
                  <h3 className="unit-title">{unit.unitName}</h3>
                  <span className="unit-id">{unit.unitId}</span>
                </div>
                <span className={`unit-status-badge ${getStatusClass(unit.status)}`}>
                  {getStatusIcon(unit.status)}
                  <span>{unit.status.toUpperCase()}</span>
                </span>
              </div>
              
              <div className="unit-details">
                <div className="detail-row">
                  <span className="detail-label">Unit Number:</span>
                  <span className="detail-value">{unit.unitNumber}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Rent Amount:</span>
                  <span className="detail-value rent">
                    <FaDollarSign /> {formatCurrency(unit.rentAmount)}/month
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Size:</span>
                  <span className="detail-value">{unit.size || "N/A"}</span>
                </div>
                {unit.amenities && unit.amenities.length > 0 && (
                  <div className="detail-row">
                    <span className="detail-label">Amenities:</span>
                    <span className="detail-value amenities">
                      {unit.amenities.slice(0, 2).join(', ')}
                      {unit.amenities.length > 2 ? '...' : ''}
                    </span>
                  </div>
                )}
              </div>

              {/* Tenant Info (if leased) */}
              {unit.status === "leased" && unit.tenantName && (
                <div className="tenant-info">
                  <h4><FaUser /> Tenant Details</h4>
                  <div className="detail-row">
                    <span className="detail-label">Name:</span>
                    <span className="detail-value tenant-name">{unit.tenantName}</span>
                  </div>
                  {unit.tenantPhone && (
                    <div className="detail-row">
                      <span className="detail-label">Phone:</span>
                      <span className="detail-value">
                        <FaPhone /> {unit.tenantPhone}
                      </span>
                    </div>
                  )}
                  {unit.leaseStart && (
                    <div className="detail-row">
                      <span className="detail-label">Lease Period:</span>
                      <span className="detail-value">
                        <FaCalendar /> {formatDate(unit.leaseStart)} to {formatDate(unit.leaseEnd)}
                      </span>
                    </div>
                  )}
                </div>
              )}

              {/* Unit Notes */}
              {unit.notes && (
                <div className="unit-notes">
                  <span className="notes-label">Notes:</span>
                  <p className="notes-content">{unit.notes}</p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="unit-actions">
                <div className="status-control">
                  <span className="action-label">Change Status:</span>
                  <select
                    value={unit.status}
                    onChange={(e) => handleStatusUpdate(index, e.target.value)}
                    className="status-select"
                  >
                    <option value="vacant">Vacant</option>
                    <option value="leased">Leased</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>
                
                <div className="action-buttons">
                  {unit.status === "vacant" && (
                    <button 
                      className="action-btn assign-btn"
                      onClick={() => handleAssignTenant(index)}
                    >
                      <FaUserPlus /> Assign Tenant
                    </button>
                  )}
                  
                  <button 
                    className="action-btn edit-btn"
                    onClick={() => handleEditUnit(index)}
                  >
                    <FaEdit /> Edit
                  </button>
                  
                  <button 
                    className="action-btn view-btn"
                    onClick={() => alert(`View unit ${unit.unitNumber} details`)}
                  >
                    <FaExpand /> Details
                  </button>
                </div>
              </div>
              
              {/* Last Updated */}
              <div className="unit-footer">
                <span className="updated-text">
                  Updated: {formatDate(unit.updatedAt)}
                </span>
              </div>
            </div>
          ))
        )}
      </div>
      
      {/* Quick Actions */}
      <div className="quick-actions">
        <h3>Quick Actions</h3>
        <div className="action-buttons-grid">
          <button className="quick-action-btn" onClick={() => navigate(`/property/${id}/edit`)}>
            <FaEdit /> Edit Property Details
          </button>
          <button className="quick-action-btn" onClick={() => window.print()}>
            <FaChartLine /> Print Unit Report
          </button>
          <button className="quick-action-btn" onClick={() => alert("Export feature coming soon")}>
            📊 Export to Excel
          </button>
        </div>
      </div>
    </div>
  );
};

export default PropertyUnits;