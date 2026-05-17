const catalogoExercicios = [
  { id: 1, titulo: 'Fonema /R/ inicial', tipo: 'fonema', nivel: 1, fonema: '/r/', desc: 'Praticar o som do R no inicio das palavras: rato, rua, rio.' },
  { id: 2, titulo: 'Fonema /S/ final', tipo: 'fonema', nivel: 1, fonema: '/s/', desc: 'Treinar o S no final das silabas: casca, pasta, festa.' },
  { id: 3, titulo: 'Silabas com L', tipo: 'silaba', nivel: 1, fonema: '/l/', desc: 'Repetir silabas la, le, li, lo, lu em sequencia.' },
  { id: 4, titulo: 'Digrafo LH', tipo: 'fonema', nivel: 2, fonema: '/lh/', desc: 'Trabalhar o som lh: folha, telha, galho, filho.' },
  { id: 5, titulo: 'Digrafo NH', tipo: 'fonema', nivel: 2, fonema: '/nh/', desc: 'Praticar o nh: ninho, banho, sonho, caminho.' },
  { id: 6, titulo: 'Palavras com R forte', tipo: 'palavra', nivel: 2, fonema: '/rr/', desc: 'Pronunciar palavras com rr: carro, terra, borracha, ferro.' },
  { id: 7, titulo: 'Encontros consonantais BR/PR', tipo: 'silaba', nivel: 2, fonema: '/br/ /pr/', desc: 'Treinar bra, bre, pri, pra em palavras como prato, branco.' },
  { id: 8, titulo: 'Frases com /S/ e /Z/', tipo: 'frase', nivel: 3, fonema: '/s/ /z/', desc: 'Ler frases que alternam o som S e Z para diferenciacao.' },
  { id: 9, titulo: 'Fonema /T/ e /D/', tipo: 'fonema', nivel: 1, fonema: '/t/ /d/', desc: 'Distinguir e pronunciar T e D: dado, tudo, tarde, dente.' },
  { id: 10, titulo: 'Palavras polissilabas', tipo: 'palavra', nivel: 3, fonema: 'Misto', desc: 'Pronunciar palavras longas com multiplas silabas.' },
  { id: 11, titulo: 'Silabas com CH', tipo: 'silaba', nivel: 1, fonema: '/ch/', desc: 'Repetir cha, che, chi, cho, chu: chave, cheio, chuveiro.' },
  { id: 12, titulo: 'Frases ritmicas', tipo: 'frase', nivel: 2, fonema: 'Misto', desc: 'Recitar frases em ritmo para treinar fluencia e articulacao.' },
];

let exerciciosPersonalizados = [];
let selecionados = [];
let filtroAtivo = 'todos';

function obterTodosExercicios() {
  return [...catalogoExercicios, ...exerciciosPersonalizados];
}

function renderExercicios() {
  const grade = document.getElementById('exercises-grid');
  if (!grade) return;

  const busca = (document.getElementById('search-ex')?.value || '').toLowerCase();
  const filtrados = obterTodosExercicios().filter(exercicio => {
    const tipoIgual = filtroAtivo === 'todos' || exercicio.tipo === filtroAtivo;
    const personalizadoIgual = filtroAtivo === 'custom' && exercicio.custom;
    const buscaIgual = !busca
      || exercicio.titulo.toLowerCase().includes(busca)
      || exercicio.fonema.toLowerCase().includes(busca);

    return (tipoIgual || personalizadoIgual) && buscaIgual;
  });

  if (filtrados.length === 0) {
    grade.innerHTML = '<p class="msg-vazia">Nenhum exercicio encontrado.</p>';
    return;
  }

  grade.innerHTML = filtrados.map(exercicio => {
    const estaSelecionado = selecionados.some(item => item.id === exercicio.id);
    const rotuloTipo = { fonema: 'Fonema', silaba: 'Silaba', palavra: 'Palavra', frase: 'Frase' }[exercicio.tipo] || exercicio.tipo;
    const pontosNivel = [1, 2, 3]
      .map(nivel => `<span class="${nivel <= exercicio.nivel ? 'ativo' : ''}"></span>`)
      .join('');

    return `
      <button class="cartao-exercicio ${estaSelecionado ? 'selecionado' : ''}" type="button" onclick="alternarExercicio(${exercicio.id})">
        <span class="selo-exercicio ${exercicio.custom ? 'personalizado' : exercicio.tipo}">${exercicio.custom ? 'Personalizado' : rotuloTipo}</span>
        <div class="exercicio-titulo">${exercicio.titulo}</div>
        <div class="exercicio-descricao">${exercicio.desc}</div>
        <div class="exercicio-meta">
          <div class="pontos-nivel">${pontosNivel}</div>
          <span class="exercicio-fonema">${exercicio.fonema}</span>
        </div>
      </button>`;
  }).join('');
}

