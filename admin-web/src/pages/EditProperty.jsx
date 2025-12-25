// src/pages/EditProperty.jsx
import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { 
  doc, 
  getDoc, 
  updateDoc,
  arrayUnion,
  arrayRemove,
  Timestamp
} from "firebase/firestore";
import { db, storage } from "../pages/firebase/firebase";
import { ref, uploadBytes, getDownloadURL, deleteObject } from "firebase/storage";
import "../styles/EditProperty.css";
import { 
  FaSave, 
  FaTimes, 
  FaHome, 
  FaBed, 
  FaBath, 
  FaRulerCombined,
  FaDollarSign,
  FaUser,
  FaPhone,
  FaEnvelope,
  FaCalendar,
  FaImages,
  FaFileAlt,
  FaPlus,
  FaTrash,
  FaChevronUp,
  FaChevronDown,
  FaCalculator,
  FaChartLine,
  FaUpload,
  FaCheck,
  FaBuilding,
  FaKey,
  FaWifi,
  FaCar,
  FaSwimmingPool,
  FaDumbbell,
  FaDog,
  FaSmokingBan,
  FaParking
} from "react-icons/fa";

const EditProperty = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingImages, setUploadingImages] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  // Property state with all fields
  const [property, setProperty] = useState({
    // Basic Information
    name: '',
    address: '',
    city: '',
    postalCode: '',
    country: 'Kenya',
    propertyType: 'apartment',
    description: '',
    
    // Financial Details
    rentAmount: 0,
    depositAmount: 0,
    securityDeposit: 0,
    paymentFrequency: 'monthly',
    utilitiesIncluded: [],
    additionalFees: [],
    
    // Property Specifications
    bedrooms: 1,
    bathrooms: 1,
    size: 0,
    sizeUnit: 'sqft',
    yearBuilt: new Date().getFullYear(),
    floor: '',
    totalFloors: 1,
    parkingSpaces: 0,
    furnished: false,
    furnishedDetails: '',
    
    // Units Management
    units: 1,
    unitDetails: {
      totalUnits: 1,
      vacantCount: 1,
      leasedCount: 0,
      maintenanceCount: 0,
      occupancyRate: 0,
      units: []
    },
    
    // Landlord/Owner Information
    landlordName: '',
    landlordPhone: '',
    landlordEmail: '',
    landlordAddress: '',
    managementCompany: '',
    managementContact: '',
    
    // Status & Availability
    status: 'available',
    dateAvailable: '',
    minimumLease: 12,
    maximumLease: 24,
    availableFrom: '',
    applicationFee: 0,
    screeningRequired: true,
    
    // Media
    images: [],
    documents: [],
    floorPlans: [],
    virtualTour: '',
    
    // Amenities & Features
    amenities: [],
    features: [],
    rules: [],
    
    // Advanced Details
    propertyTax: 0,
    insurance: 0,
    maintenanceCost: 0,
    hoaFees: 0,
    notes: '',
    
    // Timestamps
    createdAt: new Date(),
    updatedAt: new Date()
  });

  // Available options
  const propertyTypes = [
    'apartment', 'house', 'condo', 'townhouse', 'studio', 
    'commercial', 'office', 'retail', 'industrial', 'land'
  ];
  
  const utilitiesOptions = [
    'water', 'electricity', 'gas', 'internet', 'cable_tv',
    'trash', 'sewage', 'heating', 'cooling', 'maintenance'
  ];
  
  const amenitiesOptions = [
    { id: 'parking', label: 'Parking', icon: <FaParking /> },
    { id: 'wifi', label: 'WiFi', icon: <FaWifi /> },
    { id: 'pool', label: 'Swimming Pool', icon: <FaSwimmingPool /> },
    { id: 'gym', label: 'Gym', icon: <FaDumbbell /> },
    { id: 'security', label: 'Security', icon: <FaKey /> },
    { id: 'elevator', label: 'Elevator', icon: <FaBuilding /> },
    { id: 'laundry', label: 'Laundry Facilities', icon: <FaBuilding /> },
    { id: 'pets', label: 'Pet Friendly', icon: <FaDog /> },
    { id: 'smoke_free', label: 'Smoke Free', icon: <FaSmokingBan /> },
    { id: 'furnished', label: 'Furnished', icon: <FaHome /> }
  ];

  const paymentFrequencies = [
    'monthly', 'quarterly', 'biannually', 'annually'
  ];

  // Fetch property data
  useEffect(() => {
    fetchProperty();
  }, [id]);

  const fetchProperty = async () => {
    try {
      setLoading(true);
      const docRef = doc(db, "properties", id);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        
        // Format dates
        const formatDate = (date) => {
          if (!date) return '';
          if (date.toDate) return date.toDate().toISOString().split('T')[0];
          return new Date(date).toISOString().split('T')[0];
        };

        setProperty({
          ...data,
          dateAvailable: formatDate(data.dateAvailable),
          availableFrom: formatDate(data.availableFrom),
          // Ensure arrays exist
          utilitiesIncluded: data.utilitiesIncluded || [],
          amenities: data.amenities || [],
          features: data.features || [],
          rules: data.rules || [],
          additionalFees: data.additionalFees || [],
          images: data.images || [],
          documents: data.documents || [],
          floorPlans: data.floorPlans || [],
          // Ensure unitDetails has proper structure
          unitDetails: {
            totalUnits: data.unitDetails?.totalUnits || data.units || 1,
            vacantCount: data.unitDetails?.vacantCount || (data.units || 1),
            leasedCount: data.unitDetails?.leasedCount || 0,
            maintenanceCount: data.unitDetails?.maintenanceCount || 0,
            occupancyRate: data.unitDetails?.occupancyRate || 0,
            units: data.unitDetails?.units || []
          }
        });
      } else {
        alert("Property not found");
        navigate("/properties");
      }
    } catch (error) {
      console.error("Error fetching property:", error);
      alert("Failed to load property");
    } finally {
      setLoading(false);
    }
  };

  // Handle input changes
  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    
    setProperty(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : 
              type === 'number' ? parseFloat(value) || 0 : 
              value
    }));
  };

  // Handle nested object changes
  const handleNestedChange = (parent, field, value) => {
    setProperty(prev => ({
      ...prev,
      [parent]: {
        ...prev[parent],
        [field]: value
      }
    }));
  };

  // Handle array toggles (for amenities, utilities, etc.)
  const handleArrayToggle = (arrayName, value) => {
    setProperty(prev => {
      const currentArray = prev[arrayName] || [];
      const newArray = currentArray.includes(value)
        ? currentArray.filter(item => item !== value)
        : [...currentArray, value];
      
      return {
        ...prev,
        [arrayName]: newArray
      };
    });
  };

  // UNITS MANAGEMENT FUNCTIONS

  // Handle total units change
  const handleUnitsChange = (newTotalUnits) => {
    const currentUnits = property.unitDetails.units || [];
    const currentTotal = property.units || 1;
    
    if (newTotalUnits === currentTotal) return;
    
    if (newTotalUnits > currentTotal) {
      // Add new units
      const unitsToAdd = newTotalUnits - currentTotal;
      const newUnits = [...currentUnits];
      
      for (let i = 0; i < unitsToAdd; i++) {
        const unitNumber = currentTotal + i + 1;
        newUnits.push({
          id: `unit-${Date.now()}-${i}`,
          unitNumber: `Unit ${unitNumber}`,
          rent: property.rentAmount,
          status: 'vacant',
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          size: property.size,
          notes: ''
        });
      }
      
      setProperty(prev => ({
        ...prev,
        units: newTotalUnits,
        unitDetails: {
          ...prev.unitDetails,
          totalUnits: newTotalUnits,
          vacantCount: (prev.unitDetails.vacantCount || 0) + unitsToAdd,
          units: newUnits
        }
      }));
      
    } else {
      // Remove units (with confirmation)
      if (window.confirm(`Remove ${currentTotal - newTotalUnits} units? This will delete unit data.`)) {
        const newUnits = currentUnits.slice(0, newTotalUnits);
        
        setProperty(prev => ({
          ...prev,
          units: newTotalUnits,
          unitDetails: {
            ...prev.unitDetails,
            totalUnits: newTotalUnits,
            vacantCount: Math.min(prev.unitDetails.vacantCount || 0, newTotalUnits),
            leasedCount: Math.min(prev.unitDetails.leasedCount || 0, newTotalUnits),
            maintenanceCount: Math.min(prev.unitDetails.maintenanceCount || 0, newTotalUnits),
            units: newUnits
          }
        }));
      }
    }
  };

  // Edit individual unit
  const editIndividualUnit = (index, updates) => {
    setProperty(prev => {
      const newUnits = [...prev.unitDetails.units];
      newUnits[index] = { ...newUnits[index], ...updates };
      
      // Recalculate counts based on status changes
      if (updates.status) {
        const vacantCount = newUnits.filter(u => u.status === 'vacant').length;
        const leasedCount = newUnits.filter(u => u.status === 'leased').length;
        const maintenanceCount = newUnits.filter(u => u.status === 'maintenance').length;
        
        return {
          ...prev,
          unitDetails: {
            ...prev.unitDetails,
            vacantCount,
            leasedCount,
            maintenanceCount,
            occupancyRate: Math.round((leasedCount / newUnits.length) * 100),
            units: newUnits
          }
        };
      }
      
      return {
        ...prev,
        unitDetails: {
          ...prev.unitDetails,
          units: newUnits
        }
      };
    });
  };

  // Bulk update unit statuses
  const bulkUpdateUnitStatus = (status, count = null) => {
    setProperty(prev => {
      const newUnits = [...prev.unitDetails.units];
      const unitsToUpdate = count ? newUnits.slice(0, count) : newUnits;
      
      unitsToUpdate.forEach((unit, index) => {
        newUnits[index] = { ...unit, status };
      });
      
      const vacantCount = newUnits.filter(u => u.status === 'vacant').length;
      const leasedCount = newUnits.filter(u => u.status === 'leased').length;
      const maintenanceCount = newUnits.filter(u => u.status === 'maintenance').length;
      
      return {
        ...prev,
        unitDetails: {
          ...prev.unitDetails,
          vacantCount,
          leasedCount,
          maintenanceCount,
          occupancyRate: Math.round((leasedCount / newUnits.length) * 100),
          units: newUnits
        }
      };
    });
  };

  // Bulk update rents
  const bulkUpdateRents = (percentageChange) => {
    setProperty(prev => {
      const newUnits = prev.unitDetails.units.map(unit => ({
        ...unit,
        rent: Math.round(unit.rent * (1 + percentageChange / 100))
      }));
      
      return {
        ...prev,
        unitDetails: {
          ...prev.unitDetails,
          units: newUnits
        }
      };
    });
  };

  // IMAGE MANAGEMENT

  const handleImageUpload = async (e) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;

    setUploadingImages(true);
    try {
      const uploadPromises = files.map(async (file) => {
        const storageRef = ref(storage, `properties/${id}/images/${Date.now()}-${file.name}`);
        await uploadBytes(storageRef, file);
        const downloadURL = await getDownloadURL(storageRef);
        return downloadURL;
      });

      const uploadedURLs = await Promise.all(uploadPromises);
      
      setProperty(prev => ({
        ...prev,
        images: [...prev.images, ...uploadedURLs]
      }));
      
    } catch (error) {
      console.error("Error uploading images:", error);
      alert("Failed to upload some images");
    } finally {
      setUploadingImages(false);
    }
  };

  const removeImage = (index) => {
    setProperty(prev => ({
      ...prev,
      images: prev.images.filter((_, i) => i !== index)
    }));
  };

  const moveImage = (index, direction) => {
    if (
      (direction === -1 && index === 0) ||
      (direction === 1 && index === property.images.length - 1)
    ) return;

    const newImages = [...property.images];
    [newImages[index], newImages[index + direction]] = 
    [newImages[index + direction], newImages[index]];
    
    setProperty(prev => ({
      ...prev,
      images: newImages
    }));
  };

  // FINANCIAL CALCULATIONS

  const calculateTotalMonthlyRevenue = () => {
    if (property.units === 1) return property.rentAmount;
    
    return property.unitDetails.units.reduce((total, unit) => {
      return total + (unit.status === 'leased' ? unit.rent : 0);
    }, 0);
  };

  const calculatePotentialRevenue = () => {
    if (property.units === 1) return property.rentAmount;
    
    return property.unitDetails.units.reduce((total, unit) => {
      return total + unit.rent;
    }, 0);
  };

  const calculateVacancyCost = () => {
    if (property.units === 1) {
      return property.status === 'vacant' ? property.rentAmount : 0;
    }
    
    const vacantUnits = property.unitDetails.units.filter(u => u.status === 'vacant');
    return vacantUnits.reduce((total, unit) => total + unit.rent, 0);
  };

  // ADDITIONAL FEES MANAGEMENT

  const addAdditionalFee = () => {
    const feeName = prompt("Enter fee name:");
    const feeAmount = parseFloat(prompt("Enter fee amount:"));
    
    if (feeName && !isNaN(feeAmount)) {
      setProperty(prev => ({
        ...prev,
        additionalFees: [...prev.additionalFees, { name: feeName, amount: feeAmount, frequency: 'monthly' }]
      }));
    }
  };

  const removeAdditionalFee = (index) => {
    setProperty(prev => ({
      ...prev,
      additionalFees: prev.additionalFees.filter((_, i) => i !== index)
    }));
  };

  // SAVE PROPERTY

  const handleSave = async () => {
    if (!property.name.trim()) {
      alert("Property name is required");
      return;
    }

    setSaving(true);
    try {
      const propertyRef = doc(db, "properties", id);
      
      // Prepare data for Firestore
      const updateData = {
        ...property,
        updatedAt: Timestamp.now(),
        // Convert date strings to Timestamps
        dateAvailable: property.dateAvailable ? Timestamp.fromDate(new Date(property.dateAvailable)) : null,
        availableFrom: property.availableFrom ? Timestamp.fromDate(new Date(property.availableFrom)) : null
      };

      await updateDoc(propertyRef, updateData);
      
      alert("Property updated successfully!");
      navigate(`/property/${id}/units`);
      
    } catch (error) {
      console.error("Error updating property:", error);
      alert("Failed to update property");
    } finally {
      setSaving(false);
    }
  };

  // CANCEL

  const handleCancel = () => {
    if (window.confirm("Are you sure you want to cancel? All unsaved changes will be lost.")) {
      navigate(-1);
    }
  };

  // FORMAT CURRENCY

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-KE', {
      style: 'currency',
      currency: 'KES',
      minimumFractionDigits: 0
    }).format(amount || 0);
  };

  if (loading) {
    return (
      <div className="edit-property-loading">
        <div className="spinner"></div>
        <p>Loading property data...</p>
      </div>
    );
  }

  return (
    <div className="edit-property-container">
      {/* Header */}
      <div className="edit-property-header">
        <div className="header-left">
          <h1>
            <FaHome /> Edit Property: <span className="property-name-highlight">{property.name}</span>
          </h1>
          <p className="header-subtitle">
            Update property details, manage units, and configure advanced settings.
          </p>
        </div>
        <div className="header-actions">
          <button 
            className="btn-cancel"
            onClick={handleCancel}
            disabled={saving}
          >
            <FaTimes /> Cancel
          </button>
          <button 
            className="btn-save"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? (
              <>
                <div className="spinner-small"></div> Saving...
              </>
            ) : (
              <>
                <FaSave /> Save Changes
              </>
            )}
          </button>
        </div>
      </div>

      {/* Main Form */}
      <div className="edit-property-form">
        {/* Quick Navigation Tabs */}
        <div className="form-tabs">
          <button 
            className={`tab ${!showAdvanced ? 'active' : ''}`}
            onClick={() => setShowAdvanced(false)}
          >
            Basic Information
          </button>
          <button 
            className={`tab ${showAdvanced ? 'active' : ''}`}
            onClick={() => setShowAdvanced(true)}
          >
            Advanced Management
          </button>
        </div>

        {!showAdvanced ? (
          /* BASIC INFORMATION TAB */
          <div className="basic-info-tab">
            {/* Section 1: Basic Information */}
            <div className="form-section">
              <h2><FaHome /> Basic Information</h2>
              <div className="form-grid">
                <div className="form-group">
                  <label className="required">Property Name</label>
                  <input
                    type="text"
                    name="name"
                    value={property.name}
                    onChange={handleChange}
                    required
                    className="form-input"
                    placeholder="e.g., Maisha Apartments"
                  />
                </div>
                
                <div className="form-group">
                  <label>Property Type</label>
                  <select
                    name="propertyType"
                    value={property.propertyType}
                    onChange={handleChange}
                    className="form-input"
                  >
                    {propertyTypes.map(type => (
                      <option key={type} value={type}>
                        {type.charAt(0).toUpperCase() + type.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Address</label>
                  <input
                    type="text"
                    name="address"
                    value={property.address}
                    onChange={handleChange}
                    className="form-input"
                    placeholder="Street address"
                  />
                </div>

                <div className="form-group">
                  <label>City</label>
                  <input
                    type="text"
                    name="city"
                    value={property.city}
                    onChange={handleChange}
                    className="form-input"
                    placeholder="City"
                  />
                </div>

                <div className="form-group">
                  <label>Postal Code</label>
                  <input
                    type="text"
                    name="postalCode"
                    value={property.postalCode}
                    onChange={handleChange}
                    className="form-input"
                    placeholder="e.g., 80100"
                  />
                </div>

                <div className="form-group full-width">
                  <label>Description</label>
                  <textarea
                    name="description"
                    value={property.description}
                    onChange={handleChange}
                    className="form-input form-textarea"
                    rows="3"
                    placeholder="Describe the property, features, and neighborhood..."
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Financial Details */}
            <div className="form-section">
              <h2><FaDollarSign /> Financial Details</h2>
              <div className="form-grid">
                <div className="form-group">
                  <label>Monthly Rent (KES)</label>
                  <input
                    type="number"
                    name="rentAmount"
                    value={property.rentAmount}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label>Security Deposit</label>
                  <input
                    type="number"
                    name="securityDeposit"
                    value={property.securityDeposit}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label>Payment Frequency</label>
                  <select
                    name="paymentFrequency"
                    value={property.paymentFrequency}
                    onChange={handleChange}
                    className="form-input"
                  >
                    {paymentFrequencies.map(freq => (
                      <option key={freq} value={freq}>
                        {freq.charAt(0).toUpperCase() + freq.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Application Fee</label>
                  <input
                    type="number"
                    name="applicationFee"
                    value={property.applicationFee}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>
              </div>

              {/* Additional Fees */}
              <div className="form-subsection">
                <h3>Additional Fees</h3>
                <button 
                  type="button" 
                  className="btn-add-fee"
                  onClick={addAdditionalFee}
                >
                  <FaPlus /> Add Fee
                </button>
                
                {property.additionalFees.length > 0 && (
                  <div className="fees-list">
                    {property.additionalFees.map((fee, index) => (
                      <div key={index} className="fee-item">
                        <span>{fee.name}: {formatCurrency(fee.amount)}</span>
                        <button 
                          type="button"
                          className="btn-remove-fee"
                          onClick={() => removeAdditionalFee(index)}
                        >
                          <FaTrash />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Section 3: Property Specifications */}
            <div className="form-section">
              <h2><FaBuilding /> Property Specifications</h2>
              <div className="form-grid">
                <div className="form-group">
                  <label><FaBed /> Bedrooms</label>
                  <input
                    type="number"
                    name="bedrooms"
                    value={property.bedrooms}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label><FaBath /> Bathrooms</label>
                  <input
                    type="number"
                    name="bathrooms"
                    value={property.bathrooms}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label><FaRulerCombined /> Size (sqft)</label>
                  <input
                    type="number"
                    name="size"
                    value={property.size}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label>Parking Spaces</label>
                  <input
                    type="number"
                    name="parkingSpaces"
                    value={property.parkingSpaces}
                    onChange={handleChange}
                    min="0"
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label>Year Built</label>
                  <input
                    type="number"
                    name="yearBuilt"
                    value={property.yearBuilt}
                    onChange={handleChange}
                    min="1800"
                    max={new Date().getFullYear()}
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label>Floor</label>
                  <input
                    type="text"
                    name="floor"
                    value={property.floor}
                    onChange={handleChange}
                    className="form-input"
                    placeholder="e.g., 3rd Floor"
                  />
                </div>

                <div className="form-group">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      name="furnished"
                      checked={property.furnished}
                      onChange={handleChange}
                    />
                    <span className="checkbox-text">Furnished</span>
                  </label>
                </div>
              </div>
            </div>

            {/* Section 4: Amenities */}
            <div className="form-section">
              <h2>Amenities & Features</h2>
              <div className="amenities-grid">
                {amenitiesOptions.map(amenity => (
                  <label 
                    key={amenity.id} 
                    className={`amenity-checkbox ${property.amenities.includes(amenity.id) ? 'checked' : ''}`}
                  >
                    <input
                      type="checkbox"
                      checked={property.amenities.includes(amenity.id)}
                      onChange={() => handleArrayToggle('amenities', amenity.id)}
                    />
                    <span className="amenity-icon">{amenity.icon}</span>
                    <span className="amenity-label">{amenity.label}</span>
                  </label>
                ))}
              </div>
            </div>

            {/* Section 5: Utilities Included */}
            <div className="form-section">
              <h2>Utilities Included</h2>
              <div className="utilities-grid">
                {utilitiesOptions.map(utility => (
                  <label 
                    key={utility} 
                    className={`utility-checkbox ${property.utilitiesIncluded.includes(utility) ? 'checked' : ''}`}
                  >
                    <input
                      type="checkbox"
                      checked={property.utilitiesIncluded.includes(utility)}
                      onChange={() => handleArrayToggle('utilitiesIncluded', utility)}
                    />
                    <span className="utility-label">
                      {utility.replace('_', ' ').toUpperCase()}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            {/* Section 6: Landlord Information */}
            <div className="form-section">
              <h2><FaUser /> Landlord Information</h2>
              <div className="form-grid">
                <div className="form-group">
                  <label>Landlord Name</label>
                  <input
                    type="text"
                    name="landlordName"
                    value={property.landlordName}
                    onChange={handleChange}
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label><FaPhone /> Phone</label>
                  <input
                    type="tel"
                    name="landlordPhone"
                    value={property.landlordPhone}
                    onChange={handleChange}
                    className="form-input"
                  />
                </div>

                <div className="form-group">
                  <label><FaEnvelope /> Email</label>
                  <input
                    type="email"
                    name="landlordEmail"
                    value={property.landlordEmail}
                    onChange={handleChange}
                    className="form-input"
                  />
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* ADVANCED MANAGEMENT TAB */
          <div className="advanced-info-tab">
            {/* Section 1: Units Management */}
            <div className="form-section">
              <h2><FaBuilding /> Units Management</h2>
              
              <div className="units-management-section">
                <div className="units-control-row">
                  <span className="units-control-label">Total Units:</span>
                  <div className="units-input-control">
                    <input
                      type="number"
                      value={property.units}
                      onChange={(e) => handleUnitsChange(parseInt(e.target.value) || 1)}
                      min="1"
                      max="1000"
                      className="units-count-input"
                    />
                    <span className="units-status">
                      Currently managing {property.unitDetails.units.length} units
                    </span>
                  </div>
                </div>

                {/* Bulk Actions */}
                <div className="bulk-actions-section">
                  <div className="bulk-actions-label">Bulk Actions</div>
                  <div className="bulk-actions-buttons">
                    <button 
                      onClick={() => bulkUpdateUnitStatus('vacant')}
                      className="bulk-action-btn"
                    >
                      Mark All as Vacant
                    </button>
                    <button 
                      onClick={() => bulkUpdateRents(10)}
                      className="bulk-action-btn"
                    >
                      Increase All Rents by 10%
                    </button>
                    <button 
                      onClick={() => bulkUpdateRents(-10)}
                      className="bulk-action-btn"
                    >
                      Decrease All Rents by 10%
                    </button>
                  </div>
                </div>
              </div>

              {/* Units Table */}
              {property.units > 1 && property.unitDetails.units.length > 0 && (
                <div className="units-table-container">
                  <h3>Individual Units</h3>
                  <div className="units-table">
                    <table>
                      <thead>
                        <tr>
                          <th>Unit #</th>
                          <th>Rent (KES)</th>
                          <th>Status</th>
                          <th>Bedrooms</th>
                          <th>Bathrooms</th>
                          <th>Size</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {property.unitDetails.units.map((unit, index) => (
                          <tr key={unit.id || index}>
                            <td>
                              <input
                                type="text"
                                value={unit.unitNumber}
                                onChange={(e) => editIndividualUnit(index, { unitNumber: e.target.value })}
                                className="unit-input"
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                value={unit.rent}
                                onChange={(e) => editIndividualUnit(index, { rent: parseFloat(e.target.value) || 0 })}
                                className="unit-input"
                              />
                            </td>
                            <td>
                              <select
                                value={unit.status}
                                onChange={(e) => editIndividualUnit(index, { status: e.target.value })}
                                className={`status-select status-${unit.status}`}
                              >
                                <option value="vacant">Vacant</option>
                                <option value="leased">Leased</option>
                                <option value="maintenance">Maintenance</option>
                              </select>
                            </td>
                            <td>
                              <input
                                type="number"
                                value={unit.bedrooms || property.bedrooms}
                                onChange={(e) => editIndividualUnit(index, { bedrooms: parseInt(e.target.value) || 0 })}
                                className="unit-input"
                                min="0"
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                value={unit.bathrooms || property.bathrooms}
                                onChange={(e) => editIndividualUnit(index, { bathrooms: parseInt(e.target.value) || 0 })}
                                className="unit-input"
                                min="0"
                              />
                            </td>
                            <td>
                              <input
                                type="number"
                                value={unit.size || property.size}
                                onChange={(e) => editIndividualUnit(index, { size: parseFloat(e.target.value) || 0 })}
                                className="unit-input"
                                min="0"
                              />
                            </td>
                            <td>
                              <button 
                                onClick={() => {
                                  if (window.confirm(`Remove ${unit.unitNumber}?`)) {
                                    const newUnits = [...property.unitDetails.units];
                                    newUnits.splice(index, 1);
                                    setProperty(prev => ({
                                      ...prev,
                                      units: prev.units - 1,
                                      unitDetails: {
                                        ...prev.unitDetails,
                                        totalUnits: prev.units - 1,
                                        units: newUnits
                                      }
                                    }));
                                  }
                                }}
                                className="btn-remove-unit"
                              >
                                <FaTrash />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>

            {/* Section 2: Financial Calculator */}
            <div className="form-section">
              <h2><FaCalculator /> Financial Calculator</h2>
              <div className="financial-calculator-section">
                <div className="financial-stats-grid">
                  <div className="financial-stat">
                    <span className="stat-label">TOTAL MONTHLY REVENUE:</span>
                    <span className="stat-value">
                      {formatCurrency(calculateTotalMonthlyRevenue())}
                    </span>
                  </div>
                  <div className="financial-stat">
                    <span className="stat-label">POTENTIAL REVENUE:</span>
                    <span className="stat-value">
                      {formatCurrency(calculatePotentialRevenue())}
                    </span>
                  </div>
                  <div className="financial-stat">
                    <span className="stat-label">VACANCY COST:</span>
                    <span className="stat-value warning">
                      {formatCurrency(calculateVacancyCost())}
                    </span>
                  </div>
                  <div className="financial-stat">
                    <span className="stat-label">OCCUPANCY RATE:</span>
                    <span className="stat-value">
                      {property.unitDetails.occupancyRate}%
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Section 3: Image Management */}
            <div className="form-section">
              <h2><FaImages /> Image Management</h2>
              
              <div className="image-management-section">
                <div className="upload-controls">
                  <label className="btn-upload">
                    <FaUpload /> Upload Images
                    <input
                      type="file"
                      multiple
                      accept="image/*"
                      onChange={handleImageUpload}
                      style={{ display: 'none' }}
                      disabled={uploadingImages}
                    />
                  </label>
                  <span className="upload-status">
                    {uploadingImages ? 'Uploading...' : `${property.images.length} images`}
                  </span>
                </div>

                {property.images.length > 0 ? (
                  <div className="images-preview">
                    {property.images.map((image, index) => (
                      <div key={index} className="image-preview-item">
                        <img src={image} alt={`Property ${index + 1}`} />
                        <div className="image-controls">
                          <button 
                            onClick={() => moveImage(index, -1)}
                            disabled={index === 0}
                          >
                            <FaChevronUp />
                          </button>
                          <button 
                            onClick={() => moveImage(index, 1)}
                            disabled={index === property.images.length - 1}
                          >
                            <FaChevronDown />
                          </button>
                          <button 
                            onClick={() => removeImage(index)}
                            className="btn-remove"
                          >
                            <FaTrash />
                          </button>
                          <span className="image-index">{index + 1}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="image-upload-area" onClick={() => document.querySelector('input[type="file"]')?.click()}>
                    <div className="upload-icon">📷</div>
                    <div className="upload-text">
                      Upload Images <span className="image-count">{property.images.length} images</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Section 4: Advanced Settings */}
            <div className="form-section">
              <h2><FaChartLine /> Advanced Settings</h2>
              
              <div className="advanced-settings-section">
                <div className="financial-settings-grid">
                  <div className="financial-settings-group">
                    <label className="financial-label">
                      Property Tax
                      <span>(Annual)</span>
                    </label>
                    <div className="financial-input-wrapper property-tax">
                      <input
                        type="number"
                        name="propertyTax"
                        value={property.propertyTax}
                        onChange={handleChange}
                        min="0"
                        className="financial-input"
                        placeholder="0"
                      />
                      <span className="frequency-indicator">Annual</span>
                    </div>
                  </div>

                  <div className="financial-settings-group">
                    <label className="financial-label">
                      Insurance
                      <span>(Annual)</span>
                    </label>
                    <div className="financial-input-wrapper insurance">
                      <input
                        type="number"
                        name="insurance"
                        value={property.insurance}
                        onChange={handleChange}
                        min="0"
                        className="financial-input"
                        placeholder="0"
                      />
                      <span className="frequency-indicator">Annual</span>
                    </div>
                  </div>

                  <div className="financial-settings-group">
                    <label className="financial-label">
                      Maintenance Cost
                      <span>(Monthly)</span>
                    </label>
                    <div className="financial-input-wrapper maintenance">
                      <input
                        type="number"
                        name="maintenanceCost"
                        value={property.maintenanceCost}
                        onChange={handleChange}
                        min="0"
                        className="financial-input"
                        placeholder="0"
                      />
                      <span className="frequency-indicator">Monthly</span>
                    </div>
                  </div>

                  <div className="financial-settings-group">
                    <label className="financial-label">
                      HOA Fees
                      <span>(Monthly)</span>
                    </label>
                    <div className="financial-input-wrapper hoa">
                      <input
                        type="number"
                        name="hoaFees"
                        value={property.hoaFees}
                        onChange={handleChange}
                        min="0"
                        className="financial-input"
                        placeholder="0"
                      />
                      <span className="frequency-indicator">Monthly</span>
                    </div>
                  </div>
                </div>

                <div className="advanced-notes-section">
                  <h4>Additional Notes</h4>
                  <textarea
                    name="notes"
                    value={property.notes}
                    onChange={handleChange}
                    className="advanced-notes-textarea"
                    rows="4"
                    placeholder="Maintenance notes, special instructions, legal notes..."
                  />
                  <div className="notes-help-text">
                    Add any special instructions, maintenance notes, or legal requirements here.
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Save Button (Bottom) */}
        <div className="form-actions">
          <button 
            className="btn-cancel"
            onClick={handleCancel}
            disabled={saving}
          >
            <FaTimes /> Cancel
          </button>
          <button 
            className="btn-save"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? (
              <>
                <div className="spinner-small"></div> Saving Changes...
              </>
            ) : (
              <>
                <FaSave /> Save All Changes
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default EditProperty;