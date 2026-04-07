const express = require('express');
const app = express();

// Trust the proxy to get the correct visitor IP
app.set('trust proxy', true);

app.get('/', (req, res) => {
    res.json({
        timestamp: new Date(),
        ip: req.ip
    });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