function alternarExercicio(id) {
  const exercicio = obterTodosExercicios().find(item => item.id === id);
  if (!exercicio) return;

  const index = selecionados.findIndex(item => item.id === id);

  if (index === -1) {
    selecionados.push(exercicio);
  } else {
    selecionados.splice(index, 1);
  }

  renderExercicios();
  renderSelecionados();
}

function renderSelecionados() {
  const lista = document.getElementById('selected-list');
  const contador = document.getElementById('selected-count');
  if (!lista || !contador) return;

  contador.textContent = selecionados.length;

  if (selecionados.length === 0) {
    lista.innerHTML = '<div class="selecionado-vazio">Nenhum exercicio selecionado</div>';
    return;
  }

  lista.innerHTML = selecionados.map(exercicio => `
    <div class="selecionado-item">
      <div>
        <div class="selecionado-nome">${exercicio.titulo}</div>
        <div class="selecionado-tipo">${exercicio.fonema}</div>
      </div>
      <button class="selecionado-remover" type="button" onclick="alternarExercicio(${exercicio.id})" title="Remover">x</button>
    </div>`).join('');
}

function setFiltro(tipo, elementoBtn) {
  filtroAtivo = tipo;
  document.querySelectorAll('.filtro-botao').forEach(btn => btn.classList.remove('ativo'));
  elementoBtn?.classList.add('ativo');
  renderExercicios();
}

function filtrarExercicios() {
  renderExercicios();
}

function atualizarMenuEtapas(idPagina) {
  document.querySelectorAll('.item-menu').forEach(botao => {
    botao.classList.toggle('ativo', botao.dataset.pagina === idPagina);
  });
}

