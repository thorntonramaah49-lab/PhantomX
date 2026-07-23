import { Router } from "express";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const router = Router();

router.get("/phantomx.lua", (req, res) => {
  const filePath = path.resolve(__dirname, "../public/phantomx.lua");
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.sendFile(filePath);
});

export default router;
