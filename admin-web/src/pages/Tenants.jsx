import React, { useState, useEffect } from "react";
import { db } from "../pages/firebase/firebase";
import { 
  collection, 
  getDocs, 
  query, 
  orderBy,
  deleteDoc,
  doc,
  Timestamp
} from "firebase/firestore";
import { 
  FaUser, 
  FaHome, 
  FaPhone, 
  FaEnvelope, 
  FaDollarSign, 
  FaCalendar,
  FaEdit,
  FaTrash,
  FaPlus,
  FaSearch,
  FaFilter
} from "react-icons/fa";
import { useNavigate } from "react-router-dom";
import "../styles/tenants.css";

const Tenants = () => {
  const navigate = useNavigate();
  const [tenants, setTenants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");

  // Fetch tenants from Firestore
  useEffect(() => {
    fetchTenants();
  }, []);

  const fetchTenants = async () => {
    try {
      setLoading(true);
      const q = query(
        collection(db, "tenants"),
        orderBy("createdAt", "desc")
      );
      
      const snapshot = await getDocs(q);
      const tenantList = [];
      
      snapshot.forEach((doc) => {
        const data = doc.data();
        tenantList.push({
          id: doc.id,
          ...data,
          // Convert timestamps
          leaseStart: data.leaseStart?.toDate(),
          leaseEnd: data.leaseEnd?.toDate(),
          createdAt: data.createdAt?.toDate(),
        });
      });
      
      setTenants(tenantList);
    } catch (error) {
      console.error("Error fetching tenants:", error);
    } finally {
      setLoading(false);
    }
  };

  // Delete tenant
  const handleDeleteTenant = async (tenantId, tenantName) => {
    if (!window.confirm(`Delete tenant ${tenantName}? This will free up their unit.`)) {
      return;
    }
    
    try {
      await deleteDoc(doc(db, "tenants", tenantId));
      
      // Also update the unit status back to vacant
      const tenant = tenants.find(t => t.id === tenantId);
      if (tenant?.unitId) {
        // You might want to update the unit status here
        // await updateDoc(doc(db, "units", tenant.unitId), { status: "vacant" });
      }
      
      alert("Tenant deleted successfully");
      fetchTenants(); // Refresh list
    } catch (error) {
      console.error("Error deleting tenant:", error);
      alert("Failed to delete tenant");
    }
  };

  // Filter tenants
  const filteredTenants = tenants.filter(tenant => {
    // Search filter
    const matchesSearch = 
      tenant.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tenant.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tenant.phone?.includes(searchTerm) ||
      tenant.propertyId?.toLowerCase().includes(searchTerm.toLowerCase());
    
    // Status filter
    const matchesStatus = 
      filterStatus === "all" || 
      tenant.status?.toLowerCase() === filterStatus.toLowerCase();
    
    return matchesSearch && matchesStatus;
  });

  // Format date
  const formatDate = (date) => {
    if (!date) return "N/A";
    return date.toLocaleDateString();
  };

  // Get status badge color
  const getStatusBadge = (status) => {
    switch (status?.toLowerCase()) {
      case "active":
        return <span className="status-badge active">Active</span>;
      case "pending":
        return <span className="status-badge pending">Pending</span>;
      case "inactive":
        return <span className="status-badge inactive">Inactive</span>;
      default:
        return <span className="status-badge unknown">{status || "Unknown"}</span>;
    }
  };

  if (loading) {
    return (
      <div className="tenants-container">
        <div className="loading">Loading tenants...</div>
      </div>
    );
  }

  return (
    <div className="tenant-container">
      {/* Header */}
      <div className="tenant-header">
        <div>
          <h1>Tenants Management</h1>
          <p>Manage all registered tenants and their information</p>
        </div>
        
        <button 
          className="tenant-add-btn"
          onClick={() => navigate("/tenants/add")}
        >
          <FaPlus /> Add New Tenant
        </button>
      </div>

      {/* Stats */}
      <div className="tenant-stats">
        <div className="tenant-stat-card">
          <h3>{tenants.length}</h3>
          <p>Total Tenants</p>
        </div>
        <div className="tenant-stat-card">
          <h3>{tenants.filter(t => t.status === "active").length}</h3>
          <p>Active Tenants</p>
        </div>
        <div className="tenant-stat-card">
          <h3>{tenants.filter(t => t.status === "pending").length}</h3>
          <p>Pending</p>
        </div>
        <div className="tenant-stat-card">
          <h3>
            KSh {tenants
              .filter(t => t.status === "active")
              .reduce((sum, tenant) => sum + (tenant.monthlyRent || 0), 0)
              .toLocaleString()}
          </h3>
          <p>Monthly Revenue</p>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="tenant-controls">
        <div className="tenant-search-box">
          <FaSearch />
          <input
            type="text"
            placeholder="Search by name, email, phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <div className="tenant-filter-box">
          <FaFilter />
          <select 
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      {/* Tenants Table */}
      <div className="tenant-table-container">
        {filteredTenants.length === 0 ? (
          <div className="tenant-no-tenants">
            <FaUser className="tenant-no-tenants-icon" />
            <h3>No tenants found</h3>
            <p>{searchTerm ? "Try a different search term" : "Add your first tenant to get started"}</p>
            {!searchTerm && (
              <button 
                className="tenant-add-first-btn"
                onClick={() => navigate("/tenants/add")}
              >
                <FaPlus /> Add First Tenant
              </button>
            )}
          </div>
        ) : (
          <div className="tenant-grid">
            {filteredTenants.map((tenant) => (
              <div key={tenant.id} className="tenant-card">
                <div className="tenant-card-header">
                  <div className="tenant-avatar">
                    <FaUser />
                  </div>
                  <div className="tenant-basic-info">
                    <h3>{tenant.fullName}</h3>
                    <p><FaEnvelope /> {tenant.email}</p>
                    <p><FaPhone /> {tenant.phone}</p>
                  </div>
                  <div className="tenant-status">
                    {getStatusBadge(tenant.status)}
                  </div>
                </div>

                <div className="tenant-card-details">
                  <div className="detail-row">
                    <span className="detail-label"><FaHome /> Property:</span>
                    <span className="detail-value">
                      {tenant.propertyName || `Property ${tenant.propertyId}`}
                    </span>
                  </div>
                  
                  <div className="detail-row">
                    <span className="detail-label">Unit:</span>
                    <span className="detail-value">
                      {tenant.unitNumber || `Unit ${tenant.unitId}`}
                    </span>
                  </div>
                  
                  <div className="detail-row">
                    <span className="detail-label"><FaDollarSign /> Rent:</span>
                    <span className="detail-value">
                      KSh {(tenant.monthlyRent || 0).toLocaleString()}/month
                    </span>
                  </div>
                  
                  <div className="detail-row">
                    <span className="detail-label"><FaCalendar /> Lease:</span>
                    <span className="detail-value">
                      {formatDate(tenant.leaseStart)} to {formatDate(tenant.leaseEnd)}
                    </span>
                  </div>
                </div>

                <div className="tenant-card-actions">
                  <button 
                    className="btn-view"
                    onClick={() => navigate(`/tenants/${tenant.id}`)} // Create view page later
                  >
                    <FaUser /> View
                  </button>
                  
                  <button 
                    className="btn-edit"
                    onClick={() => navigate(`/tenants/edit/${tenant.id}`)} // Create edit page later
                  >
                    <FaEdit /> Edit
                  </button>
                  
                  <button 
                    className="btn-delete"
                    onClick={() => handleDeleteTenant(tenant.id, tenant.fullName)}
                  >
                    <FaTrash /> Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Tenants;