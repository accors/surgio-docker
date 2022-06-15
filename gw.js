'use strict';

const gateway = require('@surgio/gateway');

(async () => {
    const app = await gateway.bootstrapServer();
    await app.listen(8080, '0.0.0.0');
    console.log('> Your app is ready at http://0.0.0.0:3000');
})();