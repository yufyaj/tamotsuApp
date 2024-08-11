const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');
const { successResponse, errorResponse } = require('response-utils');

const cognito = new AWS.CognitoIdentityServiceProvider();
const ses = new AWS.SES();

exports.handler = async (event) => {
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

    await connection.beginTransaction();

    try {
        // Cognitoでメールアドレスの存在確認
        const listUsersParams = {
            UserPoolId: userPoolId,
            Filter: `email = "${email}"`,
            Limit: 1
        };
        const existingUsers = await cognito.listUsers(listUsersParams).promise();
        if (existingUsers.Users.length > 0) {
            await connection.rollback();
            return errorResponse('このメールアドレスは既に登録されています');
        }

        // 検証コードの生成
        const verificationCode = Math.random().toString(36).substring(2, 8);

        // RDSにユーザー情報を一時保存
        const [result] = await connection.execute(
            'INSERT INTO temp_users (email, user_type, verification_code) VALUES (?, ?, ?)',
            [email, userType, verificationCode]
        );

        // 確認メールの送信
        await ses.sendEmail({
            Destination: { ToAddresses: [email] },
            Message: {
                Body: { Text: { Data: `TAMOTSUへご登録頂きありがとうございます。\n\n以下のリンクから確認を完了してください：\nhttps://tamotsu-app.com/verify?email=${email}&verificationCode=${verificationCode}&userType=${userType}` } },
                Subject: { Data: 'TAMOTSUへご登録ありがとうございます' }
            },
            Source: process.env.FROM_EMAIL_ADDRESS
        }).promise();

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
