// =============================================================
// relatorios.js
// Página de relatórios da fonoaudióloga:
//  - Busca dados do Firestore (pacientes + progresso_exercicios)
//  - Aplica filtros (paciente / período)
//  - Renderiza 3 gráficos com Chart.js
//  - Monta tabela de desempenho por paciente
//  - Exporta PDF (jsPDF) e CSV
// =============================================================

import { auth, db } from "./firebase.js";
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import { verificarAssinatura } from "./assinatura-guard.js";
import {
  doc, getDoc, collection, getDocs, query, where
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

// ── Estado global da página ──────────────────────────────────────────────────
let profissionalUid = null;
let profissionalNome = "Profissional";
let todosProgressos = [];   // todos os registros de progresso (cache)
let todosPacientes = [];    // todos os pacientes da fono (cache)
let dadosFiltrados = [];    // progressos após aplicar filtros
let pacientesFiltrados = []; // pacientes considerados no filtro atual

// Instâncias dos gráficos (precisamos guardar pra destruir antes de re-renderizar)
let chartEvolucao = null;
let chartAcertos = null;
let chartExercicios = null;

// ── Utilitários ──────────────────────────────────────────────────────────────
function formatarData(timestamp) {
  if (!timestamp || !timestamp.toDate) return "—";
  return timestamp.toDate().toLocaleDateString("pt-BR");
}

function classificarTaxa(taxa) {
  if (taxa >= 70) return "alta";
  if (taxa >= 40) return "media";
  return "baixa";
}

// ── Carregamento inicial ─────────────────────────────────────────────────────
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

  // Bloqueia se não tem assinatura ativa
  const ok = await verificarAssinatura(usuario.uid);
  if (!ok) return;

  profissionalUid = usuario.uid;
  profissionalNome = usuario.displayName || "Profissional";
  document.getElementById("topbar-nome").textContent = profissionalNome;

  try {
    await carregarDados();
    popularFiltroPacientes();
    aplicarFiltros();
  } catch (e) {
    console.error("Erro ao carregar dados:", e);
    alert("Erro ao carregar os dados. Verifique o console.");
  }
});

// ── Busca pacientes e progressos do Firestore ────────────────────────────────
async function carregarDados() {
  // Pacientes da fono
  const qPac = query(
    collection(db, "pacientes"),
    where("profissional_id", "==", profissionalUid),
    where("tipo", "==", "paciente")
  );
  const snapPac = await getDocs(qPac);
  todosPacientes = [];
  snapPac.forEach(d => todosPacientes.push({ id: d.id, ...d.data() }));

  // Progressos da fono
  const qProg = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid)
  );
  const snapProg = await getDocs(qProg);
  todosProgressos = [];
  snapProg.forEach(d => todosProgressos.push({ id: d.id, ...d.data() }));
}

// ── Preenche o <select> de pacientes ─────────────────────────────────────────
function popularFiltroPacientes() {
  const sel = document.getElementById("filtro-paciente");
  todosPacientes
    .sort((a, b) => (a.nome || "").localeCompare(b.nome || ""))
    .forEach(p => {
      const opt = document.createElement("option");
      opt.value = p.id;
      opt.textContent = p.nome || "Paciente";
      sel.appendChild(opt);
    });
}

// ── Aplica filtros e re-renderiza tudo ───────────────────────────────────────
function aplicarFiltros() {
  const pacienteId = document.getElementById("filtro-paciente").value;
  const periodo = document.getElementById("filtro-periodo").value;

  // Filtro por paciente
  let progressos = (pacienteId === "todos")
    ? [...todosProgressos]
    : todosProgressos.filter(p => p.paciente_id === pacienteId);

  pacientesFiltrados = (pacienteId === "todos")
    ? [...todosPacientes]
    : todosPacientes.filter(p => p.id === pacienteId);

  // Filtro por período
  if (periodo !== "todos") {
    const dias = parseInt(periodo);
    const limite = new Date();
    limite.setDate(limite.getDate() - dias);
    limite.setHours(0, 0, 0, 0);

    progressos = progressos.filter(p => {
      if (!p.concluido_em?.toDate) return false;
      return p.concluido_em.toDate() >= limite;
    });
  }

  dadosFiltrados = progressos;

  // Re-renderiza tudo
  atualizarCardsResumo();
  renderGraficoEvolucao();
  renderGraficoAcertos();
  renderGraficoExercicios();
  renderTabelaDesempenho();
}

