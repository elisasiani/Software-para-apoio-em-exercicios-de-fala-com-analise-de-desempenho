// =============================================================
// relatorios.js
// Página de relatórios da fonoaudióloga
// =============================================================

import { auth, db } from "./firebase.js";

import {
  onAuthStateChanged,
  signOut
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";

import {
  doc,
  getDoc,
  collection,
  getDocs,
  query,
  where
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

// ── Estado global ──────────────────────────────────────────────
let profissionalUid = null;
let profissionalNome = "Profissional";

let todosProgressos = [];
let todosPacientes = [];
let dadosFiltrados = [];

let chartEvolucao = null;
let chartDificuldade = null;


// ── Carregamento inicial ───────────────────────────────────────
onAuthStateChanged(auth, async (usuario) => {

  if (!usuario) {
    window.location.href = "login.html";
    return;
  }

  try {

    const docSnap = await getDoc(
      doc(db, "profissionais", usuario.uid)
    );

    if (!docSnap.exists()) {
      window.location.href = "completar-cadastro.html";
      return;
    }

    profissionalUid = usuario.uid;
    profissionalNome = usuario.displayName || "Profissional";

    document.getElementById("topbar-nome").textContent =
      profissionalNome;

    await carregarDados();

    popularFiltroPacientes();
    aplicarFiltros();
    renderPacientesAtencao();

  } catch (e) {

    console.error("Erro ao carregar dados:", e);
    alert("Erro ao carregar os dados. Verifique o console.");

  }

});


// ── Busca pacientes e progressos ───────────────────────────────
async function carregarDados() {

  const qPac = query(
    collection(db, "pacientes"),
    where("profissional_id", "==", profissionalUid),
    where("tipo", "==", "paciente")
  );

  const snapPac = await getDocs(qPac);

  todosPacientes = [];

  snapPac.forEach((d) => {
    todosPacientes.push({
      id: d.id,
      ...d.data()
    });
  });


  const qProg = query(
    collection(db, "progresso_exercicios"),
    where("profissional_id", "==", profissionalUid)
  );

  const snapProg = await getDocs(qProg);

  todosProgressos = [];

  snapProg.forEach((d) => {
    todosProgressos.push({
      id: d.id,
      ...d.data()
    });
  });

}


// ── Preenche o filtro de pacientes ─────────────────────────────
function popularFiltroPacientes() {

  const sel = document.getElementById("filtro-paciente");

  sel.innerHTML =
    '<option value="todos">Todos os pacientes</option>';

  todosPacientes
    .sort((a, b) =>
      (a.nome || "").localeCompare(b.nome || "")
    )
    .forEach((p) => {

      const opt = document.createElement("option");

      opt.value = p.id;
      opt.textContent = p.nome || "Paciente";

      sel.appendChild(opt);

    });

}


// ── Aplica os filtros ──────────────────────────────────────────
function aplicarFiltros() {

  const pacienteId =
    document.getElementById("filtro-paciente").value;

  const periodo =
    document.getElementById("filtro-periodo").value;


  let progressos = pacienteId === "todos"
    ? [...todosProgressos]
    : todosProgressos.filter(
        p => p.paciente_id === pacienteId
      );


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

  atualizarCardsResumo();
  renderGraficoEvolucao();
  renderGraficoDificuldade();

}


// ── Cards de resumo ────────────────────────────────────────────
function atualizarCardsResumo() {

  const audios = dadosFiltrados.filter(p =>
    p.audio_base64 &&
    p.audio_base64.length > 0
  ).length;


  const tentativas = dadosFiltrados.reduce((acc, p) => {

    const t = p.tentativas ?? p.numero_tentativas ?? 1;

    return acc + (typeof t === "number" ? t : 1);

  }, 0);


  document.getElementById("stat-audios").textContent = audios;

  document.getElementById("stat-tentativas").textContent =
    tentativas;

}


// ── Gráfico: evolução de exercícios ────────────────────────────
function renderGraficoEvolucao() {

  const canvas = document.getElementById("grafico-evolucao");

  if (!canvas) {
    console.error("Canvas grafico-evolucao não encontrado.");
    return;
  }


  const periodo =
    document.getElementById("filtro-periodo").value;

  const hoje = new Date();

  hoje.setHours(0, 0, 0, 0);


  let agrupamento = "dia";
  let dataInicio;


  if (periodo === "7" || periodo === "30") {

    const dias = parseInt(periodo);

    dataInicio = new Date(hoje);

    dataInicio.setDate(
      dataInicio.getDate() - (dias - 1)
    );

  } else if (periodo === "90") {

    agrupamento = "semana";

    dataInicio = new Date(hoje);

    dataInicio.setDate(
      dataInicio.getDate() - 89
    );

  } else {

    agrupamento = "semana";

    const datasValidas = dadosFiltrados
      .filter(p => p.concluido_em?.toDate)
      .map(p => {

        const d = p.concluido_em.toDate();

        d.setHours(0, 0, 0, 0);

        return d;

      });


    if (datasValidas.length > 0) {

      dataInicio = new Date(
        Math.min(...datasValidas)
      );

    } else {

      agrupamento = "dia";

      dataInicio = new Date(hoje);

      dataInicio.setDate(
        dataInicio.getDate() - 29
      );

    }

  }


  if (agrupamento === "semana") {

    const diaSemana = dataInicio.getDay();

    const offset =
      diaSemana === 0 ? 6 : diaSemana - 1;

    dataInicio.setDate(
      dataInicio.getDate() - offset
    );

  }


  const tamanhoBucketDias =
    agrupamento === "semana" ? 7 : 1;


  const buckets = [];

  const cursor = new Date(dataInicio);

  while (cursor <= hoje && buckets.length < 500) {

    buckets.push({
      inicio: new Date(cursor),
      total: 0
    });

    cursor.setDate(
      cursor.getDate() + tamanhoBucketDias
    );

  }


  dadosFiltrados.forEach(p => {

    if (!p.concluido_em?.toDate) return;

    const data = p.concluido_em.toDate();

    data.setHours(0, 0, 0, 0);

    if (data < dataInicio) return;


    const diffDias = Math.floor(
      (data - dataInicio) / 86400000
    );

    const idx = Math.floor(
      diffDias / tamanhoBucketDias
    );

    if (buckets[idx]) {
      buckets[idx].total++;
    }

  });


  const labels = buckets.map(b => {

    const inicioStr = b.inicio.toLocaleDateString(
      "pt-BR",
      {
        day: "2-digit",
        month: "2-digit"
      }
    );


    if (agrupamento === "dia") {
      return inicioStr;
    }


    const fim = new Date(b.inicio);

    fim.setDate(fim.getDate() + 6);

    const fimReal = fim > hoje ? hoje : fim;

    const fimStr = fimReal.toLocaleDateString(
      "pt-BR",
      {
        day: "2-digit",
        month: "2-digit"
      }
    );

    return `${inicioStr} - ${fimStr}`;

  });


  const dadosTotal = buckets.map(b => b.total);


  document.getElementById("sub-evolucao").textContent =
    `${dadosFiltrados.length} ${
      dadosFiltrados.length === 1
        ? "exercício"
        : "exercícios"
    } no período`;


  if (chartEvolucao) {
    chartEvolucao.destroy();
  }


  const ctx = canvas.getContext("2d");


  chartEvolucao = new Chart(ctx, {

    type: "bar",

    data: {

      labels,

      datasets: [

        {

          label: "Exercícios realizados",

          data: dadosTotal,

          backgroundColor: "rgba(124, 58, 237, 0.75)",

          borderColor: "#7c3aed",

          borderWidth: 1,

          borderRadius: 4,

          maxBarThickness: 40

        }

      ]

    },


    options: {

      responsive: true,

      maintainAspectRatio: false,

      plugins: {

        legend: {

          position: "bottom",

          labels: {

            font: {
              family: "Inter",
              size: 12
            }

          }

        },

        tooltip: {

          callbacks: {

            title: (items) =>

              agrupamento === "semana"

                ? `Semana: ${items[0].label}`

                : items[0].label

          }

        }

      },


      scales: {

        y: {

          beginAtZero: true,

          ticks: {
            precision: 0
          }

        },

        x: {

          ticks: {

            maxTicksLimit:
              agrupamento === "semana" ? 12 : 10,

            font: {
              family: "Inter",
              size: 11
            },

            maxRotation:
              agrupamento === "semana" ? 45 : 0,

            minRotation: 0

          }

        }

      }

    }

  });

}


// ── Gráfico: dificuldade ───────────────────────────────────────
function renderGraficoDificuldade() {

  const canvas = document.getElementById("grafico-dificuldade");

  const vazio = document.getElementById("dificuldade-vazio");

  if (!canvas || !vazio) {
    console.error("Elementos do gráfico de dificuldade não encontrados.");
    return;
  }


  const contagem = {};


  dadosFiltrados.forEach(p => {

    const dif = (p.dificuldade || "")
      .toLowerCase()
      .trim();

    if (!dif) return;

    contagem[dif] = (contagem[dif] || 0) + 1;

  });


  const ordem = ["fácil", "médio", "difícil"];


  const labels = Object.keys(contagem).sort((a, b) => {

    const ia = ordem.indexOf(a);
    const ib = ordem.indexOf(b);

    if (ia === -1 && ib === -1) {
      return a.localeCompare(b);
    }

    if (ia === -1) return 1;
    if (ib === -1) return -1;

    return ia - ib;

  });


  const valores = labels.map(l => contagem[l]);

  const total = valores.reduce(
    (a, b) => a + b,
    0
  );


  const coresPorNivel = {

    "fácil": "#4ade80",

    "médio": "#fbbf24",

    "difícil": "#f87171"

  };


  const cores = labels.map(l =>
    coresPorNivel[l] || "#a78bfa"
  );


  document.getElementById("sub-dificuldade").textContent =

    total > 0

      ? `${total} exercícios classificados`

      : "—";


  if (chartDificuldade) {

    chartDificuldade.destroy();

    chartDificuldade = null;

  }


  if (total === 0) {

    canvas.style.display = "none";

    vazio.style.display = "flex";

    return;

  }


  canvas.style.display = "block";

  vazio.style.display = "none";


  const ctx = canvas.getContext("2d");


  chartDificuldade = new Chart(ctx, {

    type: "doughnut",

    data: {

      labels: labels.map(l =>
        l.charAt(0).toUpperCase() + l.slice(1)
      ),

      datasets: [

        {

          data: valores,

          backgroundColor: cores,

          borderColor: "#fff",

          borderWidth: 2

        }

      ]

    },


    options: {

      responsive: true,

      maintainAspectRatio: false,

      cutout: "65%",

      plugins: {

        legend: {

          position: "bottom",

          labels: {

            font: {
              family: "Inter",
              size: 12
            },

            padding: 16

          }

        },

        tooltip: {

          callbacks: {

            label: (item) => {

              const pct = (
                (item.parsed / total) * 100
              ).toFixed(0);

              return `${item.label}: ${item.parsed} (${pct}%)`;

            }

          }

        }

      }

    }

  });

}


// ── Formata tempo de inatividade ───────────────────────────────
function formatarTempoInatividade(dias) {

  if (dias < 30) {

    return `${dias} ${
      dias === 1 ? "dia" : "dias"
    }`;

  }


  if (dias < 365) {

    const meses = Math.round(dias / 30);

    return `${meses} ${
      meses === 1 ? "mês" : "meses"
    }`;

  }


  const anos = Math.round(dias / 365);

  return `${anos} ${
    anos === 1 ? "ano" : "anos"
  }`;

}


// ── Pacientes que precisam de atenção ──────────────────────────
function renderPacientesAtencao() {

  const tbody =
    document.getElementById("tabela-atencao-body");

  const vazio =
    document.getElementById("atencao-vazio");

  const tabela =
    document.getElementById("tabela-atencao");


  if (!tbody || !vazio || !tabela) {
    console.error("Elementos da tabela de atenção não encontrados.");
    return;
  }


  const ultimaPratica = new Map();

  const estatisticas = new Map();


  todosProgressos.forEach(p => {

    if (!p.paciente_id) return;


    if (p.concluido_em?.toDate) {

      const data = p.concluido_em.toDate();

      const atual = ultimaPratica.get(p.paciente_id);

      if (!atual || data > atual) {
        ultimaPratica.set(p.paciente_id, data);
      }

    }


    if (typeof p.acertou === "boolean") {

      const stat = estatisticas.get(p.paciente_id) || {
        total: 0,
        acertos: 0
      };

      stat.total++;

      if (p.acertou) {
        stat.acertos++;
      }

      estatisticas.set(p.paciente_id, stat);

    }

  });


  const agora = new Date();

  const MIN_REGISTROS_PARA_TAXA = 3;

  const listaAtencao = [];


  todosPacientes.forEach(pac => {

    const ultima = ultimaPratica.get(pac.id);

    const stat = estatisticas.get(pac.id);


    const taxaAcerto =

      stat && stat.total >= MIN_REGISTROS_PARA_TAXA

        ? Math.round(
            (stat.acertos / stat.total) * 100
          )

        : null;


    let diasSemAtividade = null;

    const motivos = [];

    let severidade = 0;


    if (!ultima) {

      motivos.push("Nunca praticou");

      severidade = 3;

    } else {

      diasSemAtividade = Math.floor(
        (agora - ultima) / (24 * 60 * 60 * 1000)
      );


      if (diasSemAtividade >= 14) {

        motivos.push(
          `${formatarTempoInatividade(diasSemAtividade)} sem praticar`
        );

        severidade = Math.max(severidade, 2);

      } else if (diasSemAtividade >= 7) {

        motivos.push(
          `${formatarTempoInatividade(diasSemAtividade)} sem praticar`
        );

        severidade = Math.max(severidade, 1);

      }

    }


    if (taxaAcerto !== null && taxaAcerto < 60) {

      motivos.push(
        `Taxa de acerto baixa (${taxaAcerto}%)`
      );

      severidade = Math.max(severidade, 2);

    }


    if (motivos.length > 0) {

      listaAtencao.push({

        paciente: pac,

        ultima,

        diasSemAtividade,

        taxaAcerto,

        motivos,

        severidade

      });

    }

  });


  listaAtencao.sort((a, b) =>
    b.severidade - a.severidade
  );


  if (listaAtencao.length === 0) {

    tabela.style.display = "none";

    vazio.style.display = "flex";

    return;

  }


  tabela.style.display = "table";

  vazio.style.display = "none";


  tbody.innerHTML = listaAtencao.map(item => {

    const nome = item.paciente.nome || "Paciente";


    let badgeDias;


    if (!item.ultima) {

      badgeDias =
        `<span class="badge-dias nunca">Nunca praticou</span>`;

    } else {

      const cls =
        item.diasSemAtividade >= 14
          ? "critico"
          : "";

      badgeDias =
        `<span class="badge-dias ${cls}">
          ${formatarTempoInatividade(item.diasSemAtividade)}
        </span>`;

    }


    let badgeAcerto = "—";


    if (item.taxaAcerto !== null) {

      const cls =

        item.taxaAcerto >= 80

          ? "alta"

          : item.taxaAcerto >= 60

            ? "media"

            : "baixa";


      badgeAcerto =
        `<span class="taxa-acerto ${cls}">
          ${item.taxaAcerto}%
        </span>`;

    }


    return `

      <tr>

        <td>${nome}</td>

        <td>${badgeDias}</td>

        <td>${badgeAcerto}</td>

        <td>${item.motivos.join(" · ")}</td>

        <td>

          <button
            class="btn-ver-paciente"
            onclick="window.location.href='ficha-paciente.html?id=${item.paciente.id}'">

            Ver ficha

          </button>

        </td>

      </tr>

    `;

  }).join("");

}

// ── Eventos ────────────────────────────────────────────────────
document.getElementById("btn-aplicar")
  .addEventListener("click", aplicarFiltros);


document.getElementById("btn-sair")
  .addEventListener("click", async () => {

    await signOut(auth);

    window.location.href = "login.html";

  });