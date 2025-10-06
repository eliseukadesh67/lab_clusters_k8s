import gRpcDownloadClient from "../clients/downloadClient/grpc.client.js";
import path from "path";
import fs from "fs";
import crypto from "crypto";

const TEMP_DOWNLOAD_DIR = path.join(process.cwd(), "temp_downloads");
// A verificação e criação da pasta já é feita pelo Dockerfile, mas manter aqui é seguro.
if (!fs.existsSync(TEMP_DOWNLOAD_DIR)) {
  fs.mkdirSync(TEMP_DOWNLOAD_DIR);
}

const getVideoMetadata = async (req, res, next) => {
  try {
    const { url } = req.query;
    if (!url) {
      return res
        .status(400)
        .json({ error: 'O parâmetro "url" é obrigatório.' });
    }
    // Nota: O cliente REST não é usado nesta implementação, mas a lógica é mantida por flexibilidade
    const result = await gRpcDownloadClient.getMetadata({ url });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

const downloadVideo = (req, res, next) => {
  const { url } = req.query;
  if (!url) {
    return res.status(400).json({ error: 'O parâmetro "url" é obrigatório.' });
  }

  try {
    // Flag de controle para evitar limpeza em caso de sucesso
    let isCompletedSuccessfully = false;

    const stream = gRpcDownloadClient.download({ url });
    const fileId = `${crypto.randomBytes(16).toString("hex")}.mp4`;
    const tempFilePath = path.join(TEMP_DOWNLOAD_DIR, fileId);
    const fileWriteStream = fs.createWriteStream(tempFilePath);

    console.log(
      `[Gateway] Iniciando download para URL: ${url}. Arquivo temporário: ${fileId}`
    );

    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders();

    const sendSse = (data) => {
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    };

    stream.on("data", (chunk) => {
      if (chunk.progress) {
        sendSse({ type: "progress", ...chunk.progress });
      } else if (chunk.data) {
        fileWriteStream.write(chunk.data);
      }
    });

    stream.on("end", () => {
      // Marca o download como bem-sucedido ANTES de fechar a conexão
      isCompletedSuccessfully = true;

      console.log(`[Gateway] Stream gRPC para ${fileId} finalizado.`);
      fileWriteStream.end(() => {
        console.log(`[Gateway] Arquivo ${fileId} salvo com sucesso no disco.`);
        sendSse({
          type: "completed",
          downloadUrl: `api/downloads/file/${fileId}`,
        });
        res.end(); // Fecha a conexão SSE
      });
    });

    stream.on("error", (err) => {
      console.error(`[Gateway] Erro no stream gRPC para ${fileId}:`, err);
      fileWriteStream.end();
      fs.unlink(tempFilePath, (unlinkErr) => {
        if (unlinkErr)
          console.error(
            `[Gateway] Falha ao remover arquivo temporário ${fileId}:`,
            unlinkErr
          );
      });
      sendSse({
        type: "error",
        message: err.details || "Ocorreu um erro no servidor.",
      });
      res.end();
    });

    req.on("close", () => {
      // Só executa a limpeza se o download NÃO foi concluído com sucesso
      if (!isCompletedSuccessfully) {
        console.log(
          `[Gateway] Cliente desconectou (download abortado). Cancelando stream para ${fileId}.`
        );
        stream.cancel();
        fileWriteStream.end();
        fs.unlink(tempFilePath, () => {
          console.log(
            `[Gateway] Arquivo temporário abortado ${fileId} removido.`
          );
        });
      } else {
        console.log(
          `[Gateway] Conexão SSE para ${fileId} fechada normalmente após o sucesso.`
        );
      }
    });
  } catch (error) {
    console.error("Erro síncrono ao iniciar download:", error);
    next(error);
  }
};

const serveDownloadedVideo = (req, res) => {
  const { file_id } = req.params;

  if (!file_id || !/^[a-f0-9]+\.mp4$/.test(file_id)) {
    return res.status(400).send("File ID inválido.");
  }

  const filePath = path.join(TEMP_DOWNLOAD_DIR, file_id);
  console.log(`[Gateway] Cliente solicitou o arquivo: ${file_id}`);

  if (!fs.existsSync(filePath)) {
    console.warn(
      `[Gateway] Tentativa de acesso a arquivo não encontrado: ${file_id}`
    );
    return res.status(404).send("Arquivo não encontrado ou já expirado.");
  }

  // res.download() cuida dos headers e do streaming
  res.download(filePath, file_id, (err) => {
    if (err) {
      console.error(`[Gateway] Erro ao enviar o arquivo ${file_id}:`, err);
    } else {
      // O callback é executado APÓS o envio do arquivo ser concluído
      console.log(
        `[Gateway] Arquivo ${file_id} enviado com sucesso. Removendo.`
      );
      fs.unlink(filePath, (unlinkErr) => {
        if (unlinkErr) {
          console.error(
            `[Gateway] Falha ao remover o arquivo ${file_id}:`,
            unlinkErr
          );
        }
      });
    }
  });
};

export default {
  getVideoMetadata,
  downloadVideo,
  serveDownloadedVideo,
};
