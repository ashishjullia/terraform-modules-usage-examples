const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { Client } = require('pg');

const smClient = new SecretsManagerClient({});

exports.handler = async (event) => {
    console.log("Lambda: Started.");
    const secretName = process.env.SECRET_NAME;
    const dbHost = process.env.DB_HOST;
    const dbName = process.env.DB_NAME;
    const iamUser = process.env.IAM_USER;

    if (!secretName || !dbHost || !dbName || !iamUser) {
        console.error('Lambda: Missing one or more required environment variables (SECRET_NAME, DB_HOST, DB_NAME, IAM_USER).');
        return {
            statusCode: 400,
            body: JSON.stringify({ message: 'Configuration error: Missing required environment variables.' })
        };
    }

    if (!/^[a-zA-Z_][a-zA-Z0-9_$-]*$/.test(iamUser)) {
        console.error(`Lambda: Invalid IAM_USER format: '${iamUser}'. Check environment variable.`);
        return {
            statusCode: 400,
            body: JSON.stringify({ message: 'Configuration error: Invalid format for IAM_USER environment variable.' })
        };
    }

    const escapedIamUser = `"${iamUser.replace(/"/g, '""')}"`;

    const createUserSql = `CREATE USER ${escapedIamUser} WITH LOGIN`;
    const grantRoleSql = `GRANT rds_iam TO ${escapedIamUser}`;
    const grantUsageSql = `GRANT USAGE ON SCHEMA public TO ${escapedIamUser}`;
    const grantCreateSql = `GRANT CREATE ON SCHEMA public TO ${escapedIamUser}`;


    let creds;
    try {
        console.log(`Lambda: Attempting to get secret: ${secretName}`);
        const command = new GetSecretValueCommand({ SecretId: secretName });
        const secret = await smClient.send(command);
        if (secret.SecretString) { creds = JSON.parse(secret.SecretString); console.log("Lambda: Secret retrieved successfully."); }
        else { console.error("Lambda: SecretString not found..."); return { statusCode: 500, body: JSON.stringify({ message: "Secret format error..." })}; }
        if (!creds?.username || !creds?.password) { console.error("Lambda: Incomplete credentials..."); return { statusCode: 500, body: JSON.stringify({ message: "Incomplete credentials..." }) }; }
    } catch (error) { console.error(`Lambda: Secret retrieval error...`); return { statusCode: 500, body: JSON.stringify({ message: `Secret error...` }) }; }

    console.log(`Lambda: Connecting to DB ${dbName} at ${dbHost} as master user ${creds.username}`);
    const client = new Client({
        host: dbHost,
        database: dbName,
        user: creds.username,
        password: creds.password,
        ssl: { rejectUnauthorized: false }
    });

    let operationFailed = false;

    try {
        await client.connect();
        console.log("Lambda: DB connected.");

        try {
            console.log(`Lambda: Attempting to execute: CREATE USER ${iamUser}...`);
            await client.query(createUserSql);
            console.log(`Lambda: User ${iamUser} created.`);
        } catch (error) {
            if (error.code === '42710') { console.log(`Lambda: User ${iamUser} already exists.`); }
            else { console.error(`Lambda: Create user failed...`); operationFailed = true; throw error; }
        }

        if (!operationFailed) {
            try {
                console.log(`Lambda: Attempting to execute: GRANT rds_iam TO ${iamUser}...`);
                await client.query(grantRoleSql);
                console.log(`Lambda: Role rds_iam granted to user ${iamUser}.`);
            } catch (error) { console.error(`Lambda: Grant role rds_iam failed...`); operationFailed = true; throw error; }
        }

        if (!operationFailed) {
            try {
                console.log(`Lambda: Verifying role grant for user '${iamUser}'...`);
                const verifyQueryText = `SELECT pg_catalog.pg_has_role($1, 'rds_iam', 'MEMBER') AS has_role;`;
                const verifyResult = await client.query(verifyQueryText, [iamUser]);

                if (verifyResult.rows.length > 0 && verifyResult.rows[0].has_role === true) {
                    console.log(`Lambda: Verification successful. User ${iamUser} has role rds_iam.`);

                    console.log(`Lambda: Granting schema permissions to user '${iamUser}'...`);
                    try {
                        console.log(`Lambda: Executing: GRANT USAGE ON SCHEMA public...`);
                        await client.query(grantUsageSql);
                        console.log(`Lambda: Executing: GRANT CREATE ON SCHEMA public...`);
                        await client.query(grantCreateSql);
                        console.log("Lambda: Schema USAGE and CREATE granted successfully.");
                    } catch (grantError) {
                        console.error(`Lambda: Failed to grant schema permissions: ${grantError.message} (Code: ${grantError.code || 'N/A'})`);
                        operationFailed = true;
                    }
                } else {
                     console.error(`Lambda: Verification FAILED...`);
                     operationFailed = true;
                }
            } catch (error) { 
                 console.error(`Lambda: Role verification or permission granting step failed...`);
                 operationFailed = true;
            }
        }

    } catch (error) { 
        console.error("Lambda: DB connection or operation error...", error.message);
        operationFailed = true;
    } finally { 
         if (client) { await client.end().catch(err => console.error("Lambda: DB close error...")); console.log("Lambda: DB connection closed."); }
    }

    if (operationFailed) {
        console.error("Lambda: Finished with errors.");
        return null; 
    } else {
        console.log("Lambda: Finished successfully.");
        return null; 
    }
};
