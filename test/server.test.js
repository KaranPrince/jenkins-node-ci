const request = require("supertest");
const app = require("../app/app");
let server;

describe("Server.js coverage", () => {
  beforeAll(() => {
    const port = 4000; // use a test-only port
    server = app.listen(port);
  });

  afterAll(() => {
    server.close();
  });

  it("should respond with Hello message on /", async () => {
    const res = await request(server).get("/");
    expect(res.status).toBe(200);
    expect(res.text).toMatch(/Hello from Node.js/);
  });
});