function trocarPagina(idPagina) {
  document.querySelectorAll('.pagina-etapa').forEach(pagina => pagina.classList.remove('ativo'));

  const paginaAlvo = document.getElementById(idPagina);
  if (paginaAlvo) {
    paginaAlvo.classList.add('ativo');
  }

  atualizarMenuEtapas(idPagina);
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function campoObrigatorioPreenchido(id) {
  return Boolean(document.getElementById(id)?.value.trim());
}

function irParaStep2() {
  const camposObrigatorios = ['nome', 'nomeResp', 'loginUsuario', 'senhaTemp'];
  const algumVazio = camposObrigatorios.some(id => !campoObrigatorioPreenchido(id));

  if (algumVazio) {
    mostrarToast('Preencha os campos obrigatorios!', '#dc2626');
    return;
  }

  document.getElementById('nome-paciente-step2').textContent = document.getElementById('nome').value;
  renderExercicios();
  renderSelecionados();
  trocarPagina('page-step2');
}

function voltarStep1() {
  trocarPagina('page-step1');
}

function irParaStep3() {
  if (selecionados.length === 0) {
    mostrarToast('Selecione ao menos 1 exercicio!', '#dc2626');
    return;
  }

  preencherConfirmacao();
  trocarPagina('page-step3');
}

function voltarStep2() {
  trocarPagina('page-step2');
}

function preencherConfirmacao() {
  const dados = {
    nome: document.getElementById('nome')?.value || '',
    nasc: document.getElementById('dataNasc')?.value || '',
    resp: document.getElementById('nomeResp')?.value || '',
    tel: document.getElementById('telefone')?.value || '',
    login: document.getElementById('loginUsuario')?.value || '',
    obs: document.getElementById('obs')?.value || ''
  };

  const dataFormatada = dados.nasc
    ? new Date(`${dados.nasc}T00:00:00`).toLocaleDateString('pt-BR')
    : '-';

  document.getElementById('confirm-body').innerHTML = `
    <div class="confirmacao-linha"><strong>Nome:</strong> ${dados.nome}</div>
    <div class="confirmacao-linha"><strong>Nascimento:</strong> ${dataFormatada}</div>
    <div class="confirmacao-linha"><strong>Responsavel:</strong> ${dados.resp}</div>
    <div class="confirmacao-linha"><strong>Telefone:</strong> ${dados.tel || '-'}</div>
    <div class="confirmacao-linha"><strong>Login App:</strong> ${dados.login}</div>
    ${dados.obs ? `<div class="confirmacao-linha"><strong>Observacoes:</strong> ${dados.obs}</div>` : ''}
  `;

  document.getElementById('confirm-exercicios').innerHTML = selecionados
    .map(exercicio => `<span class="confirmacao-tag">${exercicio.titulo}</span>`)
    .join('');
}

async function salvarPaciente() {
  const btn = document.querySelector('.btn-success');
  if (!btn) return;

  btn.disabled = true;
  btn.textContent = 'Processando...';

  try {
    const nome = document.getElementById('nome').value.trim();
    const login = document.getElementById('loginUsuario').value.trim();
    const senha = document.getElementById('senhaTemp').value.trim();
    const profId = window._auth?.currentUser?.uid || 'anonimo';
    const loginLimpo = login.split('.')[0].toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const emailFake = `${loginLimpo}@liri.app`;

    if (!window._createUser || !window._setDoc || !window._db) {
      mostrarToast('Firebase nao foi carregado nesta pagina.', '#dc2626');
      btn.disabled = false;
      btn.textContent = 'Salvar paciente';
      return;
    }

    const userCredential = await window._createUser(window._auth, emailFake, senha);
    const uid = userCredential.user.uid;
    const dataNascimento = document.getElementById('dataNasc').value;

    await window._setDoc(window._doc(window._db, 'usuarios', uid), {
      uid,
      nome,
      email_acesso: emailFake,
      tipo: 'paciente',
      login_app: login,
      senha_temporaria: senha,
      sexo: document.getElementById('sexo').value,
      data_nascimento: dataNascimento ? window._Timestamp.fromDate(new Date(`${dataNascimento}T00:00:00`)) : null,
      responsavel: document.getElementById('nomeResp').value.trim(),
      telefone_responsavel: document.getElementById('telefone').value.trim(),
      profissional_id: profId,
      criado_em: window._Timestamp.now(),
      ativo: true
    });

    for (const exercicio of selecionados) {
      await window._addDoc(window._collection(window._db, 'prescricoes'), {
        paciente_id: uid,
        profissional_id: profId,
        exercicio_id: String(exercicio.id),
        titulo: exercicio.titulo,
        tipo: exercicio.tipo,
        data_prescricao: window._Timestamp.now()
      });
    }

    mostrarToast('Paciente cadastrado com sucesso!');
    setTimeout(() => { window.location.href = 'dashboard.html'; }, 2000);
  } catch (error) {
    console.error(error);
    mostrarToast(`Erro ao salvar: ${error.message}`, '#dc2626');
    btn.disabled = false;
    btn.textContent = 'Salvar paciente';
  }
}

function gerarCredenciais() {
  const nome = document.getElementById('nome').value.trim();
  const base = nome
    ? nome.split(' ')[0].toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z]/g, '')
    : 'paciente';
  const num = Math.floor(100 + Math.random() * 899);

  document.getElementById('loginUsuario').value = `${base}.${num}`;
  document.getElementById('senhaTemp').value = `Liri@${num}`;
}

function abrirModalCustom() {
  document.getElementById('modal-custom')?.classList.add('aberto');
}

function fecharModalCustom() {
  document.getElementById('modal-custom')?.classList.remove('aberto');
  ['custom-titulo', 'custom-desc', 'custom-fonema'].forEach(id => {
    const campo = document.getElementById(id);
    if (campo) campo.value = '';
  });
}

function salvarCustom() {
  const titulo = document.getElementById('custom-titulo').value.trim();
  if (!titulo) {
    mostrarToast('De um nome ao exercicio!', '#dc2626');
    return;
  }

  const novoExercicio = {
    id: Date.now(),
    titulo,
    tipo: document.getElementById('custom-tipo').value,
    nivel: parseInt(document.getElementById('custom-nivel').value, 10),
    fonema: document.getElementById('custom-fonema').value || '-',
    desc: document.getElementById('custom-desc').value || 'Personalizado pelo fono.',
    custom: true
  };

  exerciciosPersonalizados.push(novoExercicio);
  selecionados.push(novoExercicio);
  fecharModalCustom();
  renderExercicios();
  renderSelecionados();
}

function mostrarToast(msg, cor = '#059669') {
  const toast = document.getElementById('toast');
  const mensagem = document.getElementById('toast-msg');
  if (!toast || !mensagem) return;

  mensagem.textContent = msg;
  toast.style.background = cor;
  toast.classList.add('mostrar');
  setTimeout(() => toast.classList.remove('mostrar'), 3000);
}

document.getElementById('modal-custom')?.addEventListener('click', event => {
  if (event.target === event.currentTarget) {
    fecharModalCustom();
  }
});

renderExercicios();
renderSelecionados();
