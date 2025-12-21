// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCy1XdT0jbavIYh6_4uSuiWRMIhWZXNFfI",
  authDomain: "chak-property-system.firebaseapp.com",
  projectId: "chak-property-system",
  storageBucket: "chak-property-system.firebasestorage.app",
  messagingSenderId: "132843476536",
  appId: "1:132843476536:web:fba00433d167a31b23b8cd",
  measurementId: "G-5VL8FW5YRB"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);