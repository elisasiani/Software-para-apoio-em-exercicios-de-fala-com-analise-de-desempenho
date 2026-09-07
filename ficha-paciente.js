// =============================================================
// ficha-paciente.js
// Tela de detalhes do paciente com gestão de exercícios:
//  - Lista dados pessoais e credenciais de acesso ao app
//  - Mostra exercícios prescritos com status de conclusão
//  - Permite adicionar/remover exercícios (refletindo no mobile)
// =============================================================

import { auth, db } from "./firebase.js";
import { onAuthStateChanged } from "https://www.gstatic.com/firebasejs/12.12.1/firebase-auth.js";
import {
  doc, getDoc, addDoc, updateDoc, collection,
  getDocs, query, where, Timestamp
} from "https://www.gstatic.com/firebasejs/12.12.1/firebase-firestore.js";

// ── CATÁLOGO (idêntico ao de novopaciente.js para consistência) ──────────────
const catalogoTrilhas = [
  {
    id: 'fonemas',
    titulo: 'Trilha dos Fonemas',
    subtitulo: 'Treino do som do /R/',
    emoji: '🗣️',
    tipo: 'fonema',
    fonema: '/r/',
    exercicios: [
      { id: 'f1', palavraAlvo: 'rato', instrucao: 'Diga bem devagar:', dificuldade: 'fácil', dicaAnimacao: 'Girafa abre a boca e mostra a língua tremendo' },
      { id: 'f2', palavraAlvo: 'rua', instrucao: 'Agora tente dizer:', dificuldade: 'fácil', dicaAnimacao: 'Girafa aponta para a boca e sorri' },
      { id: 'f3', palavraAlvo: 'carro', instrucao: 'Um pouco mais difícil:', dificuldade: 'médio', dicaAnimacao: 'Girafa faz gesto de atenção com a pata' },
      { id: 'f4', palavraAlvo: 'terra', instrucao: 'Você consegue?', dificuldade: 'médio', dicaAnimacao: 'Girafa vibra de animação' },
      { id: 'f5', palavraAlvo: 'recreio', instrucao: 'Último desafio! Diga:', dificuldade: 'difícil', dicaAnimacao: 'Girafa levanta os braços de comemoração' },
    ]
  },
  {
    id: 'trava_linguas',
    titulo: 'Trava-Línguas',
    subtitulo: 'Desafie sua língua!',
    emoji: '🌀',
    tipo: 'frase',
    fonema: '/r/',
    exercicios: [
      { id: 't1', palavraAlvo: 'O rato roeu', instrucao: 'Devagar primeiro:', dificuldade: 'fácil', dicaAnimacao: 'Girafa faz sinal de calma com a pata' },
      { id: 't2', palavraAlvo: 'O rato roeu a roupa', instrucao: 'Agora um pouco mais:', dificuldade: 'fácil', dicaAnimacao: 'Girafa aponta para a boca sorrindo' },
      { id: 't3', palavraAlvo: 'O rato roeu a roupa do rei', instrucao: 'Quase lá!', dificuldade: 'médio', dicaAnimacao: 'Girafa faz joinha com a pata' },
      { id: 't4', palavraAlvo: 'O rato roeu a roupa do rei de Roma', instrucao: 'Respira e tenta:', dificuldade: 'médio', dicaAnimacao: 'Girafa torce com pompons' },
      { id: 't5', palavraAlvo: 'O rato roeu a roupa do rei de Roma e a rainha com raiva', instrucao: 'Desafio final!', dificuldade: 'difícil', dicaAnimacao: 'Girafa pula de alegria' },
    ]
  }
];

// ── Estado da página ─────────────────────────────────────────────────────────
let pacienteId = null;
let pacienteData = null;
let profissionalUid = null;
let prescricoesAtuais = [];     // [{ id, ...dados }]
let exerciciosConcluidos = new Set();
let novosSelecionados = [];     // exercícios marcados para adicionar
let trilhaExpandida = null;
let progressosPaciente = [];    // cache de progresso_exercicios deste paciente (heatmap + PDF)
let mapaDificuldadePorPrescricao = new Map(); // prescricao_id -> dificuldade (join manual)
let chartEvolucaoPaciente = null;
let chartDificuldadePaciente = null;

// ── Inicialização ────────────────────────────────────────────────────────────
const params = new URLSearchParams(window.location.search);
pacienteId = params.get('id');

if (!pacienteId) {
  alert('Paciente não informado.');
  window.location.href = 'dashboard.html';
}

onAuthStateChanged(auth, async (usuario) => {
  if (!usuario) {
    window.location.href = 'login.html';
    return;
  }
  profissionalUid = usuario.uid;
  await carregarPaciente();
  await carregarPrescricoes();
  await carregarAudios();
  await carregarHeatmapFrequencia();
  renderRelatorioDesempenho();
});

// ── Carregar dados do paciente ───────────────────────────────────────────────
async function carregarPaciente() {
  try {
    const ref = doc(db, 'pacientes', pacienteId);
    const snap = await getDoc(ref);
    if (!snap.exists()) {
      alert('Paciente não encontrado.');
      window.location.href = 'dashboard.html';
      return;
    }
    pacienteData = snap.data();

    // Segurança extra: paciente precisa ser do profissional logado
    if (pacienteData.profissional_id !== profissionalUid) {
      alert('Você não tem permissão para ver este paciente.');
      window.location.href = 'dashboard.html';
      return;
    }

    document.getElementById('nome-paciente').textContent = pacienteData.nome || 'Paciente';

    // Dados pessoais
    const nascimento = pacienteData.data_nascimento?.toDate?.();
    const idade = nascimento ? calcularIdade(nascimento) : null;
    document.getElementById('dados-pessoais').innerHTML = `
      <div class="ficha-linha"><strong>Nome:</strong> <span>${pacienteData.nome || '—'}</span></div>
      <div class="ficha-linha"><strong>Sexo:</strong> <span>${pacienteData.sexo || '—'}</span></div>
      <div class="ficha-linha"><strong>Nascimento:</strong> <span>${nascimento ? nascimento.toLocaleDateString('pt-BR') : '—'}</span></div>
      <div class="ficha-linha"><strong>Idade:</strong> <span>${idade !== null ? idade + ' anos' : '—'}</span></div>
      <div class="ficha-linha"><strong>Responsável:</strong> <span>${pacienteData.responsavel || '—'}</span></div>
      <div class="ficha-linha"><strong>Telefone:</strong> <span>${pacienteData.telefone_responsavel || '—'}</span></div>
    `;

    // Acesso ao app
    document.getElementById('dados-acesso').innerHTML = `
      <div class="credenciais-box">
        <div><strong>Login:</strong> ${pacienteData.login_app || '—'}</div>
        <div><strong>Senha:</strong> ${pacienteData.senha_temporaria || '—'}</div>
      </div>
      <p style="font-size:0.85rem;color:#6b7280;margin:0;">
        Compartilhe estas credenciais com o paciente ou responsável.
        O paciente entra no app mobile com este login.
      </p>
    `;
  } catch (e) {
    console.error(e);
    mostrarToast('Erro ao carregar paciente.', '#dc2626');
  }
}

