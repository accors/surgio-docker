// gateway.js

'use strict';

const gateway = require('@surgio/gateway');

const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 3000);

(async () => {
  const app = await gateway.bootstrapServer();
  await app.listen(port, host);
  console.log(`> Your app is ready at http://${host}:${port}`);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
