// src/pages/AddProperty.jsx
import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { 
  collection, 
  addDoc, 
  serverTimestamp, 
  getDocs,
  updateDoc,
  doc,
  arrayUnion 
} from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "../pages/firebase/firebase";
import "../styles/Addproperty.css";
import { 
  FaImage, 
  FaUpload, 
  FaTrash, 
  FaHome, 
  FaBed, 
  FaBath, 
  FaWifi, 
  FaCar, 
  FaTv, 
  FaSnowflake,
  FaSwimmingPool,
  FaDumbbell,
  FaBuilding,
  FaDoorClosed,
  FaCheckCircle
} from "react-icons/fa";

const AddProperty = () => {
  const navigate = useNavigate();
  const fileInputRef = useRef(null);
  
  const [loading, setLoading] = useState(false);
  const [uploadingImages, setUploadingImages] = useState(false);
  const [landlords, setLandlords] = useState([]);
  const [fetchingLandlords, setFetchingLandlords] = useState(true);
  const [propertyImages, setPropertyImages] = useState([]);
  
  // Property types with icons and descriptions
  const propertyTypes = [
    { value: "single", label: "Single Room", icon: "🏠", description: "Single self-contained room" },
    { value: "bedsitter", label: "Bedsitter", icon: "🛌", description: "Bed-sitting room with kitchenette" },
    { value: "one-bedroom", label: "One Bedroom", icon: "1️⃣", description: "One bedroom apartment" },
    { value: "two-bedroom", label: "Two Bedroom", icon: "2️⃣", description: "Two bedroom apartment" },
    { value: "three-bedroom", label: "Three Bedroom", icon: "3️⃣", description: "Three bedroom apartment" },
    { value: "one-two-bedroom", label: "1BR + 2BR", icon: "🏘️", description: "Mix of 1BR and 2BR units" },
    { value: "apartment", label: "Apartment Complex", icon: "🏢", description: "Multi-unit apartment building" },
    { value: "commercial", label: "Commercial", icon: "🏪", description: "Commercial property" },
  ];
  
  // Amenities options
  const amenitiesOptions = [
    { id: "wifi", label: "WiFi", icon: <FaWifi /> },
    { id: "parking", label: "Parking", icon: <FaCar /> },
    { id: "tv", label: "TV", icon: <FaTv /> },
    { id: "ac", label: "A/C", icon: <FaSnowflake /> },
    { id: "pool", label: "Swimming Pool", icon: <FaSwimmingPool /> },
    { id: "gym", label: "Gym", icon: <FaDumbbell /> },
    { id: "water", label: "24/7 Water", icon: "💧" },
    { id: "security", label: "Security", icon: "👮" },
    { id: "backup", label: "Power Backup", icon: "⚡" },
    { id: "laundry", label: "Laundry", icon: "🧺" },
  ];
  
  const [form, setForm] = useState({
    name: "",
    address: "",
    type: "apartment",
    units: 1,
    rentAmount: "",
    landlordId: "",
    landlordName: "",
    status: "available",
    description: "",
    location: "",
    city: "",
    country: "Kenya",
    amenities: [],
    propertyType: "apartment",
    bedrooms: 1,
    bathrooms: 1,
    size: "",
    images: [],
    pricing: {
      single: "",
      bedsitter: "",
      oneBedroom: "",
      twoBedroom: "",
      threeBedroom: ""
    },
    // NEW: Unit tracking fields
    unitDetails: {
      totalUnits: 1,
      vacantCount: 1,
      leasedCount: 0,
      maintenanceCount: 0,
      occupancyRate: 0,
      units: []
    }
  });

  // Fetch all landlords when component loads
  useEffect(() => {
    fetchLandlords();
  }, []);

  // Function to generate units based on total units count
  const generateUnits = (totalUnits, propertyName, rentAmount) => {
    const units = [];
    const propertyPrefix = propertyName 
      ? propertyName.replace(/\s+/g, '').substring(0, 3).toUpperCase() 
      : 'APT';
    
    const baseRent = Number(rentAmount) || 0;
    
    for (let i = 1; i <= totalUnits; i++) {
      const unitNumber = i.toString().padStart(3, '0');
      units.push({
        unitId: `${propertyPrefix}-${unitNumber}`,
        unitNumber: unitNumber,
        unitName: `${propertyName || 'Property'} - Unit ${unitNumber}`,
        status: "vacant",
        rentAmount: baseRent,
        size: form.size || "",
        amenities: [...form.amenities],
        tenantId: null,
        tenantName: "",
        tenantPhone: "",
        tenantEmail: "",
        leaseStart: null,
        leaseEnd: null,
        rentPaidUntil: null,
        notes: "",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    }
    
    return units;
  };

  const fetchLandlords = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "users"));
      const landlordsData = [];
      
      querySnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.role === "landlord") {
          landlordsData.push({
            id: doc.id,
            name: data.name,
            email: data.email,
            phone: data.phone,
            propertiesCount: data.totalProperties || 0
          });
        }
      });
      
      setLandlords(landlordsData);
    } catch (error) {
      console.error("Error fetching landlords:", error);
      alert("Failed to load landlords");
    } finally {
      setFetchingLandlords(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    
    // If selecting landlord, also get landlord name
    if (name === "landlordId") {
      const selectedLandlord = landlords.find(l => l.id === value);
      setForm({
        ...form,
        landlordId: value,
        landlordName: selectedLandlord ? selectedLandlord.name : ""
      });
    } else if (name.startsWith("pricing.")) {
      const pricingField = name.split(".")[1];
      setForm({
        ...form,
        pricing: {
          ...form.pricing,
          [pricingField]: value
        }
      });
    } else if (name === "units") {
      // Handle units change - generate units automatically
      const totalUnits = parseInt(value) || 1;
      const generatedUnits = generateUnits(totalUnits, form.name, getPriceForType());
      
      setForm(prev => ({
        ...prev,
        units: totalUnits,
        unitDetails: {
          totalUnits: totalUnits,
          vacantCount: totalUnits,
          leasedCount: 0,
          maintenanceCount: 0,
          occupancyRate: 0,
          units: generatedUnits
        }
      }));
    } else {
      setForm({ ...form, [name]: value });
    }
  };

  // Handle image upload
  const handleImageUpload = async (files) => {
    if (files.length === 0) return;
    
    setUploadingImages(true);
    const uploadedUrls = [];
    
    try {
      for (let i = 0; i < Math.min(files.length, 10); i++) {
        const file = files[i];
        if (!file.type.startsWith('image/')) continue;
        
        // Create a unique filename
        const fileName = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}_${file.name}`;
        const storageRef = ref(storage, `properties/${fileName}`);
        
        // Upload file
        await uploadBytes(storageRef, file);
        const downloadURL = await getDownloadURL(storageRef);
        uploadedUrls.push(downloadURL);
        
        // Update preview
        setPropertyImages(prev => [...prev, { url: downloadURL, name: file.name }]);
      }
      
      // Update form with image URLs
      setForm(prev => ({
        ...prev,
        images: [...prev.images, ...uploadedUrls]
      }));
      
    } catch (error) {
      console.error("Error uploading images:", error);
      alert("Failed to upload some images. Please try again.");
    } finally {
      setUploadingImages(false);
    }
  };

  // Remove image
  const removeImage = (index) => {
    setPropertyImages(prev => prev.filter((_, i) => i !== index));
    setForm(prev => ({
      ...prev,
      images: prev.images.filter((_, i) => i !== index)
    }));
  };

  // Handle drag and drop
  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    const files = Array.from(e.dataTransfer.files);
    handleImageUpload(files);
  };

  // Handle property type selection
  const handlePropertyTypeSelect = (type) => {
    // When property type changes, regenerate units if name exists
    if (form.name && form.units > 0) {
      const generatedUnits = generateUnits(form.units, form.name, getPriceForType());
      setForm(prev => ({
        ...prev,
        propertyType: type,
        unitDetails: {
          ...prev.unitDetails,
          units: generatedUnits
        }
      }));
    } else {
      setForm(prev => ({ ...prev, propertyType: type }));
    }
  };

  // Handle amenities toggle
  const toggleAmenity = (amenityId) => {
    const newAmenities = form.amenities.includes(amenityId)
      ? form.amenities.filter(id => id !== amenityId)
      : [...form.amenities, amenityId];
    
    // Update amenities in all units if they exist
    const updatedUnits = form.unitDetails.units.map(unit => ({
      ...unit,
      amenities: newAmenities
    }));
    
    setForm(prev => ({
      ...prev,
      amenities: newAmenities,
      unitDetails: {
        ...prev.unitDetails,
        units: updatedUnits
      }
    }));
  };

  // Get price based on property type
  const getPriceForType = () => {
    switch(form.propertyType) {
      case 'single': return form.pricing.single;
      case 'bedsitter': return form.pricing.bedsitter;
      case 'one-bedroom': return form.pricing.oneBedroom;
      case 'two-bedroom': return form.pricing.twoBedroom;
      case 'three-bedroom': return form.pricing.threeBedroom;
      default: return form.rentAmount;
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!form.landlordId) {
      alert("Please select a landlord");
      return;
    }
    
    // Validate pricing based on property type
    const selectedPrice = getPriceForType();
    if (!selectedPrice || selectedPrice <= 0) {
      alert(`Please enter a valid price for ${propertyTypes.find(t => t.value === form.propertyType)?.label}`);
      return;
    }
    
    setLoading(true);
    
    try {
      // Generate units if not already generated
      const unitsArray = form.unitDetails.units.length > 0 
        ? form.unitDetails.units 
        : generateUnits(form.units, form.name, selectedPrice);
      
      // Calculate monthly revenue from leased units
      const leasedUnits = unitsArray.filter(unit => unit.status === "leased");
      const monthlyRevenue = leasedUnits.reduce((total, unit) => total + (unit.rentAmount || 0), 0);
      
      // Create property data with unit details
      const propertyData = {
        // Basic info
        name: form.name,
        address: form.address,
        city: form.city,
        country: form.country,
        rentAmount: Number(selectedPrice),
        units: Number(form.units),
        propertyType: form.propertyType,
        bedrooms: Number(form.bedrooms),
        bathrooms: Number(form.bathrooms),
        size: form.size,
        description: form.description,
        amenities: form.amenities,
        images: form.images,
        
        // Landlord info
        landlordId: form.landlordId,
        landlordName: form.landlordName,
        
        // Unit details (NEW)
        unitDetails: {
          totalUnits: Number(form.units),
          vacantCount: Number(form.units),
          leasedCount: 0,
          maintenanceCount: 0,
          occupancyRate: 0,
          units: unitsArray
        },
        
        // Status and timestamps
        status: "available",
        isActive: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        monthlyRevenue: monthlyRevenue,
        totalTenants: leasedUnits.length,
        occupancy: 0
      };
      
      // Add pricing if exists
      if (form.pricing) {
        propertyData.pricing = form.pricing;
      }
      
      // Remove empty arrays/strings
      Object.keys(propertyData).forEach(key => {
        if (propertyData[key] === "" || (Array.isArray(propertyData[key]) && propertyData[key].length === 0)) {
          delete propertyData[key];
        }
      });
      
      // Save to Firestore
      const propertyRef = await addDoc(collection(db, "properties"), propertyData);
      const propertyId = propertyRef.id;
      
      console.log("✅ Property created with ID:", propertyId, "with", form.units, "units");
      
      // Update the landlord's document
      const landlordRef = doc(db, "users", form.landlordId);
      const currentTime = new Date().toISOString();
      
      await updateDoc(landlordRef, {
        properties: arrayUnion({
          propertyId: propertyId,
          propertyName: form.name,
          address: form.address,
          rentAmount: Number(selectedPrice),
          units: Number(form.units),
          vacantUnits: Number(form.units),
          leasedUnits: 0,
          status: "active",
          addedAt: currentTime,
          propertyType: form.propertyType
        }),
        totalProperties: (form.totalProperties || 0) + 1,
        lastUpdated: serverTimestamp()
      });
      
      console.log("✅ Updated landlord in users collection");
      
      // Try to update landlords collection
      try {
        const landlordProfileRef = doc(db, "landlords", form.landlordId);
        await updateDoc(landlordProfileRef, {
          properties: arrayUnion(propertyId),
          totalProperties: (form.totalProperties || 0) + 1,
          lastUpdated: serverTimestamp()
        });
        console.log("✅ Also updated landlords collection");
      } catch (error) {
        console.log("⚠️ Landlord profile doesn't exist in landlords collection, skipping...");
      }
      
      alert(`✅ Property added successfully with ${form.units} units!`);
      navigate("/properties");
      
    } catch (error) {
      console.error("Error adding property:", error);
      alert("Error adding property: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    navigate("/properties");
  };

  return (
    <div className="add-property-container">
      <div className="add-property-header">
        <h1>Add New Property</h1>
        <button className="back-button" onClick={handleCancel}>
          ← Back to Properties
        </button>
      </div>
      
      <div className="add-property-card">
        <h2>Property Details</h2>
        <p className="form-subtitle">Fill in property details and assign to a landlord</p>
        
        <form onSubmit={handleSubmit} className="add-property-form">
          
          {/* IMAGE UPLOAD SECTION */}
          <div className="form-section">
            <h3>Property Images</h3>
            <div className="image-upload-section">
              <div 
                className="drop-zone"
                onDragOver={handleDragOver}
                onDrop={handleDrop}
                onClick={() => fileInputRef.current.click()}
              >
                <FaUpload className="upload-icon" />
                <p>Drag & drop images here or click to browse</p>
                <p className="upload-hint">Recommended: 5-10 images, max 5MB each</p>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={(e) => handleImageUpload(Array.from(e.target.files))}
                  multiple
                  accept="image/*"
                  style={{ display: 'none' }}
                />
              </div>
              
              {uploadingImages && (
                <div className="uploading-status">
                  <div className="spinner"></div>
                  <p>Uploading images...</p>
                </div>
              )}
              
              {propertyImages.length > 0 && (
                <div className="image-preview-container">
                  <h4>Uploaded Images ({propertyImages.length})</h4>
                  <div className="image-grid">
                    {propertyImages.map((image, index) => (
                      <div key={index} className="image-preview">
                        <img src={image.url} alt={`Property ${index + 1}`} />
                        <button
                          type="button"
                          className="remove-image-btn"
                          onClick={() => removeImage(index)}
                        >
                          <FaTrash />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
          
          {/* PROPERTY TYPE SELECTION */}
          <div className="form-section">
            <h3>Property Type</h3>
            <div className="property-type-grid">
              {propertyTypes.map((type) => (
                <button
                  key={type.value}
                  type="button"
                  className={`property-type-card ${form.propertyType === type.value ? 'selected' : ''}`}
                  onClick={() => handlePropertyTypeSelect(type.value)}
                >
                  <span className="property-icon">{type.icon}</span>
                  <span className="property-label">{type.label}</span>
                  <span className="property-desc">{type.description}</span>
                </button>
              ))}
            </div>
          </div>
          
          {/* PRICING SECTION - Dynamic based on property type */}
          <div className="form-section">
            <h3>Pricing</h3>
            <div className="pricing-section">
              <div className="selected-type-display">
                <h4>Selected: {propertyTypes.find(t => t.value === form.propertyType)?.label}</h4>
                <p>{propertyTypes.find(t => t.value === form.propertyType)?.description}</p>
              </div>
              
              {/* Display relevant price field based on property type */}
              <div className="price-input-container">
                {form.propertyType === 'single' && (
                  <div className="form-group">
                    <label className="required">Monthly Rent for Single Room (KSh)</label>
                    <input
                      type="number"
                      name="pricing.single"
                      value={form.pricing.single}
                      onChange={handleChange}
                      placeholder="e.g., 8,000"
                      required
                      disabled={loading}
                    />
                  </div>
                )}
                
                {form.propertyType === 'bedsitter' && (
                  <div className="form-group">
                    <label className="required">Monthly Rent for Bedsitter (KSh)</label>
                    <input
                      type="number"
                      name="pricing.bedsitter"
                      value={form.pricing.bedsitter}
                      onChange={handleChange}
                      placeholder="e.g., 12,000"
                      required
                      disabled={loading}
                    />
                  </div>
                )}
                
                {form.propertyType === 'one-bedroom' && (
                  <div className="form-group">
                    <label className="required">Monthly Rent for 1 Bedroom (KSh)</label>
                    <input
                      type="number"
                      name="pricing.oneBedroom"
                      value={form.pricing.oneBedroom}
                      onChange={handleChange}
                      placeholder="e.g., 25,000"
                      required
                      disabled={loading}
                    />
                  </div>
                )}
                
                {form.propertyType === 'two-bedroom' && (
                  <div className="form-group">
                    <label className="required">Monthly Rent for 2 Bedrooms (KSh)</label>
                    <input
                      type="number"
                      name="pricing.twoBedroom"
                      value={form.pricing.twoBedroom}
                      onChange={handleChange}
                      placeholder="e.g., 40,000"
                      required
                      disabled={loading}
                    />
                  </div>
                )}
                
                {form.propertyType === 'three-bedroom' && (
                  <div className="form-group">
                    <label className="required">Monthly Rent for 3 Bedrooms (KSh)</label>
                    <input
                      type="number"
                      name="pricing.threeBedroom"
                      value={form.pricing.threeBedroom}
                      onChange={handleChange}
                      placeholder="e.g., 60,000"
                      required
                      disabled={loading}
                    />
                  </div>
                )}
                
                {/* For mixed property types */}
                {form.propertyType === 'one-two-bedroom' && (
                  <div className="mixed-pricing">
                    <div className="form-row">
                      <div className="form-group">
                        <label className="required">1 Bedroom Rent (KSh)</label>
                        <input
                          type="number"
                          name="pricing.oneBedroom"
                          value={form.pricing.oneBedroom}
                          onChange={handleChange}
                          placeholder="e.g., 25,000"
                          required
                          disabled={loading}
                        />
                      </div>
                      <div className="form-group">
                        <label className="required">2 Bedroom Rent (KSh)</label>
                        <input
                          type="number"
                          name="pricing.twoBedroom"
                          value={form.pricing.twoBedroom}
                          onChange={handleChange}
                          placeholder="e.g., 40,000"
                          required
                          disabled={loading}
                        />
                      </div>
                    </div>
                  </div>
                )}
                
                <div className="price-summary">
                  <p><strong>Monthly Revenue Estimate:</strong> KSh {(getPriceForType() || 0) * form.units}</p>
                  <p className="note">Based on {form.units} unit(s) × KSh {getPriceForType() || 0}</p>
                </div>
              </div>
            </div>
          </div>
          
          {/* AMENITIES SECTION */}
          <div className="form-section">
            <h3>Amenities & Features</h3>
            <div className="amenities-grid">
              {amenitiesOptions.map((amenity) => (
                <div
                  key={amenity.id}
                  className={`amenity-checkbox ${form.amenities.includes(amenity.id) ? 'selected' : ''}`}
                  onClick={() => toggleAmenity(amenity.id)}
                >
                  <div className="amenity-icon">{amenity.icon}</div>
                  <span className="amenity-label">{amenity.label}</span>
                  <input
                    type="checkbox"
                    checked={form.amenities.includes(amenity.id)}
                    onChange={() => {}}
                    style={{ display: 'none' }}
                  />
                </div>
              ))}
            </div>
          </div>
          
          {/* Basic Property Info (Original form fields) */}
          <div className="form-section">
            <h3>Basic Information</h3>
            
            <div className="form-group">
              <label className="required">Property Name</label>
              <input
                name="name"
                value={form.name}
                onChange={handleChange}
                placeholder="e.g., Greenview Apartments"
                required
                disabled={loading}
              />
              {form.name && form.units > 0 && (
                <p className="form-hint">
                  Units will be named: {form.name.replace(/\s+/g, '').substring(0, 3).toUpperCase()}-001 to {form.name.replace(/\s+/g, '').substring(0, 3).toUpperCase()}-{form.units.toString().padStart(3, '0')}
                </p>
              )}
            </div>
            
            <div className="form-group">
              <label className="required">Address</label>
              <input
                name="address"
                value={form.address}
                onChange={handleChange}
                placeholder="Full physical address"
                required
                disabled={loading}
              />
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label className="required">City</label>
                <input
                  name="city"
                  value={form.city}
                  onChange={handleChange}
                  placeholder="e.g., Nairobi"
                  required
                  disabled={loading}
                />
              </div>
              
              <div className="form-group">
                <label className="required">Country</label>
                <select
                  name="country"
                  value={form.country}
                  onChange={handleChange}
                  required
                  disabled={loading}
                >
                  <option value="Kenya">Kenya</option>
                  <option value="Uganda">Uganda</option>
                  <option value="Tanzania">Tanzania</option>
                  <option value="Rwanda">Rwanda</option>
                  <option value="Other">Other</option>
                </select>
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Bedrooms</label>
                <select
                  name="bedrooms"
                  value={form.bedrooms}
                  onChange={handleChange}
                  disabled={loading}
                >
                  {[1, 2, 3, 4, 5, 6].map(num => (
                    <option key={num} value={num}>{num} {num === 1 ? 'Bedroom' : 'Bedrooms'}</option>
                  ))}
                </select>
              </div>
              
              <div className="form-group">
                <label>Bathrooms</label>
                <select
                  name="bathrooms"
                  value={form.bathrooms}
                  onChange={handleChange}
                  disabled={loading}
                >
                  {[1, 2, 3, 4].map(num => (
                    <option key={num} value={num}>{num} {num === 1 ? 'Bathroom' : 'Bathrooms'}</option>
                  ))}
                </select>
              </div>
              
              <div className="form-group">
                <label>Size (sq ft)</label>
                <input
                  type="number"
                  name="size"
                  value={form.size}
                  onChange={handleChange}
                  placeholder="e.g., 1200"
                  disabled={loading}
                />
              </div>
            </div>
            
            {/* UNITS INPUT WITH PREVIEW */}
            <div className="form-group">
              <label className="required">Number of Units</label>
              <input
                type="number"
                name="units"
                value={form.units}
                onChange={handleChange}
                min="1"
                max="500"
                required
                disabled={loading}
                className="units-input"
              />
              <small className="form-hint">
                {form.units} unit(s) will be created. Each can be managed individually.
              </small>
              
              {/* Unit Preview */}
              {form.units > 0 && (
                <div className="units-preview">
                  <div className="units-stats-preview">
                    <div className="stat-item">
                      <FaBuilding />
                      <span className="stat-value">{form.units}</span>
                      <span className="stat-label">Total</span>
                    </div>
                    <div className="stat-item vacant">
                      <FaDoorClosed />
                      <span className="stat-value">{form.units}</span>
                      <span className="stat-label">Vacant</span>
                    </div>
                    <div className="stat-item leased">
                      <FaCheckCircle />
                      <span className="stat-value">0</span>
                      <span className="stat-label">Leased</span>
                    </div>
                    <div className="stat-item maintenance">
                      <FaHome />
                      <span className="stat-value">0</span>
                      <span className="stat-label">Maintenance</span>
                    </div>
                  </div>
                  
                  {form.units <= 10 && form.unitDetails.units.length > 0 && (
                    <div className="units-list-preview">
                      <p className="preview-title">First 10 Unit Numbers:</p>
                      <div className="unit-numbers-grid">
                        {form.unitDetails.units.slice(0, 10).map((unit, index) => (
                          <span key={index} className="unit-number-badge">
                            {unit.unitNumber}
                          </span>
                        ))}
                        {form.units > 10 && (
                          <span className="unit-number-badge more">
                            +{form.units - 10} more
                          </span>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
            
            <div className="form-group">
              <label>Description</label>
              <textarea
                name="description"
                value={form.description}
                onChange={handleChange}
                placeholder="Describe the property features, neighborhood, access routes..."
                rows="4"
                disabled={loading}
              />
            </div>
          </div>
          
          {/* Landlord Assignment */}
          <div className="form-section">
            <h3>Assign to Landlord</h3>
            
            <div className="form-group">
              <label className="required">Select Landlord</label>
              {fetchingLandlords ? (
                <p>Loading landlords...</p>
              ) : landlords.length === 0 ? (
                <div className="no-landlords">
                  <p>No landlords registered yet.</p>
                  <button 
                    type="button" 
                    className="secondary-button"
                    onClick={() => navigate("/landlords/add")}
                  >
                    Register a Landlord First
                  </button>
                </div>
              ) : (
                <select
                  name="landlordId"
                  value={form.landlordId}
                  onChange={handleChange}
                  required
                  disabled={loading}
                  className="landlord-select"
                >
                  <option value="">-- Select a Landlord --</option>
                  {landlords.map(landlord => (
                    <option key={landlord.id} value={landlord.id}>
                      {landlord.name} ({landlord.email}) - {landlord.propertiesCount} properties
                    </option>
                  ))}
                </select>
              )}
              
              {form.landlordName && (
                <div className="selected-landlord-info">
                  <p>Selected: <strong>{form.landlordName}</strong></p>
                </div>
              )}
            </div>
          </div>
          
          <div className="form-actions">
            <button 
              type="button" 
              className="cancel-button" 
              onClick={handleCancel}
              disabled={loading}
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className="submit-button"
              disabled={loading || fetchingLandlords || landlords.length === 0}
            >
              {loading ? (
                <>
                  <span className="spinner-small"></span>
                  Adding Property...
                </>
              ) : `Add Property with ${form.units} Units`}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddProperty;