import { startServer } from '@surgio/gateway/node';

const hostname = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 3000);

await startServer({ hostname, port });