// ── Cards de resumo ──────────────────────────────────────────────────────────
function atualizarCardsResumo() {
  const total = dadosFiltrados.length;
  const acertos = dadosFiltrados.filter(p => p.acertou).length;
  const taxa = total > 0 ? Math.round((acertos / total) * 100) : 0;

  // Pacientes que aparecem nos progressos filtrados
  const pacientesComProgresso = new Set(dadosFiltrados.map(p => p.paciente_id));

  const media = pacientesComProgresso.size > 0
    ? Math.round(total / pacientesComProgresso.size)
    : 0;

  document.getElementById("stat-total").textContent = total;
  document.getElementById("stat-acerto").textContent = taxa + "%";
  document.getElementById("stat-ativos").textContent = pacientesComProgresso.size;
  document.getElementById("stat-media").textContent = media;
}

// ── Gráfico 1: Evolução temporal (linha) ─────────────────────────────────────
function renderGraficoEvolucao() {
  const periodo = document.getElementById("filtro-periodo").value;
  const dias = periodo === "todos" ? 30 : parseInt(periodo);

  // Cria buckets por dia
  const buckets = new Map(); // chave: "YYYY-MM-DD", valor: { total, acertos }
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  for (let i = dias - 1; i >= 0; i--) {
    const d = new Date(hoje);
    d.setDate(d.getDate() - i);
    const chave = d.toISOString().split("T")[0];
    buckets.set(chave, { total: 0, acertos: 0, data: d });
  }

  dadosFiltrados.forEach(p => {
    if (!p.concluido_em?.toDate) return;
    const data = p.concluido_em.toDate();
    data.setHours(0, 0, 0, 0);
    const chave = data.toISOString().split("T")[0];
    if (buckets.has(chave)) {
      const b = buckets.get(chave);
      b.total++;
      if (p.acertou) b.acertos++;
    }
  });

  const labels = [];
  const dadosTotal = [];
  const dadosAcertos = [];

  buckets.forEach(b => {
    labels.push(b.data.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" }));
    dadosTotal.push(b.total);
    dadosAcertos.push(b.acertos);
  });

  document.getElementById("sub-evolucao").textContent =
    `${dadosFiltrados.length} ${dadosFiltrados.length === 1 ? 'exercício' : 'exercícios'} no período`;

  if (chartEvolucao) chartEvolucao.destroy();

  const ctx = document.getElementById("grafico-evolucao").getContext("2d");
  chartEvolucao = new Chart(ctx, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "Total",
          data: dadosTotal,
          borderColor: "#7c3aed",
          backgroundColor: "rgba(124, 58, 237, 0.1)",
          fill: true,
          tension: 0.3,
          borderWidth: 2,
          pointRadius: 3,
          pointBackgroundColor: "#7c3aed",
        },
        {
          label: "Acertos",
          data: dadosAcertos,
          borderColor: "#16a34a",
          backgroundColor: "rgba(22, 163, 74, 0.08)",
          fill: true,
          tension: 0.3,
          borderWidth: 2,
          pointRadius: 3,
          pointBackgroundColor: "#16a34a",
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: "bottom", labels: { font: { family: "Inter", size: 12 } } }
      },
      scales: {
        y: { beginAtZero: true, ticks: { precision: 0 } },
        x: { grid: { display: false } }
      }
    }
  });
}

