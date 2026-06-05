// =============================================================
// novopaciente-firebase.js
// Helper que inicializa o Firebase para a página de cadastro
// de paciente.
//
// 🔑 PONTO-CHAVE: usa DUAS instâncias do Firebase:
//
//   1. App principal ("[DEFAULT]") — onde a fonoaudióloga está
//      logada. NUNCA é mexido durante o cadastro.
//
//   2. App secundário ("paciente-cadastro") — usado APENAS para
//      criar a conta do paciente. Como é uma instância separada,
//      a criação não afeta a sessão da fono.
//
// Resultado: a fono cadastra o paciente e continua logada
// normalmente, sem precisar relogar.
// =============================================================

import { initializeApp, getApps, getApp, deleteApp } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-app.js";
import {
  getFirestore, collection, addDoc, setDoc, doc, getDoc, Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";
import {
  getAuth, createUserWithEmailAndPassword, onAuthStateChanged, signOut
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyAyJl7kvK3QbHcYzvyAxJ73QBCzGHDcdW0",
  authDomain: "app-fonoaudiologia-gamificado.firebaseapp.com",
  projectId: "app-fonoaudiologia-gamificado",
  storageBucket: "app-fonoaudiologia-gamificado.firebasestorage.app",
  messagingSenderId: "441545837283",
  appId: "1:441545837283:web:97a7cab5d57dc1c580d3d6",
  measurementId: "G-NT1DC4WEKN"
};

// ── 1. App PRINCIPAL (sessão da fono) ───────────────────────────────────────
const app  = getApps().length ? getApp() : initializeApp(firebaseConfig);
const db   = getFirestore(app);
const auth = getAuth(app);

// Expõe para o novopaciente.js
window._db          = db;
window._auth        = auth;
window._addDoc      = addDoc;
window._setDoc      = setDoc;
window._doc         = doc;
window._getDoc      = getDoc;
window._collection  = collection;
window._Timestamp   = Timestamp;
window._signOut     = signOut;

// ── 2. Função que cria o paciente em uma INSTÂNCIA SECUNDÁRIA ───────────────
// Esta função substitui o createUserWithEmailAndPassword direto.
// Cria uma instância isolada, registra o usuário lá, e descarta a instância.
// A sessão da fono na instância principal não é afetada.
window._criarContaPaciente = async function(email, senha) {
  const APP_SECUNDARIO = 'paciente-cadastro';

  // Se sobrou de uma tentativa anterior, descarta antes
  try {
    const existente = getApps().find(a => a.name === APP_SECUNDARIO);
    if (existente) await deleteApp(existente);
  } catch (_) {}

  // Cria instância isolada com a mesma config
  const appSecundario  = initializeApp(firebaseConfig, APP_SECUNDARIO);
  const authSecundario = getAuth(appSecundario);

  try {
    const cred = await createUserWithEmailAndPassword(authSecundario, email, senha);
    const uid  = cred.user.uid;
    // Desloga e descarta a instância secundária
    await signOut(authSecundario);
    await deleteApp(appSecundario);
    return uid;
  } catch (e) {
    // Mesmo em erro, tenta limpar a instância
    try { await deleteApp(appSecundario); } catch (_) {}
    throw e;
  }
};

// ── 3. Validação: confirma que quem está usando esta tela é uma fono ────────
window._authReady = new Promise((resolve) => {
  const unsubscribe = onAuthStateChanged(auth, async (user) => {
    unsubscribe();

    if (!user) {
      console.warn('[Liri] Sem usuário logado — redirecionando para login.');
      window.location.href = 'login.html';
      resolve(null);
      return;
    }

    try {
      const profDoc = await getDoc(doc(db, 'profissionais', user.uid));
      if (!profDoc.exists()) {
        console.warn(
          '[Liri] Usuário logado não é profissional:', user.email,
          '— deslogando e redirecionando.'
        );
        await signOut(auth);
        window.location.href = 'login.html';
        resolve(null);
        return;
      }

      // Verifica status da assinatura
      const dados = profDoc.data();
      const status = dados.status || 'pendente';
      const validade = dados.assinatura_ate?.toDate?.();

      if (status !== 'ativo') {
        console.warn('[Liri] Assinatura não ativa:', status);
        window.location.href = `assinatura-vencida.html?motivo=${status}`;
        resolve(null);
        return;
      }
      if (validade && validade < new Date()) {
        console.warn('[Liri] Assinatura vencida em:', validade);
        window.location.href = 'assinatura-vencida.html?motivo=vencida';
        resolve(null);
        return;
      }

      console.log('[Liri] Profissional autenticado:', user.uid, user.email);
      resolve(user);
    } catch (e) {
      console.error('[Liri] Erro ao validar profissional:', e);
      await signOut(auth);
      window.location.href = 'login.html';
      resolve(null);
    }
  });
});
