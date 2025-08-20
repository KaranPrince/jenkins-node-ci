const assert = require('assert');
const http = require('http');

describe('App basic test', function () {
  it('should return 200 OK from homepage', function (done) {
    http.get('http://localhost:3000', (res) => {
      assert.strictEqual(res.statusCode, 200);
      done();
    }).on('error', (err) => done(err));
  });
});