// ── Gráfico 2: Acertos vs Erros (rosca) ──────────────────────────────────────
function renderGraficoAcertos() {
  const acertos = dadosFiltrados.filter(p => p.acertou).length;
  const erros = dadosFiltrados.length - acertos;

  if (chartAcertos) chartAcertos.destroy();

  const ctx = document.getElementById("grafico-acertos").getContext("2d");
  chartAcertos = new Chart(ctx, {
    type: "doughnut",
    data: {
      labels: ["Acertos", "Erros"],
      datasets: [{
        data: [acertos, erros],
        backgroundColor: ["#16a34a", "#ef4444"],
        borderWidth: 0,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: "65%",
      plugins: {
        legend: { position: "bottom", labels: { font: { family: "Inter", size: 12 } } }
      }
    }
  });
}

// ── Gráfico 3: Exercícios mais realizados (barras horizontais) ───────────────
function renderGraficoExercicios() {
  // Conta por palavraAlvo
  const contagem = {};
  dadosFiltrados.forEach(p => {
    const palavra = p.palavraAlvo || "—";
    contagem[palavra] = (contagem[palavra] || 0) + 1;
  });

  // Top 5
  const top = Object.entries(contagem)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  if (chartExercicios) chartExercicios.destroy();

  const ctx = document.getElementById("grafico-exercicios").getContext("2d");
  chartExercicios = new Chart(ctx, {
    type: "bar",
    data: {
      labels: top.map(t => t[0]),
      datasets: [{
        label: "Realizações",
        data: top.map(t => t[1]),
        backgroundColor: "#a855f7",
        borderRadius: 6,
      }]
    },
    options: {
      indexAxis: "y",
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { beginAtZero: true, ticks: { precision: 0 } },
        y: { grid: { display: false } }
      }
    }
  });
}

// ── Tabela: desempenho por paciente ──────────────────────────────────────────
function renderTabelaDesempenho() {
  const tbody = document.getElementById("tabela-desempenho");

  // Agrupa por paciente
  const porPaciente = new Map();
  pacientesFiltrados.forEach(p => {
    porPaciente.set(p.id, {
      id: p.id,
      nome: p.nome || "Paciente",
      total: 0,
      acertos: 0,
      ultima: null,
    });
  });

  dadosFiltrados.forEach(prog => {
    const entry = porPaciente.get(prog.paciente_id);
    if (!entry) return;
    entry.total++;
    if (prog.acertou) entry.acertos++;
    const data = prog.concluido_em?.toDate?.();
    if (data && (!entry.ultima || data > entry.ultima)) {
      entry.ultima = data;
    }
  });

  // Filtra só pacientes com pelo menos 1 exercício no período
  const linhas = [...porPaciente.values()]
    .filter(p => p.total > 0)
    .sort((a, b) => b.total - a.total);

  if (linhas.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;color:#9ca3af;padding:32px">
      Nenhum dado encontrado para os filtros selecionados.
    </td></tr>`;
    return;
  }

  tbody.innerHTML = linhas.map(p => {
    const taxa = Math.round((p.acertos / p.total) * 100);
    const classe = classificarTaxa(taxa);
    const ultimaStr = p.ultima ? p.ultima.toLocaleDateString("pt-BR") : "—";

    return `
      <tr>
        <td><strong>${p.nome}</strong></td>
        <td>${p.total}</td>
        <td>${p.acertos}</td>
        <td><span class="taxa-acerto ${classe}">${taxa}%</span></td>
        <td>${ultimaStr}</td>
      </tr>
    `;
  }).join("");
}

// ── EXPORTAR CSV ─────────────────────────────────────────────────────────────
function exportarCSV() {
  if (dadosFiltrados.length === 0) {
    alert("Não há dados para exportar.");
    return;
  }

  // Mapa de pacientes para resolver nomes
  const mapaPacientes = new Map();
  todosPacientes.forEach(p => mapaPacientes.set(p.id, p.nome || "Paciente"));

  const cabecalho = ["Paciente", "Palavra/Exercício", "Trilha", "Dificuldade", "Resultado", "Data"];
  const linhas = [cabecalho];

  dadosFiltrados
    .sort((a, b) => {
      const da = a.concluido_em?.toDate?.() || new Date(0);
      const db_ = b.concluido_em?.toDate?.() || new Date(0);
      return db_ - da;
    })
    .forEach(p => {
      linhas.push([
        mapaPacientes.get(p.paciente_id) || "—",
        p.palavraAlvo || "—",
        p.trilha_titulo || "—",
        p.dificuldade || "—",
        p.acertou ? "Acertou" : "Errou",
        p.concluido_em?.toDate?.().toLocaleString("pt-BR") || "—",
      ]);
    });

  // Monta CSV (escapa aspas e vírgulas)
  const csv = linhas.map(linha =>
    linha.map(celula => {
      const txt = String(celula).replace(/"/g, '""');
      return /[",\n;]/.test(txt) ? `"${txt}"` : txt;
    }).join(";")
  ).join("\n");

  // BOM para o Excel abrir com acentos certos
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  const hoje = new Date().toISOString().split("T")[0];
  a.href = url;
  a.download = `relatorio-liri-${hoje}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ── EXPORTAR PDF ─────────────────────────────────────────────────────────────
async function exportarPDF() {
  if (dadosFiltrados.length === 0) {
    alert("Não há dados para exportar.");
    return;
  }

  const { jsPDF } = window.jspdf;
  const pdf = new jsPDF("p", "mm", "a4");

  const total = dadosFiltrados.length;
  const acertos = dadosFiltrados.filter(p => p.acertou).length;
  const taxa = total > 0 ? Math.round((acertos / total) * 100) : 0;

  const filtroPaciente = document.getElementById("filtro-paciente");
  const filtroPeriodo = document.getElementById("filtro-periodo");
  const nomePaciente = filtroPaciente.options[filtroPaciente.selectedIndex].text;
  const labelPeriodo = filtroPeriodo.options[filtroPeriodo.selectedIndex].text;

  // ── Cabeçalho ──────────────────────────────────────────────
  pdf.setFillColor(124, 58, 237);
  pdf.rect(0, 0, 210, 30, "F");
  pdf.setTextColor(255, 255, 255);
  pdf.setFontSize(18);
  pdf.setFont("helvetica", "bold");
  pdf.text("Relatório de Desempenho", 14, 14);
  pdf.setFontSize(10);
  pdf.setFont("helvetica", "normal");
  pdf.text("Liri - Sistema de Apoio Fonoaudiológico", 14, 22);

  // ── Informações gerais ─────────────────────────────────────
  pdf.setTextColor(40, 40, 40);
  pdf.setFontSize(10);
  let y = 40;
  pdf.text(`Profissional: ${profissionalNome}`, 14, y); y += 6;
  pdf.text(`Paciente: ${nomePaciente}`, 14, y); y += 6;
  pdf.text(`Período: ${labelPeriodo}`, 14, y); y += 6;
  pdf.text(`Data do relatório: ${new Date().toLocaleString("pt-BR")}`, 14, y); y += 10;

  // ── Resumo (cards) ─────────────────────────────────────────
  pdf.setFontSize(12);
  pdf.setFont("helvetica", "bold");
  pdf.text("Resumo", 14, y); y += 6;

  pdf.setFont("helvetica", "normal");
  pdf.setFontSize(10);

  const cards = [
    { label: "Exercícios realizados", valor: total },
    { label: "Acertos", valor: acertos },
    { label: "Taxa de acerto", valor: taxa + "%" },
    { label: "Pacientes envolvidos", valor: new Set(dadosFiltrados.map(p => p.paciente_id)).size },
  ];

  const cardW = 44, cardH = 22, gap = 4;
  cards.forEach((c, i) => {
    const x = 14 + i * (cardW + gap);
    pdf.setFillColor(245, 243, 255);
    pdf.roundedRect(x, y, cardW, cardH, 2, 2, "F");
    pdf.setFontSize(8);
    pdf.setTextColor(100, 100, 100);
    pdf.text(c.label, x + 3, y + 6);
    pdf.setFontSize(14);
    pdf.setTextColor(124, 58, 237);
    pdf.setFont("helvetica", "bold");
    pdf.text(String(c.valor), x + 3, y + 16);
    pdf.setFont("helvetica", "normal");
  });
  y += cardH + 10;

  // ── Gráfico de evolução (captura do canvas) ────────────────
  pdf.setTextColor(40, 40, 40);
  pdf.setFontSize(12);
  pdf.setFont("helvetica", "bold");
  pdf.text("Evolução no período", 14, y); y += 4;

  try {
    const canvasEvolucao = document.getElementById("grafico-evolucao");
    const imgEvolucao = canvasEvolucao.toDataURL("image/png");
    pdf.addImage(imgEvolucao, "PNG", 14, y, 182, 70);
    y += 76;
  } catch (e) {
    console.error("Não foi possível capturar o gráfico:", e);
  }

  // ── Tabela de desempenho por paciente ──────────────────────
  if (y > 240) { pdf.addPage(); y = 20; }

  pdf.setFontSize(12);
  pdf.setFont("helvetica", "bold");
  pdf.text("Desempenho por paciente", 14, y); y += 4;

  // Monta os dados da tabela do mesmo jeito que renderTabelaDesempenho
  const porPaciente = new Map();
  pacientesFiltrados.forEach(p => {
    porPaciente.set(p.id, { nome: p.nome || "Paciente", total: 0, acertos: 0, ultima: null });
  });
  dadosFiltrados.forEach(prog => {
    const entry = porPaciente.get(prog.paciente_id);
    if (!entry) return;
    entry.total++;
    if (prog.acertou) entry.acertos++;
    const data = prog.concluido_em?.toDate?.();
    if (data && (!entry.ultima || data > entry.ultima)) entry.ultima = data;
  });

  const linhasTabela = [...porPaciente.values()]
    .filter(p => p.total > 0)
    .sort((a, b) => b.total - a.total)
    .map(p => [
      p.nome,
      p.total,
      p.acertos,
      Math.round((p.acertos / p.total) * 100) + "%",
      p.ultima ? p.ultima.toLocaleDateString("pt-BR") : "—",
    ]);

  pdf.autoTable({
    startY: y,
    head: [["Paciente", "Total", "Acertos", "Taxa", "Última prática"]],
    body: linhasTabela,
    styles: { font: "helvetica", fontSize: 9 },
    headStyles: { fillColor: [124, 58, 237], textColor: 255 },
    alternateRowStyles: { fillColor: [248, 250, 252] },
    margin: { left: 14, right: 14 },
  });

  // Rodapé com paginação
  const totalPaginas = pdf.internal.getNumberOfPages();
  for (let i = 1; i <= totalPaginas; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.setTextColor(150, 150, 150);
    pdf.text(
      `Página ${i} de ${totalPaginas} - Gerado por Liri em ${new Date().toLocaleDateString("pt-BR")}`,
      105, 290,
      { align: "center" }
    );
  }

  const hoje = new Date().toISOString().split("T")[0];
  pdf.save(`relatorio-liri-${hoje}.pdf`);
}

// ── Listeners ────────────────────────────────────────────────────────────────
document.getElementById("btn-aplicar").addEventListener("click", aplicarFiltros);
document.getElementById("btn-export-csv").addEventListener("click", exportarCSV);
document.getElementById("btn-export-pdf").addEventListener("click", exportarPDF);

document.getElementById("btn-sair").addEventListener("click", async () => {
  await signOut(auth);
  window.location.href = "login.html";
});
