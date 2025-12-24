import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../pages/firebase/firebase";
import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";

export default function AdminRoute({ children }) {
  const [allowed, setAllowed] = useState(null);

  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setAllowed(false);
        return;
      }

      const snap = await getDoc(doc(db, "users", user.uid));
      setAllowed(snap.exists() && snap.data().role === "admin");
    });
  }, []);

  if (allowed === null) return <p>Checking access...</p>;

  return allowed ? children : <Navigate to="/login" />;
}
