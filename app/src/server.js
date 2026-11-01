import { createServer } from 'node:http';

const routes = {
  '/health': () => ({ status: 'ok' }),
};

export function createApp() {
  return createServer((request, response) => {
    const handler = routes[request.url];
    if (!handler) {
      response.writeHead(404, { 'content-type': 'application/json' });
      response.end(JSON.stringify({ error: 'not found' }));
      return;
    }
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify(handler()));
  });
}
