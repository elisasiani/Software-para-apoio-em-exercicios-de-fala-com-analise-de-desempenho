import { auth, db } from "./firebase.js";
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import {
  doc, getDoc, collection, getDocs, query, where, orderBy, limit
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";
import { verificarAssinatura, infoAssinatura } from "./assinatura-guard.js";

// ── Aviso de expiração próxima ───────────────────────────────────────────────
function mostrarAvisoExpiracao(diasRestantes, validade) {
  const aviso = document.createElement("div");
  aviso.id = "aviso-expiracao";
  aviso.style.cssText = `
    background: #fef3c7;
    border-left: 4px solid #f59e0b;
    color: #78350f;
    padding: 12px 20px;
    margin: 0 0 16px 0;
    border-radius: 8px;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  `;
  const validadeStr = validade ? validade.toLocaleDateString("pt-BR") : "—";
  const textoDias = diasRestantes === 0
    ? "hoje"
    : (diasRestantes === 1 ? "amanhã" : `em ${diasRestantes} dias`);

  aviso.innerHTML = `
    <span>
      ⚠️ <strong>Sua assinatura vence ${textoDias}</strong> (${validadeStr}).
      Entre em contato para renovar e não perder o acesso.
    </span>
    <a href="https://wa.me/5519993300749?text=Quero%20renovar%20minha%20assinatura%20Liri"
       target="_blank" rel="noopener"
       style="background:#f59e0b;color:#fff;padding:6px 14px;border-radius:6px;text-decoration:none;font-weight:600;white-space:nowrap;">
      Renovar
    </a>
  `;

  // Insere no topo da página principal
  const main = document.querySelector(".page.active") || document.body;
  main.insertBefore(aviso, main.firstChild);
}

// Navegação entre páginas
window.mostrarPagina = function (id, btn) {
  document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
  document.querySelectorAll(".menu-item").forEach(m => m.classList.remove("active"));
  document.getElementById("page-" + id).classList.add("active");
  if (btn) btn.classList.add("active");
};

// Calcula idade a partir do timestamp do Firestore ou string
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

// Conta quantos exercícios o paciente concluiu (acerto) vs total prescrito
async function calcularProgressoPaciente(pacienteId) {
  try {
    const [prescQ, progrQ] = await Promise.all([
      getDocs(query(collection(db, "prescricoes"),
        where("paciente_id", "==", pacienteId),
        where("ativo", "==", true))),
      getDocs(query(collection(db, "progresso_exercicios"),
        where("paciente_id", "==", pacienteId),
        where("acertou", "==", true)))
    ]);
    const total = prescQ.size;
    const concluidos = new Set();
    progrQ.forEach(d => {
      const pid = d.data().prescricao_id;
      if (pid) concluidos.add(pid);
    });
    if (total === 0) return 0;
    return Math.round((concluidos.size / total) * 100);
  } catch (e) {
    console.error("Erro ao calcular progresso:", e);
    return 0;
  }
}

// ── Carrega o card "Exercícios concluídos" (total geral da fono) ─────────────
async function carregarTotalExerciciosConcluidos(profissionalUid) {
  try {
    const q = query(
      collection(db, "progresso_exercicios"),
      where("profissional_id", "==", profissionalUid),
      where("acertou", "==", true)
    );
    const snap = await getDocs(q);
    document.getElementById("total-exercicios-concluidos").textContent = snap.size;
  } catch (e) {
    console.error("Erro ao contar exercícios concluídos:", e);
    document.getElementById("total-exercicios-concluidos").textContent = "—";
  }
}

// ── Formata data/hora para exibição em pt-BR ────────────────────────────────
function formatarDataHora(timestamp) {
  if (!timestamp || !timestamp.toDate) return "—";
  const data = timestamp.toDate();
  const agora = new Date();
  const diffMs = agora - data;
  const diffMin = Math.floor(diffMs / 60000);
  const diffHoras = Math.floor(diffMin / 60);
  const diffDias = Math.floor(diffHoras / 24);

  if (diffMin < 1) return "agora mesmo";
  if (diffMin < 60) return `há ${diffMin} ${diffMin === 1 ? 'minuto' : 'minutos'}`;
  if (diffHoras < 24) return `há ${diffHoras} ${diffHoras === 1 ? 'hora' : 'horas'}`;
  if (diffDias < 7) return `há ${diffDias} ${diffDias === 1 ? 'dia' : 'dias'}`;

  return data.toLocaleString("pt-BR", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit"
  });
}

