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

    if (snap.empty) {
      lista.innerHTML = `<div class="empty-msg">
        Este paciente ainda não enviou nenhum áudio. 🎙️
      </div>`;
      document.getElementById('contador-audios').textContent = '0';
      return;
    }

    // Ordena por data (mais recente primeiro)
    const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    docs.sort((a, b) => {
      const ta = a.concluido_em?.toDate?.()?.getTime() || 0;
      const tb = b.concluido_em?.toDate?.()?.getTime() || 0;
      return tb - ta;
    });

    document.getElementById('contador-audios').textContent = docs.length;

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
  } catch (e) {
    console.error('Erro ao carregar áudios:', e);
    lista.innerHTML = `<div class="empty-msg" style="color:#dc2626">
      Erro ao carregar áudios. Veja o console (F12).
    </div>`;
  }
}

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
