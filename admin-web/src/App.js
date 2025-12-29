// App.js - Updated
import { Routes, Route, Navigate } from "react-router-dom";

import Dashboard from "./pages/Dashboard";
import AdminLogin from "./pages/AdminLogin";
import AdminRoute from "./routes/AdminRoute";

// Admin pages
import Properties from "./pages/Properties";
import AddProperty from "./pages/AddProperty";
import Tenants from "./pages/Tenants";
import Landlords from "./pages/Landlords";
import AddLandlord from "./pages/AddLandlord"; // Add this import
import Maintenance from "./pages/Maintenance";
import Finance from "./pages/Finance";
import Settings from "./pages/Settings";
import Support from "./pages/Support";
import PropertyUnits from "./pages/PropertyUnits";
import EditProperty from "./pages/EditProperty";
import Applications from "./pages/Applications";
import AddTenant from "./pages/AddTenant";

function App() {
  return (
    <Routes>
      {/* PUBLIC ROUTE */}
      <Route path="/login" element={<AdminLogin />} />

      {/* PROTECTED ADMIN ROUTES */}
      <Route
        path="/dashboard"
        element={
          <AdminRoute>
            <Dashboard />
          </AdminRoute>
        }
      />

      <Route
        path="/properties/add"
        element={
         <AdminRoute>
           <AddProperty />
         </AdminRoute>
        }
      />

      <Route
        path="/properties"
        element={
          <AdminRoute>
            <Properties />
          </AdminRoute>
        }
      />
      
<Route path="/property/:id/units" element={<PropertyUnits />} />
<Route path="/properties/edit/:id" element={<EditProperty />} />
<Route path="/admin/applications" element={<Applications />} />

      <Route
        path="/tenants"
        element={
          <AdminRoute>
            <Tenants />
          </AdminRoute>
        }
      />

      <Route
        path="/tenants/add"
        element={
          <AdminRoute>
           <AddTenant />
          </AdminRoute>
        } 
      />

      <Route
        path="/landlords"
        element={
          <AdminRoute>
            <Landlords />
          </AdminRoute>
        }
      />

      {/* Add this new route */}
      <Route
        path="/landlords/add"
        element={
          <AdminRoute>
            <AddLandlord />
          </AdminRoute>
        }
      />

      <Route
        path="/maintenance"
        element={
          <AdminRoute>
            <Maintenance />
          </AdminRoute>
        }
      />

      <Route
        path="/finance"
        element={
          <AdminRoute>
            <Finance />
          </AdminRoute>
        }
      />

      <Route
        path="/settings"
        element={
          <AdminRoute>
            <Settings />
          </AdminRoute>
        }
      />

      <Route
        path="/support"
        element={
          <AdminRoute>
            <Support />
          </AdminRoute>
        }
      />

      {/* DEFAULT ROUTE */}
      <Route path="/" element={<Navigate to="/dashboard" />} />
    </Routes>
  );
}

export default App;