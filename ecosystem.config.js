module.exports = {
    apps: [{
        name: "Gateway",
        version: "1.0.0",
        cwd: "./",
        script: "gateway.js",
        autorestart: true,
        watch: true,
       watch_delay: 1000
    }]
}