import express, { Request, Response } from "express";
import dotenv from "dotenv";
import os, { networkInterfaces } from "os";

dotenv.config();

const app = express();
const PORT = process.env.PORT;
const APP_VERSION = process.env.APP_VERSION;

const getServerIP = (): string => {
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === "IPv4" && !net.internal) {
        return net.address;
      }
    }
  }
  return "Unknown";
};

app.get("/", (req: Request, res: Response) => {
  res.json({
    serverIP: getServerIP(),
    hostname: os.hostname(),
    appVersion: APP_VERSION,
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
