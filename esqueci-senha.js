// Recuperação de senha em 3 passos: e-mail -> código -> nova senha

import { functions } from "./firebase.js";
import { httpsCallable } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-functions.js";

const enviarCodigoRecuperacao = httpsCallable(functions, "enviarCodigoRecuperacao");
const verificarCodigoRecuperacao = httpsCallable(functions, "verificarCodigoRecuperacao");
const redefinirSenhaComCodigo = httpsCallable(functions, "redefinirSenhaComCodigo");

const mensagem = document.getElementById("mensagem");
const subtitulo = document.getElementById("subtitulo-etapa");

const formEmail = document.getElementById("form-email");
const formCodigo = document.getElementById("form-codigo");
const formNovaSenha = document.getElementById("form-nova-senha");

const btnEnviarCodigo = document.getElementById("btn-enviar-codigo");
const btnVerificarCodigo = document.getElementById("btn-verificar-codigo");
const btnReenviar = document.getElementById("btn-reenviar");
const btnRedefinir = document.getElementById("btn-redefinir");

let emailAtual = "";
let codigoVerificado = "";

// ── Controle visual das etapas ───────────────────────────────────────────────
function irParaEtapa(numero) {
  document.querySelectorAll(".etapa").forEach(e => e.classList.remove("ativa"));
  document.querySelectorAll(".passo-bolinha").forEach(b => b.classList.remove("ativo", "concluido"));

  if (numero === 1) {
    formEmail.classList.add("ativa");
    document.getElementById("bolinha-1").classList.add("ativo");
    subtitulo.textContent = "Digite seu e-mail cadastrado para receber um código de verificação.";
  }
  if (numero === 2) {
    formCodigo.classList.add("ativa");
    document.getElementById("bolinha-1").classList.add("concluido");
    document.getElementById("bolinha-2").classList.add("ativo");
    subtitulo.textContent = `Enviamos um código para ${emailAtual}. Confira sua caixa de entrada.`;
  }
  if (numero === 3) {
    formNovaSenha.classList.add("ativa");
    document.getElementById("bolinha-1").classList.add("concluido");
    document.getElementById("bolinha-2").classList.add("concluido");
    document.getElementById("bolinha-3").classList.add("ativo");
    subtitulo.textContent = "Crie uma nova senha para sua conta.";
  }
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

function ocultarMensagem() {
  mensagem.style.display = "none";
}

// Traduz os erros que vêm das Cloud Functions (HttpsError) para o usuário
function traduzirErroFuncao(erro) {
  const mapa = {
    "invalid-argument": "Dados inválidos. Confira e tente novamente.",
    "not-found": "Código não encontrado. Solicite um novo.",
    "deadline-exceeded": "Código expirado. Solicite um novo.",
    "resource-exhausted": "Muitas tentativas incorretas. Solicite um novo código.",
    "permission-denied": "Não foi possível concluir. Tente novamente.",
  };
  return mapa[erro.code?.replace("functions/", "")] || erro.message || "Ocorreu um erro. Tente novamente.";
}

// ── Etapa 1: enviar código ────────────────────────────────────────────────────
formEmail.addEventListener("submit", async (e) => {
  e.preventDefault();
  ocultarMensagem();

  emailAtual = document.getElementById("email").value.trim().toLowerCase();

  btnEnviarCodigo.textContent = "Enviando...";
  btnEnviarCodigo.disabled = true;

  try {
    await enviarCodigoRecuperacao({ email: emailAtual });
    irParaEtapa(2);
    iniciarCooldownReenvio();
  } catch (erro) {
    console.error(erro);
    mostrarMensagem(traduzirErroFuncao(erro), "erro");
  }

  btnEnviarCodigo.textContent = "Enviar código";
  btnEnviarCodigo.disabled = false;
});

// ── Etapa 2: verificar código ─────────────────────────────────────────────────
formCodigo.addEventListener("submit", async (e) => {
  e.preventDefault();
  ocultarMensagem();

  const codigo = document.getElementById("campo-codigo").value.trim();

  btnVerificarCodigo.textContent = "Verificando...";
  btnVerificarCodigo.disabled = true;

  try {
    await verificarCodigoRecuperacao({ email: emailAtual, codigo });
    codigoVerificado = codigo;
    irParaEtapa(3);
  } catch (erro) {
    console.error(erro);
    mostrarMensagem(traduzirErroFuncao(erro), "erro");
  }

  btnVerificarCodigo.textContent = "Verificar código";
  btnVerificarCodigo.disabled = false;
});

// Reenviar código (com espera de 45s entre envios)
function iniciarCooldownReenvio() {
  let restante = 45;
  btnReenviar.disabled = true;
  btnReenviar.textContent = `Aguarde ${restante}s`;

  const intervalo = setInterval(() => {
    restante--;
    if (restante <= 0) {
      clearInterval(intervalo);
      btnReenviar.disabled = false;
      btnReenviar.textContent = "Reenviar código";
    } else {
      btnReenviar.textContent = `Aguarde ${restante}s`;
    }
  }, 1000);
}

btnReenviar.addEventListener("click", async () => {
  ocultarMensagem();
  try {
    await enviarCodigoRecuperacao({ email: emailAtual });
    mostrarMensagem("Código reenviado! Confira seu e-mail.", "sucesso");
    iniciarCooldownReenvio();
  } catch (erro) {
    mostrarMensagem(traduzirErroFuncao(erro), "erro");
  }
});

// ── Etapa 3: mostrar/ocultar senha + validação em tempo real ─────────────────
document.querySelectorAll(".ver-senha").forEach(botao => {
  botao.addEventListener("click", () => {
    const alvo = document.getElementById(botao.dataset.alvo);
    if (alvo.type === "password") {
      alvo.type = "text";
      botao.textContent = "🙈";
    } else {
      alvo.type = "password";
      botao.textContent = "👁️";
    }
  });
});

const inputSenha = document.getElementById("senha");
const inputConfirmar = document.getElementById("confirmar-senha");

const requisitos = {
  tamanho:   { regex: /.{8,}/,                  elemento: document.getElementById("req-tamanho") },
  maiuscula: { regex: /[A-Z]/,                  elemento: document.getElementById("req-maiuscula") },
  numero:    { regex: /\d/,                     elemento: document.getElementById("req-numero") },
  especial:  { regex: /[!@#$%^&*(),.?":{}|<>]/, elemento: document.getElementById("req-especial") },
};

const forcaBarra = document.getElementById("forca-barra");
const forcaTexto = document.getElementById("forca-texto");

inputSenha.addEventListener("input", () => {
  const senha = inputSenha.value;
  let pontos = 0;

  for (const chave in requisitos) {
    if (requisitos[chave].regex.test(senha)) {
      requisitos[chave].elemento.classList.add("valido");
      pontos++;
    } else {
      requisitos[chave].elemento.classList.remove("valido");
    }
  }

  const cores  = ["#ef4444", "#f97316", "#eab308", "#16a34a"];
  const textos = ["Muito fraca", "Fraca", "Média", "Forte"];

  if (senha.length === 0) {
    forcaBarra.style.width = "0";
    forcaTexto.textContent = "Digite uma senha";
    forcaTexto.style.color = "#888";
  } else {
    forcaBarra.style.width = (pontos * 25) + "%";
    forcaBarra.style.background = cores[pontos - 1] || cores[0];
    forcaTexto.textContent      = textos[pontos - 1] || textos[0];
    forcaTexto.style.color      = cores[pontos - 1] || cores[0];
  }
});

// ── Etapa 3: enviar nova senha ────────────────────────────────────────────────
formNovaSenha.addEventListener("submit", async (e) => {
  e.preventDefault();
  ocultarMensagem();

  const senha = inputSenha.value;
  const confirmar = inputConfirmar.value;

  const todosValidos = Object.values(requisitos).every(r => r.regex.test(senha));
  if (!todosValidos) {
    mostrarMensagem("A senha não atende a todos os requisitos.", "erro");
    return;
  }

  if (senha !== confirmar) {
    mostrarMensagem("As senhas não coincidem. Verifique e tente novamente.", "erro");
    return;
  }

  btnRedefinir.textContent = "Redefinindo...";
  btnRedefinir.disabled = true;

  try {
    await redefinirSenhaComCodigo({
      email: emailAtual,
      codigo: codigoVerificado,
      novaSenha: senha,
    });

    mostrarMensagem("Senha redefinida com sucesso! Redirecionando para o login...", "sucesso");
    formNovaSenha.style.display = "none";
    setTimeout(() => {
      window.location.href = "login.html";
    }, 2200);
  } catch (erro) {
    console.error(erro);
    mostrarMensagem(traduzirErroFuncao(erro), "erro");
    btnRedefinir.textContent = "Redefinir senha";
    btnRedefinir.disabled = false;
  }
});
