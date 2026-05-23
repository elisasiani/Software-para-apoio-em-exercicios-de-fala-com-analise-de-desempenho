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
      { id: 'f1', palavraAlvo: 'rato',    instrucao: 'Diga bem devagar:',      dificuldade: 'fácil',   dicaAnimacao: 'Girafa abre a boca e mostra a língua tremendo' },
      { id: 'f2', palavraAlvo: 'rua',     instrucao: 'Agora tente dizer:',     dificuldade: 'fácil',   dicaAnimacao: 'Girafa aponta para a boca e sorri' },
      { id: 'f3', palavraAlvo: 'carro',   instrucao: 'Um pouco mais difícil:', dificuldade: 'médio',   dicaAnimacao: 'Girafa faz gesto de atenção com a pata' },
      { id: 'f4', palavraAlvo: 'terra',   instrucao: 'Você consegue?',         dificuldade: 'médio',   dicaAnimacao: 'Girafa vibra de animação' },
      { id: 'f5', palavraAlvo: 'recreio', instrucao: 'Último desafio! Diga:',  dificuldade: 'difícil', dicaAnimacao: 'Girafa levanta os braços de comemoração' },
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
      { id: 't1', palavraAlvo: 'O rato roeu',                                         instrucao: 'Devagar primeiro:',    dificuldade: 'fácil',   dicaAnimacao: 'Girafa faz sinal de calma com a pata' },
      { id: 't2', palavraAlvo: 'O rato roeu a roupa',                                 instrucao: 'Agora um pouco mais:', dificuldade: 'fácil',   dicaAnimacao: 'Girafa aponta para a boca sorrindo' },
      { id: 't3', palavraAlvo: 'O rato roeu a roupa do rei',                          instrucao: 'Quase lá!',            dificuldade: 'médio',   dicaAnimacao: 'Girafa faz joinha com a pata' },
      { id: 't4', palavraAlvo: 'O rato roeu a roupa do rei de Roma',                  instrucao: 'Respira e tenta:',     dificuldade: 'médio',   dicaAnimacao: 'Girafa torce com pompons' },
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
window.removerPrescricao = async function(prescricaoId) {
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
window.abrirSelecaoExercicios = function() {
  novosSelecionados = [];
  document.getElementById('area-adicionar').style.display = 'block';
  renderExercicios();
  document.getElementById('area-adicionar').scrollIntoView({ behavior: 'smooth' });
};

window.cancelarAdicao = function() {
  novosSelecionados = [];
  document.getElementById('area-adicionar').style.display = 'none';
};

window.toggleTrilha = function(trilhaId) {
  trilhaExpandida = trilhaExpandida === trilhaId ? null : trilhaId;
  renderExercicios();
};

window.togglePalavra = function(trilhaId, exId) {
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

window.renderExercicios = function() {
  const grade = document.getElementById('exercises-grid');
  const busca = (document.getElementById('search-ex')?.value || '').toLowerCase();
  const trilhasFiltradas = catalogoTrilhas.filter(t =>
    !busca || t.titulo.toLowerCase().includes(busca) || t.fonema.toLowerCase().includes(busca)
  );

  const difLabels = { 'fácil': '🟢', 'médio': '🟡', 'difícil': '🔴' };
  let html = '';

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
window.salvarNovosExercicios = async function() {
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
        paciente_id:      pacienteId,
        profissional_id:  profissionalUid,
        trilha_id:        s.trilhaId,
        trilha_titulo:    s.trilhaTitulo,
        trilha_tipo:      s.trilhaTipo,
        trilha_fonema:    s.trilhaFonema,
        exercicio_id:     s.exercicio.id,
        palavraAlvo:      s.exercicio.palavraAlvo,
        instrucao:        s.exercicio.instrucao,
        dicaAnimacao:     s.exercicio.dicaAnimacao || '',
        dificuldade:      s.exercicio.dificuldade,
        data_prescricao:  Timestamp.now(),
        ativo:            true
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
