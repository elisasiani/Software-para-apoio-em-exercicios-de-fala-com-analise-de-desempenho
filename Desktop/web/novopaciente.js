// ── CATÁLOGO DE TRILHAS — alinhado com DadosApp do Flutter ───────────────────
// Campos espelham exatamente o modelo Exercicio do Flutter:
// trilha_id, exercicio_id, instrucao, palavraAlvo, dicaAnimacao, dificuldade
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

// Estado da página
let selecionados    = [];
let trilhaExpandida = null;
let exerciciosPersonalizados = [];

// ── RENDER TRILHAS ────────────────────────────────────────────────────────────
function renderExercicios() {
  const grade = document.getElementById('exercises-grid');
  if (!grade) return;

  const busca = (document.getElementById('search-ex')?.value || '').toLowerCase();
  const trilhasFiltradas = catalogoTrilhas.filter(t =>
    !busca || t.titulo.toLowerCase().includes(busca) || t.fonema.toLowerCase().includes(busca)
  );

  const difLabels = { 'fácil': '🟢', 'médio': '🟡', 'difícil': '🔴' };

  let html = '';

  trilhasFiltradas.forEach(trilha => {
    const totalSel  = selecionados.filter(s => s.trilhaId === trilha.id).length;
    const expanded  = trilhaExpandida === trilha.id;
    const todosSel  = trilha.exercicios.every(ex =>
      selecionados.find(s => s.trilhaId === trilha.id && s.exercicio.id === ex.id)
    );

    const palavrasHTML = expanded ? trilha.exercicios.map(ex => {
      const sel = selecionados.find(s => s.trilhaId === trilha.id && s.exercicio.id === ex.id);
      return `
        <button class="cartao-exercicio ${sel ? 'selecionado' : ''}" type="button"
          onclick="togglePalavra('${trilha.id}', '${ex.id}')">
          <div class="exercicio-titulo">${ex.palavraAlvo}</div>
          <div class="exercicio-descricao">${ex.instrucao}</div>
          <div class="exercicio-meta">
            <span class="exercicio-fonema">${difLabels[ex.dificuldade] || ''} ${ex.dificuldade}</span>
          </div>
        </button>`;
    }).join('') : '';

    html += `
      <div style="grid-column:1/-1;background:var(--branco);border:1px solid var(--cinza-200);border-radius:8px;margin-bottom:8px;overflow:hidden;${totalSel > 0 ? 'border-color:var(--roxo-principal);' : ''}">
        <div onclick="toggleTrilha('${trilha.id}')" style="display:flex;align-items:center;justify-content:space-between;padding:16px 20px;cursor:pointer;gap:12px;">
          <div style="display:flex;align-items:center;gap:14px;">
            <span style="font-size:1.8rem;">${trilha.emoji}</span>
            <div>
              <div style="font-weight:800;color:var(--cinza-900);">${trilha.titulo}</div>
              <div style="font-size:.78rem;color:var(--cinza-400);">${trilha.subtitulo} — Fonema ${trilha.fonema}</div>
            </div>
          </div>
          <div style="display:flex;align-items:center;gap:10px;flex-shrink:0;">
            ${totalSel > 0 ? `<span style="background:var(--roxo-principal);color:#fff;border-radius:99px;padding:3px 10px;font-size:.75rem;font-weight:700;">${totalSel} selecionado${totalSel > 1 ? 's' : ''}</span>` : ''}
            <button class="filtro-botao ${todosSel ? 'ativo' : ''}" type="button"
              onclick="event.stopPropagation(); selecionarTodos('${trilha.id}')">
              ${todosSel ? 'Desmarcar todos' : 'Selecionar todos'}
            </button>
            <span style="color:var(--cinza-400);font-size:1.1rem;">${expanded ? '▲' : '▼'}</span>
          </div>
        </div>
        ${expanded ? `<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;padding:16px 20px;border-top:1px solid var(--cinza-100);background:var(--cinza-50);">${palavrasHTML}</div>` : ''}
      </div>`;
  });

  if (exerciciosPersonalizados.length > 0) {
    exerciciosPersonalizados.forEach(ex => {
      const sel = selecionados.find(s => s.trilhaId === 'custom' && s.exercicio.id === ex.id);
      html += `
        <button class="cartao-exercicio ${sel ? 'selecionado' : ''}" type="button"
          onclick="togglePalavra('custom', '${ex.id}')">
          <span class="selo-exercicio personalizado">Personalizado</span>
          <div class="exercicio-titulo">${ex.titulo}</div>
          <div class="exercicio-descricao">${ex.desc}</div>
          <div class="exercicio-meta">
            <span class="exercicio-fonema">${ex.fonema}</span>
          </div>
        </button>`;
    });
  }

  if (!html) {
    html = '<p class="msg-vazia">Nenhuma trilha encontrada.</p>';
  }

  grade.innerHTML = html;
}

function toggleTrilha(trilhaId) {
  trilhaExpandida = trilhaExpandida === trilhaId ? null : trilhaId;
  renderExercicios();
}

function togglePalavra(trilhaId, exId) {
  if (trilhaId === 'custom') {
    const ex = exerciciosPersonalizados.find(e => e.id == exId);
    if (!ex) return;
    const idx = selecionados.findIndex(s => s.trilhaId === 'custom' && s.exercicio.id == exId);
    if (idx === -1) selecionados.push({ trilhaId: 'custom', trilhaTitulo: 'Personalizado', trilhaEmoji: '✏️', trilhaTipo: ex.tipo, trilhaFonema: ex.fonema, exercicio: { id: ex.id, palavraAlvo: ex.titulo, instrucao: ex.desc, dificuldade: 'personalizado', dicaAnimacao: '' } });
    else selecionados.splice(idx, 1);
  } else {
    const trilha = catalogoTrilhas.find(t => t.id === trilhaId);
    const ex = trilha?.exercicios.find(e => e.id === exId);
    if (!ex) return;
    const idx = selecionados.findIndex(s => s.trilhaId === trilhaId && s.exercicio.id === exId);
    if (idx === -1) selecionados.push({ trilhaId, trilhaTitulo: trilha.titulo, trilhaEmoji: trilha.emoji, trilhaTipo: trilha.tipo, trilhaFonema: trilha.fonema, exercicio: ex });
    else selecionados.splice(idx, 1);
  }
  renderExercicios();
  renderSelecionados();
}

function selecionarTodos(trilhaId) {
  const trilha = catalogoTrilhas.find(t => t.id === trilhaId);
  if (!trilha) return;
  const todosSel = trilha.exercicios.every(ex =>
    selecionados.find(s => s.trilhaId === trilhaId && s.exercicio.id === ex.id)
  );
  if (todosSel) {
    selecionados = selecionados.filter(s => s.trilhaId !== trilhaId);
  } else {
    trilha.exercicios.forEach(ex => {
      if (!selecionados.find(s => s.trilhaId === trilhaId && s.exercicio.id === ex.id)) {
        selecionados.push({ trilhaId, trilhaTitulo: trilha.titulo, trilhaEmoji: trilha.emoji, trilhaTipo: trilha.tipo, trilhaFonema: trilha.fonema, exercicio: ex });
      }
    });
  }
  trilhaExpandida = trilhaId;
  renderExercicios();
  renderSelecionados();
}

function setFiltro(tipo, btn) {
  document.querySelectorAll('.filtro-botao').forEach(b => b.classList.remove('ativo'));
  btn?.classList.add('ativo');
  renderExercicios();
}

function filtrarExercicios() { renderExercicios(); }

// ── PAINEL DE SELECIONADOS ────────────────────────────────────────────────────
function renderSelecionados() {
  const lista    = document.getElementById('selected-list');
  const contador = document.getElementById('selected-count');
  if (!lista || !contador) return;

  contador.textContent = selecionados.length;

  if (!selecionados.length) {
    lista.innerHTML = '<div class="selecionado-vazio">Nenhum exercicio selecionado</div>';
    return;
  }

  const porTrilha = {};
  selecionados.forEach(s => {
    if (!porTrilha[s.trilhaId]) porTrilha[s.trilhaId] = { titulo: s.trilhaTitulo, emoji: s.trilhaEmoji, itens: [] };
    porTrilha[s.trilhaId].itens.push(s);
  });

  lista.innerHTML = Object.values(porTrilha).map(grupo => `
    <div style="margin-bottom:12px;">
      <div style="font-size:.75rem;font-weight:700;color:var(--roxo-principal);margin-bottom:6px;padding-bottom:4px;border-bottom:1px solid var(--cinza-100);">
        ${grupo.emoji} ${grupo.titulo}
      </div>
      ${grupo.itens.map(s => `
        <div class="selecionado-item">
          <div>
            <div class="selecionado-nome">${s.exercicio.palavraAlvo}</div>
            <div class="selecionado-tipo">${s.exercicio.dificuldade}</div>
          </div>
          <button class="selecionado-remover" type="button"
            onclick="togglePalavra('${s.trilhaId}', '${s.exercicio.id}')" title="Remover">✕</button>
        </div>`).join('')}
    </div>`).join('');
}

// ── NAVEGAÇÃO STEPS ───────────────────────────────────────────────────────────
function trocarPagina(idPagina) {
  document.querySelectorAll('.pagina-etapa').forEach(p => p.classList.remove('ativo'));
  document.getElementById(idPagina)?.classList.add('ativo');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function irParaStep2() {
  const obrigatorios = ['nome', 'nomeResp', 'loginUsuario', 'senhaTemp'];
  if (obrigatorios.some(id => !document.getElementById(id)?.value.trim())) {
    mostrarToast('Preencha os campos obrigatorios!', '#dc2626'); return;
  }
  document.getElementById('nome-paciente-step2').textContent = document.getElementById('nome').value;
  renderExercicios();
  renderSelecionados();
  trocarPagina('page-step2');
}

function voltarStep1() { trocarPagina('page-step1'); }

function irParaStep3() {
  if (!selecionados.length) {
    mostrarToast('Selecione ao menos 1 exercicio!', '#dc2626'); return;
  }
  preencherConfirmacao();
  trocarPagina('page-step3');
}

function voltarStep2() { trocarPagina('page-step2'); }

function preencherConfirmacao() {
  const nasc = document.getElementById('dataNasc')?.value || '';
  const obs  = document.getElementById('obs')?.value || '';
  const dataFormatada = nasc ? new Date(`${nasc}T00:00:00`).toLocaleDateString('pt-BR') : '—';

  document.getElementById('confirm-body').innerHTML = `
    <div class="confirmacao-linha"><strong>Nome:</strong> ${document.getElementById('nome').value}</div>
    <div class="confirmacao-linha"><strong>Nascimento:</strong> ${dataFormatada}</div>
    <div class="confirmacao-linha"><strong>Responsavel:</strong> ${document.getElementById('nomeResp').value}</div>
    <div class="confirmacao-linha"><strong>Telefone:</strong> ${document.getElementById('telefone').value || '—'}</div>
    <div class="confirmacao-linha"><strong>Login App:</strong> ${document.getElementById('loginUsuario').value}</div>
    ${obs ? `<div class="confirmacao-linha"><strong>Observacoes:</strong> ${obs}</div>` : ''}`;

  const porTrilha = {};
  selecionados.forEach(s => {
    if (!porTrilha[s.trilhaId]) porTrilha[s.trilhaId] = { titulo: s.trilhaTitulo, emoji: s.trilhaEmoji, itens: [] };
    porTrilha[s.trilhaId].itens.push(s.exercicio.palavraAlvo);
  });

  document.getElementById('confirm-exercicios').innerHTML =
    Object.values(porTrilha).map(g =>
      `<div style="width:100%;margin-bottom:8px;">
        <span style="font-size:.78rem;font-weight:700;color:var(--roxo-principal);display:block;margin-bottom:4px;">${g.emoji} ${g.titulo}</span>
        <div style="display:flex;flex-wrap:wrap;gap:6px;">
          ${g.itens.map(p => `<span class="confirmacao-tag">${p}</span>`).join('')}
        </div>
      </div>`
    ).join('');
}

// ── HELPERS DE LOGIN ──────────────────────────────────────────────────────────

/**
 * Converte o login digitado pela fonoaudióloga (ex: "bibi.123", "ana clara")
 * em um e-mail interno único para o Firebase Auth.
 *
 * ⚠️ MUDANÇA IMPORTANTE: agora preserva TUDO (letras+números),
 * para que "bibi.123" e "bibi.456" sejam usuários DIFERENTES.
 * Antes, ambos viravam "bibi@liri.app" e colidiam.
 */
function loginParaEmailUnico(login) {
  const limpo = login
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')   // remove acentos
    .replace(/\s+/g, '.')                                // espaços → ponto
    .replace(/[^a-z0-9.]/g, '');                         // só letra, número, ponto
  return `${limpo}@liri.app`;
}

// ── SALVAR PACIENTE ───────────────────────────────────────────────────────────
async function salvarPaciente() {
  const btn = document.querySelector('.btn-success');
  if (!btn) return;
  btn.disabled = true;
  btn.textContent = 'Salvando...';

  try {
    const nome   = document.getElementById('nome').value.trim();
    const login  = document.getElementById('loginUsuario').value.trim();
    const senha  = document.getElementById('senhaTemp').value.trim();

    if (!login) {
      mostrarToast('Informe um login.', '#dc2626');
      restaurarBotao(btn);
      return;
    }
    if (senha.length < 6) {
      mostrarToast('A senha precisa ter ao menos 6 caracteres.', '#dc2626');
      restaurarBotao(btn);
      return;
    }

    if (!window._criarContaPaciente || !window._setDoc || !window._db) {
      mostrarToast('Firebase nao carregado.', '#dc2626');
      restaurarBotao(btn);
      return;
    }

    // ✅ ESPERA o estado de Auth ser resolvido antes de prosseguir.
    // Isso evita o bug onde currentUser ainda é null no momento do clique.
    const profissionalLogado = await window._authReady;
    if (!profissionalLogado) {
      mostrarToast('Sessão expirada. Faça login novamente.', '#dc2626');
      setTimeout(() => { window.location.href = 'login.html'; }, 1500);
      return;
    }
    const profId = profissionalLogado.uid;
    console.log('[Liri] Salvando paciente. Profissional UID:', profId);

    // ✅ Agora o login completo (com pontos e números) é preservado no e-mail
    const emailFake = loginParaEmailUnico(login);

    // 1. Cria a conta do paciente em uma INSTÂNCIA SECUNDÁRIA do Firebase.
    //    Isso garante que a sessão da fono na instância principal não seja
    //    afetada — ela continua logada normalmente após o cadastro.
    const uid  = await window._criarContaPaciente(emailFake, senha);
    const nasc = document.getElementById('dataNasc').value;

    // 2. Salva em pacientes/{uid}
    await window._setDoc(window._doc(window._db, 'pacientes', uid), {
      uid,
      nome,
      email_acesso:         emailFake,
      tipo:                 'paciente',
      login_app:            login,
      senha_temporaria:     senha,
      sexo:                 document.getElementById('sexo').value,
      data_nascimento:      nasc ? window._Timestamp.fromDate(new Date(`${nasc}T00:00:00`)) : null,
      responsavel:          document.getElementById('nomeResp').value.trim(),
      telefone_responsavel: document.getElementById('telefone').value.trim(),
      profissional_id:      profId,
      progresso:            0,
      criado_em:            window._Timestamp.now(),
      ativo:                true
    });

    // 3. Salva cada exercício prescrito em prescricoes/
    for (const s of selecionados) {
      await window._addDoc(window._collection(window._db, 'prescricoes'), {
        paciente_id:      uid,
        profissional_id:  profId,
        trilha_id:        s.trilhaId,
        trilha_titulo:    s.trilhaTitulo,
        trilha_tipo:      s.trilhaTipo,
        trilha_fonema:    s.trilhaFonema,
        exercicio_id:     s.exercicio.id,
        palavraAlvo:      s.exercicio.palavraAlvo,
        instrucao:        s.exercicio.instrucao,
        dicaAnimacao:     s.exercicio.dicaAnimacao,
        dificuldade:      s.exercicio.dificuldade,
        data_prescricao:  window._Timestamp.now(),
        ativo:            true
      });
    }

    mostrarToast('Paciente cadastrado com sucesso!');
    setTimeout(() => { window.location.href = 'dashboard.html'; }, 1500);

  } catch (erro) {
    console.error(erro);

    // Erro de login duplicado → volta pro step 1 e sugere outro login
    if (erro.code === 'auth/email-already-in-use') {
      mostrarToast(
        'Este login já está em uso. Geramos outro para você — confira na etapa 1.',
        '#dc2626'
      );
      sugerirOutroLogin();
      trocarPagina('page-step1');
      // Foca no campo de login para a fonoaudióloga ajustar se quiser
      setTimeout(() => document.getElementById('loginUsuario')?.focus(), 400);
      restaurarBotao(btn);
      return;
    }

    const msgs = {
      'auth/weak-password':          'Senha fraca. Use ao menos 6 caracteres.',
      'auth/network-request-failed': 'Sem conexão com a internet.',
      'auth/invalid-email':          'Login inválido. Use só letras, números e ponto.',
    };
    mostrarToast(msgs[erro.code] || `Erro: ${erro.message}`, '#dc2626');
    restaurarBotao(btn);
  }
}

function restaurarBotao(btn) {
  btn.disabled = false;
  btn.textContent = 'Salvar paciente';
}

/** Gera um login alternativo somando um sufixo aleatório ao atual. */
function sugerirOutroLogin() {
  const campo = document.getElementById('loginUsuario');
  if (!campo) return;
  const atual = campo.value.trim();
  // Remove sufixo numérico antigo (ex: bibi.123 → bibi)
  const base = atual.split('.')[0] || 'paciente';
  const num = Math.floor(100 + Math.random() * 899);
  campo.value = `${base}.${num}`;
}

// ── CREDENCIAIS ───────────────────────────────────────────────────────────────
function gerarCredenciais() {
  const nome = document.getElementById('nome').value.trim();
  const base = nome
    ? nome.split(' ')[0].toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z]/g, '')
    : 'paciente';
  const num = Math.floor(100 + Math.random() * 899);
  document.getElementById('loginUsuario').value = `${base}.${num}`;
  document.getElementById('senhaTemp').value    = `Liri@${num}`;
}

// ── MODAL EXERCÍCIO PERSONALIZADO ────────────────────────────────────────────
function abrirModalCustom() {
  document.getElementById('modal-custom')?.classList.add('aberto');
}

function fecharModalCustom() {
  document.getElementById('modal-custom')?.classList.remove('aberto');
  ['custom-titulo', 'custom-desc', 'custom-fonema'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
}

function salvarCustom() {
  const titulo = document.getElementById('custom-titulo').value.trim();
  if (!titulo) { mostrarToast('De um nome ao exercicio!', '#dc2626'); return; }

  const novoEx = {
    id:    Date.now(),
    titulo,
    tipo:  document.getElementById('custom-tipo').value,
    nivel: parseInt(document.getElementById('custom-nivel').value, 10),
    fonema: document.getElementById('custom-fonema').value || '—',
    desc:  document.getElementById('custom-desc').value || 'Personalizado.',
    custom: true
  };

  exerciciosPersonalizados.push(novoEx);
  selecionados.push({
    trilhaId: 'custom', trilhaTitulo: 'Personalizado', trilhaEmoji: '✏️',
    trilhaTipo: novoEx.tipo, trilhaFonema: novoEx.fonema,
    exercicio: { id: novoEx.id, palavraAlvo: novoEx.titulo, instrucao: novoEx.desc, dificuldade: 'personalizado', dicaAnimacao: '' }
  });

  fecharModalCustom();
  renderExercicios();
  renderSelecionados();
  mostrarToast('Exercicio criado e adicionado!');
}

// ── TOAST ─────────────────────────────────────────────────────────────────────
function mostrarToast(msg, cor = '#059669') {
  const toast = document.getElementById('toast');
  const label = document.getElementById('toast-msg');
  if (!toast || !label) return;
  label.textContent  = msg;
  toast.style.background = cor;
  toast.classList.add('mostrar');
  setTimeout(() => toast.classList.remove('mostrar'), 3000);
}

document.getElementById('modal-custom')?.addEventListener('click', e => {
  if (e.target === e.currentTarget) fecharModalCustom();
});

// Inicializa
renderExercicios();
renderSelecionados();
