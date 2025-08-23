const request = require("supertest");
const app = require("../app/app");
let server;

describe("Server.js coverage", () => {
  before((done) => {
    const port = 4000; // use a test-only port
    server = app.listen(port, () => done());
  });

  after((done) => {
    server.close(() => done());
  });

  it("should respond with Hello message on /", async () => {
    const res = await request(server).get("/");
    if (res.status !== 200) throw new Error("Expected 200 OK");
    if (!res.text.includes("Hello from Node.js")) {
      throw new Error("Expected response to include Hello from Node.js");
    }
  });
});
