import { auth } from "./firebase.js";
import {
  signInWithEmailAndPassword,
  setPersistence,
  browserLocalPersistence,
  browserSessionPersistence
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import { entrarComGoogle } from "./google-auth.js";

const form = document.getElementById("form-login");
const btnEntrar = document.getElementById("btn-entrar");
const btnGoogle = document.getElementById("btn-google");
const mensagemErro = document.getElementById("mensagem-erro");

// Tradução dos erros do Firebase para português
function traduzirErro(codigo) {
  const erros = {
    "auth/invalid-email": "E-mail inválido.",
    "auth/user-not-found": "Nenhuma conta encontrada com este e-mail.",
    "auth/wrong-password": "Senha incorreta.",
    "auth/invalid-credential": "E-mail ou senha incorretos.",
    "auth/too-many-requests": "Muitas tentativas. Tente novamente mais tarde.",
    "auth/user-disabled": "Esta conta foi desativada.",
  };
  return erros[codigo] || "Ocorreu um erro. Tente novamente.";
}

function mostrarErro(msg) {
  mensagemErro.textContent = msg;
  mensagemErro.style.display = "block";
}

function ocultarErro() {
  mensagemErro.style.display = "none";
}

// ── Login com e-mail e senha ─────────────────────────────────────────────────
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  ocultarErro();

  const email = document.getElementById("email").value;
  const senha = document.getElementById("senha").value;
  const lembrar = document.getElementById("lembrar").checked;

  btnEntrar.textContent = "Entrando...";
  btnEntrar.disabled = true;

  try {
    // "Lembrar de mim" define se a sessão persiste ou não
    const persistencia = lembrar ? browserLocalPersistence : browserSessionPersistence;
    await setPersistence(auth, persistencia);

    await signInWithEmailAndPassword(auth, email, senha);

    // Login bem-sucedido → redireciona para a área do profissional
    window.location.href = "dashboard.html";

  } catch (erro) {
    mostrarErro(traduzirErro(erro.code));
    btnEntrar.textContent = "Entrar";
    btnEntrar.disabled = false;
  }
});

// ── Login com Google ─────────────────────────────────────────────────────────
btnGoogle.addEventListener("click", async () => {
  ocultarErro();
  btnGoogle.disabled = true;
  btnGoogle.textContent = "Conectando...";

  await entrarComGoogle((mensagem) => {
    // Callback chamado em caso de erro
    mostrarErro(mensagem);
    btnGoogle.disabled = false;
    // Restaura o botão original com o ícone
    btnGoogle.innerHTML = `
      <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
        <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
        <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
        <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
        <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
      </svg>
      Entrar com Google
    `;
  });
});