// ── Carrega as últimas atividades dos pacientes da fono ─────────────────────
async function carregarAtividadesRecentes(profissionalUid) {
  const container = document.getElementById("atividades-recentes");
  try {
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
          <div class="act-avatar">
            <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
          </div>
          <div class="act-info">
            <div class="act-name">Nenhuma atividade ainda</div>
            <div class="act-desc">As atividades aparecerão aqui quando os pacientes realizarem exercícios</div>
          </div>
        </div>`;
      return;
    }

    // Cache de nomes (evita buscar o mesmo paciente várias vezes)
    const cacheNomes = new Map();
    async function nomePaciente(pacienteId) {
      if (cacheNomes.has(pacienteId)) return cacheNomes.get(pacienteId);
      try {
        const docPac = await getDoc(doc(db, "pacientes", pacienteId));
        const nome = docPac.exists() ? (docPac.data().nome || "Paciente") : "Paciente";
        cacheNomes.set(pacienteId, nome);
        return nome;
      } catch {
        return "Paciente";
      }
    }

    const itens = [];
    for (const d of snap.docs) {
      const dados = d.data();
      const nome = await nomePaciente(dados.paciente_id);
      const palavra = dados.palavraAlvo || "exercício";
      const quando = formatarDataHora(dados.concluido_em);
      const acerto = dados.acertou ? "✓ Acertou" : "Tentou";
      const corBolinha = dados.acertou ? "#16a34a" : "#f59e0b";

      itens.push(`
        <div class="act-item">
          <div class="act-avatar" style="background: ${corBolinha}1A; color: ${corBolinha};">
            <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
            </svg>
          </div>
          <div class="act-info">
            <div class="act-name">${nome} — "${palavra}"</div>
            <div class="act-desc">${acerto} · ${quando}</div>
          </div>
        </div>
      `);
    }

    container.innerHTML = itens.join("");
  } catch (e) {
    console.error("Erro ao carregar atividades recentes:", e);
    // Erro típico: índice composto faltando — mostra link no console
    container.innerHTML = `
      <div class="act-item">
        <div class="act-info">
          <div class="act-name">Não foi possível carregar atividades</div>
          <div class="act-desc">Veja o console (F12) — pode precisar criar um índice no Firestore.</div>
        </div>
      </div>`;
  }
}

// ── Carrega o gráfico de atividades dos últimos 7 dias ─────────────────────
async function carregarGrafico7Dias(profissionalUid) {
  const container = document.getElementById("grafico-7dias-body");
  const subtitulo = document.getElementById("grafico-subtitulo");

  try {
    const seteDiasAtras = new Date();
    seteDiasAtras.setDate(seteDiasAtras.getDate() - 6);
    seteDiasAtras.setHours(0, 0, 0, 0);

    const q = query(
      collection(db, "progresso_exercicios"),
      where("profissional_id", "==", profissionalUid)
    );
    const snap = await getDocs(q);

    // Inicializa um bucket pra cada um dos 7 dias
    const buckets = []; // [{ dia, label, total }]
    const labelsDia = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];
    for (let i = 0; i < 7; i++) {
      const d = new Date(seteDiasAtras);
      d.setDate(d.getDate() + i);
      buckets.push({
        data: d,
        label: labelsDia[d.getDay()],
        total: 0,
      });
    }

    // Conta progressos por dia
    snap.forEach(doc => {
      const ts = doc.data().concluido_em;
      if (!ts || !ts.toDate) return;
      const data = ts.toDate();
      if (data < seteDiasAtras) return;

      // Acha o bucket pelo dia/mês
      for (const b of buckets) {
        if (
          b.data.getDate() === data.getDate() &&
          b.data.getMonth() === data.getMonth() &&
          b.data.getFullYear() === data.getFullYear()
        ) {
          b.total++;
          break;
        }
      }
    });

    const total = buckets.reduce((acc, b) => acc + b.total, 0);
    const maximo = Math.max(...buckets.map(b => b.total), 1);
    const hojeISO = new Date().toDateString();

    subtitulo.textContent = `Total: ${total} ${total === 1 ? 'exercício' : 'exercícios'}`;

    container.innerHTML = `<div class="grafico-7dias">
      ${buckets.map(b => {
      const altura = (b.total / maximo) * 100;
      const ehHoje = b.data.toDateString() === hojeISO;
      const zero = b.total === 0;
      return `
          <div class="barra-coluna" title="${b.data.toLocaleDateString('pt-BR')}">
            <div class="barra-valor">${b.total > 0 ? b.total : ''}</div>
            <div class="barra-wrap">
              <div class="barra ${zero ? 'zerada' : ''} ${ehHoje && !zero ? 'barra-hoje' : ''}"
                   style="height: ${zero ? 4 : Math.max(altura, 8)}%"></div>
            </div>
            <div class="barra-label ${ehHoje ? 'hoje' : ''}">${b.label}</div>
          </div>`;
    }).join("")}
    </div>`;
  } catch (e) {
    console.error("Erro ao carregar gráfico 7 dias:", e);
    container.innerHTML = `<div class="grafico-loading">Não foi possível carregar o gráfico.</div>`;
  }
}

// ── Carrega lista de pacientes inativos (≥ 7 dias sem praticar) ────────────
async function carregarPacientesInativos(profissionalUid) {
  const container = document.getElementById("pacientes-inativos");

  try {
    // 1. Pega todos os pacientes da fono
    const pacQ = query(
      collection(db, "pacientes"),
      where("profissional_id", "==", profissionalUid),
      where("tipo", "==", "paciente")
    );
    const pacSnap = await getDocs(pacQ);

    if (pacSnap.empty) {
      container.innerHTML = `<div class="alerta-vazio">
        Nenhum paciente cadastrado ainda.
      </div>`;
      return;
    }

    // 2. Pega todos os progressos da fono
    const progrQ = query(
      collection(db, "progresso_exercicios"),
      where("profissional_id", "==", profissionalUid)
    );
    const progrSnap = await getDocs(progrQ);

    // Mapa paciente_id → última data de prática
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

    // 3. Filtra pacientes inativos (≥ 7 dias) ou que nunca praticaram
    const agora = new Date();
    const SETE_DIAS_MS = 7 * 24 * 60 * 60 * 1000;
    const inativos = [];

    pacSnap.forEach(p => {
      const dados = p.data();
      const ultima = ultimaPratica.get(p.id);
      let diasInativo;
      let statusKey; // 'nunca' | 'inativo' | 'critico'

      if (!ultima) {
        diasInativo = null;
        statusKey = 'nunca';
      } else {
        const diff = agora - ultima;
        if (diff < SETE_DIAS_MS) return; // ativo, não entra na lista
        diasInativo = Math.floor(diff / (24 * 60 * 60 * 1000));
        statusKey = diasInativo >= 14 ? 'critico' : 'inativo';
      }

      inativos.push({
        id: p.id,
        nome: dados.nome || "Paciente",
        diasInativo,
        statusKey,
        ultima,
      });
    });

    // Ordena: críticos primeiro, depois inativos, depois "nunca praticou"
    inativos.sort((a, b) => {
      const ordem = { critico: 0, inativo: 1, nunca: 2 };
      if (ordem[a.statusKey] !== ordem[b.statusKey]) {
        return ordem[a.statusKey] - ordem[b.statusKey];
      }
      // Dentro do mesmo grupo, ordena por dias inativo (mais antigo primeiro)
      return (b.diasInativo || 0) - (a.diasInativo || 0);
    });

    if (inativos.length === 0) {
      container.innerHTML = `<div class="alerta-vazio">
        ✓ Todos os pacientes estão ativos! 🎉
      </div>`;
      return;
    }

    container.innerHTML = inativos.slice(0, 10).map(p => {
      let badgeTxt, badgeClass, detalhe;
      if (p.statusKey === 'nunca') {
        badgeTxt = 'Nunca praticou';
        badgeClass = 'nunca';
        detalhe = 'Ainda não fez nenhum exercício no app.';
      } else {
        badgeTxt = `${p.diasInativo} ${p.diasInativo === 1 ? 'dia' : 'dias'}`;
        badgeClass = p.statusKey === 'critico' ? 'critico' : '';
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

  } catch (e) {
    console.error("Erro ao carregar pacientes inativos:", e);
    container.innerHTML = `<div class="alerta-vazio" style="background:#fee2e2;color:#b91c1c;">
      Não foi possível carregar a lista.
    </div>`;
  }
}

// ── Carrega os áudios recentes dos pacientes (com player) ──────────────────
async function carregarAudiosRecentes(profissionalUid) {
  const container = document.getElementById("audios-recentes-dashboard");
  const contador  = document.getElementById("contador-audios-dashboard");

  try {
    const q = query(
      collection(db, "progresso_exercicios"),
      where("profissional_id", "==", profissionalUid),
      where("tem_audio", "==", true)
    );
    const snap = await getDocs(q);

    if (snap.empty) {
      container.innerHTML = `<div class="grafico-loading">
        Nenhum áudio recebido ainda. 🎙️
      </div>`;
      contador.textContent = "0 áudios";
      return;
    }

    // Ordena por data desc (mais recente primeiro) — feito no client
    const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    docs.sort((a, b) => {
      const ta = a.concluido_em?.toDate?.()?.getTime() || 0;
      const tb = b.concluido_em?.toDate?.()?.getTime() || 0;
      return tb - ta;
    });

    contador.textContent = `${docs.length} ${docs.length === 1 ? 'áudio' : 'áudios'}`;

    // Cache de nomes
    const cacheNomes = new Map();
    async function nomePaciente(pacienteId) {
      if (cacheNomes.has(pacienteId)) return cacheNomes.get(pacienteId);
      try {
        const docPac = await getDoc(doc(db, "pacientes", pacienteId));
        const nome = docPac.exists() ? (docPac.data().nome || "Paciente") : "Paciente";
        cacheNomes.set(pacienteId, nome);
        return nome;
      } catch { return "Paciente"; }
    }

    // Mostra só os 5 mais recentes
    const top5 = docs.slice(0, 5);
    const itens = [];
    for (const d of top5) {
      const nome    = await nomePaciente(d.paciente_id);
      const data    = d.concluido_em?.toDate?.();
      const dataStr = data ? formatarDataHora(d.concluido_em) : '—';
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
  } catch (e) {
    console.error("Erro ao carregar áudios recentes:", e);
    container.innerHTML = `<div class="grafico-loading">
      Não foi possível carregar os áudios.
    </div>`;
  }
}

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

  // ── CHECAGEM DE ASSINATURA ────────────────────────────────────
  // Bloqueia acesso se status != ativo OU se assinatura venceu
  const okAssinatura = await verificarAssinatura(usuario.uid);
  if (!okAssinatura) return;

  // Aviso amarelo no topo se faltam <= 7 dias para vencer
  const info = await infoAssinatura(usuario.uid);
  if (info && info.diasRestantes !== null && info.diasRestantes <= 7 && info.diasRestantes >= 0) {
    mostrarAvisoExpiracao(info.diasRestantes, info.validade);
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
      setIfExists("cfg-nome", d.nome);
      setIfExists("cfg-email", d.email);
      setIfExists("cfg-crfa", d.crfa);
      setIfExists("cfg-telefone", d.telefone);
      setIfExists("cfg-cpf", d.cpf);
    }

    // Carrega em paralelo: stats, gráfico, inativos e atividades
    carregarTotalExerciciosConcluidos(usuario.uid);
    carregarGrafico7Dias(usuario.uid);
    carregarAudiosRecentes(usuario.uid);
    carregarPacientesInativos(usuario.uid);
    carregarAtividadesRecentes(usuario.uid);

    // Lista de pacientes da fono
    const q = query(
      collection(db, "pacientes"),
      where("profissional_id", "==", usuario.uid),
      where("tipo", "==", "paciente")
    );
    const snap = await getDocs(q);
    document.getElementById("total-pacientes").textContent = snap.size;

    const tbody = document.getElementById("tabela-pacientes");
    if (snap.empty) {
      tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;color:#9ca3af;padding:32px">
        Nenhum paciente vinculado ainda.
      </td></tr>`;
      return;
    }

    tbody.innerHTML = "";
    const linhas = [];
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
        <td><span class="badge-ativo">Ativo</span></td>
        <td>
          <div class="prog-cell">
            <div class="prog-pill" style="width:0px"></div>
            <span class="prog-num" data-pid="${p.id}">…</span>
          </div>
        </td>`;
      tbody.appendChild(tr);
      linhas.push({ tr, id: p.id });
    });

    for (const { tr, id } of linhas) {
      const pct = await calcularProgressoPaciente(id);
      const pill = tr.querySelector(".prog-pill");
      const num = tr.querySelector(".prog-num");
      if (pill) pill.style.width = `${Math.max(2, pct * 0.6)}px`;
      if (num) num.textContent = `${pct}%`;
    }
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
