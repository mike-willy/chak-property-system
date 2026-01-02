import React from "react";
import { 
  FaUserPlus, FaWrench, FaMoneyBill, FaFileContract,
  FaExclamationTriangle, FaEnvelope, FaBell, FaReceipt, FaHome
} from "react-icons/fa";

const NotificationIcon = ({ type, size = 20 }) => {
  const iconProps = { size };
  
  switch (type) {
    case "tenant_application":
      return <FaUserPlus {...iconProps} style={{ color: "#3b82f6" }} />;
    case "maintenance_request":
      return <FaWrench {...iconProps} style={{ color: "#f59e0b" }} />;
    case "rent_payment":
      return <FaMoneyBill {...iconProps} style={{ color: "#10b981" }} />;
    case "lease_expiry":
      return <FaFileContract {...iconProps} style={{ color: "#8b5cf6" }} />;
    case "system_alert":
      return <FaExclamationTriangle {...iconProps} style={{ color: "#ef4444" }} />;
    case "tenant_message":
      return <FaEnvelope {...iconProps} style={{ color: "#ec4899" }} />;
    case "invoice_due":
      return <FaReceipt {...iconProps} style={{ color: "#f97316" }} />;
    case "property_alert":
      return <FaHome {...iconProps} style={{ color: "#06b6d4" }} />;
    default:
      return <FaBell {...iconProps} style={{ color: "#6b7280" }} />;
  }
};

export default NotificationIcon;