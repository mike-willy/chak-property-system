import React, { useEffect, useState, useRef } from "react";
import {
  FaTachometerAlt,
  FaHome,
  FaUsers,
  FaUserTie,
  FaTools,
  FaMoneyBillWave,
  FaCog,
  FaLifeRing,
  FaCamera,
} from "react-icons/fa";
import { useNavigate, useLocation } from "react-router-dom";
import { auth, db, storage } from "../pages/firebase/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import "../styles/sidebar.css";

const Sidebar = () => {
  const [user, setUser] = useState(null);
  const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef(null);

  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        await fetchUserData(currentUser.uid);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const fetchUserData = async (userId) => {
    try {
      const userDoc = await getDoc(doc(db, "users", userId));
      if (userDoc.exists()) {
        setUserData(userDoc.data());
      }
    } catch (error) {
      console.error("Error fetching user data:", error);
    }
  };

  const handleImageClick = () => {
    fileInputRef.current.click();
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file || !user) return;

    if (!file.type.startsWith("image/")) {
      alert("Please upload an image file");
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      alert("File size should be less than 5MB");
      return;
    }

    setUploading(true);

    try {
      const storageRef = ref(storage, `profile-pictures/${user.uid}`);
      await uploadBytes(storageRef, file);
      const photoURL = await getDownloadURL(storageRef);

      await setDoc(
        doc(db, "users", user.uid),
        {
          ...userData,
          photoURL,
          updatedAt: new Date(),
        },
        { merge: true }
      );

      setUserData((prev) => ({ ...prev, photoURL }));
    } catch (error) {
      console.error("Error uploading profile picture:", error);
      alert("Failed to upload profile picture");
    } finally {
      setUploading(false);
      e.target.value = "";
    }
  };

  const getUserName = () => {
    if (userData?.displayName) return userData.displayName;
    if (!user || !user.email) return "Admin";
    const namePart = user.email.split("@")[0];
    return namePart.charAt(0).toUpperCase() + namePart.slice(1);
  };

  const getUserInitial = () => {
    return getUserName().charAt(0).toUpperCase();
  };

  const menuItems = [
    { icon: <FaTachometerAlt />, label: "Dashboard", path: "/dashboard" },
    { icon: <FaHome />, label: "Properties", path: "/properties" },
    { icon: <FaUsers />, label: "Tenants", path: "/tenants" },
    { icon: <FaUserTie />, label: "Landlords", path: "/landlords" },
    { icon: <FaTools />, label: "Maintenance", path: "/maintenance" },
    { icon: <FaMoneyBillWave />, label: "Finance", path: "/finance" },
  ];

  const systemItems = [
    { icon: <FaCog />, label: "Settings", path: "/settings" },
    { icon: <FaLifeRing />, label: "Support", path: "/support" },
  ];

  const isActive = (path) => {
    return (
      location.pathname === path ||
      location.pathname.startsWith(path + "/")
    );
  };

  return (
    <div className="sidebar">
      {/* PROFILE */}
      <div className="sidebar-profile">
        {loading ? (
          <div className="profile-loading">Loading...</div>
        ) : (
          <>
            <div className="profile-avatar-container">
              <div
                className="profile-avatar"
                onClick={handleImageClick}
              >
                {userData?.photoURL ? (
                  <img
                    src={userData.photoURL}
                    alt="Profile"
                    className="profile-image"
                  />
                ) : (
                  <div className="avatar-initial">
                    {getUserInitial()}
                  </div>
                )}

                <div className="upload-overlay">
                  <FaCamera />
                </div>

                {uploading && (
                  <div className="uploading-overlay">
                    <div className="uploading-spinner"></div>
                  </div>
                )}
              </div>

              <input
                type="file"
                ref={fileInputRef}
                onChange={handleFileUpload}
                accept="image/*"
                style={{ display: "none" }}
              />
            </div>

            <div className="profile-info">
              <h3 className="profile-name">{getUserName()}</h3>
              <p className="profile-email">
                {user?.email || "admin@chakestates.com"}
              </p>
              <span className="profile-role">Agent</span>
            </div>
          </>
        )}
      </div>

      {/* MENU */}
      <div className="sidebar-scrollable">
        <p className="sidebar-title">MENU</p>
        <ul className="sidebar-menu">
          {menuItems.map((item, index) => (
            <li
              key={index}
              className={isActive(item.path) ? "active" : ""}
              onClick={() => navigate(item.path)}
            >
              {item.icon} <span>{item.label}</span>
            </li>
          ))}
        </ul>

        {/* SYSTEM (FIXED) */}
        <div className="sidebar-system">
          <p className="sidebar-title">SYSTEM</p>
          <ul className="sidebar-bottom">
            {systemItems.map((item, index) => (
              <li
                key={index}
                className={isActive(item.path) ? "active" : ""}
                onClick={() => navigate(item.path)}
              >
                {item.icon} <span>{item.label}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
