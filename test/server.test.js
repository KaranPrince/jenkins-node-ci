const request = require("supertest");
const server = require("../app/server");

describe("Server.js coverage", () => {
  it("should respond with Deployment Success message on /", async () => {
    const res = await request(server).get("/");
    if (res.status !== 200) throw new Error("Expected 200 OK");
    if (!res.text.includes("Jenkins Deployment Successful")) {
      throw new Error("Expected response to include Deployment Success message");
    }
  });
});
