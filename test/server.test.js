const { spawn } = require("child_process");
const path = require("path");

describe("Server.js listen()", () => {
  it("should start the server process", (done) => {
    const serverProcess = spawn("node", [path.join(__dirname, "../app/server.js")], {
      env: { ...process.env, PORT: 4000 },
    });

    serverProcess.stdout.on("data", (data) => {
      if (data.toString().includes("Server listening")) {
        serverProcess.kill();
        done();
      }
    });

    serverProcess.on("error", done);
  });
});
