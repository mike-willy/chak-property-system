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
      
      // 1. Create auth account
      const cred = await createUserWithEmailAndPassword(
        auth,
        form.email,
        form.password
      );

      console.log("✅ Auth account created. UID:", cred.user.uid);
      console.log("🔑 Currently logged in as:", auth.currentUser?.email);
      
      // 2. Create Firestore user profile
      console.log("📝 Creating Firestore document...");
      
      const landlordData = {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,
        phone: form.phone,
        role: "landlord",
        isVerified: true,
        createdAt: serverTimestamp(),
        properties: [],
        totalProperties: 0,
        status: "active",
      };
      
      console.log("Data to save:", landlordData);
      
      await setDoc(doc(db, "users", cred.user.uid), landlordData);
      
      console.log("✅ Firestore document created successfully!");
      console.log("=== 🎉 Registration complete ===");

      // 3. Reset form and show success
      setForm({
        name: "",
        email: "",
        phone: "",
        password: "",
      });
      
      setSuccess(`
        ✅ Landlord Registered Successfully!
        
        Landlord Details:
        • Name: ${form.name}
        • Email: ${form.email}
        • Phone: ${form.phone}
        
        They can now login on the mobile app using:
        Email: ${form.email}
        Password: ${form.password}
        
        Redirecting to landlords list...
      `);
      
      // 4. Redirect back to landlords list after 3 seconds
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
      } else if (error.code === 'permission-denied' || error.code === 'firestore/permission-denied') {
        errorMessage = `
          Permission denied! 
          
          Please update your Firestore rules to allow:
          1. Any authenticated user to create landlord accounts
          2. Make sure rule includes: (isAuthenticated() && request.resource.data.role == "landlord")
          
          Current rules don't allow this operation.
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
          <h3>How It Works</h3>
          <ul>
            <li><strong>Step 1:</strong> Admin fills this form on web app</li>
            <li><strong>Step 2:</strong> System creates landlord account</li>
            <li><strong>Step 3:</strong> Landlord receives email/password</li>
            <li><strong>Step 4:</strong> Landlord logs in on mobile app</li>
            <li><strong>Step 5:</strong> Landlord appears in your landlords list</li>
          </ul>
          
          <div className="note-box">
            <strong>Note:</strong> After registration, you'll be redirected to the landlords list.
            The new landlord will appear there immediately.
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddLandlord;