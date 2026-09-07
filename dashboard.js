import { auth, db } from "./firebase.js";
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import {
  doc, getDoc, collection, getDocs, query, where, orderBy, limit
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

// Navegação entre páginas
window.mostrarPagina = function (id, btn) {
  document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
  document.querySelectorAll(".menu-item").forEach(m => m.classList.remove("active"));
  const pagina = document.getElementById("page-" + id);
  if (pagina) pagina.classList.add("active");
  if (btn) btn.classList.add("active");
};

// Calcula a idade a partir da data de nascimento
function calcularIdade(dataNasc) {
  if (!dataNasc) return null;
  let nasc;
  if (dataNasc.toDate) {
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

// Extrai um Date de qualquer formato de timestamp do Firestore
function pegarData(timestamp) {
  if (!timestamp) return null;
  if (typeof timestamp.toDate === 'function') return timestamp.toDate();
  if (timestamp.seconds !== undefined) return new Date(timestamp.seconds * 1000);
  return null;
}

// Conta o total de áudios da fono
async function carregarTotalAudios(profissionalUid) {
  const q = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid)
  );
  const snap = await getDocs(q);
  const el = document.getElementById("total-exercicios-concluidos");
  if (el) el.textContent = snap.size;
}

// Formata a data pra mostrar "há X minutos", "há X horas" etc
function formatarDataHora(timestamp) {
  if (!timestamp || !timestamp.toDate) return "—";
  const data = timestamp.toDate();
  const agora = new Date();
  const diffMs = agora - data;
  const diffMin = Math.floor(diffMs / 60000);
  const diffHoras = Math.floor(diffMin / 60);
  const diffDias = Math.floor(diffHoras / 24);

  if (diffMin < 1) return "agora";
  if (diffMin < 60) return `há ${diffMin} min`;
  if (diffHoras < 24) return `há ${diffHoras}h`;
  if (diffDias < 7) return `há ${diffDias} ${diffDias === 1 ? 'dia' : 'dias'}`;

  return data.toLocaleString("pt-BR", {
    day: "2-digit", month: "2-digit",
    hour: "2-digit", minute: "2-digit"
  });
}

// Carrega as últimas atividades dos pacientes
async function carregarAtividadesRecentes(profissionalUid) {
  const container = document.getElementById("atividades-recentes");
  if (!container) return;

  const q = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid),
    orderBy("concluido_em", "desc"),
    limit(10)
  );
  const snap = await getDocs(q);

  if (snap.empty) {
    container.innerHTML = `
      <div class="act-item">
        <div class="act-info">
          <div class="act-name">Nenhuma atividade ainda</div>
          <div class="act-desc">As atividades vão aparecer aqui quando os pacientes praticarem</div>
        </div>
      </div>`;
    return;
  }

  // Cache pra não buscar o mesmo paciente várias vezes
  const cacheNomes = new Map();
  async function pegarNome(pacienteId) {
    if (cacheNomes.has(pacienteId)) return cacheNomes.get(pacienteId);
    const docPac = await getDoc(doc(db, "pacientes", pacienteId));
    const nome = docPac.exists() ? (docPac.data().nome || "Paciente") : "Paciente";
    cacheNomes.set(pacienteId, nome);
    return nome;
  }

  const itens = [];
  for (const d of snap.docs) {
    const dados = d.data();
    const nome = await pegarNome(dados.paciente_id);
    const palavra = dados.palavraAlvo || "exercício";
    const quando = formatarDataHora(dados.concluido_em);
    const tentativas = dados.tentativas || 1;
    const txtTent = tentativas === 1 ? "1 tentativa" : `${tentativas} tentativas`;

    itens.push(`
      <div class="act-item">
        <div class="act-avatar" style="background: #7c3aed1A; color: #7c3aed;">
          <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-14 0M12 4v15m0 0l-4-4m4 4l4-4"/>
          </svg>
        </div>
        <div class="act-info">
          <div class="act-name">${nome} — "${palavra}"</div>
          <div class="act-desc">${txtTent} · ${quando}</div>
        </div>
      </div>
    `);
  }

  container.innerHTML = itens.join("");
}

// Lista de pacientes que não praticam há 7+ dias
async function carregarPacientesInativos(profissionalUid) {
  const container = document.getElementById("pacientes-inativos");
  if (!container) return;

  // Busca todos os pacientes
  const pacQ = query(
    collection(db, "pacientes"),
    where("profissional_id", "==", profissionalUid),
    where("tipo", "==", "paciente")
  );
  const pacSnap = await getDocs(pacQ);

  if (pacSnap.empty) {
    container.innerHTML = `<div class="alerta-vazio">Nenhum paciente cadastrado ainda.</div>`;
    return;
  }

  // Busca todos os progressos
  const progrQ = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid)
  );
  const progrSnap = await getDocs(progrQ);

  // Pega a última prática de cada paciente
  const ultimaPratica = new Map();
  progrSnap.forEach(d => {
    const dados = d.data();
    const ts = dados.concluido_em;
    if (!ts || !ts.toDate || !dados.paciente_id) return;
    const data = ts.toDate();
    const atual = ultimaPratica.get(dados.paciente_id);
    if (!atual || data > atual) {
      ultimaPratica.set(dados.paciente_id, data);
    }
  });

  // Filtra os que não praticam há 7+ dias ou nunca praticaram
  const agora = new Date();
  const SETE_DIAS = 7 * 24 * 60 * 60 * 1000;
  const inativos = [];

  pacSnap.forEach(p => {
    const dados = p.data();
    const ultima = ultimaPratica.get(p.id);
    let diasInativo;
    let status;

    if (!ultima) {
      diasInativo = null;
      status = 'nunca';
    } else {
      const diff = agora - ultima;
      if (diff < SETE_DIAS) return;
      diasInativo = Math.floor(diff / (24 * 60 * 60 * 1000));
      status = diasInativo >= 14 ? 'critico' : 'inativo';
    }

    inativos.push({
      id: p.id,
      nome: dados.nome || "Paciente",
      diasInativo,
      status,
      ultima,
    });
  });

  // Ordena: críticos primeiro
  inativos.sort((a, b) => {
    const ordem = { critico: 0, inativo: 1, nunca: 2 };
    if (ordem[a.status] !== ordem[b.status]) {
      return ordem[a.status] - ordem[b.status];
    }
    return (b.diasInativo || 0) - (a.diasInativo || 0);
  });

  if (inativos.length === 0) {
    container.innerHTML = `<div class="alerta-vazio">Todos os pacientes estão em dia!</div>`;
    return;
  }

  container.innerHTML = inativos.slice(0, 10).map(p => {
    let badgeTxt, badgeClass, detalhe;
    if (p.status === 'nunca') {
      badgeTxt = 'Nunca praticou';
      badgeClass = 'nunca';
      detalhe = 'Ainda não enviou áudios.';
    } else {
      badgeTxt = `${p.diasInativo} ${p.diasInativo === 1 ? 'dia' : 'dias'}`;
      badgeClass = p.status === 'critico' ? 'critico' : '';
      detalhe = `Última prática: ${p.ultima.toLocaleDateString('pt-BR')}`;
    }

    return `
      <div class="paciente-inativo" onclick="window.location.href='ficha-paciente.html?id=${p.id}'">
        <div class="inativo-info">
          <div class="inativo-nome">${p.nome}</div>
          <div class="inativo-detalhe">${detalhe}</div>
        </div>
        <span class="badge-dias ${badgeClass}">${badgeTxt}</span>
      </div>
    `;
  }).join("");
}

// Player com os áudios mais recentes
async function carregarAudiosRecentes(profissionalUid) {
  const container = document.getElementById("audios-recentes-dashboard");
  const contador  = document.getElementById("contador-audios-dashboard");
  if (!container) return;

  const q = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid),
    where("tem_audio", "==", true)
  );
  const snap = await getDocs(q);

  if (snap.empty) {
    container.innerHTML = `<div class="grafico-loading">Nenhum áudio recebido ainda.</div>`;
    if (contador) contador.textContent = "0 áudios";
    return;
  }

  // Ordena por data (mais recente primeiro)
  const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  docs.sort((a, b) => {
    const ta = a.concluido_em?.toDate?.()?.getTime() || 0;
    const tb = b.concluido_em?.toDate?.()?.getTime() || 0;
    return tb - ta;
  });

  if (contador) contador.textContent = `${docs.length} ${docs.length === 1 ? 'áudio' : 'áudios'}`;

  // Cache de nomes
  const cacheNomes = new Map();
  async function pegarNome(pacienteId) {
    if (cacheNomes.has(pacienteId)) return cacheNomes.get(pacienteId);
    const docPac = await getDoc(doc(db, "pacientes", pacienteId));
    const nome = docPac.exists() ? (docPac.data().nome || "Paciente") : "Paciente";
    cacheNomes.set(pacienteId, nome);
    return nome;
  }

  // Pega só os 5 mais recentes
  const top5 = docs.slice(0, 5);
  const itens = [];
  for (const d of top5) {
    const nome    = await pegarNome(d.paciente_id);
    const dataStr = d.concluido_em ? formatarDataHora(d.concluido_em) : '—';
    const palavra = d.palavraAlvo || 'exercício';
    const formato = d.audio_formato || 'audio/mp4';
    const audioSrc = `data:${formato};base64,${d.audio_base64}`;

    itens.push(`
      <div class="audio-recente-item">
        <div class="audio-recente-topo">
          <div class="audio-recente-info">
            <div class="nome">${nome} — "${palavra}"</div>
            <div class="meta">${dataStr}</div>
          </div>
        </div>
        <audio controls preload="none" src="${audioSrc}"></audio>
      </div>
    `);
  }

  container.innerHTML = itens.join("");
}

