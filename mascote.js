// Mascote flutuante da girafa
// Passa o mouse: mostra uma frase amigável no balão
// Clica: volta para a página inicial (index.html)

const fraseMascote = document.getElementById("mascote-frase");
const balaoMascote = document.getElementById("mascote-balao");
const imgMascote = document.getElementById("mascote-img");

const frases = [
  "Oi! Eu sou a Liri! 🦒",
  "Clique em mim para voltar ao início!",
  "Cada exercício é um passo a mais na comunicação da criança.",
  "Você já viu a página \"Quem Somos\"?",
  "Praticar um pouquinho todo dia faz toda diferença!",
  "Bem-vindo(a) ao Liri!",
];

let indiceFrase = 0;

function mostrarBalao() {
  fraseMascote.textContent = frases[indiceFrase];
  indiceFrase = (indiceFrase + 1) % frases.length;
  balaoMascote.classList.add("visivel");
}

function esconderBalao() {
  balaoMascote.classList.remove("visivel");
}

// Mouse (desktop)
imgMascote.addEventListener("mouseenter", mostrarBalao);
imgMascote.addEventListener("mouseleave", esconderBalao);

// Teclado (acessibilidade - navegação por Tab)
imgMascote.addEventListener("focus", mostrarBalao);
imgMascote.addEventListener("blur", esconderBalao);