// ── Carregar prescrições e progresso ─────────────────────────────────────────
async function carregarPrescricoes() {
  const lista = document.getElementById('lista-prescritos');
  lista.innerHTML = '<div class="loading-msg">Carregando exercícios…</div>';

  try {
    // 1. Prescrições ativas do paciente
    const qPresc = query(
      collection(db, 'prescricoes'),
      where('paciente_id', '==', pacienteId),
      where('ativo', '==', true)
    );
    const snapPresc = await getDocs(qPresc);
    prescricoesAtuais = [];
    snapPresc.forEach(d => prescricoesAtuais.push({ id: d.id, ...d.data() }));

    // 2. Exercícios já concluídos (acerto)
    const qProgr = query(
      collection(db, 'progresso_exercicios'),
      where('paciente_id', '==', pacienteId),
      where('acertou', '==', true)
    );
    const snapProgr = await getDocs(qProgr);
    exerciciosConcluidos.clear();
    snapProgr.forEach(d => {
      const pid = d.data().prescricao_id;
      if (pid) exerciciosConcluidos.add(pid);
    });

    renderListaPrescritos();
  } catch (e) {
    console.error(e);
    lista.innerHTML = '<div class="empty-msg">Erro ao carregar exercícios.</div>';
  }
}

function renderListaPrescritos() {
  const lista = document.getElementById('lista-prescritos');
  document.getElementById('contador-prescritos').textContent = prescricoesAtuais.length;

  if (prescricoesAtuais.length === 0) {
    lista.innerHTML = `<div class="empty-msg">
      Nenhum exercício prescrito ainda. Clique em <strong>Adicionar exercícios</strong>.
    </div>`;
    return;
  }

  // Agrupa por trilha_titulo
  const grupos = {};
  prescricoesAtuais.forEach(p => {
    const grupo = p.trilha_titulo || 'Outros';
    if (!grupos[grupo]) grupos[grupo] = [];
    grupos[grupo].push(p);
  });

  lista.innerHTML = Object.entries(grupos).map(([titulo, items]) => `
    <div style="margin-bottom:20px;">
      <h4 style="color:var(--roxo-principal,#7B2FBE);margin:0 0 8px 0;font-size:0.92rem;">
        ${titulo} <span style="color:#9ca3af;font-weight:400;">(${items.length})</span>
      </h4>
      ${items.map(p => `
        <div class="exerc-prescrito">
          <div class="exerc-info">
            <div class="exerc-titulo">${p.palavraAlvo || '—'}</div>
            <div class="exerc-meta">
              ${p.instrucao || ''} ·
              ${p.dificuldade || ''} ${p.trilha_fonema ? '· ' + p.trilha_fonema : ''}
            </div>
          </div>
          ${exerciciosConcluidos.has(p.id)
      ? '<span class="btn-concluido">✓ Concluído</span>'
      : ''}
          <button class="btn-remover" onclick="removerPrescricao('${p.id}')">Remover</button>
        </div>
      `).join('')}
    </div>
  `).join('');
}

// ── REMOVER PRESCRIÇÃO (soft delete) ─────────────────────────────────────────
window.removerPrescricao = async function (prescricaoId) {
  const presc = prescricoesAtuais.find(p => p.id === prescricaoId);
  if (!presc) return;
  if (!confirm(`Remover o exercício "${presc.palavraAlvo}" da prescrição?`)) return;

  try {
    await updateDoc(doc(db, 'prescricoes', prescricaoId), {
      ativo: false,
      removido_em: Timestamp.now()
    });
    prescricoesAtuais = prescricoesAtuais.filter(p => p.id !== prescricaoId);
    renderListaPrescritos();
    mostrarToast('Exercício removido!');
  } catch (e) {
    console.error(e);
    mostrarToast('Erro ao remover.', '#dc2626');
  }
};

// ── ÁREA DE ADIÇÃO ───────────────────────────────────────────────────────────
window.abrirSelecaoExercicios = function () {
  novosSelecionados = [];
  document.getElementById('area-adicionar').style.display = 'block';
  renderExercicios();
  document.getElementById('area-adicionar').scrollIntoView({ behavior: 'smooth' });
};

window.cancelarAdicao = function () {
  novosSelecionados = [];
  document.getElementById('area-adicionar').style.display = 'none';
};

window.toggleTrilha = function (trilhaId) {
  trilhaExpandida = trilhaExpandida === trilhaId ? null : trilhaId;
  renderExercicios();
};

window.togglePalavra = function (trilhaId, exId) {
  const trilha = catalogoTrilhas.find(t => t.id === trilhaId);
  const ex = trilha?.exercicios.find(e => e.id === exId);
  if (!ex) return;

  // Não permite duplicar: se já está prescrito (e ativo), avisa
  const jaPrescrito = prescricoesAtuais.some(p =>
    p.trilha_id === trilhaId && p.exercicio_id === exId);
  if (jaPrescrito) {
    mostrarToast('Este exercício já está prescrito.', '#f59e0b');
    return;
  }

  const idx = novosSelecionados.findIndex(s =>
    s.trilhaId === trilhaId && s.exercicio.id === exId);
  if (idx === -1) {
    novosSelecionados.push({
      trilhaId, trilhaTitulo: trilha.titulo, trilhaTipo: trilha.tipo,
      trilhaFonema: trilha.fonema, exercicio: ex
    });
  } else {
    novosSelecionados.splice(idx, 1);
  }
  renderExercicios();
  document.getElementById('qtd-adicionando').textContent = novosSelecionados.length;
};

