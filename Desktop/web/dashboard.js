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

// Calcula idade a partir do timestamp do Firestore ou string
function calcularIdade(dataNasc) {
  if (!dataNasc) return null;
  let nasc;
  if (dataNasc.toDate) {              // Timestamp do Firestore
    nasc = dataNasc.toDate();
  } else if (typeof dataNasc === 'string') {
    nasc = new Date(dataNasc);
  } else {
    return null;
  }
  if (isNaN(nasc.getTime())) return null;
  const hoje = new Date();
  let idade = hoje.getFullYear() - nasc.getFullYear();
  const m = hoje.getMonth() - nasc.getMonth();
  if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) idade--;
  return idade;
}

// Protege a página — redireciona se não estiver logado
onAuthStateChanged(auth, async (usuario) => {
  if (!usuario) {
    window.location.href = "login.html";
    return;
  }

  const nome = usuario.displayName || "Profissional";
  document.getElementById("topbar-nome").textContent = nome;
  document.getElementById("titulo-boas-vindas").textContent = `Olá, ${nome.split(" ")[0]}! 👋`;

  try {
    const docSnap = await getDoc(doc(db, "profissionais", usuario.uid));
    if (docSnap.exists()) {
      const d = docSnap.data();
      const setIfExists = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.value = val || "";
      };
      setIfExists("cfg-nome",     d.nome);
      setIfExists("cfg-email",    d.email);
      setIfExists("cfg-crfa",     d.crfa);
      setIfExists("cfg-telefone", d.telefone);
      setIfExists("cfg-cpf",      d.cpf);
    }

    // Busca pacientes pelo profissional_id
    const q = query(
      collection(db, "pacientes"),
      where("profissional_id", "==", usuario.uid),
      where("tipo", "==", "paciente")
    );
    const snap = await getDocs(q);
    document.getElementById("total-pacientes").textContent = snap.size;

    const tbody = document.getElementById("tabela-pacientes");
    if (snap.empty) {
      tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;color:#9ca3af;padding:32px">
        Nenhum paciente vinculado ainda.
      </td></tr>`;
      return;
    }

    tbody.innerHTML = "";
    snap.forEach(p => {
      const dados = p.data();
      const idade = calcularIdade(dados.data_nascimento);
      const tr = document.createElement("tr");
      tr.style.cursor = "pointer";
      tr.title = "Clique para ver/editar a ficha";
      tr.onclick = () => {
        window.location.href = `ficha-paciente.html?id=${p.id}`;
      };
      tr.innerHTML = `
        <td>${dados.nome || "—"}</td>
        <td>${idade !== null ? idade + " anos" : "—"}</td>
        <td>${dados.responsavel || "—"}</td>
        <td><span class="badge-ativo">Ativo</span></td>`;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error(e);
  }
});

// Filtro de busca local (na tabela já renderizada)
document.getElementById("busca-paciente")?.addEventListener("input", (e) => {
  const termo = e.target.value.toLowerCase();
  document.querySelectorAll("#tabela-pacientes tr").forEach(tr => {
    const texto = tr.textContent.toLowerCase();
    tr.style.display = texto.includes(termo) ? "" : "none";
  });
});

// Botão sair
document.getElementById("btn-sair").addEventListener("click", async () => {
  await signOut(auth);
  window.location.href = "login.html";
});