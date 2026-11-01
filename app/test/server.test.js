import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createApp } from '../src/server.js';

async function withServer(run) {
  const server = createApp();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    return await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('GET /health reports ok', async () => {
  await withServer(async (base) => {
    const response = await fetch(`${base}/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
  });
});

test('an unknown route returns 404', async () => {
  await withServer(async (base) => {
    const response = await fetch(`${base}/missing`);
    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: 'not found' });
  });
});
