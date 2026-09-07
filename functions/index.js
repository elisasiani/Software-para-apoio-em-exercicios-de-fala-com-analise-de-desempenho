// =============================================================
// functions/index.js
// Cloud Functions da recuperação de senha por código de 6 dígitos
//
// 3 funções:
//   1. enviarCodigoRecuperacao  -> gera o código e manda por e-mail
//   2. verificarCodigoRecuperacao -> confere se o código digitado está certo
//   3. redefinirSenhaComCodigo  -> troca a senha de fato (via Admin SDK)
//
// As credenciais do e-mail remetente vêm do arquivo functions/.env
// (veja o arquivo .env.exemplo e o guia de configuração).
// =============================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
setGlobalOptions({ region: "southamerica-east1", maxInstances: 10 });

const db = admin.firestore();

const DURACAO_CODIGO_MS = 10 * 60 * 1000; // código vale por 10 minutos
const MAX_TENTATIVAS = 5;

function gerarCodigo() {
  return String(Math.floor(100000 + Math.random() * 900000)); // 6 dígitos
}

function criarTransporte() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_SENHA,
    },
  });
}

// ── 1. Envia o código de recuperação por e-mail ──────────────────────────────
exports.enviarCodigoRecuperacao = onCall(async (request) => {
  const email = String(request.data?.email || "").trim().toLowerCase();

  if (!email) {
    throw new HttpsError("invalid-argument", "Informe um e-mail.");
  }

  // Verifica se existe uma conta com esse e-mail no Firebase Authentication
  let usuario;
  try {
    usuario = await admin.auth().getUserByEmail(email);
  } catch (erro) {
    // Não revelamos se o e-mail existe ou não (evita que alguém
    // descubra quais e-mails estão cadastrados no sistema)
    return { sucesso: true };
  }

  const codigo = gerarCodigo();
  const agora = Date.now();

  await db.collection("codigos_recuperacao").doc(email).set({
    codigo,
    uid: usuario.uid,
    criadoEm: agora,
    expiraEm: agora + DURACAO_CODIGO_MS,
    tentativas: 0,
    verificado: false,
  });

  const transporte = criarTransporte();

  await transporte.sendMail({
    from: `"Liri" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: "Seu código de recuperação de senha - Liri",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto; padding: 24px;">
        <h2 style="color:#7a08af; margin-bottom: 4px;">Liri</h2>
        <p style="color:#333;">Use o código abaixo para redefinir sua senha:</p>
        <p style="font-size: 34px; font-weight: bold; letter-spacing: 10px; color:#510077; text-align:center; margin: 24px 0;">
          ${codigo}
        </p>
        <p style="color:#777; font-size: 13px;">
          Esse código expira em 10 minutos. Se você não solicitou essa alteração, apenas ignore este e-mail.
        </p>
      </div>
    `,
  });

  return { sucesso: true };
});

// ── 2. Verifica se o código digitado está correto ────────────────────────────
exports.verificarCodigoRecuperacao = onCall(async (request) => {
  const email = String(request.data?.email || "").trim().toLowerCase();
  const codigo = String(request.data?.codigo || "").trim();

  if (!email || !codigo) {
    throw new HttpsError("invalid-argument", "Informe e-mail e código.");
  }

  const ref = db.collection("codigos_recuperacao").doc(email);
  const snap = await ref.get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "Código não encontrado. Solicite um novo.");
  }

  const dados = snap.data();

  if (Date.now() > dados.expiraEm) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Código expirado. Solicite um novo.");
  }

  if (dados.tentativas >= MAX_TENTATIVAS) {
    await ref.delete();
    throw new HttpsError("resource-exhausted", "Muitas tentativas incorretas. Solicite um novo código.");
  }

  if (dados.codigo !== codigo) {
    await ref.update({ tentativas: admin.firestore.FieldValue.increment(1) });
    throw new HttpsError("invalid-argument", "Código incorreto.");
  }

  await ref.update({ verificado: true });
  return { sucesso: true };
});

// ── 3. Redefine a senha de fato (só funciona se o código já foi verificado) ──
exports.redefinirSenhaComCodigo = onCall(async (request) => {
  const email = String(request.data?.email || "").trim().toLowerCase();
  const codigo = String(request.data?.codigo || "").trim();
  const novaSenha = String(request.data?.novaSenha || "");

  if (novaSenha.length < 8) {
    throw new HttpsError("invalid-argument", "A senha deve ter pelo menos 8 caracteres.");
  }

  const ref = db.collection("codigos_recuperacao").doc(email);
  const snap = await ref.get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "Solicite um novo código.");
  }

  const dados = snap.data();

  if (!dados.verificado || dados.codigo !== codigo) {
    throw new HttpsError("permission-denied", "Verifique o código antes de redefinir a senha.");
  }

  if (Date.now() > dados.expiraEm) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Código expirado. Solicite um novo.");
  }

  await admin.auth().updateUser(dados.uid, { password: novaSenha });
  await ref.delete();

  return { sucesso: true };
});
