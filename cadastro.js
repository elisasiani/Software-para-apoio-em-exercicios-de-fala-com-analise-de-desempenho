import { auth, db } from "./firebase.js";
import { createUserWithEmailAndPassword, updateProfile } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import {
  doc, setDoc, getDocs, collection, query, where, Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";
import { entrarComGoogle } from "./google-auth.js";

const form = document.getElementById("form-cadastro");
const btnCadastrar = document.getElementById("btn-cadastrar");
const btnGoogle = document.getElementById("btn-google");
const mensagem = document.getElementById("mensagem");

// Tradução dos erros do Firebase
function traduzirErro(codigo) {
  const erros = {
    "auth/email-already-in-use": "Este e-mail já está cadastrado.",
    "auth/invalid-email": "E-mail inválido.",
    "auth/weak-password": "A senha deve ter pelo menos 6 caracteres.",
  };
  return erros[codigo] || "Ocorreu um erro. Tente novamente.";
}

function mostrarErro(msg) {
  mensagem.style.background = "#fee2e2";
  mensagem.style.color = "#dc2626";
  mensagem.textContent = msg;
  mensagem.style.display = "block";
}

function mostrarSucesso(msg) {
  mensagem.style.background = "#dcfce7";
  mensagem.style.color = "#16a34a";
  mensagem.textContent = msg;
  mensagem.style.display = "block";
}

function ocultarMensagem() {
  mensagem.style.display = "none";
}

// Máscara CPF: 000.000.000-00
document.getElementById("cpf").addEventListener("input", (e) => {
  let v = e.target.value.replace(/\D/g, "");
  v = v.replace(/(\d{3})(\d)/, "$1.$2");
  v = v.replace(/(\d{3})(\d)/, "$1.$2");
  v = v.replace(/(\d{3})(\d{1,2})$/, "$1-$2");
  e.target.value = v;
});

// Máscara Telefone: (11) 91234-5678
document.getElementById("telefone").addEventListener("input", (e) => {
  let v = e.target.value.replace(/\D/g, "");
  v = v.replace(/^(\d{2})(\d)/, "($1) $2");
  v = v.replace(/(\d{5})(\d{1,4})$/, "$1-$2");
  e.target.value = v;
});

// ── Cadastro com e-mail e senha ──────────────────────────────────────────────
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  ocultarMensagem();

  // Helpers para validação visual
  const limparErros = () => {
    document.querySelectorAll(".grupo-input input.campo-erro")
      .forEach(el => el.classList.remove("campo-erro"));
  };
  const marcarErro = (id) => {
    const el = document.getElementById(id);
    if (el) el.classList.add("campo-erro");
  };

  limparErros();

  const nome = document.getElementById("nome").value.trim();
  const email = document.getElementById("email").value.trim();
  const cpf = document.getElementById("cpf").value.trim();
  const telefone = document.getElementById("telefone").value.trim();
  const crfa = document.getElementById("crfa").value.trim();
  const senha = document.getElementById("senha").value;
  const confirmarSenha = document.getElementById("confirmar-senha").value;

  // ── Validação de campos obrigatórios ─────────────────────
  const obrigatorios = [
    { id: "nome",             valor: nome,            nome: "Nome completo" },
    { id: "email",            valor: email,           nome: "E-mail" },
    { id: "cpf",              valor: cpf,             nome: "CPF" },
    { id: "telefone",         valor: telefone,        nome: "Telefone" },
    { id: "crfa",             valor: crfa,            nome: "CRFa" },
    { id: "senha",            valor: senha,           nome: "Senha" },
    { id: "confirmar-senha",  valor: confirmarSenha,  nome: "Confirmação de senha" },
  ];

  const faltando = obrigatorios.filter(c => !c.valor);
  if (faltando.length > 0) {
    faltando.forEach(c => marcarErro(c.id));
    mostrarErro(
      faltando.length === 1
        ? `Preencha o campo: ${faltando[0].nome}.`
        : `Preencha todos os campos obrigatórios (${faltando.length} faltando).`
    );
    // Foca no primeiro campo vazio
    document.getElementById(faltando[0].id)?.focus();
    return;
  }

  // ── Validações específicas ────────────────────────────────
  if (senha !== confirmarSenha) {
    marcarErro("senha");
    marcarErro("confirmar-senha");
    mostrarErro("As senhas não coincidem.");
    return;
  }

  if (senha.length < 6) {
    marcarErro("senha");
    mostrarErro("A senha deve ter pelo menos 6 caracteres.");
    return;
  }

  btnCadastrar.textContent = "Verificando dados...";
  btnCadastrar.disabled = true;

  try {
    // ── 0. VALIDA SE O CPF JÁ ESTÁ EM USO ────────────────────────
    // Cada CPF só pode ter UMA conta no sistema.
    const qCpf = query(
      collection(db, "profissionais"),
      where("cpf", "==", cpf)
    );
    const snapCpf = await getDocs(qCpf);
    if (!snapCpf.empty) {
      marcarErro("cpf");
      mostrarErro(
        "Este CPF já está cadastrado. Faça login ou recupere sua senha."
      );
      btnCadastrar.textContent = "Cadastrar";
      btnCadastrar.disabled = false;
      return;
    }

    btnCadastrar.textContent = "Cadastrando...";

    // 1. Cria o usuário no Firebase Authentication
    const credencial = await createUserWithEmailAndPassword(auth, email, senha);
    const usuario = credencial.user;

    // 2. Salva o nome de exibição no perfil
    await updateProfile(usuario, { displayName: nome });

    // 3. Salva os dados extras no Firestore
    // Novos profissionais entram com status "pendente" — só ficam ativos
    // depois que o administrador confirma o pagamento manualmente.
    await setDoc(doc(db, "profissionais", usuario.uid), {
      nome,
      email,
      cpf,
      telefone,
      crfa,
      criadoEm:        new Date().toISOString(),

      // ── CONTROLE DE ASSINATURA ──
      status:          "pendente",     // pendente | ativo | inativo
      plano:           "mensal",       // mensal | anual
      assinatura_ate:  null,           // Timestamp da validade (admin define ao ativar)
      pagamento_observacao: ""         // campo livre para admin anotar
    });

    // 4. Sucesso → vai para a tela de aguardando ativação
    mostrarSucesso(
      "Cadastro realizado! Seu acesso será liberado após a confirmação " +
      "do pagamento. Redirecionando..."
    );

    setTimeout(() => {
      window.location.href = "assinatura-vencida.html?motivo=pendente";
    }, 3500);

  } catch (erro) {
    mostrarErro(traduzirErro(erro.code));
    btnCadastrar.textContent = "Cadastrar";
    btnCadastrar.disabled = false;
  }
});

// ── Cadastro com Google ──────────────────────────────────────────────────────
btnGoogle.addEventListener("click", async () => {
  ocultarMensagem();
  btnGoogle.disabled = true;
  btnGoogle.textContent = "Conectando...";

  await entrarComGoogle((mensagemErro) => {
    // Callback chamado em caso de erro
    mostrarErro(mensagemErro);
    btnGoogle.disabled = false;
    btnGoogle.innerHTML = `
      <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
        <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
        <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
        <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
        <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
      </svg>
      Cadastrar com Google
    `;
  });
});
// ── UX: quando o usuário começa a digitar num campo marcado em vermelho,
//        a borda vermelha some automaticamente
document.querySelectorAll(".grupo-input input").forEach(input => {
  input.addEventListener("input", () => {
    if (input.classList.contains("campo-erro")) {
      input.classList.remove("campo-erro");
    }
  });
});
