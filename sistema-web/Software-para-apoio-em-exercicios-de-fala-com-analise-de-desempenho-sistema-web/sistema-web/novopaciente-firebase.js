import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
    import { getFirestore, collection, addDoc, setDoc, doc, Timestamp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
    import { getAuth, createUserWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";

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
    const db = getFirestore(app);
    const auth = getAuth(app);

    // Expõe para o script principal acessar
    window._db = db;
    window._auth = auth;
    window._addDoc = addDoc;
    window._setDoc = setDoc;
    window._doc = doc;
    window._collection = collection;
    window._Timestamp = Timestamp;
    window._createUser = createUserWithEmailAndPassword;