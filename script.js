// Seleciona elementos do DOM
const trilho = document.getElementById('trilhoCarrossel');
const slides = document.querySelectorAll('.slide');
const indicadores = document.querySelectorAll('.indicador');

let atual = 0;
let intervaloAutomatico;

/**
 * Atualiza a posição do trilho e o estado visual dos indicadores
 */
function atualizarCarrossel() {
    // Move o trilho
    trilho.style.transform = `translateX(-${atual * 100}%)`;

    // Atualiza o estado visual dos indicadores
    indicadores.forEach((dot, i) => {
        dot.classList.toggle('ativo', i === atual);
        // Acessibilidade: indica ao leitor de tela qual é o slide atual
        dot.setAttribute('aria-current', i === atual ? 'true' : 'false');
    });
}

/**
 * Lógica de navegação (próximo ou anterior)
 * @param {number} direcao - 1 para próximo, -1 para anterior
 */
function moverSlide(direcao) {
    const totalSlides = slides.length;
    
    // O cálculo (atual + direcao + totalSlides) % totalSlides garante 
    // que o carrossel seja infinito (volta ao início ou vai ao fim)
    atual = (atual + direcao + totalSlides) % totalSlides;
    
    atualizarCarrossel();
    reiniciarAuto(); // Reseta o timer ao interagir manualmente
}

/**
 * Navegação direta via indicadores
 * @param {number} indice 
 */
function irParaSlide(indice) {
    atual = indice;
    atualizarCarrossel();
    reiniciarAuto();
}

/**
 * Reinicia o temporizador do autoplay para evitar conflitos 
 * quando o usuário clica nos botões
 */
function reiniciarAuto() {
    clearInterval(intervaloAutomatico);
    intervaloAutomatico = setInterval(() => moverSlide(1), 5000);
}

// Inicializa o autoplay
intervaloAutomatico = setInterval(() => moverSlide(1), 5000);

// Opcional: Adiciona suporte a teclado (setas esquerda/direita)
document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowLeft') moverSlide(-1);
    if (e.key === 'ArrowRight') moverSlide(1);
});
