const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;
const indexPath = path.join(__dirname, "index.html");

function renderIndex() {
  let html = fs.readFileSync(indexPath, "utf8");
  const mapping = {
    "__BUILD_NUMBER__": process.env.BUILD_NUMBER || "N/A",
    "__GIT_DATE__": process.env.GIT_DATE || new Date().toISOString(),
    "__GIT_BRANCH__": process.env.GIT_BRANCH || "unknown",
    "__GIT_COMMIT__": process.env.GIT_COMMIT || "unknown",
    "__GIT_AUTHOR__": process.env.GIT_AUTHOR || "unknown",
    "__GIT_MESSAGE__": process.env.GIT_MESSAGE || "n/a",
    "__ENVIRONMENT__": process.env.ENVIRONMENT || "local",
  };
  Object.keys(mapping).forEach((key) => {
    html = html.replace(new RegExp(key, "g"), mapping[key]);
  });
  return html;
}

app.get("/", (req, res) => {
  res.type("html").send(renderIndex());
});

app.use(express.static(path.join(__dirname)));

module.exports = app; // 👉 export the app only
