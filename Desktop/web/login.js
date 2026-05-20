import { auth } from "./firebase.js";
    import {
      signInWithEmailAndPassword,
      sendPasswordResetEmail,
      setPersistence,
      browserLocalPersistence,
      browserSessionPersistence
    } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";

    const form = document.getElementById("form-login");
    const btnEntrar = document.getElementById("btn-entrar");
    const mensagemErro = document.getElementById("mensagem-erro");
    const linkEsqueceu = document.getElementById("link-esqueceu");

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

    // Login
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

    // Esqueceu a senha
    linkEsqueceu.addEventListener("click", async (e) => {
      e.preventDefault();
      const email = document.getElementById("email").value;

      if (!email) {
        mostrarErro("Digite seu e-mail acima para redefinir a senha.");
        return;
      }

      try {
        await sendPasswordResetEmail(auth, email);
        mensagemErro.style.background = "#dcfce7";
        mensagemErro.style.color = "#16a34a";
        mensagemErro.textContent = "E-mail de redefinição enviado! Verifique sua caixa de entrada.";
        mensagemErro.style.display = "block";
      } catch (erro) {
        mostrarErro(traduzirErro(erro.code));
      }
    });