import { auth } from "./firebase.js";
import { sendPasswordResetEmail } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";

const form = document.getElementById("form-recuperar");
const btnEnviar = document.getElementById("btn-enviar");
const mensagem = document.getElementById("mensagem");

function traduzirErro(codigo) {
  const erros = {
    "auth/invalid-email": "E-mail inválido.",
    "auth/user-not-found": "Nenhuma conta encontrada com este e-mail.",
    "auth/too-many-requests": "Muitas tentativas. Tente novamente mais tarde.",
    "auth/missing-email": "Digite seu e-mail.",
  };
  return erros[codigo] || "Ocorreu um erro. Tente novamente.";
}

function mostrarMensagem(texto, tipo) {
  mensagem.textContent = texto;
  mensagem.style.display = "block";
  if (tipo === "sucesso") {
    mensagem.style.background = "#dcfce7";
    mensagem.style.color = "#166534";
  } else {
    mensagem.style.background = "#fee2e2";
    mensagem.style.color = "#dc2626";
  }
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  mensagem.style.display = "none";

  const email = document.getElementById("email").value.trim();

  btnEnviar.textContent = "Enviando...";
  btnEnviar.disabled = true;

  try {
    // Configura para que o link do e-mail leve para a página customizada "nova-senha.html"
    const actionCodeSettings = {
      url: window.location.origin + "/nova-senha.html",
      handleCodeInApp: false,
    };

    await sendPasswordResetEmail(auth, email, actionCodeSettings);
    mostrarMensagem(
      "E-mail enviado com sucesso! Verifique sua caixa de entrada (e a pasta de spam) e siga as instruções para criar uma nova senha.",
      "sucesso"
    );
    form.reset();
    btnEnviar.textContent = "Enviar novamente";
  } catch (erro) {
    console.error("Erro ao enviar link de recuperação:", erro.code, erro.message);
    mostrarMensagem(traduzirErro(erro.code), "erro");
    btnEnviar.textContent = "Enviar link de recuperação";
  }

  btnEnviar.disabled = false;
});