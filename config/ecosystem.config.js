module.exports = {
    apps: [{
        name: "Gateway",
        version: "1.0.0",
        cwd: "/surgio",
        script: "gateway.js",
        autorestart: true,
        watch: ["Gateway"],
    }]
}