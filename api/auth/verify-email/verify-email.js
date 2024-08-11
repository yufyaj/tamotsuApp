const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');
const { formatResponse, successResponse, errorResponse } = require('response-utils');

const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
    // HTTPメソッドを取得
    const httpMethod = event.httpMethod;

    switch(httpMethod) {
        case 'POST':
            return handlePostRequest(event);
        case 'OPTIONS':
            return successResponse({});
        default:
            return errorResponse('Method Not Allowed', 405);
    }
};

async function handlePostRequest(event) {
    const { email, verificationCode, password } = JSON.parse(event.body);
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;
    
    console.log(password);

    // 入力バリデーション
    if (!email || !verificationCode || !password) {
        return errorResponse('必須フィールドが不足しています');
    }

    const connection = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME
    });

    await connection.beginTransaction();

    try {
        // MySQLから一時保存データを取得
        const [rows] = await connection.execute(
            'SELECT * FROM temp_users WHERE email = ?',
            [email]
        );

        if (rows.length === 0) {
            await connection.rollback();
            return errorResponse('アイテムが見つかりません。', 400);
        }

        const tempUser = rows[0];

        if (tempUser.verification_code !== verificationCode) {
            await connection.rollback();
            return errorResponse('無効な検証コードです。', 400);
        }

        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

        if (tempUser.user_type === 'user') {
            // シーケンスを取得してuser_idを生成
            const [sequenceResult] = await connection.execute('SELECT get_next_sequence("user_id_seq") AS next_val');
            const userId = `U${String(sequenceResult[0].next_val).padStart(7, '0')}`;

            // usersテーブルに登録
            await connection.execute(
                'INSERT INTO users (user_id, email, created_at, last_login) VALUES (?, ?, ?, ?)',
                [userId, email, now, now]
            );

            // Cognitoにユーザーを登録
            const signUpParams = {
                ClientId: clientId,
                Username: email,
                Password: password,
                UserAttributes: [{
                    Name: 'custom:userId',
                    Value: userId
                }]
            };
            await cognito.signUp(signUpParams).promise();
        } else if (tempUser.user_type === 'nutritionist') {
            // シーケンスを取得してnutrition_idを生成
            const [sequenceResult] = await connection.execute('SELECT get_next_sequence("nutritionist_id_seq") AS next_val');
            const nutritionistId = `N${String(sequenceResult[0].next_val).padStart(7, '0')}`;

            // usersテーブルに登録
            await connection.execute(
                'INSERT INTO nutritionists (nutritionist_id, email, created_at, last_login) VALUES (?, ?, ?, ?)',
                [nutritionistId, email, now, now]
            );

            // Cognitoにユーザーを登録
            const signUpParams = {
                ClientId: clientId,
                Username: email,
                Password: password,
                UserAttributes: [{
                    Name: 'custom:nutritionistId',
                    Value: nutritionistId
                }]
            };
            await cognito.signUp(signUpParams).promise();
        }

        // ユーザーを確認済みに設定
        const confirmSignUpParams = {
            UserPoolId: userPoolId,
            Username: email,
        };
        await cognito.adminConfirmSignUp(confirmSignUpParams).promise();

        // ログイン処理
        const loginParams = {
            AuthFlow: 'ADMIN_NO_SRP_AUTH',
            UserPoolId: userPoolId,
            ClientId: clientId,
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password,
            },
        };
        const loginResponse = await cognito.adminInitiateAuth(loginParams).promise();
        const token = loginResponse.AuthenticationResult.AccessToken;

        // temp_usersテーブルから該当のレコードを削除
        await connection.execute(
            'DELETE FROM temp_users WHERE email = ?',
            [email]
        );

        await connection.commit();

        return successResponse({ message: 'ユーザーの登録が完了しました', token: token});
    } catch (error) {
        await connection.rollback();
        console.error('Error:', error);
        return errorResponse('サーバーエラーが発生しました');
    } finally {
        await connection.end();
    }
}
