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
    name: "",
    email: "",
    phone: "",
    password: "",
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
    setError("");
  };

  const validateForm = () => {
    if (!form.name.trim()) {
      setError("Full name is required");
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
      
      // Check if admin is logged in before starting
      const adminUser = auth.currentUser;
      if (!adminUser) {
        throw new Error("You must be logged in as admin to register landlords");
      }
      
      console.log("Admin logged in:", adminUser.email);
      console.log("Creating landlord account for:", form.email);
      
      // IMPORTANT: Sign out admin temporarily to create landlord auth account
      // OR use Firebase Admin SDK on backend (recommended)
      // For now, we'll try to create directly
      
      // 1. Create auth account
      const cred = await createUserWithEmailAndPassword(
        auth,
        form.email,
        form.password
      );

      console.log("✅ Auth account created. UID:", cred.user.uid);
      
      // 2. Sign back in as admin if needed
      // In production, use Firebase Admin SDK or separate backend
      
      // 3. Create Firestore user profile - FIXED DATA STRUCTURE
      const landlordData = {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,
        phone: form.phone,
        role: "landlord",
        isVerified: true,
        createdAt: serverTimestamp(),
        properties: [], // Empty array
        totalProperties: 0,
        status: "active",
        // Removed assignedProperties to simplify
        lastUpdated: serverTimestamp()
      };
      
      console.log("📝 Creating Firestore document in 'users' collection...");
      await setDoc(doc(db, "users", cred.user.uid), landlordData);
      
      console.log("✅ Firestore user document created!");
      
      // 4. Create landlord profile document
      const landlordProfileData = {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,
        phone: form.phone,
        role: "landlord", // ADD THIS
        createdAt: serverTimestamp(),
        totalProperties: 0,
        activeProperties: 0,
        vacantProperties: 0,
        totalRent: 0,
        averageRent: 0,
        properties: [], // Property IDs will go here
        status: "active" // ADD THIS
      };
      
      console.log("📝 Creating landlord profile in 'landlords' collection...");
      await setDoc(doc(db, "landlords", cred.user.uid), landlordProfileData);
      
      console.log("✅ Landlord profile created!");
      console.log("=== 🎉 Registration complete ===");

      // Reset form and show success
      setForm({
        name: "",
        email: "",
        phone: "",
        password: "",
      });
      
      setSuccess(`
        ✅ LANDLORD REGISTERED SUCCESSFULLY!
        
        Landlord Details:
        • Name: ${form.name}
        • Email: ${form.email}
        • Phone: ${form.phone}
        • Landlord ID: ${cred.user.uid}
        
        Login Credentials (For Mobile App):
        Email: ${form.email}
        Password: ${form.password}
        
        Next Steps:
        1. Go to "Add Property" to assign properties to this landlord
        2. The landlord can now login on the mobile app
        3. They will see their assigned properties in the app
        
        Redirecting to landlords list...
      `);
      
      // Redirect back to landlords list after 3 seconds
      setTimeout(() => {
        navigate("/landlords");
      }, 3000);
      
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
          
          Current Firestore rules don't allow admin to create user documents.
          
          Solution 1: Update Firestore rules to allow admin to create users
          Solution 2: Use Firebase Admin SDK on a backend server
          Solution 3: Create a Cloud Function for user registration
          
          Error details: ${error.message}
        `;
      } else if (error.message.includes("must be logged in")) {
        errorMessage = error.message;
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
            <p className="form-subtitle">Fill in the details below to register a new landlord</p>
            
            <form onSubmit={handleSubmit} className="add-landlord-form">
              <div className="form-group">
                <label htmlFor="name" className="required">Full Name</label>
                <input
                  id="name"
                  name="name"
                  type="text"
                  value={form.name}
                  onChange={handleChange}
                  placeholder="Enter landlord's full name"
                  className="form-input"
                  required
                  disabled={loading}
                />
                <span className="helper-text">Legal name as per identification</span>
              </div>
              
              <div className="form-group">
                <label htmlFor="email" className="required">Email Address</label>
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
                <span className="helper-text">Will be used for login and notifications</span>
              </div>
              
              <div className="form-group">
                <label htmlFor="phone" className="required">Phone Number</label>
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
                <span className="helper-text">Primary contact number</span>
              </div>
              
              <div className="form-group">
                <label htmlFor="password" className="required">Password</label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  value={form.password}
                  onChange={handleChange}
                  placeholder="Create a secure password"
                  className="form-input"
                  required
                  disabled={loading}
                />
                <div className="password-helper">
                  <span>Password strength: </span>
                  <span className={`strength-text ${
                    form.password.length >= 8 ? 'strength-strong' : 
                    form.password.length >= 6 ? 'strength-medium' : 
                    form.password.length > 0 ? 'strength-weak' : ''
                  }`}>
                    {form.password.length >= 8 ? 'Strong' : 
                     form.password.length >= 6 ? 'Medium' : 
                     form.password.length > 0 ? 'Weak' : 'None'}
                  </span>
                </div>
                <span className="helper-text">Must be at least 6 characters</span>
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
              <h3>How Property Assignment Works</h3>
              <ul>
                <li>After registering a landlord, go to "Add Property"</li>
                <li>Select this landlord when adding a new property</li>
                <li>The property will be automatically linked to this landlord</li>
                <li>The landlord will see all their properties in the mobile app</li>
                <li>Each landlord has their own separate property list</li>
              </ul>
              
              <div className="note-box">
                <strong>Important:</strong> This landlord can now login on the mobile app using the credentials above.
                They will see any properties you assign to them.
              </div>
              
              <div className="permission-note">
                <strong>⚠️ Permission Note:</strong> Make sure your Firestore rules allow admin to create user documents.
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default AddLandlord;