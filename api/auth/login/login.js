const { CognitoIdentityProviderClient, InitiateAuthCommand, GetUserCommand } = require("@aws-sdk/client-cognito-identity-provider");
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.MY_REGION });

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return errorResponse('Method Not Allowed', 405);
    }

    const { email, password } = JSON.parse(event.body);

    if (!email || !password) {
        return errorResponse('Email and password are required', 400);
    }

    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;

    try {
        // Cognitoで認証
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: clientId,
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password
            }
        };

        const authCommand = new InitiateAuthCommand(authParams);
        const authResult = await cognitoClient.send(authCommand);
        const accessToken = authResult.AuthenticationResult.AccessToken;
        const refreshToken = authResult.AuthenticationResult.RefreshToken;

        // Cognitoからユーザー情報を取得
        const userParams = {
            AccessToken: accessToken
        };
        const getUserCommand = new GetUserCommand(userParams);
        const userInfo = await cognitoClient.send(getUserCommand);
        const cognitoEmail = userInfo.Username;

        // RDSに接続
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });

        try {
            // usersテーブルでチェック
            const [userRows] = await connection.execute('SELECT * FROM users WHERE email = ?', [cognitoEmail]);
            if (userRows.length > 0) {
                return successResponse({
                    message: 'Login successful',
                    access_token: accessToken,
                    refresh_token: refreshToken,
                    userType: 'user'
                });
            }

            // nutritionistsテーブルでチェック
            const [nutritionistRows] = await connection.execute('SELECT * FROM nutritionists WHERE email = ?', [cognitoEmail]);
            if (nutritionistRows.length > 0) {
                return successResponse({
                    message: 'Login successful',
                    access_token: accessToken,
                    refresh_token: refreshToken,
                    userType: 'nutritionist'
                });
            }

            // どちらのテーブルにも存在しない場合
            return errorResponse('User not found in database', 404);

        } finally {
            await connection.end();
        }

    } catch (error) {
        console.error('Login error:', error);
        return errorResponse('An error occurred during login', 500);
    }
};