// =============================================================
// VOLUME DE ATENDIMENTOS
// Reaproveita os pacientes e progressos já carregados na página
// (nada de consultas/agendamento, já que o sistema não tem isso —
// os indicadores são adaptados para pacientes cadastrados e
// áudios enviados).
// =============================================================
let cachePacientesVolume = [];
let cacheProgressosVolume = [];
let chartVolumeAtendimentos = null;

async function carregarVolumeAtendimentos(profissionalUid) {
  // Pacientes (reaproveita se possível, senão busca)
  const pacQ = query(
    collection(db, "pacientes"),
    where("profissional_id", "==", profissionalUid),
    where("tipo", "==", "paciente")
  );
  const pacSnap = await getDocs(pacQ);
  cachePacientesVolume = pacSnap.docs.map(d => ({ id: d.id, ...d.data() }));

  // Todos os progressos (áudios/exercícios) da fono
  const progQ = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid)
  );
  const progSnap = await getDocs(progQ);
  cacheProgressosVolume = progSnap.docs.map(d => ({ id: d.id, ...d.data() }));

  atualizarNovosPacientes();
  atualizarPacientesAtivos();
  renderGraficoVolume();
}

// Card 1: novos pacientes cadastrados no período selecionado
function atualizarNovosPacientes() {
  const select = document.getElementById("filtro-periodo-novos-pacientes");
  const el = document.getElementById("stat-novos-pacientes");
  if (!select || !el) return;

  const dias = parseInt(select.value);
  const limite = new Date();
  limite.setDate(limite.getDate() - dias);
  limite.setHours(0, 0, 0, 0);

  const total = cachePacientesVolume.filter(p => {
    const data = pegarData(p.criado_em);
    return data && data >= limite;
  }).length;

  el.textContent = total;
}

// Card 2: pacientes que enviaram pelo menos 1 áudio nos últimos 12 meses
function atualizarPacientesAtivos() {
  const el = document.getElementById("stat-pacientes-ativos");
  if (!el) return;

  const umAnoAtras = new Date();
  umAnoAtras.setFullYear(umAnoAtras.getFullYear() - 1);

  const ativos = new Set();
  cacheProgressosVolume.forEach(p => {
    const data = pegarData(p.concluido_em);
    if (data && data >= umAnoAtras && p.paciente_id) {
      ativos.add(p.paciente_id);
    }
  });

  el.textContent = ativos.size;
}

