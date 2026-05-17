import { auth, db } from "./firebase.js";
    import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
    import { doc, getDoc, collection, getDocs, query, where } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

    // Navegação entre páginas
    window.mostrarPagina = function(id, btn) {
      document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
      document.querySelectorAll(".menu-item").forEach(m => m.classList.remove("active"));
      document.getElementById("page-" + id).classList.add("active");
      if (btn) btn.classList.add("active");
    };

    // Protege a página — redireciona se não estiver logado
    onAuthStateChanged(auth, async (usuario) => {
      if (!usuario) {
        window.location.href = "login.html";
        return;
      }

      const nome = usuario.displayName || "Profissional";
      document.getElementById("topbar-nome").textContent = nome;
      document.getElementById("titulo-boas-vindas").textContent = `Olá, ${nome.split(" ")[0]}! 👋`;

      // Busca dados do profissional no Firestore
      try {
        const docSnap = await getDoc(doc(db, "profissionais", usuario.uid));
        if (docSnap.exists()) {
          const d = docSnap.data();
          document.getElementById("cfg-nome").value = d.nome || "";
          document.getElementById("cfg-email").value = d.email || "";
          document.getElementById("cfg-crfa").value = d.crfa || "";
          document.getElementById("cfg-telefone").value = d.telefone || "";
          document.getElementById("cfg-cpf").value = d.cpf || "";

          // Busca pacientes vinculados pelo CRFa
          if (d.crfa) {
            const q = query(collection(db, "usuarios"), where("profissional_id", "==", usuario.uid), where("tipo", "==", "paciente"));
            const snap = await getDocs(q);
            document.getElementById("total-pacientes").textContent = snap.size;

            if (!snap.empty) {
              const tbody = document.getElementById("tabela-pacientes");
              tbody.innerHTML = "";
              snap.forEach(p => {
                const dados = p.data();
                tbody.innerHTML += `
                  <tr>
                    <td>${dados.nome || "—"}</td>
                    <td>${dados.idade ? dados.idade + " anos" : "—"}</td>
                    <td>${dados.responsavel || "—"}</td>
                    <td><span class="badge-ativo">Ativo</span></td>
                    <td>
                      <div class="prog-cell">
                        <div class="prog-pill" style="width:${(dados.progresso || 0) * 0.6}px"></div>
                        <span class="prog-num">${dados.progresso || 0}%</span>
                      </div>
                    </td>
                  </tr>`;
              });
            }
          }
        }
      } catch (e) { console.error(e); }
    });

    // Botão sair
    document.getElementById("btn-sair").addEventListener("click", async () => {
      await signOut(auth);
      window.location.href = "login.html";
    });