// =============================================
// firebase.js — Configuração central do Firebase
// Importe este arquivo em todas as páginas
// =============================================

import { initializeApp } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-analytics.js";
import { getFunctions } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-functions.js";

const firebaseConfig = {
  apiKey: "AIzaSyAyJl7kvK3QbHcYzvyAxJ73QBCzGHDcdW0",
  authDomain: "app-fonoaudiologia-gamificado.firebaseapp.com",
  projectId: "app-fonoaudiologia-gamificado",
  storageBucket: "app-fonoaudiologia-gamificado.firebasestorage.app",
  messagingSenderId: "441545837283",
  appId: "1:441545837283:web:97a7cab5d57dc1c580d3d6",
  measurementId: "G-NT1DC4WEKN"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const analytics = getAnalytics(app);
export const functions = getFunctions(app, "southamerica-east1");