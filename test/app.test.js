const request = require('supertest');
const app = require('../app/server');

describe('App basic test', () => {
  it('should return 200 OK from homepage', async () => {
    await request(app).get('/').expect(200);
  });
});
