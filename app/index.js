const express = require("express");
const client = require("prom-client");

const app = express();

// Create a Registry which registers the metrics
const register = new client.Registry();

// Add default system metrics (CPU, RAM, event loop, GC, etc.)
client.collectDefaultMetrics({ register });

// Example custom metric
const httpRequestCounter = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"]
});

register.registerMetric(httpRequestCounter);

// Middleware for counting requests
app.use((req, res, next) => {
  res.on("finish", () => {
    httpRequestCounter.labels(req.method, req.path, res.statusCode).inc();
  });
  next();
});

app.get("/", (req, res) => {
  res.send("Hello World!");
});

// Metrics endpoint
app.get("/metrics", async (req, res) => {
  res.setHeader("Content-Type", register.contentType);
  res.send(await register.metrics());
});

app.listen(3050, () => console.log("Server running on port 3000"));
