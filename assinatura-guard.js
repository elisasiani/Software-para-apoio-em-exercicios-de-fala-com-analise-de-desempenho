// =============================================================
// assinatura-guard.js
// Módulo de verificação de assinatura ativa.
//
// Importe nas páginas protegidas (dashboard, ficha-paciente,
// cadastrar-paciente, relatorios):
//
//   import { verificarAssinatura } from "./assinatura-guard.js";
//
//   onAuthStateChanged(auth, async (usuario) => {
//     if (!usuario) { window.location.href = "login.html"; return; }
//     const ok = await verificarAssinatura(usuario.uid);
//     if (!ok) return; // já redirecionou
//     // ... resto do código da página
//   });
// =============================================================

import { db } from "./firebase.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

const PAGINA_BLOQUEIO = "assinatura-vencida.html";

/**
 * Verifica se o profissional está com assinatura ativa.
 * @returns {Promise<boolean>} true se pode acessar; false se redirecionou.
 */
export async function verificarAssinatura(uid) {
  try {
    const docSnap = await getDoc(doc(db, "profissionais", uid));
    if (!docSnap.exists()) {
      // Sem perfil — precisa completar cadastro
      window.location.href = "completar-cadastro.html";
      return false;
    }

    const dados = docSnap.data();
    const status = dados.status || "pendente";

    // Status diferentes de "ativo" sempre bloqueiam
    if (status !== "ativo") {
      window.location.href = `${PAGINA_BLOQUEIO}?motivo=${status}`;
      return false;
    }

    // Status "ativo" mas com data expirada
    const validade = dados.assinatura_ate?.toDate?.();
    if (validade && validade < new Date()) {
      window.location.href = `${PAGINA_BLOQUEIO}?motivo=vencida`;
      return false;
    }

    return true;
  } catch (e) {
    console.error("[Liri] Erro ao verificar assinatura:", e);
    // Em caso de erro de rede, deixa passar (não trava o sistema)
    return true;
  }
}

/**
 * Retorna informações da assinatura para exibir no dashboard.
 * @returns {Promise<{status, plano, diasRestantes, validade} | null>}
 */
export async function infoAssinatura(uid) {
  try {
    const docSnap = await getDoc(doc(db, "profissionais", uid));
    if (!docSnap.exists()) return null;

    const dados = docSnap.data();
    const validade = dados.assinatura_ate?.toDate?.();
    let diasRestantes = null;

    if (validade) {
      const diff = validade - new Date();
      diasRestantes = Math.floor(diff / (1000 * 60 * 60 * 24));
    }

    return {
      status:        dados.status        || "pendente",
      plano:         dados.plano         || "mensal",
      validade,
      diasRestantes,
    };
  } catch (e) {
    console.error("[Liri] Erro ao buscar info de assinatura:", e);
    return null;
  }
}
