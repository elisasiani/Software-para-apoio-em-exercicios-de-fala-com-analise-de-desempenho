const textoDinamico = document.getElementById('texto-dinamico');

if (textoDinamico) {
    const texto = 'fonoaudiologia infantil';
    let indiceTexto = 0;

    function digitarTexto() {
        if (indiceTexto < texto.length) {
            textoDinamico.textContent += texto.charAt(indiceTexto);
            indiceTexto++;

            setTimeout(digitarTexto, 80);
        }
    }

    digitarTexto();
}