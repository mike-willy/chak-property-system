import React, { useState, useEffect } from "react";
import { db } from "../pages/firebase/firebase";
import { 
  collection, 
  addDoc, 
  getDocs,
  query,
  where,
  updateDoc,
  doc,
  Timestamp 
} from "firebase/firestore";
import { useNavigate, useLocation } from "react-router-dom";
import { FaUserPlus, FaHome, FaDollarSign, FaCalendar, FaUsers, FaTimes } from "react-icons/fa";
import "../styles/addTenant.css";

const AddTenant = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [properties, setProperties] = useState([]);
  const [units, setUnits] = useState([]);
  const [loading, setLoading] = useState(false);
  
  // Check for prefill data from applications
  const [prefillData, setPrefillData] = useState(() => {
    if (location.state?.prefillData) {
      return location.state.prefillData;
    }
    const stored = localStorage.getItem('prefillTenantData');
    if (stored) {
      localStorage.removeItem('prefillTenantData');
      return JSON.parse(stored);
    }
    return null;
  });
  
  // Form state
  const [formData, setFormData] = useState({
    fullName: prefillData?.fullName || "",
    email: prefillData?.email || "",
    phone: prefillData?.phone || "",
    idNumber: "",
    propertyId: prefillData?.propertyId || "",
    unitId: prefillData?.unitId || "",
    leaseStart: "",
    leaseEnd: "",
    monthlyRent: prefillData?.monthlyRent || "",
    securityDeposit: "",
    emergencyContactName: "",
    emergencyContactPhone: "",
  });

  useEffect(() => {
    loadProperties();
    if (prefillData?.propertyId) {
      loadUnits(prefillData.propertyId);
    }
  }, []);

  const loadProperties = async () => {
    try {
      const snapshot = await getDocs(collection(db, "properties"));
      const propertyList = [];
      snapshot.forEach((doc) => {
        propertyList.push({
          id: doc.id,
          name: doc.data().name,
          ...doc.data()
        });
      });
      setProperties(propertyList);
    } catch (error) {
      console.error("Error loading properties:", error);
    }
  };

  const loadUnits = async (propertyId) => {
    try {
      const q = query(
        collection(db, "units"),
        where("propertyId", "==", propertyId),
        where("status", "==", "vacant")
      );
      
      const snapshot = await getDocs(q);
      const unitList = [];
      snapshot.forEach((doc) => {
        unitList.push({
          id: doc.id,
          unitNumber: doc.data().unitNumber,
          monthlyRent: doc.data().monthlyRent,
          type: doc.data().type || "Apartment",
          ...doc.data()
        });
      });
      setUnits(unitList);
    } catch (error) {
      console.error("Error loading units:", error);
    }
  };

  const handlePropertyChange = (propertyId) => {
    setFormData({
      ...formData,
      propertyId,
      unitId: "",
      monthlyRent: ""
    });
    loadUnits(propertyId);
  };

  const handleUnitChange = (unitId) => {
    const selectedUnit = units.find(unit => unit.id === unitId);
    setFormData({
      ...formData,
      unitId,
      monthlyRent: selectedUnit?.monthlyRent || ""
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (!formData.fullName || !formData.email || !formData.propertyId || !formData.unitId) {
        alert("Please fill all required fields");
        setLoading(false);
        return;
      }

      const tenantData = {
        fullName: formData.fullName,
        email: formData.email,
        phone: formData.phone,
        idNumber: formData.idNumber,
        propertyId: formData.propertyId,
        unitId: formData.unitId,
        monthlyRent: parseFloat(formData.monthlyRent) || 0,
        securityDeposit: parseFloat(formData.securityDeposit) || parseFloat(formData.monthlyRent) || 0,
        emergencyContactName: formData.emergencyContactName,
        emergencyContactPhone: formData.emergencyContactPhone,
        status: "active",
        leaseStart: Timestamp.fromDate(new Date(formData.leaseStart)),
        leaseEnd: Timestamp.fromDate(new Date(formData.leaseEnd)),
        createdAt: Timestamp.now(),
        createdBy: "admin",
        balance: 0,
      };

      const tenantRef = await addDoc(collection(db, "tenants"), tenantData);

      if (formData.unitId) {
        await updateDoc(doc(db, "units", formData.unitId), {
          status: "occupied",
          tenantId: tenantRef.id,
          tenantName: formData.fullName,
          occupiedAt: Timestamp.now(),
        });
      }

      if (prefillData?.applicationId) {
        await updateDoc(doc(db, "tenantApplications", prefillData.applicationId), {
          status: "approved",
          processedAt: Timestamp.now(),
          tenantId: tenantRef.id,
        });
      }

      alert("Tenant added successfully!");
      navigate("/tenants");
      
    } catch (error) {
      console.error("Error adding tenant:", error);
      alert("Failed to add tenant. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  return (
    <div className="add-tenant-page">
      {/* Header with both buttons */}
      <div className="page-header">
        <div className="header-left">
          <h1><FaUserPlus /> Add New Tenant</h1>
          {prefillData && (
            <div className="prefill-notice">
              ✓ Pre-filled from tenant application
            </div>
          )}
        </div>
        
        <div className="header-actions">
          <button 
            className="view-tenants-btn" 
            onClick={() => navigate("/tenants")}
          >
            <FaUsers /> View Tenants
          </button>
        </div>
      </div>

      <div className="page-content">
        <form onSubmit={handleSubmit} className="tenant-form">
          
          {/* Section 1: Tenant Information */}
          <div className="form-section">
            <h2><FaUserPlus /> Tenant Information</h2>
            <div className="form-grid">
              <div className="form-group">
                <label>Full Name *</label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  required
                  placeholder="John Doe"
                />
              </div>
              
              <div className="form-group">
                <label>Email Address *</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                  placeholder="john@example.com"
                />
              </div>
              
              <div className="form-group">
                <label>Phone Number *</label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleInputChange}
                  required
                  placeholder="+254 712 345 678"
                />
              </div>
              
              <div className="form-group">
                <label>ID/Passport Number</label>
                <input
                  type="text"
                  name="idNumber"
                  value={formData.idNumber}
                  onChange={handleInputChange}
                  placeholder="12345678"
                />
              </div>
            </div>
          </div>

          {/* Section 2: Property & Unit */}
          <div className="form-section">
            <h2><FaHome /> Property & Unit</h2>
            <div className="form-grid">
              <div className="form-group">
                <label>Select Property *</label>
                <select
                  name="propertyId"
                  value={formData.propertyId}
                  onChange={(e) => handlePropertyChange(e.target.value)}
                  required
                >
                  <option value="">Choose a property</option>
                  {properties.map(property => (
                    <option key={property.id} value={property.id}>
                      {property.name} - {property.address}
                    </option>
                  ))}
                </select>
              </div>
              
              <div className="form-group">
                <label>Select Unit *</label>
                <select
                  name="unitId"
                  value={formData.unitId}
                  onChange={(e) => handleUnitChange(e.target.value)}
                  required
                  disabled={!formData.propertyId}
                >
                  <option value="">Choose a unit</option>
                  {units.map(unit => (
                    <option key={unit.id} value={unit.id}>
                      {unit.unitNumber} ({unit.type}) - KSh {unit.monthlyRent?.toLocaleString()}/month
                    </option>
                  ))}
                </select>
                {units.length === 0 && formData.propertyId && (
                  <p className="helper-text">No vacant units available for this property</p>
                )}
              </div>
            </div>
          </div>

          {/* Section 3: Financial Details */}
          <div className="form-section">
            <h2><FaDollarSign /> Financial Details</h2>
            <div className="form-grid">
              <div className="form-group">
                <label>Monthly Rent (KSh) *</label>
                <input
                  type="number"
                  name="monthlyRent"
                  value={formData.monthlyRent}
                  onChange={handleInputChange}
                  required
                  placeholder="25000"
                  min="0"
                />
              </div>
              
              <div className="form-group">
                <label>Security Deposit (KSh)</label>
                <input
                  type="number"
                  name="securityDeposit"
                  value={formData.securityDeposit}
                  onChange={handleInputChange}
                  placeholder="25000"
                  min="0"
                />
                <p className="helper-text">Usually equal to one month's rent</p>
              </div>
            </div>
          </div>

          {/* Section 4: Lease Period */}
          <div className="form-section">
            <h2><FaCalendar /> Lease Period</h2>
            <div className="form-grid">
              <div className="form-group">
                <label>Lease Start Date *</label>
                <input
                  type="date"
                  name="leaseStart"
                  value={formData.leaseStart}
                  onChange={handleInputChange}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Lease End Date *</label>
                <input
                  type="date"
                  name="leaseEnd"
                  value={formData.leaseEnd}
                  onChange={handleInputChange}
                  required
                />
              </div>
            </div>
          </div>

          {/* Section 5: Emergency Contact */}
          <div className="form-section">
            <h2>Emergency Contact</h2>
            <div className="form-grid">
              <div className="form-group">
                <label>Contact Name</label>
                <input
                  type="text"
                  name="emergencyContactName"
                  value={formData.emergencyContactName}
                  onChange={handleInputChange}
                  placeholder="Emergency contact person"
                />
              </div>
              
              <div className="form-group">
                <label>Contact Phone</label>
                <input
                  type="tel"
                  name="emergencyContactPhone"
                  value={formData.emergencyContactPhone}
                  onChange={handleInputChange}
                  placeholder="+254 700 000 000"
                />
              </div>
            </div>
          </div>

          {/* Form Actions */}
          <div className="form-actions">
            <button type="button" className="btn-cancel" onClick={() => navigate("/tenants")}>
              <FaTimes /> Cancel
            </button>
            <button type="submit" className="btn-submit" disabled={loading}>
              {loading ? "Adding Tenant..." : "Add Tenant"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddTenant;