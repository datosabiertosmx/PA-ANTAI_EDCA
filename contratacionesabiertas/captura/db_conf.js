
var options = {};

var pgp = require('pg-promise')(options);

const config = {
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_NAME ||'edca',
    user: process.env.POSTGRES_USER || 'user_back',
    password: process.env.POSTGRES_PASSWORD || 'back_password'
};

var edca_db = pgp(config);

console.log('DB Config -> ', JSON.stringify(config));

const configDash = {
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_NAME ||'edca',
    user: process.env.POSTGRES_USER || 'user_front',
    password: process.env.POSTGRES_PASSWORD || 'front_password'
};

var connectionDashboard = pgp(configDash);
var dash_user = configDash.user;


module.exports = {
    pgp: pgp,
    edca_db : edca_db,
    dashboard: connectionDashboard,
    dash_user: dash_user
};
