import { signInWithEmailAndPassword } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../pages/firebase/firebase";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaBuilding, FaLock, FaEnvelope, FaSignInAlt } from "react-icons/fa";
import "../styles/AdminLogin.css";

export default function AdminLogin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);

      const userDoc = await getDoc(doc(db, "users", cred.user.uid));

      if (!userDoc.exists()) {
        throw new Error("No user record found");
      }

      if (userDoc.data().role !== "admin") {
        await auth.signOut();
        throw new Error("Access denied. Admins only.");
      }

      navigate("/");
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Left Side - Branding */}
      <div className="login-left">
        <div className="brand-section">
          <div className="brand-logo">
            <FaBuilding size={48} />
          </div>
          <h1 className="brand-title">CHAK Estates</h1>
          <p className="brand-tagline">Administrative Control Panel</p>
        </div>

        <div className="features">
          <div className="feature">
            <div className="feature-icon">🔐</div>
            <div className="feature-text">Secure Admin Access</div>
          </div>
          <div className="feature">
            <div className="feature-icon">📊</div>
            <div className="feature-text">Real-time Analytics</div>
          </div>
          <div className="feature">
            <div className="feature-icon">🏢</div>
            <div className="feature-text">Full System Control</div>
          </div>
        </div>

        <div className="security-notice">
          <FaLock size={14} />
          <span>Restricted Access • Authorized Personnel Only</span>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="login-right">
        <div className="login-card">
          <div className="login-header">
            <h2>Admin Login</h2>
            <p>Access the property management system</p>
          </div>

          <form onSubmit={handleLogin} className="login-form">
            {error && <div className="error-alert">{error}</div>}

            <div className="form-group">
              <label className="form-label">
                <FaEnvelope className="input-icon" />
                Admin Email
              </label>
              <input
                type="email"
                placeholder="admin@chakestates.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="form-input"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">
                <FaLock className="input-icon" />
                Password
              </label>
              <input
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="form-input"
                required
              />
            </div>

            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? (
                <>
                  <span className="spinner"></span>
                  Authenticating...
                </>
              ) : (
                <>
                  <FaSignInAlt />
                  Login 
                </>
              )}
            </button>
          </form>

          <div className="login-footer">
            <div className="security-info">
              <div className="security-item">
                <FaLock size={12} />
                <span>Firebase Secure Authentication</span>
              </div>
              <div className="security-item">
                <FaBuilding size={12} />
                <span>Role-Based Access Control</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}