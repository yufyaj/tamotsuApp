const { CognitoIdentityProviderClient, ListUsersCommand } = require("@aws-sdk/client-cognito-identity-provider");
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.MY_REGION });
const sesClient = new SESClient({ region: process.env.MY_REGION });

exports.handler = async (event) => {
    console.log("debug_log_0: start");

    const { email, userType } = JSON.parse(event.body);
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;
    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    // 入力バリデーション
    if (!email || !userType) {
        return errorResponse('必須フィールドが不足しています');
    }

    const connection = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME
    });

    console.log("debug_log_1: connected db");

    await connection.beginTransaction();

    console.log("debug_log_2: begin transaction");

    try {
        // Cognitoでメールアドレスの存在確認
        const listUsersParams = {
            UserPoolId: userPoolId,
            Filter: `email = "${email}"`,
            Limit: 1
        };
        const existingUsers = await cognitoClient.send(new ListUsersCommand(listUsersParams));
        if (existingUsers.Users.length > 0) {
            await connection.rollback();
            return errorResponse('このメールアドレスは既に登録されています');
        }

        console.log("debug_log_3: checked cognito");

        // 検証コードの生成
        const verificationCode = Math.random().toString(36).substring(2, 8);

        // RDSにユーザー情報を一時保存
        const [result] = await connection.execute(
            'INSERT INTO temp_users (email, user_type, verification_code) VALUES (?, ?, ?)',
            [email, userType, verificationCode]
        );

        console.log("debug_log_4: save temp_users");

        // 確認メールの送信
        await sesClient.send(new SendEmailCommand({
            Destination: { ToAddresses: [email] },
            Message: {
                Body: { Text: { Data: `TAMOTSUへご登録頂きありがとうございます。\n\n以下のリンクから確認を完了してください：\nhttps://tamotsu-app.com/verify?email=${email}&verificationCode=${verificationCode}&userType=${userType}` } },
                Subject: { Data: 'TAMOTSUへご登録ありがとうございます' }
            },
            Source: process.env.FROM_EMAIL_ADDRESS
        }));

        console.log("debug_log_5: send mail");

        await connection.commit();
        return successResponse({message:'仮登録が完了しました。メールをご確認ください。'});
    } catch (error) {
        await connection.rollback();
        console.error('Error:', error);
        return errorResponse('サーバーエラーが発生しました');
    } finally {
        await connection.end();
    }
};
