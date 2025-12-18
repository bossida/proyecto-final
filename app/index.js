const express = require("express");
const axios = require("axios");
const swaggerUi = require("swagger-ui-express");
const swaggerJsdoc = require("swagger-jsdoc");
const client = require("prom-client");

const app = express();
const PORT = 3080;

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
  if (
    req.path === "/metrics" ||
    req.path.startsWith("/api-docs")
  ) {
    return next();
  }
  res.on("finish", () => {
    httpRequestCounter.labels(req.method, req.path, res.statusCode).inc();
  });
  next();
});


/* -------------------- Swagger config -------------------- */
const swaggerOptions = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Country Search API",
      version: "1.0.0",
      description: "API to search countries by partial name using Rest Countries"
    },
    servers: [
      {
        url: `/`
      }
    ]
  },
  apis: ["./index.js"] // where Swagger comments live
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));



/* -------------------- Routes -------------------- */

/**
 * @swagger
 * /countries:
 *   get:
 *     summary: Search countries by partial name
 *     description: Returns country name, capital, and flag URL
 *     parameters:
 *       - in: query
 *         name: name
 *         required: true
 *         schema:
 *           type: string
 *         description: Partial country name (e.g. "arg")
 *     responses:
 *       200:
 *         description: List of matching countries
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   name:
 *                     type: string
 *                     example: Argentine Republic
 *                   capital:
 *                     type: string
 *                     example: Buenos Aires
 *                   flag:
 *                     type: string
 *                     example: https://flagcdn.com/w320/ar.png
 *       400:
 *         description: Missing query parameter
 *       404:
 *         description: No countries found
 */
app.get("/countries", async (req, res) => {
  const { name } = req.query;

  if (!name) {
    return res.status(400).json({
      error: "Query parameter 'name' is required"
    });
  }

  try {
    const response = await axios.get(
      `https://restcountries.com/v3.1/name/${name}`,
      { params: { fullText: false } }
    );

    const countries = response.data.map(country => ({
      name: country.name?.official || country.name?.common,
      capital: country.capital ? country.capital[0] : "N/A",
      flag: country.flags?.png || country.flags?.svg
    }));

    res.json(countries);
  } catch (error) {
    if (error.response?.status === 404) {
      return res.status(404).json({ message: "No countries found" });
    }
    res.status(500).json({ error: "Error fetching countries" });
  }
});

app.get("/", (req, res) => {
  res.send("Hello World!");
});

// Metrics endpoint
app.get("/metrics", async (req, res) => {
  res.setHeader("Content-Type", register.contentType);
  res.send(await register.metrics());
});

app.listen(PORT, () => console.log("Server running on port 3080"));
