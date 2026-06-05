// =============================================================
// google-auth.js
// Módulo reutilizável para login com Google.
// Usado pelas páginas login.html e cadastro.html.
//
// FLUXO:
//   1. Abre popup do Google
//   2. Usuário escolhe a conta
//   3. Verifica no Firestore se o profissional já existe:
//      - Se SIM → vai para dashboard.html
//      - Se NÃO → vai para completar-cadastro.html
// =============================================================

import { auth, db } from "./firebase.js";
import {
  GoogleAuthProvider,
  signInWithPopup
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import {
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

// Provider do Google
const provider = new GoogleAuthProvider();
// Força o Google a mostrar a tela de escolha de conta toda vez
// (evita logar automaticamente na conta errada caso o usuário tenha várias)
provider.setCustomParameters({ prompt: "select_account" });

/**
 * Executa o login com Google e redireciona conforme o caso.
 *
 * @param {Function} onErro - callback recebido com a mensagem de erro
 *                            (para a página exibir no banner)
 */
export async function entrarComGoogle(onErro) {
  try {
    // 1. Abre popup do Google
    const resultado = await signInWithPopup(auth, provider);
    const usuario = resultado.user;

    // 2. Verifica se já existe registro do profissional no Firestore
    const ref = doc(db, "profissionais", usuario.uid);
    const snap = await getDoc(ref);

    if (snap.exists()) {
      // Profissional já cadastrado → vai direto para o dashboard
      window.location.href = "dashboard.html";
    } else {
      // Primeira vez logando com Google → precisa completar cadastro
      window.location.href = "completar-cadastro.html";
    }

  } catch (erro) {
    console.error("Erro no login com Google:", erro);

    // Mensagens amigáveis para os erros mais comuns
    const mensagens = {
      "auth/popup-closed-by-user":   "Você fechou a janela do Google antes de concluir.",
      "auth/popup-blocked":          "O navegador bloqueou o popup. Permita popups e tente novamente.",
      "auth/cancelled-popup-request":"Operação cancelada. Tente novamente.",
      "auth/network-request-failed": "Sem conexão com a internet. Verifique sua rede.",
      "auth/account-exists-with-different-credential":
        "Este e-mail já está cadastrado com outro método. Entre com e-mail e senha.",
    };

    const mensagem = mensagens[erro.code] || "Não foi possível entrar com Google. Tente novamente.";

    if (typeof onErro === "function") {
      onErro(mensagem);
    }
  }
}