window.renderExercicios = function () {
  const grade = document.getElementById('exercises-grid');
  const busca = (document.getElementById('search-ex')?.value || '').toLowerCase();
  const trilhasFiltradas = catalogoTrilhas.filter(t =>
    !busca || t.titulo.toLowerCase().includes(busca) || t.fonema.toLowerCase().includes(busca)
  );

  const difLabels = { 'fácil': '🟢', 'médio': '🟡', 'difícil': '🔴' };
  let html = '';

  // ── Bloco dos exercícios personalizados criados nesta sessão ──
  const personalizadosPendentes = novosSelecionados.filter(s => s.trilhaId === 'custom');
  if (personalizadosPendentes.length > 0) {
    html += `
      <div style="grid-column:1/-1;background:#fff8f0;border:1px solid #ffb74d;border-radius:8px;margin-bottom:8px;padding:16px 20px;">
        <div style="display:flex; align-items:center; justify-content:space-between; gap:12px; margin-bottom:12px;">
          <div style="display:flex; align-items:center; gap:14px;">
            <span style="font-size:1.6rem;">✏️</span>
            <div>
              <div style="font-weight:800; color:#4a148c;">Personalizados (criados agora)</div>
              <div style="font-size:.78rem; color:#9ca3af;">Serão salvos quando você clicar em "Salvar adições"</div>
            </div>
          </div>
          <span style="background:#7B2FBE;color:#fff;border-radius:99px;padding:3px 10px;font-size:.75rem;font-weight:700;">
            ${personalizadosPendentes.length}
          </span>
        </div>
        <div style="display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); gap:12px;">
          ${personalizadosPendentes.map(s => `
            <div class="cartao-exercicio selecionado" style="position:relative;">
              <span class="selo-exercicio personalizado" style="background:#7B2FBE;color:#fff;border-radius:6px;padding:2px 8px;font-size:.7rem;font-weight:700;">Personalizado</span>
              <div class="exercicio-titulo">${s.exercicio.palavraAlvo}</div>
              <div class="exercicio-descricao">${s.exercicio.instrucao}</div>
              <div class="exercicio-meta">
                <span class="exercicio-fonema">${difLabels[s.exercicio.dificuldade] || ''} ${s.exercicio.dificuldade}</span>
              </div>
              <button type="button" onclick="removerCustomPendente('${s.exercicio.id}')"
                style="position:absolute;top:6px;right:6px;background:#fee2e2;color:#dc2626;border:none;border-radius:6px;padding:4px 8px;font-size:.7rem;font-weight:700;cursor:pointer;">
                Remover
              </button>
            </div>
          `).join('')}
        </div>
      </div>`;
  }

  trilhasFiltradas.forEach(trilha => {
    const totalSel = novosSelecionados.filter(s => s.trilhaId === trilha.id).length;
    const expanded = trilhaExpandida === trilha.id;

    const palavrasHTML = expanded ? trilha.exercicios.map(ex => {
      const jaPrescrito = prescricoesAtuais.some(p =>
        p.trilha_id === trilha.id && p.exercicio_id === ex.id);
      const sel = novosSelecionados.find(s =>
        s.trilhaId === trilha.id && s.exercicio.id === ex.id);
      const classes = jaPrescrito ? 'cartao-exercicio' : (sel ? 'cartao-exercicio selecionado' : 'cartao-exercicio');
      const disabled = jaPrescrito ? 'opacity:0.5;cursor:not-allowed;' : '';
      return `
        <button class="${classes}" type="button" style="${disabled}"
          onclick="togglePalavra('${trilha.id}', '${ex.id}')">
          <div class="exercicio-titulo">${ex.palavraAlvo}</div>
          <div class="exercicio-descricao">${ex.instrucao}</div>
          <div class="exercicio-meta">
            <span class="exercicio-fonema">${difLabels[ex.dificuldade] || ''} ${ex.dificuldade}</span>
            ${jaPrescrito ? '<span style="color:#16a34a;font-size:0.7rem;">✓ Já prescrito</span>' : ''}
          </div>
        </button>`;
    }).join('') : '';

    html += `
      <div style="grid-column:1/-1;background:var(--branco,#fff);border:1px solid var(--cinza-200,#e5e7eb);border-radius:8px;margin-bottom:8px;overflow:hidden;${totalSel > 0 ? 'border-color:var(--roxo-principal,#7B2FBE);' : ''}">
        <div onclick="toggleTrilha('${trilha.id}')" style="display:flex;align-items:center;justify-content:space-between;padding:16px 20px;cursor:pointer;gap:12px;">
          <div style="display:flex;align-items:center;gap:14px;">
            <span style="font-size:1.8rem;">${trilha.emoji}</span>
            <div>
              <div style="font-weight:800;color:var(--cinza-900,#111827);">${trilha.titulo}</div>
              <div style="font-size:.78rem;color:var(--cinza-400,#9ca3af);">${trilha.subtitulo} — Fonema ${trilha.fonema}</div>
            </div>
          </div>
          <div style="display:flex;align-items:center;gap:10px;">
            ${totalSel > 0 ? `<span style="background:var(--roxo-principal,#7B2FBE);color:#fff;border-radius:99px;padding:3px 10px;font-size:.75rem;font-weight:700;">${totalSel} para adicionar</span>` : ''}
            <span style="color:var(--cinza-400,#9ca3af);font-size:1.1rem;">${expanded ? '▲' : '▼'}</span>
          </div>
        </div>
        ${expanded ? `<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;padding:16px 20px;border-top:1px solid var(--cinza-100,#f3f4f6);background:var(--cinza-50,#f9fafb);">${palavrasHTML}</div>` : ''}
      </div>`;
  });

  if (!html) html = '<p class="msg-vazia">Nenhuma trilha encontrada.</p>';
  grade.innerHTML = html;
  document.getElementById('qtd-adicionando').textContent = novosSelecionados.length;
};

// ── SALVAR NOVAS PRESCRIÇÕES ─────────────────────────────────────────────────
window.salvarNovosExercicios = async function () {
  if (novosSelecionados.length === 0) {
    mostrarToast('Selecione ao menos 1 exercício.', '#f59e0b');
    return;
  }
  const btn = event.target;
  btn.disabled = true;
  btn.textContent = 'Salvando…';

  try {
    for (const s of novosSelecionados) {
      await addDoc(collection(db, 'prescricoes'), {
        paciente_id: pacienteId,
        profissional_id: profissionalUid,
        trilha_id: s.trilhaId,
        trilha_titulo: s.trilhaTitulo,
        trilha_tipo: s.trilhaTipo,
        trilha_fonema: s.trilhaFonema,
        exercicio_id: s.exercicio.id,
        palavraAlvo: s.exercicio.palavraAlvo,
        instrucao: s.exercicio.instrucao,
        dicaAnimacao: s.exercicio.dicaAnimacao || '',
        dificuldade: s.exercicio.dificuldade,
        data_prescricao: Timestamp.now(),
        ativo: true
      });
    }
    mostrarToast(`${novosSelecionados.length} exercício(s) adicionado(s)!`);
    novosSelecionados = [];
    document.getElementById('area-adicionar').style.display = 'none';
    await carregarPrescricoes(); // recarrega
  } catch (e) {
    console.error(e);
    mostrarToast('Erro ao salvar.', '#dc2626');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Salvar adições';
  }
};

// ── Helpers ──────────────────────────────────────────────────────────────────
function calcularIdade(nasc) {
  const hoje = new Date();
  let idade = hoje.getFullYear() - nasc.getFullYear();
  const m = hoje.getMonth() - nasc.getMonth();
  if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) idade--;
  return idade;
}

function mostrarToast(msg, cor = '#059669') {
  const toast = document.getElementById('toast');
  const label = document.getElementById('toast-msg');
  if (!toast || !label) return;
  label.textContent = msg;
  toast.style.background = cor;
  toast.classList.add('mostrar');
  setTimeout(() => toast.classList.remove('mostrar'), 3000);
}

// =============================================================
// CARREGAR ÁUDIOS GRAVADOS PELO PACIENTE
// Busca os progresso_exercicios que têm áudio anexado e
// renderiza um player <audio> para cada um.
// =============================================================
let audiosPacienteCache = []; // cache dos áudios buscados (filtro de data aplica em cima disso)

async function carregarAudios() {
  const lista = document.getElementById('lista-audios');
  if (!lista) return;
  lista.innerHTML = '<div class="loading-msg">Carregando áudios…</div>';

  try {
    const q = query(
      collection(db, 'progresso_exercicios'),
      where('paciente_id', '==', pacienteId),
      where('tem_audio', '==', true)
    );
    const snap = await getDocs(q);
    audiosPacienteCache = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    renderizarListaAudios();
  } catch (e) {
    console.error('Erro ao carregar áudios:', e);
    lista.innerHTML = `<div class="empty-msg" style="color:#dc2626">
      Erro ao carregar áudios. Veja o console (F12).
    </div>`;
  }
}

// Aplica o filtro de data (De/Até) sobre o cache e desenha a lista
function renderizarListaAudios() {
  const lista = document.getElementById('lista-audios');
  const contador = document.getElementById('contador-audios');
  if (!lista || !contador) return;

  const valorDe = document.getElementById('audios-filtro-de')?.value;
  const valorAte = document.getElementById('audios-filtro-ate')?.value;

  const dataDe = valorDe ? new Date(`${valorDe}T00:00:00`) : null;
  const dataAte = valorAte ? new Date(`${valorAte}T23:59:59`) : null;

  const filtrando = Boolean(valorDe || valorAte);

  let docs = audiosPacienteCache.filter(d => {
    const data = d.concluido_em?.toDate?.();
    if (!data) return false;
    if (dataDe && data < dataDe) return false;
    if (dataAte && data > dataAte) return false;
    return true;
  });

  // Ordena por data (mais recente primeiro)
  docs.sort((a, b) => {
    const ta = a.concluido_em?.toDate?.()?.getTime() || 0;
    const tb = b.concluido_em?.toDate?.()?.getTime() || 0;
    return tb - ta;
  });

  contador.textContent = docs.length;

  if (docs.length === 0) {
    lista.innerHTML = `<div class="empty-msg">
      ${filtrando
        ? 'Nenhum áudio encontrado nesse período. 📅'
        : 'Este paciente ainda não enviou nenhum áudio. 🎙️'}
    </div>`;
    return;
  }

  lista.innerHTML = docs.map(d => {
    const data    = d.concluido_em?.toDate?.();
    const dataStr = data
      ? data.toLocaleString('pt-BR', {
          day: '2-digit', month: '2-digit', year: 'numeric',
          hour: '2-digit', minute: '2-digit'
        })
      : '—';
    const palavra    = d.palavraAlvo || 'exercício';
    const tentativas = d.tentativas  || 1;
    const formato    = d.audio_formato || 'audio/mp4';
    const base64     = d.audio_base64;

    // Monta data URL para o player HTML5 tocar direto
    const audioSrc = `data:${formato};base64,${base64}`;

    return `
      <div class="audio-item">
        <div class="audio-item-cabecalho">
          <div>
            <div class="audio-palavra">"${palavra}"</div>
            <div class="audio-meta">📅 ${dataStr}</div>
          </div>
          <div>
            <span class="audio-tag tentativas">
              ${tentativas} ${tentativas === 1 ? 'tentativa' : 'tentativas'}
            </span>
          </div>
        </div>
        <audio controls preload="none" src="${audioSrc}"></audio>
      </div>
    `;
  }).join('');
}

document.getElementById('audios-filtro-de')?.addEventListener('change', renderizarListaAudios);
document.getElementById('audios-filtro-ate')?.addEventListener('change', renderizarListaAudios);
document.getElementById('audios-limpar-filtro')?.addEventListener('click', () => {
  const de = document.getElementById('audios-filtro-de');
  const ate = document.getElementById('audios-filtro-ate');
  if (de) de.value = '';
  if (ate) ate.value = '';
  renderizarListaAudios();
});

// =============================================================
// EDIÇÃO DE DADOS DO PACIENTE
// =============================================================
const modalEdicao = document.getElementById('modal-editar-paciente');

function abrirModalEdicao() {
  if (!pacienteData) return;

  // Preenche o formulário com os dados atuais
  document.getElementById('edit-nome').value = pacienteData.nome || '';
  document.getElementById('edit-sexo').value = pacienteData.sexo || '';
  document.getElementById('edit-responsavel').value = pacienteData.responsavel || '';
  document.getElementById('edit-telefone').value = pacienteData.telefone || '';
  document.getElementById('edit-observacoes').value = pacienteData.observacoes || '';

  // Converte Timestamp/data para formato YYYY-MM-DD do input[type=date]
  const dataNasc = pacienteData.data_nascimento;
  let dataStr = '';
  if (dataNasc) {
    const d = dataNasc.toDate ? dataNasc.toDate() : new Date(dataNasc);
    if (!isNaN(d.getTime())) {
      dataStr = d.toISOString().split('T')[0];
    }
  }
  document.getElementById('edit-nascimento').value = dataStr;

  // Esconde mensagem antiga
  document.getElementById('msg-edicao').style.display = 'none';

  // Mostra o modal
  modalEdicao.style.display = 'flex';
}

function fecharModalEdicao() {
  modalEdicao.style.display = 'none';
}

// Conecta botões
document.getElementById('btn-editar-paciente')?.addEventListener('click', abrirModalEdicao);
document.getElementById('btn-fechar-edicao')?.addEventListener('click', fecharModalEdicao);
document.getElementById('btn-cancelar-edicao')?.addEventListener('click', fecharModalEdicao);

// Fecha quando clica fora do conteúdo
modalEdicao?.addEventListener('click', (e) => {
  if (e.target === modalEdicao) fecharModalEdicao();
});

// Máscara de telefone no input de edição
const inputTelEdicao = document.getElementById('edit-telefone');
inputTelEdicao?.addEventListener('input', (e) => {
  let v = e.target.value.replace(/\D/g, '').slice(0, 11);
  if (v.length > 0) v = '(' + v;
  if (v.length > 3) v = v.slice(0, 3) + ') ' + v.slice(3);
  if (v.length > 10) v = v.slice(0, 10) + '-' + v.slice(10);
  e.target.value = v;
});

// Submeter formulário
document.getElementById('form-editar-paciente')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = document.getElementById('msg-edicao');
  const btnSalvar = document.getElementById('btn-salvar-edicao');

  const nome        = document.getElementById('edit-nome').value.trim();
  const sexo        = document.getElementById('edit-sexo').value;
  const nascStr     = document.getElementById('edit-nascimento').value;
  const responsavel = document.getElementById('edit-responsavel').value.trim();
  const telefone    = document.getElementById('edit-telefone').value.trim();
  const observacoes = document.getElementById('edit-observacoes').value.trim();

  if (!nome) {
    msg.style.display = 'block';
    msg.style.background = '#fee2e2';
    msg.style.color = '#dc2626';
    msg.textContent = 'O nome é obrigatório.';
    return;
  }

  btnSalvar.disabled = true;
  btnSalvar.textContent = 'Salvando…';

  try {
    // Monta o objeto de atualização
    const atualizacao = {
      nome,
      sexo:        sexo || null,
      responsavel: responsavel || null,
      telefone:    telefone || null,
      observacoes: observacoes || null,
    };

    // Converte a data pra Timestamp (ou null)
    if (nascStr) {
      atualizacao.data_nascimento = Timestamp.fromDate(new Date(nascStr + 'T00:00:00'));
    } else {
      atualizacao.data_nascimento = null;
    }

    await updateDoc(doc(db, 'pacientes', pacienteId), atualizacao);

    // Atualiza estado local e recarrega visualmente
    Object.assign(pacienteData, atualizacao);

    msg.style.display = 'block';
    msg.style.background = '#dcfce7';
    msg.style.color = '#16a34a';
    msg.textContent = 'Dados atualizados com sucesso!';

    // Fecha o modal e recarrega a ficha
    setTimeout(async () => {
      fecharModalEdicao();
      await carregarPaciente();
    }, 800);

  } catch (e) {
    console.error('Erro ao salvar edição:', e);
    msg.style.display = 'block';
    msg.style.background = '#fee2e2';
    msg.style.color = '#dc2626';
    msg.textContent = 'Erro ao salvar. Tente novamente.';
  } finally {
    btnSalvar.disabled = false;
    btnSalvar.textContent = 'Salvar alterações';
  }
});

// =============================================================
// EXERCÍCIO PERSONALIZADO — modal de criação rápida na ficha
// O exercício é adicionado direto a `novosSelecionados`, então
// já fica "pré-selecionado" e basta clicar em "Salvar adições".
// =============================================================
const modalCustom = document.getElementById('modal-custom-ficha');

window.abrirModalCustom = function () {
  // Limpa campos
  document.getElementById('custom-titulo-ficha').value = '';
  document.getElementById('custom-tipo-ficha').value = 'fonema';
  document.getElementById('custom-nivel-ficha').value = '1';
  document.getElementById('custom-fonema-ficha').value = '';
  document.getElementById('custom-desc-ficha').value = '';
  modalCustom.style.display = 'flex';
};

window.fecharModalCustom = function () {
  modalCustom.style.display = 'none';
};

// Fecha clicando no fundo
modalCustom?.addEventListener('click', (e) => {
  if (e.target === modalCustom) window.fecharModalCustom();
});

window.salvarCustom = function () {
  const titulo = document.getElementById('custom-titulo-ficha').value.trim();
  if (!titulo) {
    mostrarToast('Informe a palavra ou frase do exercício.', '#dc2626');
    return;
  }

  const nivelNum = parseInt(document.getElementById('custom-nivel-ficha').value, 10);
  const mapaDif = { 1: 'fácil', 2: 'médio', 3: 'difícil' };
  const dificuldade = mapaDif[nivelNum] || 'fácil';

  const tipo   = document.getElementById('custom-tipo-ficha').value;
  const fonema = document.getElementById('custom-fonema-ficha').value.trim() || '—';
  const desc   = document.getElementById('custom-desc-ficha').value.trim()
                  || `Pratique: ${titulo}`;

  // ID único pra esse exercício custom
  const exId = 'custom_' + Date.now();

  // Adiciona direto na lista de selecionados — vai ser salvo junto
  // quando a fono clicar em "Salvar adições"
  novosSelecionados.push({
    trilhaId:    'custom',
    trilhaTitulo:'Personalizado',
    trilhaTipo:  tipo,
    trilhaFonema: fonema,
    exercicio: {
      id:           exId,
      palavraAlvo:  titulo,
      instrucao:    desc,
      dicaAnimacao: '',
      dificuldade
    }
  });

  // Atualiza visualmente o contador e mensagem
  document.getElementById('qtd-adicionando').textContent = novosSelecionados.length;
  window.renderExercicios();
  mostrarToast(`"${titulo}" adicionado. Clique em "Salvar adições" para confirmar.`);

  window.fecharModalCustom();
};

window.removerCustomPendente = function (exId) {
  const idx = novosSelecionados.findIndex(s =>
    s.trilhaId === 'custom' && s.exercicio.id === exId);
  if (idx !== -1) {
    novosSelecionados.splice(idx, 1);
    window.renderExercicios();
  }
};

// =============================================================
// FREQUÊNCIA DE PRÁTICA — Heatmap estilo GitHub
// Busca todos os progresso_exercicios do paciente (não só os com
// áudio) e monta um heatmap de atividade dos últimos 6 meses.
// O resultado (progressosPaciente) também alimenta a exportação em PDF.
// =============================================================
async function carregarHeatmapFrequencia() {
  const container = document.getElementById('heatmap-frequencia');
  if (!container) return;

  try {
    const q = query(
      collection(db, 'progresso_exercicios'),
      where('paciente_id', '==', pacienteId)
    );
    const snap = await getDocs(q);
    progressosPaciente = snap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Os documentos de progresso não trazem a dificuldade direto —
    // ela mora na prescrição. Busca TODAS as prescrições do paciente
    // (não só as ativas, pra cobrir progresso de prescrições antigas)
    // e monta um mapa prescricao_id -> dificuldade.
    const qPrescTodas = query(
      collection(db, 'prescricoes'),
      where('paciente_id', '==', pacienteId)
    );
    const snapPrescTodas = await getDocs(qPrescTodas);
    mapaDificuldadePorPrescricao = new Map();
    snapPrescTodas.forEach(d => {
      const dados = d.data();
      if (dados.dificuldade) {
        mapaDificuldadePorPrescricao.set(d.id, dados.dificuldade);
      }
    });

    // Preenche a dificuldade de cada progresso via join manual
    // (mantém o valor original se por acaso já vier no próprio documento)
    progressosPaciente.forEach(p => {
      if (!p.dificuldade && p.prescricao_id) {
        p.dificuldade = mapaDificuldadePorPrescricao.get(p.prescricao_id) || '';
      }
    });

    renderHeatmapFrequencia();
  } catch (e) {
    console.error('Erro ao carregar frequência de prática:', e);
    container.innerHTML = '<div class="empty-msg">Não foi possível carregar a frequência de prática.</div>';
  }
}

function renderHeatmapFrequencia() {
  const container = document.getElementById('heatmap-frequencia');
  if (!container) return;

  // Conta exercícios por dia
  const contagemPorDia = new Map(); // "YYYY-MM-DD" -> total
  progressosPaciente.forEach(p => {
    if (!p.concluido_em?.toDate) return;
    const data = p.concluido_em.toDate();
    data.setHours(0, 0, 0, 0);
    const chave = data.toISOString().split('T')[0];
    contagemPorDia.set(chave, (contagemPorDia.get(chave) || 0) + 1);
  });

  const SEMANAS = 26; // ~6 meses
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  // Domingo da semana atual
  const domingoAtual = new Date(hoje);
  domingoAtual.setDate(domingoAtual.getDate() - domingoAtual.getDay());

  // Domingo de início (SEMANAS semanas atrás)
  const domingoInicio = new Date(domingoAtual);
  domingoInicio.setDate(domingoInicio.getDate() - (SEMANAS - 1) * 7);

  // Monta a matriz [semana][dia da semana]
  const colunas = [];
  for (let w = 0; w < SEMANAS; w++) {
    const coluna = [];
    for (let d = 0; d < 7; d++) {
      const dia = new Date(domingoInicio);
      dia.setDate(dia.getDate() + w * 7 + d);
      const chave = dia.toISOString().split('T')[0];
      const futuro = dia > hoje;
      coluna.push({
        data: dia,
        contagem: futuro ? null : (contagemPorDia.get(chave) || 0)
      });
    }
    colunas.push(coluna);
  }

  function nivel(contagem) {
    if (contagem === null) return 'futuro';
    if (contagem === 0) return 0;
    if (contagem <= 2) return 1;
    if (contagem <= 4) return 2;
    if (contagem <= 7) return 3;
    return 4;
  }

  // Labels de mês: mostra o nome na coluna em que o mês começa
  const mesesLabels = [];
  let mesAnterior = null;
  colunas.forEach((coluna, i) => {
    const mes = coluna[0].data.getMonth();
    if (mes !== mesAnterior) {
      mesesLabels.push({ index: i, label: coluna[0].data.toLocaleDateString('pt-BR', { month: 'short' }) });
      mesAnterior = mes;
    }
  });

  const diasSemanaLabels = ['', 'Seg', '', 'Qua', '', 'Sex', ''];

  const registrosNoPeriodo = Array.from(contagemPorDia.entries())
    .filter(([chave]) => new Date(chave + 'T00:00:00') >= domingoInicio);
  const totalPeriodo = registrosNoPeriodo.reduce((acc, [, v]) => acc + v, 0);
  const diasAtivos = registrosNoPeriodo.filter(([, v]) => v > 0).length;

  container.innerHTML = `
    <div class="heatmap-scroll">
      <div class="heatmap-meses">
        ${colunas.map((_, i) => {
          const label = mesesLabels.find(m => m.index === i);
          return `<div class="heatmap-mes-label">${label ? label.label : ''}</div>`;
        }).join('')}
      </div>
      <div class="heatmap-corpo">
        <div class="heatmap-dias-labels">
          ${diasSemanaLabels.map(l => `<div class="heatmap-dia-label">${l}</div>`).join('')}
        </div>
        <div class="heatmap-grade">
          ${colunas.map(coluna => `
            <div class="heatmap-coluna">
              ${coluna.map(cel => {
                const niv = nivel(cel.contagem);
                const titulo = niv === 'futuro'
                  ? ''
                  : `${cel.contagem} ${cel.contagem === 1 ? 'exercício' : 'exercícios'} em ${cel.data.toLocaleDateString('pt-BR')}`;
                return `<div class="heatmap-dia nivel-${niv}" title="${titulo}"></div>`;
              }).join('')}
            </div>
          `).join('')}
        </div>
      </div>
      <div class="heatmap-legenda">
        <span>Menos</span>
        <div class="heatmap-dia nivel-0"></div>
        <div class="heatmap-dia nivel-1"></div>
        <div class="heatmap-dia nivel-2"></div>
        <div class="heatmap-dia nivel-3"></div>
        <div class="heatmap-dia nivel-4"></div>
        <span>Mais</span>
      </div>
    </div>
  `;

  const totalEl = document.getElementById('heatmap-total');
  if (totalEl) {
    totalEl.textContent = diasAtivos > 0
      ? `${diasAtivos} ${diasAtivos === 1 ? 'dia ativo' : 'dias ativos'} nos últimos 6 meses (${totalPeriodo} ${totalPeriodo === 1 ? 'exercício' : 'exercícios'})`
      : 'Nenhuma atividade nos últimos 6 meses';
  }
}

// =============================================================
// RELATÓRIO DE DESEMPENHO — gráficos (evolução + dificuldade)
// Reaproveita os dados já buscados em `progressosPaciente`
// (carregados por carregarHeatmapFrequencia), então não faz
// nenhuma consulta nova ao Firestore.
// =============================================================
function obterProgressosFiltradosPeriodo() {
  const periodo = document.getElementById('filtro-periodo-relatorio')?.value || '30';
  if (periodo === 'todos') return [...progressosPaciente];

  const dias = parseInt(periodo);
  const limite = new Date();
  limite.setDate(limite.getDate() - dias);
  limite.setHours(0, 0, 0, 0);

  return progressosPaciente.filter(p => {
    if (!p.concluido_em?.toDate) return false;
    return p.concluido_em.toDate() >= limite;
  });
}

function renderRelatorioDesempenho() {
  const dadosFiltrados = obterProgressosFiltradosPeriodo();
  atualizarStatsRelatorio(dadosFiltrados);
  renderGraficoEvolucaoPaciente(dadosFiltrados);
  renderGraficoDificuldadePaciente(dadosFiltrados);
}

function atualizarStatsRelatorio(dadosFiltrados) {
  const audios = dadosFiltrados.filter(p =>
    p.audio_base64 && p.audio_base64.length > 0
  ).length;

  const tentativas = dadosFiltrados.reduce((acc, p) => {
    const t = p.tentativas ?? p.numero_tentativas ?? 1;
    return acc + (typeof t === 'number' ? t : 1);
  }, 0);

  const elAudios = document.getElementById('rel-stat-audios');
  const elTentativas = document.getElementById('rel-stat-tentativas');
  if (elAudios) elAudios.textContent = audios;
  if (elTentativas) elTentativas.textContent = tentativas;
}

function renderGraficoEvolucaoPaciente(dadosFiltrados) {
  const canvas = document.getElementById('grafico-evolucao-paciente');
  if (!canvas) return;

  const periodo = document.getElementById('filtro-periodo-relatorio')?.value || '30';
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);

  let agrupamento = 'dia';
  let dataInicio;

  if (periodo === '7' || periodo === '30') {
    const dias = parseInt(periodo);
    dataInicio = new Date(hoje);
    dataInicio.setDate(dataInicio.getDate() - (dias - 1));
  } else if (periodo === '90') {
    agrupamento = 'semana';
    dataInicio = new Date(hoje);
    dataInicio.setDate(dataInicio.getDate() - 89);
  } else {
    agrupamento = 'semana';
    const datasValidas = dadosFiltrados
      .filter(p => p.concluido_em?.toDate)
      .map(p => {
        const d = p.concluido_em.toDate();
        d.setHours(0, 0, 0, 0);
        return d;
      });

    if (datasValidas.length > 0) {
      dataInicio = new Date(Math.min(...datasValidas));
    } else {
      agrupamento = 'dia';
      dataInicio = new Date(hoje);
      dataInicio.setDate(dataInicio.getDate() - 29);
    }
  }

  if (agrupamento === 'semana') {
    const diaSemana = dataInicio.getDay();
    const offset = diaSemana === 0 ? 6 : diaSemana - 1;
    dataInicio.setDate(dataInicio.getDate() - offset);
  }

  const tamanhoBucketDias = agrupamento === 'semana' ? 7 : 1;

  const buckets = [];
  const cursor = new Date(dataInicio);
  while (cursor <= hoje && buckets.length < 500) {
    buckets.push({ inicio: new Date(cursor), total: 0 });
    cursor.setDate(cursor.getDate() + tamanhoBucketDias);
  }

  dadosFiltrados.forEach(p => {
    if (!p.concluido_em?.toDate) return;
    const data = p.concluido_em.toDate();
    data.setHours(0, 0, 0, 0);
    if (data < dataInicio) return;

    const diffDias = Math.floor((data - dataInicio) / 86400000);
    const idx = Math.floor(diffDias / tamanhoBucketDias);
    if (buckets[idx]) buckets[idx].total++;
  });

  const labels = buckets.map(b => {
    const inicioStr = b.inicio.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
    if (agrupamento === 'dia') return inicioStr;

    const fim = new Date(b.inicio);
    fim.setDate(fim.getDate() + 6);
    const fimReal = fim > hoje ? hoje : fim;
    const fimStr = fimReal.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
    return `${inicioStr} - ${fimStr}`;
  });

  const dadosTotal = buckets.map(b => b.total);

  if (chartEvolucaoPaciente) chartEvolucaoPaciente.destroy();

  const ctx = canvas.getContext('2d');
  chartEvolucaoPaciente = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Exercícios realizados',
        data: dadosTotal,
        backgroundColor: 'rgba(123, 47, 190, 0.75)',
        borderColor: '#7B2FBE',
        borderWidth: 1,
        borderRadius: 4,
        maxBarThickness: 40
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            title: (items) => agrupamento === 'semana' ? `Semana: ${items[0].label}` : items[0].label
          }
        }
      },
      scales: {
        y: { beginAtZero: true, ticks: { precision: 0 } },
        x: {
          ticks: {
            maxTicksLimit: agrupamento === 'semana' ? 12 : 10,
            font: { family: 'Inter', size: 11 },
            maxRotation: agrupamento === 'semana' ? 45 : 0,
            minRotation: 0
          }
        }
      }
    }
  });
}

function renderGraficoDificuldadePaciente(dadosFiltrados) {
  const canvas = document.getElementById('grafico-dificuldade-paciente');
  const vazio = document.getElementById('dificuldade-paciente-vazio');
  if (!canvas || !vazio) return;

  const contagem = {};
  dadosFiltrados.forEach(p => {
    const dif = (p.dificuldade || '').toLowerCase().trim();
    if (!dif) return;
    contagem[dif] = (contagem[dif] || 0) + 1;
  });

  const ordem = ['fácil', 'médio', 'difícil'];
  const labels = Object.keys(contagem).sort((a, b) => {
    const ia = ordem.indexOf(a);
    const ib = ordem.indexOf(b);
    if (ia === -1 && ib === -1) return a.localeCompare(b);
    if (ia === -1) return 1;
    if (ib === -1) return -1;
    return ia - ib;
  });

  const valores = labels.map(l => contagem[l]);
  const total = valores.reduce((a, b) => a + b, 0);

  const coresPorNivel = {
    'fácil': '#4ade80',
    'médio': '#fbbf24',
    'difícil': '#f87171'
  };
  const cores = labels.map(l => coresPorNivel[l] || '#a78bfa');

  if (chartDificuldadePaciente) {
    chartDificuldadePaciente.destroy();
    chartDificuldadePaciente = null;
  }

  if (total === 0) {
    canvas.style.display = 'none';
    vazio.style.display = 'flex';
    return;
  }

  canvas.style.display = 'block';
  vazio.style.display = 'none';

  const ctx = canvas.getContext('2d');
  chartDificuldadePaciente = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: labels.map(l => l.charAt(0).toUpperCase() + l.slice(1)),
      datasets: [{
        data: valores,
        backgroundColor: cores,
        borderColor: '#fff',
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '65%',
      plugins: {
        legend: {
          position: 'bottom',
          labels: { font: { family: 'Inter', size: 12 }, padding: 16 }
        },
        tooltip: {
          callbacks: {
            label: (item) => {
              const pct = ((item.parsed / total) * 100).toFixed(0);
              return `${item.label}: ${item.parsed} (${pct}%)`;
            }
          }
        }
      }
    }
  });
}

// Reaplica os gráficos quando o período do relatório muda
document.getElementById('filtro-periodo-relatorio')?.addEventListener('change', renderRelatorioDesempenho);

// =============================================================
// EXPORTAR RELATÓRIO EM PDF
// Função mantida no código (sem botão conectado no momento) —
// gera um PDF resumido com dados do paciente, estatísticas gerais,
// distribuição por dificuldade, desempenho por fonema e frequência
// de prática — pensado para enviar aos pais/responsáveis ou anexar
// ao prontuário.
// =============================================================
async function gerarRelatorioPdf() {
  const btn = document.getElementById('btn-exportar-pdf');
  if (!pacienteData) {
    mostrarToast('Aguarde o carregamento dos dados do paciente.', '#dc2626');
    return;
  }

  const textoOriginal = btn.textContent;
  btn.disabled = true;
  btn.textContent = 'Gerando…';

  try {
    const { jsPDF } = window.jspdf;
    const docPdf = new jsPDF();

    const corRoxo = [123, 47, 190];
    const margem = 14;
    let y = 20;

    // Cabeçalho
    docPdf.setFontSize(18);
    docPdf.setTextColor(...corRoxo);
    docPdf.setFont(undefined, 'bold');
    docPdf.text('Relatório de Evolução — Liri', margem, y);
    y += 6;
    docPdf.setDrawColor(...corRoxo);
    docPdf.line(margem, y, 196, y);
    y += 10;

    // Dados do paciente
    const nascimento = pacienteData.data_nascimento?.toDate?.();
    const idade = nascimento ? calcularIdade(nascimento) : null;

    docPdf.setFontSize(13);
    docPdf.setTextColor(20, 20, 20);
    docPdf.text(pacienteData.nome || 'Paciente', margem, y);
    y += 7;

    docPdf.setFontSize(10);
    docPdf.setFont(undefined, 'normal');
    docPdf.setTextColor(80, 80, 80);
    [
      `Nascimento: ${nascimento ? nascimento.toLocaleDateString('pt-BR') : '—'}${idade !== null ? ` (${idade} anos)` : ''}`,
      `Responsável: ${pacienteData.responsavel || '—'}`,
      `Telefone: ${pacienteData.telefone_responsavel || pacienteData.telefone || '—'}`,
      `Relatório gerado em: ${new Date().toLocaleDateString('pt-BR')}`
    ].forEach(linha => {
      docPdf.text(linha, margem, y);
      y += 5.5;
    });
    y += 4;

    // Resumo geral
    const total = progressosPaciente.length;
    const comAcertoInfo = progressosPaciente.filter(p => typeof p.acertou === 'boolean');
    const acertos = comAcertoInfo.filter(p => p.acertou).length;
    const taxaAcertoGeral = comAcertoInfo.length > 0
      ? Math.round((acertos / comAcertoInfo.length) * 100)
      : null;
    const totalTentativas = progressosPaciente.reduce((acc, p) => {
      const t = p.tentativas ?? p.numero_tentativas ?? 1;
      return acc + (typeof t === 'number' ? t : 1);
    }, 0);
    const totalAudios = progressosPaciente.filter(p => p.audio_base64 || p.tem_audio).length;

    docPdf.setFontSize(12);
    docPdf.setTextColor(...corRoxo);
    docPdf.setFont(undefined, 'bold');
    docPdf.text('Resumo geral', margem, y);
    y += 3;

    docPdf.autoTable({
      startY: y,
      margin: { left: margem, right: margem },
      theme: 'grid',
      headStyles: { fillColor: corRoxo },
      styles: { fontSize: 9.5 },
      head: [['Exercícios realizados', 'Total de tentativas', 'Áudios enviados', 'Taxa de acerto geral']],
      body: [[
        String(total),
        String(totalTentativas),
        String(totalAudios),
        taxaAcertoGeral !== null ? `${taxaAcertoGeral}%` : '—'
      ]]
    });
    y = docPdf.lastAutoTable.finalY + 10;

    // Distribuição por dificuldade
    const contagemDificuldade = {};
    progressosPaciente.forEach(p => {
      const dif = (p.dificuldade || '').toLowerCase().trim();
      if (!dif) return;
      contagemDificuldade[dif] = (contagemDificuldade[dif] || 0) + 1;
    });
    const ordemDif = ['fácil', 'médio', 'difícil'];
    const labelsDif = Object.keys(contagemDificuldade).sort((a, b) => {
      const ia = ordemDif.indexOf(a), ib = ordemDif.indexOf(b);
      if (ia === -1 && ib === -1) return a.localeCompare(b);
      if (ia === -1) return 1;
      if (ib === -1) return -1;
      return ia - ib;
    });

    if (labelsDif.length > 0) {
      docPdf.setFontSize(12);
      docPdf.setTextColor(...corRoxo);
      docPdf.setFont(undefined, 'bold');
      docPdf.text('Distribuição por nível de dificuldade', margem, y);
      y += 3;

      docPdf.autoTable({
        startY: y,
        margin: { left: margem, right: margem },
        theme: 'grid',
        headStyles: { fillColor: corRoxo },
        styles: { fontSize: 9.5 },
        head: [['Dificuldade', 'Exercícios', '% do total']],
        body: labelsDif.map(l => {
          const qtd = contagemDificuldade[l];
          const pct = total > 0 ? Math.round((qtd / total) * 100) : 0;
          return [l.charAt(0).toUpperCase() + l.slice(1), String(qtd), `${pct}%`];
        })
      });
      y = docPdf.lastAutoTable.finalY + 10;
    }

    // Desempenho por fonema
    const estatisticasFonema = new Map(); // fonema -> { total, acertos }
    progressosPaciente.forEach(p => {
      const fonema = p.trilha_fonema || p.fonema;
      if (!fonema) return;
      const stat = estatisticasFonema.get(fonema) || { total: 0, acertos: 0 };
      stat.total++;
      if (p.acertou === true) stat.acertos++;
      estatisticasFonema.set(fonema, stat);
    });

    if (estatisticasFonema.size > 0) {
      if (y > 250) { docPdf.addPage(); y = 20; }

      docPdf.setFontSize(12);
      docPdf.setTextColor(...corRoxo);
      docPdf.setFont(undefined, 'bold');
      docPdf.text('Desempenho por fonema', margem, y);
      y += 3;

      docPdf.autoTable({
        startY: y,
        margin: { left: margem, right: margem },
        theme: 'grid',
        headStyles: { fillColor: corRoxo },
        styles: { fontSize: 9.5 },
        head: [['Fonema', 'Exercícios', 'Taxa de acerto']],
        body: Array.from(estatisticasFonema.entries()).map(([fonema, stat]) => [
          fonema,
          String(stat.total),
          stat.total > 0 ? `${Math.round((stat.acertos / stat.total) * 100)}%` : '—'
        ])
      });
      y = docPdf.lastAutoTable.finalY + 10;
    }

    // Frequência de prática (últimos 6 meses)
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const seisMesesAtras = new Date(hoje);
    seisMesesAtras.setMonth(seisMesesAtras.getMonth() - 6);

    const diasComPratica = new Set();
    progressosPaciente.forEach(p => {
      if (!p.concluido_em?.toDate) return;
      const data = p.concluido_em.toDate();
      if (data >= seisMesesAtras) {
        diasComPratica.add(data.toISOString().split('T')[0]);
      }
    });

    if (y > 260) { docPdf.addPage(); y = 20; }
    docPdf.setFontSize(12);
    docPdf.setTextColor(...corRoxo);
    docPdf.setFont(undefined, 'bold');
    docPdf.text('Frequência de prática', margem, y);
    y += 7;

    docPdf.setFontSize(10);
    docPdf.setFont(undefined, 'normal');
    docPdf.setTextColor(80, 80, 80);
    docPdf.text(
      `${diasComPratica.size} ${diasComPratica.size === 1 ? 'dia ativo' : 'dias ativos'} nos últimos 6 meses.`,
      margem, y
    );

    // Rodapé com numeração de páginas
    const totalPaginas = docPdf.internal.getNumberOfPages();
    for (let i = 1; i <= totalPaginas; i++) {
      docPdf.setPage(i);
      docPdf.setFontSize(8);
      docPdf.setTextColor(150, 150, 150);
      docPdf.text(`Liri — Software de apoio a exercícios de fala · Página ${i}/${totalPaginas}`, margem, 290);
    }

    const nomeArquivo = `relatorio-${(pacienteData.nome || 'paciente').toLowerCase().replace(/[^a-z0-9]+/g, '-')}.pdf`;
    docPdf.save(nomeArquivo);
    mostrarToast('PDF gerado com sucesso!');
  } catch (e) {
    console.error('Erro ao gerar PDF:', e);
    mostrarToast('Erro ao gerar o PDF. Veja o console (F12).', '#dc2626');
  } finally {
    btn.disabled = false;
    btn.textContent = textoOriginal;
  }
}