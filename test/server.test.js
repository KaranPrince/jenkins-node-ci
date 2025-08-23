const request = require("supertest");
const app = require("../app/app");

describe("Server startup", () => {
  it("should respond on / with Hello message", (done) => {
    request(app)
      .get("/")
      .expect(200)
      .expect(/Hello from Node.js/)
      .end(done);
  });
});