// Gráfico de linha: volume de atendimentos (áudios/exercícios) por período
function renderGraficoVolume() {
  const canvas = document.getElementById("grafico-volume-atendimentos");
  const select = document.getElementById("filtro-granularidade-volume");
  if (!canvas || !select) return;

  const granularidade = select.value; // 'dia' | 'semana' | 'mes'
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  let buckets = [];

  if (granularidade === "dia") {
    for (let i = 29; i >= 0; i--) {
      const d = new Date(hoje);
      d.setDate(d.getDate() - i);
      buckets.push({ inicio: d, label: d.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" }), total: 0 });
    }
  } else if (granularidade === "semana") {
    const diaSemana = hoje.getDay();
    const offset = diaSemana === 0 ? 6 : diaSemana - 1;
    const inicioSemanaAtual = new Date(hoje);
    inicioSemanaAtual.setDate(inicioSemanaAtual.getDate() - offset);

    for (let i = 11; i >= 0; i--) {
      const d = new Date(inicioSemanaAtual);
      d.setDate(d.getDate() - i * 7);
      const fim = new Date(d);
      fim.setDate(fim.getDate() + 6);
      const fimReal = fim > hoje ? hoje : fim;
      buckets.push({
        inicio: d,
        label: `${d.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" })}-${fimReal.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" })}`,
        total: 0
      });
    }
  } else {
    for (let i = 11; i >= 0; i--) {
      const d = new Date(hoje.getFullYear(), hoje.getMonth() - i, 1);
      buckets.push({ inicio: d, label: d.toLocaleDateString("pt-BR", { month: "short", year: "2-digit" }), total: 0 });
    }
  }

  cacheProgressosVolume.forEach(p => {
    const data = pegarData(p.concluido_em);
    if (!data) return;
    data.setHours(0, 0, 0, 0);

    if (granularidade === "mes") {
      const idx = buckets.findIndex(b =>
        b.inicio.getFullYear() === data.getFullYear() && b.inicio.getMonth() === data.getMonth()
      );
      if (idx !== -1) buckets[idx].total++;
    } else {
      const tamanhoDias = granularidade === "semana" ? 7 : 1;
      for (let i = 0; i < buckets.length; i++) {
        const inicioB = buckets[i].inicio;
        const fimB = new Date(inicioB);
        fimB.setDate(fimB.getDate() + tamanhoDias);
        if (data >= inicioB && data < fimB) {
          buckets[i].total++;
          break;
        }
      }
    }
  });

  if (chartVolumeAtendimentos) chartVolumeAtendimentos.destroy();

  const ctx = canvas.getContext("2d");
  chartVolumeAtendimentos = new Chart(ctx, {
    type: "line",
    data: {
      labels: buckets.map(b => b.label),
      datasets: [{
        label: "Atendimentos (áudios enviados)",
        data: buckets.map(b => b.total),
        borderColor: "#7c3aed",
        backgroundColor: "rgba(124, 58, 237, 0.1)",
        fill: true,
        tension: 0.3,
        borderWidth: 2,
        pointRadius: 3,
        pointBackgroundColor: "#7c3aed",
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: { beginAtZero: true, ticks: { precision: 0 } },
        x: { grid: { display: false }, ticks: { maxTicksLimit: 12 } }
      }
    }
  });
}

document.getElementById("filtro-periodo-novos-pacientes")?.addEventListener("change", atualizarNovosPacientes);
document.getElementById("filtro-granularidade-volume")?.addEventListener("change", renderGraficoVolume);

// ── Proteção da página + carregamento inicial ───────────────────────────────
onAuthStateChanged(auth, async (usuario) => {
  if (!usuario) {
    window.location.href = "login.html";
    return;
  }

  const docSnap = await getDoc(doc(db, "profissionais", usuario.uid));
  if (!docSnap.exists()) {
    window.location.href = "completar-cadastro.html";
    return;
  }

  const nome = usuario.displayName || "Profissional";
  const elTopbarNome = document.getElementById("topbar-nome");
  if (elTopbarNome) elTopbarNome.textContent = nome;
  const elTituloBoasVindas = document.getElementById("titulo-boas-vindas");
  if (elTituloBoasVindas) elTituloBoasVindas.textContent = `Olá, ${nome.split(" ")[0]}!`;

  // Preenche os campos de configuração
  const d = docSnap.data();
  const setIfExists = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.value = val || "";
  };
  setIfExists("cfg-nome", d.nome);
  setIfExists("cfg-email", d.email);
  setIfExists("cfg-crfa", d.crfa);
  setIfExists("cfg-telefone", d.telefone);
  setIfExists("cfg-cpf", d.cpf);

  // Carrega tudo em paralelo
  carregarTotalAudios(usuario.uid);
  carregarAudiosRecentes(usuario.uid);
  carregarPacientesInativos(usuario.uid);
  carregarAtividadesRecentes(usuario.uid);
  carregarVolumeAtendimentos(usuario.uid);

  // Lista de pacientes na aba "Pacientes"
  const q = query(
    collection(db, "pacientes"),
    where("profissional_id", "==", usuario.uid),
    where("tipo", "==", "paciente")
  );
  const snap = await getDocs(q);
  const elTotalPacientes = document.getElementById("total-pacientes");
  if (elTotalPacientes) elTotalPacientes.textContent = snap.size;

  const tbody = document.getElementById("tabela-pacientes");
  if (!tbody) return;

  if (snap.empty) {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;color:#9ca3af;padding:32px">
      Nenhum paciente cadastrado.
    </td></tr>`;
    return;
  }

  tbody.innerHTML = "";
  snap.forEach(p => {
    const dados = p.data();
    const idade = calcularIdade(dados.data_nascimento);
    const tr = document.createElement("tr");
    tr.style.cursor = "pointer";
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
});

// Busca de paciente
document.getElementById("busca-paciente")?.addEventListener("input", (e) => {
  const termo = e.target.value.toLowerCase();
  document.querySelectorAll("#tabela-pacientes tr").forEach(tr => {
    const texto = tr.textContent.toLowerCase();
    tr.style.display = texto.includes(termo) ? "" : "none";
  });
});

// Botão sair
document.getElementById("btn-sair")?.addEventListener("click", async () => {
  await signOut(auth);
  window.location.href = "login.html";
});