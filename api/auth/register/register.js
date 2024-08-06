const AWS = require('aws-sdk');
const { successResponse, errorResponse } = require('response-utils');
const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamodb = new AWS.DynamoDB.DocumentClient();
const ses = new AWS.SES();

exports.handler = async (event) => {
    const { email, userType } = JSON.parse(event.body);
    const clientId = process.env.COGNITO_USER_POOL_CLIENT_ID;
    const userPoolId = process.env.COGNITO_USER_POOL_ID;

    // 入力バリデーション
    if (!email || !userType) {
        return errorResponse('必須フィールドが不足しています');
    }

    try {
        // Cognitoでメールアドレスの存在確認
        const listUsersParams = {
            UserPoolId: userPoolId,
            Filter: `email = "${email}"`,
            Limit: 1
        };
        const existingUsers = await cognito.listUsers(listUsersParams).promise();
        if (existingUsers.Users.length > 0) {
            return errorResponse('このメールアドレスは既に登録されています');
        }

        // 検証コードの生成
        const verificationCode = Math.random().toString(36).substring(2, 8);

        // DynamoDBにユーザー情報を一時保存
        const timestamp = new Date().toISOString();
        const dynamoParams = {
            TableName: 'tamotsu-table',
            Item: {
                PK: `EMAIL#${email}`,
                SK: `METADATA#${timestamp}`,
                TypePK: `TYPE#TEMP_USER`,
                TypeSK: `EMAIL#${email}`,
                GSI1PK: `STATUS#UNVERIFIED`,
                GSI1SK: `CREATED#${timestamp}`,
                Type: 'TEMP_USER',
                Data: {
                    email: email,
                    user_type: userType,
                    verification_code: verificationCode,
                    created_at: timestamp
                }
            }
        };

        await dynamodb.put(dynamoParams).promise();

        // 確認メールの送信
        await ses.sendEmail({
            Destination: { ToAddresses: [email] },
            Message: {
                Body: { Text: { Data: `TAMOTSUへご登録頂きありがとうございます。\n\n以下のリンクから確認を完了してください：\nhttps://api.tamotsu-app.com/auth/verify-email?email=${email}&verificationCode=${verificationCode}` } },
                Subject: { Data: 'TAMOTSUへご登録ありがとうございます' }
            },
            Source: process.env.FROM_EMAIL_ADDRESS
        }).promise();

        return successResponse({message:'仮登録が完了しました。メールをご確認ください。'});
    } catch (error) {
        console.error('Error:', error);
        return errorResponse('サーバーエラーが発生しました');
    }
};
