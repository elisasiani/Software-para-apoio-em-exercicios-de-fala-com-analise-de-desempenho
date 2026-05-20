import { auth, db } from "./firebase.js";
    import { createUserWithEmailAndPassword, updateProfile } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
    import { doc, setDoc } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

    const form = document.getElementById("form-cadastro");
    const btnCadastrar = document.getElementById("btn-cadastrar");
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

    // Cadastro
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      mensagem.style.display = "none";

      const nome = document.getElementById("nome").value.trim();
      const email = document.getElementById("email").value.trim();
      const cpf = document.getElementById("cpf").value.trim();
      const telefone = document.getElementById("telefone").value.trim();
      const crfa = document.getElementById("crfa").value.trim();
      const senha = document.getElementById("senha").value;
      const confirmarSenha = document.getElementById("confirmar-senha").value;

      // Validações locais
      if (senha !== confirmarSenha) {
        mostrarErro("As senhas não coincidem.");
        return;
      }

      if (senha.length < 6) {
        mostrarErro("A senha deve ter pelo menos 6 caracteres.");
        return;
      }

      btnCadastrar.textContent = "Cadastrando...";
      btnCadastrar.disabled = true;

      try {
        // 1. Cria o usuário no Firebase Authentication
        const credencial = await createUserWithEmailAndPassword(auth, email, senha);
        const usuario = credencial.user;

        // 2. Salva o nome de exibição no perfil
        await updateProfile(usuario, { displayName: nome });

        // 3. Salva os dados extras no Firestore
        await setDoc(doc(db, "profissionais", usuario.uid), {
          nome,
          email,
          cpf,
          telefone,
          crfa,
          criadoEm: new Date().toISOString()
        });

        // 4. Sucesso → redireciona para o login
        mostrarSucesso("Cadastro realizado com sucesso! Redirecionando...");

        setTimeout(() => {
          window.location.href = "login.html";
        }, 2000);

      } catch (erro) {
        mostrarErro(traduzirErro(erro.code));
        btnCadastrar.textContent = "Cadastrar";
        btnCadastrar.disabled = false;
      }
    });