// src/pages/AddLandlord.jsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { auth, db } from "../pages/firebase/firebase";
import "../styles/AddLandlord.css";

const AddLandlord = () => {
  const navigate = useNavigate();
  
  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    password: "",
    address: "",
    company: ""
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
    setError("");
  };

  const validateForm = () => {
    if (!form.firstName.trim()) {
      setError("First name is required");
      return false;
    }
    if (!form.lastName.trim()) {
      setError("Last name is required");
      return false;
    }
    if (!form.email.includes("@")) {
      setError("Valid email is required");
      return false;
    }
    if (!form.phone.trim()) {
      setError("Phone number is required");
      return false;
    }
    if (form.password.length < 6) {
      setError("Password must be at least 6 characters");
      return false;
    }
    return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    setLoading(true);
    setError("");
    setSuccess("");

    try {
      console.log("=== 🚀 Starting landlord registration ===");
      
      // Check if admin is logged in
      const adminUser = auth.currentUser;
      if (!adminUser) {
        throw new Error("You must be logged in as admin to register landlords");
      }
      
      console.log("Admin logged in:", adminUser.email);
      console.log("Creating landlord account for:", form.email);
      
      // Create the combined name
      const fullName = `${form.firstName} ${form.lastName}`.trim();
      
      // 1. Create auth account for landlord
      const cred = await createUserWithEmailAndPassword(
        auth,
        form.email,
        form.password
      );

      const landlordUid = cred.user.uid;
      console.log("✅ Auth account created. UID:", landlordUid);
      
      // 2. Create landlord profile in 'landlords' collection ONLY
      const landlordData = {
        uid: landlordUid,
        firstName: form.firstName,
        lastName: form.lastName,
        name: fullName,
        email: form.email,
        phone: form.phone,
        address: form.address || "",
        company: form.company || "",
        role: "landlord", // Add role field
        createdAt: serverTimestamp(),
        createdBy: adminUser.uid,
        properties: [],
        totalProperties: 0,
        activeProperties: 0,
        status: "active",
        lastLogin: null,
        updatedAt: serverTimestamp()
      };
      
      console.log("📝 Creating landlord profile in 'landlords' collection...");
      console.log("Landlord data being saved:", landlordData);
      await setDoc(doc(db, "landlords", landlordUid), landlordData);
      console.log("✅ Landlord profile created in 'landlords' collection!");
      
      console.log("=== 🎉 Registration complete ===");

      // Reset form and show success
      setForm({
        firstName: "",
        lastName: "",
        email: "",
        phone: "",
        password: "",
        address: "",
        company: ""
      });
      
      setSuccess(`
        ✅ LANDLORD REGISTERED SUCCESSFULLY!
        
        Landlord Details:
        • Name: ${fullName}
        • Email: ${form.email}
        • Phone: ${form.phone}
        • Company: ${form.company || "Not provided"}
        • Landlord ID: ${landlordUid}
        
        Login Credentials (For Mobile App):
        Email: ${form.email}
        Password: ${form.password}
        
        Document Created:
        1. Firebase Auth account ✓
        2. Landlords collection document ✓
        
        Next Steps:
        1. Go to "Add Property" to assign properties to this landlord
        2. The landlord can now login on the mobile app
        3. They will see their assigned properties in the app
        
        Redirecting to landlords list...
      `);
      
      // Redirect after 5 seconds
      setTimeout(() => {
        navigate("/landlords");
      }, 5000);
      
    } catch (error) {
      console.error("🔴 Registration error:", {
        code: error.code,
        message: error.message,
        fullError: error
      });
      
      let errorMessage = "Registration failed. Please try again.";
      
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (error.code === 'auth/weak-password') {
        errorMessage = "Password is too weak.";
      } else if (error.code === 'permission-denied') {
        errorMessage = `
          🔒 PERMISSION DENIED!
          
          Firestore rules are blocking creation in 'landlords' collection.
          
          Use these SIMPLE rules temporarily:
          
          rules_version = '2';
          service cloud.firestore {
            match /databases/{database}/documents {
              match /landlords/{document=**} {
                allow read, write: if request.auth != null;
              }
            }
          }
          
          Error details: ${error.message}
        `;
      } else if (error.message.includes("must be logged in")) {
        errorMessage = "You must be logged in as admin. Please login first.";
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    navigate("/landlords");
  };

  return (
    <div className="add-landlord-container">
      <div className="add-landlord-header">
        <h1>Register New Landlord</h1>
        <button className="back-button" onClick={handleCancel}>
          ← Back to Landlords
        </button>
      </div>
      
      <div className="add-landlord-card">
        {success && (
          <div className="success-message">
            <span className="success-icon">✅</span>
            <div className="success-content">
              {success.split('\n').map((line, index) => (
                <div key={index}>{line}</div>
              ))}
            </div>
          </div>
        )}
        
        {error && (
          <div className="error-message">
            <span className="error-icon">⚠️</span>
            <div className="error-content">
              {error.split('\n').map((line, index) => (
                <div key={index}>{line}</div>
              ))}
            </div>
          </div>
        )}
        
        {!success && (
          <>
            <h2>Landlord Details</h2>
            <p className="form-subtitle">Fill in the details to register a new landlord</p>
            
            <form onSubmit={handleSubmit} className="add-landlord-form">
              <div className="form-row">
                <div className="form-group half">
                  <label htmlFor="firstName" className="required">First Name</label>
                  <input
                    id="firstName"
                    name="firstName"
                    type="text"
                    value={form.firstName}
                    onChange={handleChange}
                    placeholder="John"
                    className="form-input"
                    required
                    disabled={loading}
                  />
                </div>
                
                <div className="form-group half">
                  <label htmlFor="lastName" className="required">Last Name</label>
                  <input
                    id="lastName"
                    name="lastName"
                    type="text"
                    value={form.lastName}
                    onChange={handleChange}
                    placeholder="Doe"
                    className="form-input"
                    required
                    disabled={loading}
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group half">
                  <label htmlFor="email" className="required">Email</label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    value={form.email}
                    onChange={handleChange}
                    placeholder="landlord@example.com"
                    className="form-input"
                    required
                    disabled={loading}
                  />
                  <span className="helper-text">For login and notifications</span>
                </div>
                
                <div className="form-group half">
                  <label htmlFor="phone" className="required">Phone</label>
                  <input
                    id="phone"
                    name="phone"
                    type="tel"
                    value={form.phone}
                    onChange={handleChange}
                    placeholder="+254 712 345 678"
                    className="form-input"
                    required
                    disabled={loading}
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group half">
                  <label htmlFor="company">Company (Optional)</label>
                  <input
                    id="company"
                    name="company"
                    type="text"
                    value={form.company}
                    onChange={handleChange}
                    placeholder="Company name"
                    className="form-input"
                    disabled={loading}
                  />
                </div>
                
                <div className="form-group half">
                  <label htmlFor="password" className="required">Password</label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    value={form.password}
                    onChange={handleChange}
                    placeholder="Min. 6 characters"
                    className="form-input"
                    required
                    disabled={loading}
                  />
                </div>
              </div>
              
              <div className="form-group">
                <label htmlFor="address">Address (Optional)</label>
                <input
                  id="address"
                  name="address"
                  type="text"
                  value={form.address}
                  onChange={handleChange}
                  placeholder="Physical address"
                  className="form-input"
                  disabled={loading}
                />
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
                  disabled={loading}
                >
                  {loading ? (
                    <>
                      <svg className="loading-spinner" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" opacity="0.25"/>
                        <path d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" fill="currentColor"/>
                      </svg>
                      Registering...
                    </>
                  ) : 'Register Landlord'}
                </button>
              </div>
            </form>
            
            <div className="info-section">
              <h3>Important Information</h3>
              <p>
                <strong>Landlord will be created in 'landlords' collection only.</strong>
                The landlord can login on the mobile app using the email and password above.
              </p>
              <ul>
                <li>First Name + Last Name = Full Name in database</li>
                <li>The landlord will see their full name in the mobile app</li>
                <li>All landlord data is stored in the 'landlords' collection</li>
              </ul>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default AddLandlord;